-- Filum Consolidated Setup
-- Run this in the Supabase production dashboard SQL editor.
-- Safe to re-run (uses IF NOT EXISTS / OR REPLACE / DO blocks).

-- ═══════════════════════════════════════════════════════════════════════════════
-- 0. Extensions
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. Tables
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_color TEXT NOT NULL DEFAULT '#f2a830',
  bio TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) <= 500),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);

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

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. Views
-- ═══════════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. Table-level Grants (required before RLS policies can take effect)
-- ═══════════════════════════════════════════════════════════════════════════════

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. RLS Policies
-- ═══════════════════════════════════════════════════════════════════════════════

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Profiles are public" ON profiles FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Posts
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Posts are public" ON posts FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Authenticated users can insert posts" ON posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE USING (auth.uid() = author_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE USING (auth.uid() = author_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Comments
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Comments are public" ON comments FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Authenticated users can insert comments" ON comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can update their own comments" ON comments FOR UPDATE USING (auth.uid() = author_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can delete their own comments" ON comments FOR DELETE USING (auth.uid() = author_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Votes
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Votes are public" ON votes FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Authenticated users can insert votes" ON votes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can update their own votes" ON votes FOR UPDATE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can delete their own votes" ON votes FOR DELETE USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Follows
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  CREATE POLICY "Follows are public" ON follows FOR SELECT USING (true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Authenticated users can follow" ON follows FOR INSERT WITH CHECK (auth.role() = 'authenticated');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Views: PostgREST requires explicit SELECT grant (RLS does not apply to views)
GRANT SELECT ON post_scores TO anon, authenticated;
GRANT SELECT ON comment_scores TO anon, authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. Enable Realtime
-- ═══════════════════════════════════════════════════════════════════════════════
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE posts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE votes;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. Functions
-- ═══════════════════════════════════════════════════════════════════════════════

-- Vote on a post (upsert/delete toggle)
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

-- Vote on a comment (upsert/delete toggle)
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

-- Auto-create profile on user signup
-- FIXED: SET search_path = 'public' so unqualified "profiles" resolves correctly
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public' AS $$
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

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. Trigger
-- ═══════════════════════════════════════════════════════════════════════════════
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. Backfill missing profiles for existing auth users
--    (fixes sign-ups that happened while the trigger was broken)
-- ═══════════════════════════════════════════════════════════════════════════════
INSERT INTO profiles (id, username, display_name, avatar_color, bio)
SELECT
  u.id,
  COALESCE(u.raw_user_meta_data ->> 'username', 'user_' || substr(u.id::text, 1, 8)),
  COALESCE(u.raw_user_meta_data ->> 'display_name', 'New User'),
  '#' || substr(md5(u.id::text), 1, 6),
  ''
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 9. Seed Data
-- ═══════════════════════════════════════════════════════════════════════════════

-- Auth users (password: password123)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, confirmation_sent_at, confirmation_token, recovery_token, email_change_token_new, email_change, raw_app_meta_data, raw_user_meta_data, aud, role, created_at, updated_at, instance_id)
VALUES
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', 'mia@example.com',
    crypt('password123', gen_salt('bf')), NOW(), NOW(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"username":"miahoff","display_name":"Mia Hoffmann"}',
    'authenticated', 'authenticated', NOW(), NOW(), '00000000-0000-0000-0000-000000000000'),
  ('0deb72f5-935f-4ddf-9bfc-547ca5842a0c', 'jonas@example.com',
    crypt('password123', gen_salt('bf')), NOW(), NOW(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"username":"jonskern","display_name":"Jonas Kern"}',
    'authenticated', 'authenticated', NOW(), NOW(), '00000000-0000-0000-0000-000000000000'),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', 'sara@example.com',
    crypt('password123', gen_salt('bf')), NOW(), NOW(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"username":"saravoss","display_name":"Sara Voss"}',
    'authenticated', 'authenticated', NOW(), NOW(), '00000000-0000-0000-0000-000000000000'),
  ('acacf524-8d99-488b-829f-74920953527f', 'tobias@example.com',
    crypt('password123', gen_salt('bf')), NOW(), NOW(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"username":"tobiauer","display_name":"Tobias Auer"}',
    'authenticated', 'authenticated', NOW(), NOW(), '00000000-0000-0000-0000-000000000000'),
  ('ddec37f1-bfe3-4876-8188-7ddb18bbd5ea', 'lena@example.com',
    crypt('password123', gen_salt('bf')), NOW(), NOW(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"username":"lenabraun","display_name":"Lena Braun"}',
    'authenticated', 'authenticated', NOW(), NOW(), '00000000-0000-0000-0000-000000000000')
ON CONFLICT (id) DO NOTHING;

-- Auth identities (GoTrue needs these for login resolution)
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', '713152e8-eccd-4db5-a3ae-1f4d83c88540',
   '{"sub":"713152e8-eccd-4db5-a3ae-1f4d83c88540","email":"mia@example.com"}',
   'email', 'mia@example.com', NOW(), NOW(), NOW()),
  ('0deb72f5-935f-4ddf-9bfc-547ca5842a0c', '0deb72f5-935f-4ddf-9bfc-547ca5842a0c',
   '{"sub":"0deb72f5-935f-4ddf-9bfc-547ca5842a0c","email":"jonas@example.com"}',
   'email', 'jonas@example.com', NOW(), NOW(), NOW()),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', '7373fc1d-b07b-4ce8-9b19-95c0ec035a7a',
   '{"sub":"7373fc1d-b07b-4ce8-9b19-95c0ec035a7a","email":"sara@example.com"}',
   'email', 'sara@example.com', NOW(), NOW(), NOW()),
  ('acacf524-8d99-488b-829f-74920953527f', 'acacf524-8d99-488b-829f-74920953527f',
   '{"sub":"acacf524-8d99-488b-829f-74920953527f","email":"tobias@example.com"}',
   'email', 'tobias@example.com', NOW(), NOW(), NOW()),
  ('ddec37f1-bfe3-4876-8188-7ddb18bbd5ea', 'ddec37f1-bfe3-4876-8188-7ddb18bbd5ea',
   '{"sub":"ddec37f1-bfe3-4876-8188-7ddb18bbd5ea","email":"lena@example.com"}',
   'email', 'lena@example.com', NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Profiles (for seed users; backfill query above already covers real users)
INSERT INTO profiles (id, username, display_name, avatar_color, bio)
VALUES
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', 'miahoff', 'Mia Hoffmann', '#8C00FF', 'Building things'),
  ('0deb72f5-935f-4ddf-9bfc-547ca5842a0c', 'jonskern', 'Jonas Kern', '#6600CC', 'UX & Design'),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', 'saravoss', 'Sara Voss', '#AA44FF', 'Full-stack dev'),
  ('acacf524-8d99-488b-829f-74920953527f', 'tobiauer', 'Tobias Auer', '#550099', 'Infrastructure'),
  ('ddec37f1-bfe3-4876-8188-7ddb18bbd5ea', 'lenabraun', 'Lena Braun', '#CC77FF', 'Product thinker')
ON CONFLICT (id) DO UPDATE SET avatar_color = EXCLUDED.avatar_color, bio = EXCLUDED.bio;

-- Posts
INSERT INTO posts (id, author_id, content, created_at)
VALUES
  ('10000000-0000-0000-0000-000000000001', '713152e8-eccd-4db5-a3ae-1f4d83c88540',
   'Reviewed my first AI-written PR today. Syntax was perfect but the logic completely missed the point. We have a long way to go.',
   NOW() - INTERVAL '23 minutes'),
  ('10000000-0000-0000-0000-000000000002', '0deb72f5-935f-4ddf-9bfc-547ca5842a0c',
   'Hot take: the best UX trick is building fewer features. Every feature you don''t build is a bug you never have to fix.',
   NOW() - INTERVAL '58 minutes'),
  ('10000000-0000-0000-0000-000000000003', '7373fc1d-b07b-4ce8-9b19-95c0ec035a7a',
   'Morning coffee reminder: You don''t have to jump on every trend. Solid fundamentals > hype stacks. React is still not dead. Postgres either.',
   NOW() - INTERVAL '3 hours'),
  ('10000000-0000-0000-0000-000000000004', 'acacf524-8d99-488b-829f-74920953527f',
   'Anyone have Supabase production experience? Thinking of migrating from Firebase. Main concern: costs at ~100k MAU.',
   NOW() - INTERVAL '7 hours'),
  ('10000000-0000-0000-0000-000000000005', 'ddec37f1-bfe3-4876-8188-7ddb18bbd5ea',
   'Design isn''t how it looks. Design is how it works. If you tell your designers "make it prettier" you haven''t understood the problem.',
   NOW() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;

-- Comments
INSERT INTO comments (id, post_id, author_id, parent_id, content, created_at)
VALUES
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001',
   '0deb72f5-935f-4ddf-9bfc-547ca5842a0c', NULL,
   'Classic. The AI optimises for "looks like real code" -- not "solves the actual problem".',
   NOW() - INTERVAL '20 minutes'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001',
   '7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', '20000000-0000-0000-0000-000000000001',
   'That''s the fundamental problem with RLHF. It learns to maximise human approval, not correctness.',
   NOW() - INTERVAL '18 minutes'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001',
   '713152e8-eccd-4db5-a3ae-1f4d83c88540', '20000000-0000-0000-0000-000000000002',
   'Yep. And humans are terrible at reviewing code that''s wrong but looks plausible.',
   NOW() - INTERVAL '15 minutes'),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001',
   'acacf524-8d99-488b-829f-74920953527f', NULL,
   'Same here. The code passed tests because the tests were also written by AI.',
   NOW() - INTERVAL '17 minutes'),
  ('20000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002',
   '7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', NULL,
   'True up to a point. Sometimes features are necessary for the product to be usable at all.',
   NOW() - INTERVAL '50 minutes'),
  ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000002',
   'ddec37f1-bfe3-4876-8188-7ddb18bbd5ea', NULL,
   'Strongly agree. Feature bloat is the death of every good product.',
   NOW() - INTERVAL '45 minutes')
