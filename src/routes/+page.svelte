<script lang="ts">
  import { onMount } from 'svelte';
  import FeedView from '$lib/components/FeedView.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { SortMode, FeedMode } from '$lib/types';

  let feedMode = $state<FeedMode>('following');
  let sortMode = $state<SortMode>('chron');

  async function loadFeed() {
    if (!auth.initialized) return;
    let followingIds: string[] = [];
    if (feedMode === 'following' && auth.profile) {
      const supabase = createClient();
      const { data } = await supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', auth.profile.id);
      if (data) followingIds = data.map(f => f.following_id);
    }
    postsStore.fetchFeed(followingIds, sortMode, auth.user?.id);
  }

  $effect(() => {
    if (auth.initialized) {
      loadFeed();
    }
  });

  $effect(() => {
    feedMode;
    sortMode;
    if (auth.initialized) loadFeed();
  });

  let profile = $derived(auth.profile);

  function openThread(id: string) {
    window.location.href = `/post/${id}`;
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }

  function newPost(content: string) {
    if (!profile) return;
    postsStore.createPost(content, profile);
  }
</script>

<svelte:head>
  <title>Filum - Home</title>
</svelte:head>

<FeedView
  posts={postsStore.posts}
  userProfile={profile}
  {feedMode}
  {sortMode}
  onSetFeedMode={(m) => feedMode = m}
  onSetSortMode={(m) => sortMode = m}
  onOpenThread={openThread}
  onVotePost={votePost}
  onNewPost={newPost}
/>
