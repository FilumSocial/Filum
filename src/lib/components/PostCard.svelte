<script lang="ts">
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
    <button class="user-row" onclick={(e) => { e.stopPropagation(); window.location.href = `/profile/${post.author.id}`; }}>
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
      <span class="text-[14px] leading-none">&#128172;</span>
      <span class="text-[13px]">{post.comment_count}</span>
    </button>
    <button class="act-btn" onclick={(e) => { e.stopPropagation(); }}>
      <span class="text-[14px] leading-none">&#8599;</span>
    </button>
  </div>
</div>

<style>
  .pcard {
    padding: 16px 20px;
    border-bottom: 1px solid var(--border);
    transition: background 0.15s, box-shadow 0.15s;
  }
  .pcard:hover {
    background: oklch(1 0 0 / 0.015);
    box-shadow: var(--shadow-s);
    position: relative;
  }
  .post-content {
    font-size: 15px;
    line-height: 1.6;
    color: var(--text1);
    margin: 4px 0 14px 0;
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
    border-radius: 6px;
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
