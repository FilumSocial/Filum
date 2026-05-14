<script lang="ts">
  import { goto } from '$app/navigation';
  import FeedView from '$lib/components/FeedView.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { SortMode, FeedMode } from '$lib/types';

  let feedMode = $state<FeedMode>('following');
  let sortMode = $state<SortMode>('chron');

  let loadingMore = $state(false);

  async function loadFeed() {
    if (!auth.initialized) return;
    let followingIds: string[] = [];
    if (feedMode === 'following' && auth.profile) {
      const supabase = createClient();
      const { data } = await supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', auth.profile.id) as { data: { following_id: string }[] | null };
      if (data) followingIds = data.map(f => f.following_id);
    }
    await postsStore.fetchFeed(followingIds, sortMode, auth.user?.id);
  }

  async function loadMore() {
    if (loadingMore || !postsStore.hasMore) return;
    loadingMore = true;
    let followingIds: string[] = [];
    if (feedMode === 'following' && auth.profile) {
      const supabase = createClient();
      const { data } = await supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', auth.profile.id) as { data: { following_id: string }[] | null };
      if (data) followingIds = data.map(f => f.following_id);
    }
    await postsStore.fetchFeed(followingIds, sortMode, auth.user?.id, true);
    loadingMore = false;
  }

  $effect(() => {
    if (auth.initialized) loadFeed();
  });

  $effect(() => {
    feedMode; sortMode;
    if (auth.initialized) loadFeed();
  });

  let profile = $derived(auth.profile);

  function openThread(id: string) {
    goto(`/post/${id}`);
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }

  async function newPost(content: string): Promise<void> {
    if (!auth.profile) return;
    await postsStore.createPost(content, auth.profile);
  }

  async function deletePost(id: string) {
    await postsStore.deletePost(id);
  }
</script>

<svelte:head>
  <title>Filum - Home</title>
</svelte:head>

<FeedView
  posts={postsStore.posts}
  userProfile={profile}
  error={postsStore.error}
  hasMore={postsStore.hasMore}
  {feedMode}
  {sortMode}
  {loadingMore}
  onSetFeedMode={(m) => feedMode = m}
  onSetSortMode={(m) => sortMode = m}
  onOpenThread={openThread}
  onVotePost={votePost}
  onNewPost={newPost}
  onLoadMore={loadMore}
  onDeletePost={deletePost}
/>
