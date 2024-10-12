require 'discordrb'
require 'sqlite3'
require 'json'
require 'fileutils'
require 'net/http'
require 'uri'
require 'rspotify'

# Authenticate Spotify API
RSpotify.authenticate('<CLIENT_ID>', '<CLIENT_SECRET>')

# Launch Node.js Middleware
middleware_dir = "discord_audio_middleware"
middleware_command = "node server.js"

# Check if middleware directory exists
if Dir.exist?(middleware_dir)
  Dir.chdir(middleware_dir) do
    puts "Starting Node.js middleware..."
    # Run Node.js server in the background with error handling
    if system("#{middleware_command} &")
      puts "Node.js middleware started successfully."
    else
      puts "Failed to start Node.js middleware. Please check the server script."
      exit
    end
  end
  Dir.chdir("..") # Return to the original directory
else
  puts "Middleware directory not found. Please ensure that the middleware is installed in #{middleware_dir}."
  exit
end

# First Time Setup
CONFIG_FILE = 'config.json'

unless File.exist?(CONFIG_FILE)
  puts 'Welcome to the Discord Music Bot setup!'
  puts 'Before we begin, make sure you have your Discord Bot Token ready.'
  puts 'Setting up the configuration...'
  print 'Please enter your Discord Bot Token: '
  bot_token = gets.chomp

  print 'Please enter your desired command prefix (default is !): '
  command_prefix = gets.chomp
  command_prefix = '!' if command_prefix.empty?

  config = { 'bot_token' => bot_token, 'command_prefix' => command_prefix }
  begin
    File.open(CONFIG_FILE, 'w') { |file| file.write(config.to_json) }
    puts 'Configuration saved!'
  rescue Errno::EACCES => e
    puts "Failed to write configuration file: #{e.message}. Please check your file permissions."
    exit
  end
end

# Load Config
config = JSON.parse(File.read(CONFIG_FILE))
DISCORD_BOT_TOKEN = config['bot_token']
COMMAND_PREFIX = config['command_prefix']

# Initialize SQLite Database
DB_FILE = 'music_bot.db'

unless File.exist?(DB_FILE)
  puts 'Setting up the database for the first time...'
  db = SQLite3::Database.new DB_FILE
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS playlists (
      id INTEGER PRIMARY KEY,
      user_id TEXT,
      name TEXT,
      songs TEXT
    );
  SQL

  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS settings (
      id INTEGER PRIMARY KEY,
      user_id TEXT,
      key TEXT,
      value TEXT
    );
  SQL

  puts 'Database setup complete!'
else
  db = SQLite3::Database.new DB_FILE
end

# Initialize Discord Bot
bot = Discordrb::Commands::CommandBot.new(token: DISCORD_BOT_TOKEN, prefix: COMMAND_PREFIX)

# Commands
bot.command(:play, description: 'Play a song from YouTube') do |event, *song_name|
  # Check if the user is in a voice channel
  user_voice_channel = event.user.voice_channel
  if user_voice_channel.nil?
    event.respond 'You need to be in a voice channel for me to join!'
    next
  end

  # Check if the bot is already connected to a voice channel
  if bot.voice(event.server)&.channel != user_voice_channel
    # Make the bot join the user's voice channel
    bot.voice_connect(user_voice_channel)
  end

  # Play the song
  song_name = song_name.join(' ')
  if song_name.empty?
    event.respond 'Please provide a song name or URL!'
  else
    event.respond "Requesting to play: #{song_name}"

    # Send request to Node.js middleware
    uri = URI.parse("http://localhost:3000/play")
    response = Net::HTTP.post_form(uri, { "song_name" => song_name, "guild_id" => event.server.id, "channel_id" => user_voice_channel.id })
    if response.code == "200"
      event.respond "Playing: #{song_name}"
    else
      event.respond "There was an error processing your request."
    end
  end
end

