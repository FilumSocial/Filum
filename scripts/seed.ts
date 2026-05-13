import { createClient } from '@supabase/supabase-js';

const supabase = createClient('http://127.0.0.1:54321', 'SUPABASE_ANON_KEY');
const admin = createClient('http://127.0.0.1:54321', 'SUPABASE_SERVICE_ROLE_KEY');

const users = [
  { email: 'mia@example.com', password: 'password123', username: 'miahoff', display_name: 'Mia Hoffmann', avatar_color: '#8C00FF', bio: 'Building things' },
  { email: 'jonas@example.com', password: 'password123', username: 'jonskern', display_name: 'Jonas Kern', avatar_color: '#FF3F7F', bio: 'UX & Design' },
  { email: 'sara@example.com', password: 'password123', username: 'saravoss', display_name: 'Sara Voss', avatar_color: '#FFC400', bio: 'Full-stack dev' },
  { email: 'tobias@example.com', password: 'password123', username: 'tobiauer', display_name: 'Tobias Auer', avatar_color: '#450693', bio: 'Infrastructure' },
  { email: 'lena@example.com', password: 'password123', username: 'lenabraun', display_name: 'Lena Braun', avatar_color: '#CC44AA', bio: 'Product thinker' },
];

const ids: Record<string, string> = {};

for (const u of users) {
  const { data: existing } = await supabase.from('profiles').select('id').eq('username', u.username).single();
  if (existing) {
    ids[u.email] = existing.id;
    console.log(`Existing ${u.email} -> ${existing.id}`);
    continue;
  }

  const { data, error } = await supabase.auth.signUp({
    email: u.email,
    password: u.password,
    options: { data: { username: u.username, display_name: u.display_name } },
  });
  if (error) {
    console.error(`Failed ${u.email}: ${error.message}`);
    continue;
  }
  if (!data.user?.id) {
    console.error(`No user id for ${u.email}`);
    continue;
  }
  ids[u.email] = data.user.id;
  console.log(`Created ${u.email} -> ${data.user.id}`);
}

// Update profiles (use service_role key to bypass RLS)
for (const u of users) {
  const id = ids[u.email];
  if (!id) continue;
  await admin.from('profiles').update({ avatar_color: u.avatar_color, bio: u.bio }).eq('id', id);
  console.log(`Profile updated for ${u.email}`);
}

// Clear old content (use service_role key to bypass RLS)
await admin.from('votes').delete().in('user_id', Object.values(ids));
await admin.from('follows').delete().in('follower_id', Object.values(ids));
await admin.from('comments').delete().in('author_id', Object.values(ids));
await admin.from('posts').delete().in('author_id', Object.values(ids));

// Insert posts
const posts = [
  { id: '10000000-0000-0000-0000-000000000001', author: 'mia@example.com', content: "Reviewed my first AI-written PR today. Syntax was perfect but the logic completely missed the point. We have a long way to go.", mins: 23 },
  { id: '10000000-0000-0000-0000-000000000002', author: 'jonas@example.com', content: "Hot take: the best UX trick is building fewer features. Every feature you don't build is a bug you never have to fix.", mins: 58 },
  { id: '10000000-0000-0000-0000-000000000003', author: 'sara@example.com', content: "Morning coffee reminder: You don't have to jump on every trend. Solid fundamentals > hype stacks. React is still not dead. Postgres either.", mins: 180 },
  { id: '10000000-0000-0000-0000-000000000004', author: 'tobias@example.com', content: "Anyone have Supabase production experience? Thinking of migrating from Firebase. Main concern: costs at ~100k MAU.", mins: 420 },
  { id: '10000000-0000-0000-0000-000000000005', author: 'lena@example.com', content: "Design isn't how it looks. Design is how it works. If you tell your designers \"make it prettier\" you haven't understood the problem.", mins: 720 },
];

for (const p of posts) {
  await admin.from('posts').upsert({
    id: p.id, author_id: ids[p.author], content: p.content, created_at: new Date(Date.now() - p.mins * 60000).toISOString(),
  }, { onConflict: 'id' });
  console.log(`Post ${p.id} by ${p.author}`);
}

// Insert comments
const comments = [
  { id: '20000000-0000-0000-0000-000000000001', post: '10000000-0000-0000-0000-000000000001', author: 'jonas@example.com', parent: null, content: "Classic. The AI optimises for looks like real code not solves the actual problem.", mins: 20 },
  { id: '20000000-0000-0000-0000-000000000002', post: '10000000-0000-0000-0000-000000000001', author: 'sara@example.com', parent: '20000000-0000-0000-0000-000000000001', content: "That's the fundamental problem with RLHF. It learns to maximise human approval, not correctness.", mins: 18 },
  { id: '20000000-0000-0000-0000-000000000003', post: '10000000-0000-0000-0000-000000000001', author: 'mia@example.com', parent: '20000000-0000-0000-0000-000000000002', content: "Yep. And humans are terrible at reviewing code that's wrong but looks plausible.", mins: 15 },
  { id: '20000000-0000-0000-0000-000000000004', post: '10000000-0000-0000-0000-000000000001', author: 'tobias@example.com', parent: null, content: "Same here. The code passed tests because the tests were also written by AI.", mins: 17 },
  { id: '20000000-0000-0000-0000-000000000005', post: '10000000-0000-0000-0000-000000000002', author: 'sara@example.com', parent: null, content: "True up to a point. Sometimes features are necessary for the product to be usable at all.", mins: 50 },
  { id: '20000000-0000-0000-0000-000000000006', post: '10000000-0000-0000-0000-000000000002', author: 'lena@example.com', parent: null, content: "Strongly agree. Feature bloat is the death of every good product.", mins: 45 },
];

for (const c of comments) {
  const r: Record<string, any> = { id: c.id, post_id: c.post, author_id: ids[c.author], content: c.content, created_at: new Date(Date.now() - c.mins * 60000).toISOString() };
  if (c.parent) r.parent_id = c.parent;
  await admin.from('comments').upsert(r, { onConflict: 'id' });
  console.log(`Comment ${c.id} by ${c.author}`);
}

// Insert votes
const votes = [
  { user: 'jonas@example.com', post: '10000000-0000-0000-0000-000000000001', type: 'up' },
  { user: 'sara@example.com', post: '10000000-0000-0000-0000-000000000001', type: 'up' },
  { user: 'tobias@example.com', post: '10000000-0000-0000-0000-000000000001', type: 'down' },
  { user: 'mia@example.com', post: '10000000-0000-0000-0000-000000000002', type: 'up' },
  { user: 'lena@example.com', post: '10000000-0000-0000-0000-000000000002', type: 'up' },
  { user: 'mia@example.com', post: '10000000-0000-0000-0000-000000000005', type: 'up' },
  { user: 'sara@example.com', post: '10000000-0000-0000-0000-000000000005', type: 'up' },
];

for (const v of votes) {
  await admin.from('votes').upsert({ user_id: ids[v.user], post_id: v.post, vote_type: v.type }, { onConflict: 'user_id,post_id' });
}

// Insert follows
const follows: [string, string][] = [
  ['mia@example.com', 'jonas@example.com'],
  ['mia@example.com', 'sara@example.com'],
  ['mia@example.com', 'lena@example.com'],
  ['jonas@example.com', 'mia@example.com'],
  ['sara@example.com', 'mia@example.com'],
];

for (const [follower, following] of follows) {
  await admin.from('follows').upsert({ follower_id: ids[follower], following_id: ids[following] }, { onConflict: 'follower_id,following_id' });
}

console.log('Seed complete.');
