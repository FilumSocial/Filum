import { createClient } from '$lib/supabase/client';
import type { Profile } from '$lib/types';

class AuthStore {
  user = $state<{ id: string; email?: string } | null>(null);
  profile = $state<Profile | null>(null);
  loading = $state(true);
  initialized = $state(false);

  async init() {
    const supabase = createClient();
    const { data: { session } } = await supabase.auth.getSession();
    if (session?.user) {
      this.user = { id: session.user.id, email: session.user.email };
      await this.loadProfile(session.user.id);
    }
    this.loading = false;
    this.initialized = true;

    supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        this.user = { id: session.user.id, email: session.user.email };
        await this.loadProfile(session.user.id);
      } else {
        this.user = null;
        this.profile = null;
      }
    });
  }

  async loadProfile(userId: string) {
    const supabase = createClient();
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    if (data) this.profile = data as Profile;
  }

  async signIn(email: string, password: string) {
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  }

  async signUp(email: string, password: string, username: string, displayName: string) {
    const supabase = createClient();
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username, display_name: displayName },
      },
    });
    if (error) throw error;
  }

  async signOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    this.user = null;
    this.profile = null;
  }
}

export const auth = new AuthStore();
