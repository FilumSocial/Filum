import { createClient } from '@supabase/supabase-js';

const supabase = createClient('http://127.0.0.1:54321', 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');

const users = [
  { email: 'mia@example.com', password: 'password123', username: 'miahoff', display_name: 'Mia Hoffmann' },
  { email: 'jonas@example.com', password: 'password123', username: 'jonskern', display_name: 'Jonas Kern' },
  { email: 'sara@example.com', password: 'password123', username: 'saravoss', display_name: 'Sara Voss' },
  { email: 'tobias@example.com', password: 'password123', username: 'tobiauer', display_name: 'Tobias Auer' },
  { email: 'lena@example.com', password: 'password123', username: 'lenabraun', display_name: 'Lena Braun' },
];

for (const u of users) {
  const { data, error } = await supabase.auth.signUp({
    email: u.email,
    password: u.password,
    options: { data: { username: u.username, display_name: u.display_name } },
  });
  if (error) {
    console.error(`Failed ${u.email}: ${error.message}`);
  } else {
    console.log(`Created ${u.email} -> ${data.user?.id}`);
  }
}

console.log('Done.');