bot.command(:playspotify, description: 'Play songs from a Spotify playlist') do |event, playlist_url|
  # Check if the user is in a voice channel
  user_voice_channel = event.user.voice_channel
  if user_voice_channel.nil?
    event.respond 'You need to be in a voice channel for me to join!'
    next
  end

  # Check if the bot is already connected to a voice channel
  if bot.voice(event.server)&.channel != user_voice_channel
    # Make the bot join the user's voice channel
    bot.voice_connect(user_voice_channel)
  end

  # Extract Spotify playlist ID from URL
  begin
    playlist_id = playlist_url.split('/').last.split('?').first
    playlist = RSpotify::Playlist.find_by_id(playlist_id)
  rescue StandardError => e
    event.respond "Failed to fetch the Spotify playlist: #{e.message}. Please ensure the URL is correct."
    next
  end

  if playlist.nil?
    event.respond 'Invalid Spotify playlist URL!'
    next
  end

  # Iterate over tracks and search YouTube for each one
  playlist.tracks.each do |track|
    song_name = "#{track.name} by #{track.artists.first.name}"
    event.respond "Searching YouTube for: #{song_name}"
    # Send request to Node.js middleware to play the song
    uri = URI.parse("http://localhost:3000/play")
    response = Net::HTTP.post_form(uri, { "song_name" => song_name, "guild_id" => event.server.id, "channel_id" => user_voice_channel.id })
    if response.code != "200"
      event.respond "There was an error playing: #{song_name}"
    end
  end
end

bot.command(:addplaylist, description: 'Add a new playlist') do |event, playlist_name|
  user_id = event.user.id
  if playlist_name.nil? || playlist_name.strip.empty?
    event.respond 'Please provide a valid playlist name!'
  else
    db.execute('INSERT INTO playlists (user_id, name, songs) VALUES (?, ?, ?)', [user_id, playlist_name.strip, '[]'])
    event.respond "Playlist '#{playlist_name}' has been created!"
  end
end

bot.command(:addsong, description: 'Add a song to an existing playlist') do |event, playlist_name, *song_name|
  user_id = event.user.id
  song_name = song_name.join(' ')
  if playlist_name.nil? || song_name.empty?
    event.respond 'Please provide both a playlist name and a song name!'
  else
    playlist = db.execute('SELECT songs FROM playlists WHERE user_id = ? AND name = ?', [user_id, playlist_name]).first
    if playlist
      songs = JSON.parse(playlist[0])
      songs << song_name
      db.execute('UPDATE playlists SET songs = ? WHERE user_id = ? AND name = ?', [songs.to_json, user_id, playlist_name])
      event.respond "Added '#{song_name}' to playlist '#{playlist_name}'."
    else
      event.respond "Playlist '#{playlist_name}' not found!"
    end
  end
end

bot.command(:playlists, description: 'List all playlists') do |event|
  user_id = event.user.id
  playlists = db.execute('SELECT name FROM playlists WHERE user_id = ?', [user_id])
  if playlists.empty?
    event.respond 'You have no playlists yet.'
  else
    playlist_names = playlists.map { |p| p[0] }.join(', ')
    event.respond "Your playlists: #{playlist_names}"
  end
end

bot.command(:setvolume, description: 'Set the default volume level') do |event, volume|
  user_id = event.user.id
  if volume.nil? || !(0..100).include?(volume.to_i)
    event.respond 'Please provide a valid volume level (0-100)!'
  else
    db.execute('INSERT OR REPLACE INTO settings (user_id, key, value) VALUES (?, ?, ?)', [user_id, 'volume', volume])
    event.respond "Default volume set to #{volume}."
  end
end

bot.command(:help, description: 'Display available commands') do |event|
  event.respond "Available commands:\n" +
                "#{COMMAND_PREFIX}play [song name or URL] - Play a song.\n" +
                "#{COMMAND_PREFIX}playspotify [Spotify playlist URL] - Play songs from a Spotify playlist.\n" +
                "#{COMMAND_PREFIX}addplaylist [name] - Add a new playlist.\n" +
                "#{COMMAND_PREFIX}addsong [playlist name] [song name] - Add a song to a playlist.\n" +
                "#{COMMAND_PREFIX}playlists - List all your playlists.\n" +
                "#{COMMAND_PREFIX}setvolume [0-100] - Set your default volume level."
end

# Run the Bot
bot.run