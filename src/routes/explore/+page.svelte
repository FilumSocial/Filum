<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import PostCard from '$lib/components/PostCard.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import type { SortMode } from '$lib/types';

  let sortMode = $state<SortMode>('top');
  let loadingMore = $state(false);
  let sentinelEl = $state<HTMLDivElement | null>(null);
  let sentinelObserver: IntersectionObserver | null = null;
  let currentTag = $derived($page.url.searchParams.get('tag') || '');

  $effect(() => {
    if (auth.initialized) {
      postsStore.fetchFeed([], sortMode, auth.user?.id, false, currentTag || undefined);
    }
  });

  $effect(() => {
    sortMode; currentTag;
    if (auth.initialized) postsStore.fetchFeed([], sortMode, auth.user?.id, false, currentTag || undefined);
  });

  $effect(() => {
    const el = sentinelEl;
    if (sentinelObserver) sentinelObserver.disconnect();
    if (el && postsStore.hasMore) {
      sentinelObserver = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting && !loadingMore) {
          loadMore();
        }
      }, { rootMargin: '300px' });
      sentinelObserver.observe(el);
    }
    return () => {
      if (sentinelObserver) sentinelObserver.disconnect();
    };
  });

  async function loadMore() {
    if (loadingMore || !postsStore.hasMore) return;
    loadingMore = true;
    await postsStore.fetchFeed([], sortMode, auth.user?.id, true, currentTag || undefined);
    loadingMore = false;
  }

  function openThread(id: string) {
    goto(`/post/${id}`);
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }

  async function deletePost(id: string) {
    await postsStore.deletePost(id);
  }

  async function editPost(id: string, content: string) {
    await postsStore.editPost(id, content);
  }
</script>

<svelte:head>
  <title>Filum - Explore</title>
</svelte:head>

<div>
  <div class="sticky-hd">
    <span class="font-semibold text-[15px]">{currentTag ? `#${currentTag}` : 'Explore'}</span>
    <div class="btn-group">
      <button
        class="hd-btn"
        class:on={sortMode === 'top'}
        onclick={() => sortMode = 'top'}
      >Top</button>
      <button
        class="hd-btn"
        class:on={sortMode === 'chron'}
        onclick={() => sortMode = 'chron'}
      >New</button>
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
        currentUserId={auth.user?.id}
        onDelete={() => deletePost(post.id)}
        onEdit={(_, c) => editPost(post.id, c)}
        onClick={() => openThread(post.id)}
        onVote={(dir) => votePost(post.id, dir)}
      />
    {/each}
    {#if postsStore.hasMore}
      <div bind:this={sentinelEl} class="sentinel"></div>
    {/if}
    {#if loadingMore}
      <div class="flex justify-center pb-8">
        <span class="text-[13px] text-[var(--text3)]">Loading more...</span>
      </div>
    {/if}
  {/if}
</div>

<style>
  .sticky-hd {
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 48px;
    padding: 0 20px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(14px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .btn-group {
    display: flex;
    gap: 4px;
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
    background: var(--accent);
    color: oklch(0.06 0 0);
    border-color: var(--accent);
  }
  .sentinel {
    height: 1px;
    width: 100%;
    pointer-events: none;
  }
</style>
