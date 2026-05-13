-- Filum seed data (public schema only)
-- Auth users must be created via the GoTrue API (see scripts/seed.ts)
-- Run: bun run scripts/seed.ts

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
