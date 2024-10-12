# Discord Music Bot

This is a feature-rich, lightweight music bot using Ruby for commands and Node.js for audio playback. It integrates an SQLite database for data persistence and provides personalized music features such as user-created playlists and customizable settings.

## Features

1. **First-Time Setup**
   - Prompts the user to enter the Discord bot token and desired command prefix during initial setup.
   - Configuration is saved to a `config.json` file for future use. Ensure this file is kept secure, as it contains the bot token needed for authentication.

2. **SQLite Integration**
   - Uses SQLite to manage user data such as playlists and settings.
   - Playlists can be created, updated, and managed per user.
   - User settings, such as volume level, are saved for a personalized experience.

3. **Node.js Middleware for Audio Playback**
   - Uses Node.js with `discord.js` and `yt-dlp` to fetch and play audio from YouTube in a Discord voice channel.
   - The Ruby bot sends requests to the Node.js server for audio playback, providing a separation of concerns between command handling and audio playback.

4. **Commands**
   - `!play [song_name]`: Play a song by sending a request to the Node.js middleware for audio playback.
   - `!playspotify [playlist_url]`: Play songs from a Spotify playlist by finding matching YouTube videos.
   - `!addplaylist [name]`: Create a new playlist for the user.
   - `!addsong [playlist_name] [song_name]`: Add a song to an existing playlist.
   - `!playlists`: List all playlists created by the user.
   - `!setvolume [level]`: Set the default volume level for the user.
   - `!help`: Display available commands and their descriptions.

5. **Database Setup**
   - On the first run, the bot creates an SQLite database (`music_bot.db`) with tables for playlists and user settings.

## First-Time Setup

When running the bot for the first time, the installer script (`installer.sh`) will:
- Install necessary dependencies (Ruby gems, Node.js, and npm packages).
- Set up the SQLite database.
- Prompt you for the **Discord Bot Token** and **Command Prefix**.
- Create a configuration file (`config.json`) to store the bot token and command prefix.

## Running the Bot

### 1. Install Dependencies
Run the installer script:
```bash
./installer.sh
```
The script will install all required Ruby gems, Node.js dependencies, and set up the SQLite database.


### 2. Start the Bot
Run the Ruby bot script, it will start the middleware automatically:
```bash
ruby bot.rb
```
This script will connect the bot to Discord, handle user commands, and interact with the Node.js server for playback.

## Commands Overview

- **!play [song name or URL]**: Play a song by sending a request to the Node.js middleware for audio playback.
- **!playspotify [Spotify playlist URL]**: Play songs from a Spotify playlist by finding matching YouTube videos.
- **!addplaylist [name]**: Create a new playlist for the user.
- **!addsong [playlist name] [song name]**: Add a song to an existing playlist.
- **!playlists**: List all user-created playlists.
- **!setvolume [0-100]**: Set the user's default volume level.
- **!help**: Display all available commands.

## Database Details

The bot uses an SQLite database (`music_bot.db`) to store:
- **Playlists**: User-created playlists and their associated songs.
- **User Settings**: User-specific settings, such as volume level.

The database is automatically set up during the first run if it does not already exist.

## Node.js Middleware
The Node.js middleware handles audio playback using the following technologies:
- **`discord.js`**: Manages the Discord bot client and voice connections.
- **`yt-dlp`**: Fetches audio from YouTube for playback.
- **`ffmpeg-static`**: Provides FFmpeg for audio processing.
- **`@discordjs/opus`**: Manages the Opus codec for Discord voice connections.

## Extending the Bot
This bot can be extended with additional features, such as:
- **Advanced Playback Controls**: Adding support for pause, resume, skip, etc.
- **Queue Management**: Implementing song queues, shuffling, and looping.
- **Integration with Other Streaming Services**: Adding support for Spotify, SoundCloud, etc.
- **User Profiles**: Storing user-specific preferences like equalizer settings, preferred genres, and more.

Feel free to modify and improve the bot to suit your needs!