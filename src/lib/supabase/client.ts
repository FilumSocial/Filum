import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
// Support both naming conventions (Supabase renamed "anon key" -> "publishable key")
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY;

let client: ReturnType<typeof createBrowserClient> | null = null;
let _warned = false;

export function createClient() {
  if (client) return client;

  if (!supabaseUrl || !supabaseAnonKey) {
    if (!_warned) {
      _warned = true;
      console.error(
        'Missing Supabase credentials. Create a .env file with:\n' +
        'VITE_SUPABASE_URL=https://your-project.supabase.co\n' +
        'VITE_SUPABASE_ANON_KEY=your-publishable-key'
      );
    }
    // Return a dummy that throws on any request
    client = new Proxy({} as ReturnType<typeof createBrowserClient>, {
      get(_, prop) {
        return () => { throw new Error('Supabase not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in .env'); };
      },
    }) as unknown as ReturnType<typeof createBrowserClient>;
    return client;
  }

  client = createBrowserClient(supabaseUrl, supabaseAnonKey, {
    cookieOptions: {
      name: 'sb-auth',
      path: '/',
      sameSite: 'lax',
      secure: globalThis.location?.protocol === 'https:',
    },
  });
  return client;
}
