<script lang="ts">
  import PostCard from './PostCard.svelte';
  import ComposeBox from './ComposeBox.svelte';
  import type { PostWithScore, Profile, SortMode, FeedMode } from '$lib/types';

  let {
    posts,
    userProfile,
    error = null,
    feedMode,
    sortMode,
    onSetFeedMode,
    onSetSortMode,
    onOpenThread,
    onVotePost,
    onNewPost,
  }: {
    posts: PostWithScore[];
    userProfile: Profile | null;
    error?: string | null;
    feedMode: FeedMode;
    sortMode: SortMode;
    onSetFeedMode: (mode: FeedMode) => void;
    onSetSortMode: (mode: SortMode) => void;
    onOpenThread: (id: string) => void;
    onVotePost: (id: string, dir: 'up' | 'down') => void;
    onNewPost: (content: string) => Promise<void> | void;
  } = $props();
</script>

<div>
  <div class="sticky-hd">
    <div class="btn-group">
      <button
        class="hd-btn"
        class:on={feedMode === 'following'}
        onclick={() => onSetFeedMode('following')}
      >Following</button>
      <button
        class="hd-btn"
        class:on={feedMode === 'rec'}
        onclick={() => onSetFeedMode('rec')}
      >Recommended</button>
    </div>
    <div class="btn-group">
      <button
        class="hd-btn"
        class:on={sortMode === 'chron'}
        onclick={() => onSetSortMode('chron')}
      >New</button>
      <button
        class="hd-btn"
        class:on={sortMode === 'top'}
        onclick={() => onSetSortMode('top')}
      >Top</button>
    </div>
  </div>

  {#if userProfile}
    <ComposeBox
      profile={userProfile}
      placeholder="What are you thinking?"
      buttonLabel="Post"
      onSubmit={onNewPost}
    />
  {:else}
    <div class="compose-empty">
      <div class="w-full text-center py-4">
        <p class="text-[var(--text2)] text-[14px] mb-2">Sign in to join the conversation</p>
        <a href="/login" class="inline-block w-full px-4 py-2.5 rounded-[8px] bg-[var(--accent-soft)] text-[var(--accent)] font-semibold text-[14px] no-underline text-center">Sign in</a>
      </div>
    </div>
  {/if}

  {#if error}
    <div class="error-banner">{error}</div>
  {/if}

  {#if posts.length === 0}
    <div class="empty-card">
      {feedMode === 'following' ? 'No posts yet. Follow more people!' : 'No recommended posts yet.'}
    </div>
  {:else}
    {#each posts as post (post.id)}
      <PostCard
        {post}
        onClick={() => onOpenThread(post.id)}
        onVote={(dir) => onVotePost(post.id, dir)}
      />
    {/each}
  {/if}
</div>

<style>
  .error-banner {
    margin: 0 12px 24px;
    padding: 10px 14px;
    background: rgba(224, 112, 112, 0.12);
    color: oklch(0.65 0.16 25);
    border-radius: 8px;
    font-size: 13px;
  }

  .compose-empty {
    margin: 0 12px 24px;
    padding: 14px 20px;
    background: var(--bg-raised);
    border-radius: 12px;
    border: 1px solid var(--border);
  }
  .compose-empty:first-of-type {
    margin-top: 12px;
  }

  .empty-card {
    margin: 0 12px;
    text-align: center;
    padding: 60px 20px;
    color: var(--text3);
    font-size: 14px;
  }

  .sticky-hd {
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 48px;
    padding: 36px 12px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(12px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .btn-group {
    display: flex;
    gap: 8px;
  }
  .hd-btn {
    padding: 6px 14px;
    border-radius: 8px;
    border: 1px solid var(--border);
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.12s;
    white-space: nowrap;
  }
  .hd-btn:hover {
    border-color: var(--text3);
    color: var(--text1);
  }
  .hd-btn.on {
    background: var(--accent-soft);
    color: oklch(0.06 0 0);
    border-color: var(--accent);
  }
</style>
