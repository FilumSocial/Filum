import { createClient } from '$lib/supabase/client';
import { goto } from '$app/navigation';
import type { Profile } from '$lib/types';
import type { AuthChangeEvent, Session } from '@supabase/supabase-js';

class AuthStore {
  user = $state<{ id: string; email?: string } | null>(null);
  profile = $state<Profile | null>(null);
  loading = $state(true);
  initialized = $state(false);

  // singleton client so cookie storage is consistent
  #supabase = createClient();

  async init() {
    try {
      const { data: { session } } = await this.#supabase.auth.getSession();
      this.#handleSession(session);
    } catch (e) {
      console.error('Auth init error:', e);
    } finally {
      this.loading = false;
      this.initialized = true;
    }

    this.#supabase.auth.onAuthStateChange((_event, session) => {
      this.#handleSession(session);
    });
  }

  #handleSession(session: Session | null) {
    if (session?.user) {
      this.user = { id: session.user.id, email: session.user.email };
      this.#loadProfile(session.user.id);
    } else {
      this.user = null;
      this.profile = null;
    }
  }

  async #loadProfile(userId: string) {
    try {
      const { data } = await this.#supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      if (data) this.profile = data as Profile;
    } catch (e) {
      // profile might not exist yet if trigger hasn't run
      console.error('Profile load error:', e);
    }
  }

  async signIn(email: string, password: string) {
    const { error } = await this.#supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    await goto('/');
  }

  async signUp(email: string, password: string, username: string, displayName: string) {
    const { error } = await this.#supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username, display_name: displayName },
      },
    });
    if (error) throw error;
  }

  async signOut() {
    await this.#supabase.auth.signOut();
    this.user = null;
    this.profile = null;
    await goto('/');
  }
}

export const auth = new AuthStore();
