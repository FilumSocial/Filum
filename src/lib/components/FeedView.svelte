<script lang="ts">
  import PostCard from './PostCard.svelte';
  import ComposeBox from './ComposeBox.svelte';
  import type { PostWithScore, Profile, SortMode, FeedMode } from '$lib/types';

  let {
    posts,
    userProfile,
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
    feedMode: FeedMode;
    sortMode: SortMode;
    onSetFeedMode: (mode: FeedMode) => void;
    onSetSortMode: (mode: SortMode) => void;
    onOpenThread: (id: string) => void;
    onVotePost: (id: string, dir: 'up' | 'down') => void;
    onNewPost: (content: string) => void;
  } = $props();
</script>

<div>
  <div class="sticky-hd">
    <div class="flex justify-between items-center">
      <span class="font-semibold text-[17px]">Home</span>
      <div class="seg">
        <button
          class="seg-btn"
          class:on={sortMode === 'chron'}
          onclick={() => onSetSortMode('chron')}
        >&#9201; New</button>
        <button
          class="seg-btn"
          class:on={sortMode === 'top'}
          onclick={() => onSetSortMode('top')}
        >&#128293; Top</button>
      </div>
    </div>
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
  </div>

  {#if userProfile}
    <ComposeBox
      profile={userProfile}
      placeholder="What are you thinking?"
      buttonLabel="Post"
      onSubmit={onNewPost}
    />
  {/if}

  {#if posts.length === 0}
    <div class="text-[var(--text3)] text-center py-[60px] px-5 text-[14px]">
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
  .sticky-hd {
    padding: 14px 20px;
    border-bottom: 1px solid var(--border);
    position: sticky;
    top: 0;
    background: rgba(12, 11, 10, 0.93);
    backdrop-filter: blur(14px);
    z-index: 20;
  }
  .tabs {
    display: flex;
    gap: 0;
    margin-top: 10px;
  }
  .tab {
    flex: 1;
    padding: 11px 6px;
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
    flex: 1;
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
