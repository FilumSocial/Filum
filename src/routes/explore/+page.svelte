<script lang="ts">
  import { onMount } from 'svelte';
  import PostCard from '$lib/components/PostCard.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import type { PostWithScore, SortMode } from '$lib/types';

  let sortMode = $state<SortMode>('top');

  $effect(() => {
    if (auth.initialized) {
      postsStore.fetchFeed([], sortMode, auth.user?.id);
    }
  });

  $effect(() => {
    sortMode;
    if (auth.initialized) postsStore.fetchFeed([], sortMode, auth.user?.id);
  });

  function openThread(id: string) {
    window.location.href = `/post/${id}`;
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }
</script>

<svelte:head>
  <title>Filum - Explore</title>
</svelte:head>

<div>
  <div class="sticky-hd">
    <div class="flex justify-between items-center">
      <span class="font-semibold text-[17px]">Explore</span>
      <div class="seg">
        <button
          class="seg-btn"
          class:on={sortMode === 'top'}
          onclick={() => sortMode = 'top'}
        >Top</button>
        <button
          class="seg-btn"
          class:on={sortMode === 'chron'}
          onclick={() => sortMode = 'chron'}
        >New</button>
      </div>
    </div>
  </div>

  {#if postsStore.posts.length === 0}
    <div class="text-[var(--text3)] text-center py-[60px] px-5 text-[14px]">
      No posts yet. Be the first to post!
    </div>
  {:else}
    {#each postsStore.posts as post (post.id)}
      <PostCard
        {post}
        onClick={() => openThread(post.id)}
        onVote={(dir) => votePost(post.id, dir)}
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
