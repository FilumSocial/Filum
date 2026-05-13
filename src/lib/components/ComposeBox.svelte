<script lang="ts">
  import Avatar from './Avatar.svelte';
  import type { Profile } from '$lib/types';

  let {
    profile,
    onSubmit,
    placeholder = 'What are you thinking?',
    buttonLabel = 'Post',
    autoFocus = false,
    compact = false,
  }: {
    profile: Profile;
    onSubmit: (content: string) => void;
    placeholder?: string;
    buttonLabel?: string;
    autoFocus?: boolean;
    compact?: boolean;
  } = $props();

  let text = $state('');

  function submit() {
    if (!text.trim()) return;
    onSubmit(text.trim());
    text = '';
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
  <div class="flex-1">
    <textarea
      class="compose-ta"
      style={compact ? 'font-size:14px;min-height:38px' : ''}
      placeholder={placeholder}
      bind:value={text}
      rows={text && !compact ? 3 : 1}
      onkeydown={handleKeydown}
    ></textarea>
    {#if text}
      <div class="flex justify-end mt-1.5">
        <button
          class="post-btn"
          class:compact
          disabled={!text.trim()}
          onclick={submit}
        >{buttonLabel}</button>
      </div>
    {/if}
  </div>
</div>

<style>
  .compose {
    padding: 14px 20px;
    border-bottom: 1px solid var(--border);
    display: flex;
    gap: 11px;
    align-items: flex-start;
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
  .compose-ta::placeholder {
    color: var(--text3);
  }
  .post-btn {
    padding: 7px 18px;
    border: none;
    border-radius: 18px;
    background: var(--accent);
    color: #0c0b0a;
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.12s;
  }
  .post-btn:hover {
    opacity: 0.87;
  }
  .post-btn:disabled {
    opacity: 0.35;
    cursor: default;
  }
  .post-btn.compact {
    padding: 5px 13px;
    border-radius: 14px;
    font-size: 12px;
  }
</style>
