<script lang="ts">
  import Avatar from './Avatar.svelte';
  import type { Profile } from '$lib/types';

  let {
    profile,
    onSubmit,
    placeholder = 'What are you thinking?',
    buttonLabel = 'Post',
    compact = false,
    maxLength = compact ? 2000 : 500,
  }: {
    profile: Profile;
    onSubmit: (content: string) => Promise<void> | void;
    placeholder?: string;
    buttonLabel?: string;
    compact?: boolean;
    maxLength?: number;
  } = $props();

  let text = $state('');
  let submitting = $state(false);
  let error = $state('');
  let remaining = $derived(maxLength - text.length);

  async function submit() {
    if (!text.trim() || submitting) return;
    submitting = true;
    error = '';
    try {
      await onSubmit(text.trim());
      text = '';
    } catch (e) {
      error = e instanceof Error ? e.message : 'Something went wrong';
    } finally {
      submitting = false;
    }
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  }
</script>

<div class="compose">
  <Avatar name={profile.display_name} color={profile.avatar_color} size={compact ? 32 : 38} />
  <div class="flex-1 min-w-0">
    <textarea
      class="compose-ta"
      class:compact
      placeholder={placeholder}
      bind:value={text}
      rows={text && !compact ? 3 : 1}
      onkeydown={handleKeydown}
      disabled={submitting}
      maxlength={maxLength}
    ></textarea>
    {#if error}
      <p class="error-msg">{error}</p>
    {/if}
    {#if text}
      <div class="flex justify-between items-center mt-1.5">
        <span
          class="char-count"
          class:near={remaining <= 20 && remaining > 0}
          class:over={remaining < 0}
        >{remaining}</span>
        <button
          class="post-btn"
          class:compact
          disabled={!text.trim() || submitting || remaining < 0}
          onclick={submit}
        >
          {submitting ? 'Posting...' : buttonLabel}
        </button>
      </div>
    {/if}
  </div>
</div>

<style>
  .compose {
    margin: 24px 12px 24px;
    padding: 14px 20px;
    display: flex;
    gap: 11px;
    align-items: flex-start;
    background: var(--bg-raised);
    border-radius: 12px;
    border: 1px solid var(--border);
  }
  .compose:first-of-type {
    margin-top: 12px;
  }
  .compose-ta {
    width: 100%;
    background: transparent;
    border: none;
    outline: none;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 15px;
    resize: none;
    line-height: 1.55;
    min-height: 44px;
  }
  .compose-ta.compact {
    font-size: 14px;
    min-height: 38px;
  }
  .compose-ta::placeholder {
    color: var(--text3);
  }
  .compose-ta:disabled {
    opacity: 0.5;
  }
  .post-btn {
    padding: 7px 18px;
    border: none;
    border-radius: 8px;
    background: var(--accent);
    color: oklch(0.06 0 0);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.15s, transform 0.15s;
    flex-shrink: 0;
    box-shadow: var(--shadow-s);
  }
  .post-btn:hover {
    opacity: 0.87;
    transform: scale(1.02);
  }
  .post-btn:active {
    transform: scale(0.96);
  }
  .post-btn:disabled {
    opacity: 0.35;
    cursor: default;
    transform: none;
    box-shadow: none;
  }
  .post-btn.compact {
    padding: 5px 13px;
    border-radius: 8px;
    font-size: 12px;
  }
  .char-count {
    font-size: 11px;
    color: var(--text3);
    font-weight: 500;
    transition: color 0.15s;
  }
  .char-count.near {
    color: oklch(0.7 0.14 75);
  }
  .char-count.over {
    color: oklch(0.65 0.16 25);
  }
  .error-msg {
    font-size: 12px;
    color: oklch(0.65 0.16 25);
    margin-top: 4px;
  }
</style>
