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
    <div class="tabs">
      <button
        class="tab"
        class:on={feedMode === 'following'}
        onclick={() => onSetFeedMode('following')}
      >Following</button>
      <button
        class="tab"
        class:on={feedMode === 'rec'}
        onclick={() => onSetFeedMode('rec')}
      >Recommended</button>
    </div>
    <div class="seg">
      <button
        class="seg-btn"
        class:on={sortMode === 'chron'}
        onclick={() => onSetSortMode('chron')}
      >New</button>
      <button
        class="seg-btn"
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
        <a href="/login" class="inline-block px-5 py-2 rounded-[8px] bg-[var(--accent)] text-[oklch(0.06_0_0)] font-semibold text-[13px] no-underline hover:opacity-87 transition-opacity">Sign in</a>
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
    padding: 0 20px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(12px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .tabs {
    display: flex;
    gap: 0;
    height: 100%;
  }
  .tab {
    height: 100%;
    padding: 0 14px;
    border: none;
    border-bottom: 2px solid transparent;
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.12s;
  }
  .tab:hover { color: var(--text1); }
  .tab.on {
    color: var(--text1);
    border-bottom-color: var(--accent);
  }
  .seg {
    display: flex;
    background: var(--surface2);
    border-radius: 7px;
    padding: 3px;
    gap: 2px;
  }
  .seg-btn {
    padding: 5px 10px;
    border: none;
    border-radius: 5px;
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 12px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.12s;
    white-space: nowrap;
  }
  .seg-btn.on {
    background: var(--surface);
    color: var(--text1);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
  }
</style>
