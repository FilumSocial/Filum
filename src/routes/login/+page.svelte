<script lang="ts">
  import { auth } from '$lib/stores/auth.svelte';

  let email = $state('');
  let password = $state('');
  let error = $state('');
  let loading = $state(false);

  async function handleSubmit(e: Event) {
    e.preventDefault();
    error = '';
    loading = true;
    try {
      await auth.signIn(email, password);
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to sign in';
    } finally {
      loading = false;
    }
  }
</script>

<div class="auth-page">
  <div class="auth-card">
    <div class="logo">Filum</div>
    <h1 class="text-xl font-semibold mb-1">Sign in</h1>
    <p class="text-sm text-[var(--text3)] mb-6">Welcome back</p>

    <form onsubmit={handleSubmit}>
      {#if error}
        <div class="error-msg">{error}</div>
      {/if}

      <input
        type="email"
        placeholder="Email"
        bind:value={email}
        class="auth-input"
        required
      />
      <input
        type="password"
        placeholder="Password"
        bind:value={password}
        class="auth-input"
        required
      />

      <button type="submit" class="auth-btn" disabled={loading}>
        {loading ? 'Signing in...' : 'Sign in'}
      </button>
    </form>

    <p class="text-sm text-[var(--text3)] mt-4 text-center">
      Don't have an account?
      <a href="/register" class="text-[var(--accent)] hover:underline">Sign up</a>
    </p>
  </div>
</div>

<style>
  .auth-page {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--bg);
    padding: 20px;
  }
  .auth-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 32px;
    width: 100%;
    max-width: 380px;
  }
  .logo {
    font-family: 'Cormorant Garamond', serif;
    font-size: 28px;
    color: var(--accent);
    text-align: center;
    margin-bottom: 20px;
  }
  .auth-input {
    width: 100%;
    padding: 10px 14px;
    margin-bottom: 12px;
    background: var(--surface2);
    border: 1px solid var(--border);
    border-radius: 8px;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    outline: none;
    transition: border-color 0.12s;
  }
  .auth-input:focus {
    border-color: var(--accent);
  }
  .auth-btn {
    width: 100%;
    padding: 10px;
    border: none;
    border-radius: 8px;
    background: var(--accent);
    color: #0c0b0a;
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 6px;
  }
  .auth-btn:disabled {
    opacity: 0.5;
    cursor: default;
  }
  .error-msg {
    background: rgba(224, 112, 112, 0.12);
    color: #e07070;
    padding: 8px 12px;
    border-radius: 8px;
    font-size: 13px;
    margin-bottom: 12px;
  }
</style>
