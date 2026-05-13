<script lang="ts">
  import { auth } from '$lib/stores/auth.svelte';

  let email = $state('');
  let password = $state('');
  let username = $state('');
  let displayName = $state('');
  let error = $state('');
  let loading = $state(false);
  let success = $state(false);

  async function handleSubmit(e: Event) {
    e.preventDefault();
    error = '';
    loading = true;
    try {
      await auth.signUp(email, password, username, displayName);
      success = true;
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to sign up';
    } finally {
      loading = false;
    }
  }
</script>

<div class="auth-page">
  <div class="auth-card">
    <div class="logo">Filum</div>
    <h1 class="text-xl font-semibold mb-1">Create account</h1>
    <p class="text-sm text-[var(--text3)] mb-6">Join the conversation</p>

    {#if success}
      <div class="success-msg">
        Account created! Check your email for a confirmation link.
      </div>
      <p class="text-sm text-[var(--text3)] mt-4 text-center">
        <a href="/login" class="text-[var(--accent)] hover:underline">Sign in</a>
      </p>
    {:else}
      <form onsubmit={handleSubmit}>
        {#if error}
          <div class="error-msg">{error}</div>
        {/if}

        <input
          type="text"
          placeholder="Username"
          bind:value={username}
          class="auth-input"
          required
        />
        <input
          type="text"
          placeholder="Display name"
          bind:value={displayName}
          class="auth-input"
          required
        />
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
          {loading ? 'Creating account...' : 'Create account'}
        </button>
      </form>

      <p class="text-sm text-[var(--text3)] mt-4 text-center">
        Already have an account?
        <a href="/login" class="text-[var(--accent)] hover:underline">Sign in</a>
      </p>
    {/if}
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
    border-radius: 12px;
    padding: 32px;
    width: 100%;
    max-width: 380px;
    box-shadow: var(--shadow-m);
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
    border: 1px solid transparent;
    border-radius: 8px;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    outline: none;
    transition: border-color 0.15s, box-shadow 0.15s;
  }
  .auth-input:focus {
    border-color: var(--accent);
    box-shadow:
      inset 0 1px 2px oklch(0 0 0 / 0.3),
      0 0 0 3px oklch(0.72 0.18 75 / 0.12);
  }
  .auth-btn {
    width: 100%;
    padding: 10px;
    border: none;
    border-radius: 8px;
    background: var(--accent);
    color: oklch(0.06 0 0);
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
    background: oklch(0.65 0.16 25 / 0.12);
    color: oklch(0.65 0.16 25);
    padding: 8px 12px;
    border-radius: 8px;
    font-size: 13px;
    margin-bottom: 12px;
  }
  .success-msg {
    background: oklch(0.72 0.14 145 / 0.12);
    color: oklch(0.72 0.14 145);
    padding: 12px 16px;
    border-radius: 8px;
    font-size: 14px;
    margin-bottom: 12px;
  }
</style>
