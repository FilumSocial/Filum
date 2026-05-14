-- Filum Database Schema
-- Run this in Supabase SQL Editor

-- 1. Profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_color TEXT NOT NULL DEFAULT '#f2a830',
  bio TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are public"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 2. Posts
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Posts are public"
  ON posts FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert posts"
  ON posts FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own posts"
  ON posts FOR DELETE
  USING (auth.uid() = author_id);

-- 3. Comments (threaded)
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 2000),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are public"
  ON comments FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert comments"
  ON comments FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own comments"
  ON comments FOR DELETE
  USING (auth.uid() = author_id);

-- 4. Votes
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT one_target CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR
    (post_id IS NULL AND comment_id IS NOT NULL)
  ),
  UNIQUE (user_id, post_id),
  UNIQUE (user_id, comment_id)
);

CREATE INDEX idx_votes_post ON votes(post_id);
CREATE INDEX idx_votes_comment ON votes(comment_id);
CREATE INDEX idx_votes_user ON votes(user_id);

ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Votes are public"
  ON votes FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert votes"
  ON votes FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update their own votes"
  ON votes FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own votes"
  ON votes FOR DELETE
  USING (auth.uid() = user_id);

-- 5. Follows
CREATE TABLE follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows are public"
  ON follows FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can follow"
  ON follows FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can unfollow"
  ON follows FOR DELETE
  USING (auth.uid() = follower_id);

-- 6. Table-level grants for API roles (required before RLS can take effect)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 7. Helper views for scores
CREATE VIEW post_scores AS
SELECT
  p.id,
  p.author_id,
  p.content,
  p.created_at,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) AS upvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS downvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) - COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS score
FROM posts p
LEFT JOIN votes v ON v.post_id = p.id
GROUP BY p.id;

CREATE VIEW comment_scores AS
SELECT
  c.id,
  c.post_id,
  c.author_id,
  c.parent_id,
  c.content,
  c.created_at,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) AS upvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS downvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) - COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS score
FROM comments c
LEFT JOIN votes v ON v.comment_id = c.id
GROUP BY c.id;

-- 7. Grant SELECT on views (PostgREST requires explicit grants for views)
GRANT SELECT ON post_scores TO anon, authenticated;
GRANT SELECT ON comment_scores TO anon, authenticated;

-- 8. Enable Realtime for live updates
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE votes;

-- 8. Function: vote on a post (atomic upsert, no race condition)
CREATE OR REPLACE FUNCTION vote_post(p_post_id UUID, p_vote_type TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  WITH toggled_off AS (
    DELETE FROM votes
    WHERE user_id = auth.uid() AND post_id = p_post_id AND vote_type = p_vote_type
    RETURNING 1
  )
  INSERT INTO votes (user_id, post_id, vote_type)
  SELECT auth.uid(), p_post_id, p_vote_type
  WHERE NOT EXISTS (SELECT 1 FROM toggled_off)
  ON CONFLICT (user_id, post_id) DO UPDATE SET vote_type = EXCLUDED.vote_type;
END;
$$;

-- Function: vote on a comment (atomic upsert, no race condition)
CREATE OR REPLACE FUNCTION vote_comment(p_comment_id UUID, p_vote_type TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  WITH toggled_off AS (
    DELETE FROM votes
    WHERE user_id = auth.uid() AND comment_id = p_comment_id AND vote_type = p_vote_type
    RETURNING 1
  )
  INSERT INTO votes (user_id, comment_id, vote_type)
  SELECT auth.uid(), p_comment_id, p_vote_type
  WHERE NOT EXISTS (SELECT 1 FROM toggled_off)
  ON CONFLICT (user_id, comment_id) DO UPDATE SET vote_type = EXCLUDED.vote_type;
END;
$$;

-- Function: create profile on signup
-- FIXED: search_path = 'public' so unqualified "profiles" resolves
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  INSERT INTO profiles (id, username, display_name, avatar_color)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'username', 'user_' || substr(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', 'New User'),
    '#' || substr(md5(NEW.id::text), 1, 6)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
