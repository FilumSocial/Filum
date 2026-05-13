-- Filum seed data
-- Run this in the Supabase production dashboard SQL editor.
-- Creates auth users, profiles, posts, comments, votes, and follows.
-- Password for all seed users: password123

-- Auth users (profiles auto-created by on_auth_user_created trigger)
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

-- Update profiles with proper avatar_color and bio
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
