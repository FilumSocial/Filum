-- Filum Initial Schema
-- Migration: 001
-- Auto-applied by Supabase CLI / Dashboard on project setup

-- 1. Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_color TEXT NOT NULL DEFAULT '#f2a830',
  bio TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "Profiles are public" ON profiles FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. Posts
CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "Posts are public" ON posts FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can insert posts" ON posts FOR INSERT WITH CHECK (auth.role() = 'authenticated'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE USING (auth.uid() = author_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE USING (auth.uid() = author_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 3. Comments (threaded)
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 2000),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_comments_post ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON comments(parent_id);
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "Comments are public" ON comments FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can insert comments" ON comments FOR INSERT WITH CHECK (auth.role() = 'authenticated'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update their own comments" ON comments FOR UPDATE USING (auth.uid() = author_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete their own comments" ON comments FOR DELETE USING (auth.uid() = author_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 4. Votes (polymorphic: applies to posts OR comments, enforced by CHECK)
CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('up', 'down')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT one_target CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL)
  ),
  UNIQUE (user_id, post_id),
  UNIQUE (user_id, comment_id)
);
CREATE INDEX IF NOT EXISTS idx_votes_post ON votes(post_id);
CREATE INDEX IF NOT EXISTS idx_votes_comment ON votes(comment_id);
CREATE INDEX IF NOT EXISTS idx_votes_user ON votes(user_id);
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "Votes are public" ON votes FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can insert votes" ON votes FOR INSERT WITH CHECK (auth.role() = 'authenticated'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update their own votes" ON votes FOR UPDATE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete their own votes" ON votes FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 5. Follows
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (follower_id, following_id),
  CHECK (follower_id != following_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN CREATE POLICY "Follows are public" ON follows FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Authenticated users can follow" ON follows FOR INSERT WITH CHECK (auth.role() = 'authenticated'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 6. Helper views for aggregated scores
CREATE OR REPLACE VIEW post_scores AS
SELECT p.id, p.author_id, p.content, p.created_at,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) AS upvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS downvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) - COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS score
FROM posts p LEFT JOIN votes v ON v.post_id = p.id GROUP BY p.id;

CREATE OR REPLACE VIEW comment_scores AS
SELECT c.id, c.post_id, c.author_id, c.parent_id, c.content, c.created_at,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) AS upvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS downvotes,
  COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'up'), 0) - COALESCE(COUNT(v.id) FILTER (WHERE v.vote_type = 'down'), 0) AS score
FROM comments c LEFT JOIN votes v ON v.comment_id = c.id GROUP BY c.id;

-- 7. Enable Realtime for live score updates
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE votes;

-- 8. Voting RPC functions
CREATE OR REPLACE FUNCTION vote_post(p_post_id UUID, p_vote_type TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public' AS $$
DECLARE existing TEXT;
BEGIN
  SELECT vote_type INTO existing FROM votes WHERE user_id = auth.uid() AND post_id = p_post_id;
  IF existing IS NULL THEN
    INSERT INTO votes (user_id, post_id, vote_type) VALUES (auth.uid(), p_post_id, p_vote_type);
  ELSIF existing = p_vote_type THEN
    DELETE FROM votes WHERE user_id = auth.uid() AND post_id = p_post_id;
  ELSE
    UPDATE votes SET vote_type = p_vote_type WHERE user_id = auth.uid() AND post_id = p_post_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION vote_comment(p_comment_id UUID, p_vote_type TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public' AS $$
DECLARE existing TEXT;
BEGIN
  SELECT vote_type INTO existing FROM votes WHERE user_id = auth.uid() AND comment_id = p_comment_id;
  IF existing IS NULL THEN
    INSERT INTO votes (user_id, comment_id, vote_type) VALUES (auth.uid(), p_comment_id, p_vote_type);
  ELSIF existing = p_vote_type THEN
    DELETE FROM votes WHERE user_id = auth.uid() AND comment_id = p_comment_id;
  ELSE
    UPDATE votes SET vote_type = p_vote_type WHERE user_id = auth.uid() AND comment_id = p_comment_id;
  END IF;
END;
$$;

-- 9. Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_color)
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
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