ON CONFLICT (id) DO NOTHING;

-- Votes
INSERT INTO votes (user_id, post_id, vote_type)
VALUES
  ('0deb72f5-935f-4ddf-9bfc-547ca5842a0c', '10000000-0000-0000-0000-000000000001', 'up'),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', '10000000-0000-0000-0000-000000000001', 'up'),
  ('acacf524-8d99-488b-829f-74920953527f', '10000000-0000-0000-0000-000000000001', 'down'),
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', '10000000-0000-0000-0000-000000000002', 'up'),
  ('ddec37f1-bfe3-4876-8188-7ddb18bbd5ea', '10000000-0000-0000-0000-000000000002', 'up'),
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', '10000000-0000-0000-0000-000000000005', 'up'),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', '10000000-0000-0000-0000-000000000005', 'up')
ON CONFLICT (user_id, post_id) DO NOTHING;

-- Follows
INSERT INTO follows (follower_id, following_id)
VALUES
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', '0deb72f5-935f-4ddf-9bfc-547ca5842a0c'),
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', '7373fc1d-b07b-4ce8-9b19-95c0ec035a7a'),
  ('713152e8-eccd-4db5-a3ae-1f4d83c88540', 'ddec37f1-bfe3-4876-8188-7ddb18bbd5ea'),
  ('0deb72f5-935f-4ddf-9bfc-547ca5842a0c', '713152e8-eccd-4db5-a3ae-1f4d83c88540'),
  ('7373fc1d-b07b-4ce8-9b19-95c0ec035a7a', '713152e8-eccd-4db5-a3ae-1f4d83c88540')
ON CONFLICT (follower_id, following_id) DO NOTHING;
