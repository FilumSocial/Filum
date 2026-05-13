<script lang="ts">
  import Avatar from '$lib/components/Avatar.svelte';
  import PostCard from '$lib/components/PostCard.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { Profile, PostWithScore } from '$lib/types';

  let { params } = $props();

  let profile = $state<Profile | null>(null);
  let userPosts = $state<PostWithScore[]>([]);
  let loading = $state(true);
  let isFollowing = $state(false);

  async function loadProfile() {
    const supabase = createClient();
    const { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', params.id)
      .single();

    if (profileData) {
      profile = profileData as Profile;

      // Check if following
      if (auth.profile) {
        const { data: followData } = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', auth.profile.id)
          .eq('following_id', params.id)
          .single();
        isFollowing = !!followData;
      }

      // Get post scores
      const { data: postData } = await supabase
        .from('post_scores')
        .select('*')
        .eq('author_id', params.id)
        .order('created_at', { ascending: false });

      if (postData) {
        const { data: countData } = await supabase
          .from('comments')
          .select('post_id')
          .in('post_id', postData.map(p => p.id));

        const commentCounts = new Map<string, number>();
        if (countData) {
          for (const c of countData) {
            commentCounts.set(c.post_id, (commentCounts.get(c.post_id) || 0) + 1);
          }
        }

        userPosts = postData.map(p => ({
          ...p,
          author: profileData as Profile,
          user_vote: null,
          comment_count: commentCounts.get(p.id) || 0,
        })) as PostWithScore[];
      }
    }
    loading = false;
  }

  $effect(() => {
    if (auth.initialized) loadProfile();
  });

  async function toggleFollow() {
    if (!auth.profile || !profile) return;
    const supabase = createClient();
    if (isFollowing) {
      await supabase
        .from('follows')
        .delete()
        .eq('follower_id', auth.profile.id)
        .eq('following_id', profile.id);
      isFollowing = false;
    } else {
      await supabase
        .from('follows')
        .insert({ follower_id: auth.profile.id, following_id: profile.id });
      isFollowing = true;
    }
  }

  function openThread(id: string) {
    window.location.href = `/post/${id}`;
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }
</script>

<svelte:head>
  <title>Filum - Profile</title>
</svelte:head>

{#if loading}
  <div class="flex items-center justify-center py-20 text-[var(--text3)]">Loading...</div>
{:else if profile}
  <div>
    <div class="profile-header">
      <Avatar name={profile.display_name} color={profile.avatar_color} size={64} />
      <div class="flex-1">
        <h1 class="text-xl font-semibold">{profile.display_name}</h1>
        <p class="text-sm text-[var(--text3)]">@{profile.username}</p>
        {#if profile.bio}
          <p class="text-sm mt-2">{profile.bio}</p>
        {/if}
      </div>
      {#if auth.profile && auth.profile.id !== profile.id}
        <button class="follow-btn" class:following={isFollowing} onclick={toggleFollow}>
          {isFollowing ? 'Following' : 'Follow'}
        </button>
      {/if}
    </div>

    <div class="border-b border-[var(--border)] px-5 py-3">
      <span class="text-sm font-semibold text-[var(--text1)]">Posts</span>
    </div>

    {#if userPosts.length === 0}
      <div class="text-[var(--text3)] text-center py-[60px] px-5 text-[14px]">
        No posts yet.
      </div>
    {:else}
      {#each userPosts as post (post.id)}
        <PostCard
          {post}
          onClick={() => openThread(post.id)}
          onVote={(dir) => votePost(post.id, dir)}
        />
      {/each}
    {/if}
  </div>
{:else}
  <div class="flex items-center justify-center py-20 text-[var(--text3)]">User not found</div>
{/if}

<style>
  .profile-header {
    padding: 24px 20px;
    border-bottom: 1px solid var(--border);
    display: flex;
    gap: 16px;
    align-items: flex-start;
  }
  .follow-btn {
    padding: 6px 16px;
    border: 1px solid var(--accent);
    border-radius: 18px;
    background: transparent;
    color: var(--accent);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    flex-shrink: 0;
    transition: all 0.12s;
  }
  .follow-btn.following {
    background: var(--accent);
    color: oklch(0.06 0 0);
  }
</style>
