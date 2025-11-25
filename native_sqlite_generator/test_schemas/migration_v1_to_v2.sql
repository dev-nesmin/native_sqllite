-- Migration generated: 2025-10-28T20:26:32.722604
-- From version: 1.0.0
-- To version:   2.0.0

-- =============================================================================

BEGIN TRANSACTION;

-- Create new table: comments
CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  postId INTEGER NOT NULL,
  userId INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

-- Update table: users (3 changes)
-- Migration generated: 2025-10-28T20:26:32.724783
-- From: users
-- To:   users
-- Changes: 3

-- =============================================================================

BEGIN TRANSACTION;

-- Add column created_at INTEGER to users
ALTER TABLE users ADD COLUMN created_at INTEGER DEFAULT NULL;

-- Add column bio TEXT to users
ALTER TABLE users ADD COLUMN bio TEXT;

-- Add index on users (created_at)
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at);

COMMIT;

-- Migration complete


-- Update table: posts (2 changes)
-- Migration generated: 2025-10-28T20:26:32.725066
-- From: posts
-- To:   posts
-- Changes: 2

-- =============================================================================

BEGIN TRANSACTION;

-- Add column published_at INTEGER to posts
ALTER TABLE posts ADD COLUMN published_at INTEGER;

-- Add index on posts (published_at)
CREATE INDEX IF NOT EXISTS idx_posts_published_at ON posts (published_at);

COMMIT;

-- Migration complete


COMMIT;
