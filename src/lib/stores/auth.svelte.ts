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

    this.#supabase.auth.onAuthStateChange((_event: AuthChangeEvent, session: Session | null) => {
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

  async signIn(email: string, password: string) {
    const { error } = await this.#supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;

    const { data: { session } } = await this.#supabase.auth.getSession();
    if (!session?.user) {
      console.error('SignIn: No session after successful login');
      return;
    }

    this.user = { id: session.user.id, email: session.user.email };
    console.log('SignIn: user set', this.user);

    const profile = await this.#loadProfile(session.user.id);
    if (!profile) {
      console.error('SignIn: profile not found for user', session.user.id);
    }

    await goto('/');
  }

  async #loadProfile(userId: string): Promise<Profile | null> {
    try {
      const { data, error } = await this.#supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
      if (error) {
        console.error('Profile load error:', error.message);
        return null;
      }
      if (data) {
        this.profile = data as Profile;
        return this.profile;
      }
      return null;
    } catch (e) {
      console.error('Profile load exception:', e);
      return null;
    }
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
