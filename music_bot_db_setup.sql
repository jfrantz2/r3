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