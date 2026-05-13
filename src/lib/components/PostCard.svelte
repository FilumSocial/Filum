<script lang="ts">
  import { goto } from '$app/navigation';
  import Avatar from './Avatar.svelte';
  import VoteRow from './VoteRow.svelte';
  import { ago } from '$lib/utils';
  import type { PostWithScore } from '$lib/types';

  let {
    post,
    onClick,
    onVote,
    following = false,
  }: {
    post: PostWithScore;
    onClick: () => void;
    onVote: (dir: 'up' | 'down') => void;
    following?: boolean;
  } = $props();
</script>

<div
  class="pcard fade-up cursor-pointer"
  onclick={onClick}
  role="button"
  tabindex="0"
  onkeydown={(e) => { if (e.key === 'Enter') onClick(); }}
>
    <button class="user-row" onclick={(e) => { e.stopPropagation(); goto(`/profile/${post.author.id}`); }}>
      <Avatar name={post.author.display_name} color={post.author.avatar_color} size={38} />
      <div class="flex-1 min-w-0 text-left">
        <div class="flex items-center gap-1.5 flex-wrap">
          <span class="font-semibold text-[14px] text-[var(--text1)] hover:underline">{post.author.display_name}</span>
          {#if following}
            <span class="following-badge">following</span>
          {/if}
          <span class="text-[12px] text-[var(--text3)]">@{post.author.username}</span>
        </div>
      </div>
      <span class="text-[12px] text-[var(--text3)] shrink-0">{ago(post.created_at)}</span>
    </button>

  <p class="post-content">{post.content}</p>

  <div class="flex items-center gap-1">
    <VoteRow
      upvotes={post.upvotes}
      downvotes={post.downvotes}
      userVote={post.user_vote}
      onVote={onVote}
    />
    <button class="act-btn" onclick={(e) => { e.stopPropagation(); }}>
      <svg width="15" height="15" viewBox="0 0 15 15" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M2 1h11a1 1 0 011 1v8a1 1 0 01-1 1H5l-3 3V2a1 1 0 011-1z"/></svg>
      <span class="text-[13px]">{post.comment_count}</span>
    </button>
    <button class="act-btn" aria-label="Share" onclick={(e) => { e.stopPropagation(); }}>
      <svg width="15" height="15" viewBox="0 0 15 15" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="4" cy="7.5" r="2"/><circle cx="11" cy="4.5" r="2"/><circle cx="11" cy="10.5" r="2"/><path d="M6 8.5l3 2M9 4.5l-3 2"/></svg>
    </button>
  </div>
</div>

<style>
  .pcard {
    margin: 0 12px 24px;
    padding: 16px 20px;
    background: var(--surface);
    border-radius: 12px;
    border: 1px solid var(--border);
    transition: border-color 0.15s;
  }
  .pcard:first-of-type {
    margin-top: 12px;
  }
  .pcard:hover {
    border-color: var(--text3);
  }
  .post-content {
    font-size: 15px;
    line-height: 1.6;
    color: var(--text1);
    margin: 6px 0 16px 0;
    white-space: pre-wrap;
  }
  .following-badge {
    font-size: 10px;
    padding: 1px 6px;
    border-radius: 10px;
    background: var(--accent-soft);
    color: var(--accent);
    font-weight: 600;
  }
  .act-btn {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 5px 8px;
    border: none;
    border-radius: 8px;
    background: transparent;
    color: var(--text2);
    font-size: 13px;
    cursor: pointer;
    transition: all 0.1s;
  }
  .act-btn:hover {
    background: var(--surface2);
    color: var(--text1);
  }
  .fade-up {
    animation: fadeUp 0.18s ease forwards;
  }
  .user-row {
    display: flex;
    gap: 12px;
    margin-bottom: 10px;
    align-items: center;
    width: 100%;
    background: none;
    border: none;
    padding: 0;
    font: inherit;
    color: inherit;
    cursor: pointer;
    text-align: left;
  }
  .user-row:hover { opacity: 0.85; }
</style>
