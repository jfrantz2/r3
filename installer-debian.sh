#!/bin/bash

# Installer Script for Discord Music Bot (Debian-based Distributions)

# Update Package List
sudo apt-get update

# Install Required System Packages
sudo apt-get install -y curl sqlite3 ffmpeg build-essential

# Install Ruby
if ! command -v ruby > /dev/null 2>&1; then
  echo "Installing Ruby..."
  sudo apt-get install -y ruby-full
else
  echo "Ruby is already installed."
fi

# Install Ruby Gems
install_gem() {
  if ! gem list -i "$1" > /dev/null 2>&1; then
    echo "Installing $1..."
    gem install "$1"
  else
    echo "$1 is already installed."
  fi
}

install_gem discordrb
install_gem sqlite3
install_gem json
install_gem rspotify

# Install Node.js and npm
if ! command -v node > /dev/null 2>&1; then
  echo "Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js is already installed."
fi

# Install Node.js Dependencies for Audio Middleware
if [ ! -d "discord_audio_middleware" ]; then
  mkdir discord_audio_middleware
fi

cd discord_audio_middleware

if [ ! -f "package.json" ]; then
  echo "Initializing Node.js environment..."
  npm init -y
  npm install discord.js express yt-dlp ffmpeg-static @discordjs/opus
else
  echo "Node.js dependencies are already installed."
fi
cd ..

# Set Up Configuration File
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Setting up configuration file for the first time..."
  read -p "Please enter your Discord Bot Token: " bot_token
  read -p "Please enter your desired command prefix (default is !): " command_prefix
  command_prefix=${command_prefix:-"!"}

  echo "{\n  \"bot_token\": \"$bot_token\",\n  \"command_prefix\": \"$command_prefix\"\n}" > $CONFIG_FILE
  echo "Configuration saved to $CONFIG_FILE."
else
  echo "Configuration file already exists."
fi

# Set Up SQLite Database
DB_FILE="music_bot.db"
if [ ! -f "$DB_FILE" ]; then
  echo "Setting up SQLite database..."
  sqlite3 $DB_FILE <<EOF
CREATE TABLE IF NOT EXISTS playlists (
  id INTEGER PRIMARY KEY,
  user_id TEXT,
  name TEXT,
  songs TEXT
);

CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY,
  user_id TEXT,
  key TEXT,
  value TEXT
);
EOF
  echo "Database setup complete."
else
  echo "Database already exists."
fi

# Final Message
echo "Installation complete! You can now run your Discord Music Bot."