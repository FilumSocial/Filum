<script lang="ts">
  import { goto } from '$app/navigation';
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
  let followerCount = $state(0);
  let followingCount = $state(0);

  async function loadProfile() {
    const supabase = createClient();
    const { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', params.id)
      .single();

    if (profileData) {
      profile = profileData as Profile;

      const [followData, countRes, followerCountRes, followingCountRes] = await Promise.all([
        auth.profile
          ? supabase.from('follows').select('id').eq('follower_id', auth.profile.id).eq('following_id', params.id).single()
          : Promise.resolve({ data: null }),
        supabase.from('post_scores').select('*').eq('author_id', params.id).order('created_at', { ascending: false }),
        supabase.from('follows').select('*', { count: 'exact', head: true }).eq('following_id', params.id),
        supabase.from('follows').select('*', { count: 'exact', head: true }).eq('follower_id', params.id),
      ]) as any;

      isFollowing = !!followData?.data;
      followerCount = followerCountRes.count || 0;
      followingCount = followingCountRes.count || 0;

      const postData = countRes?.data;
      if (postData) {
        const { data: countData } = await supabase
          .from('comments')
          .select('post_id')
          .in('post_id', postData.map((p: any) => p.id) as string[]) as { data: { post_id: string }[] | null };

        const commentCounts = new Map<string, number>();
        if (countData) {
          for (const c of countData) {
            commentCounts.set(c.post_id, (commentCounts.get(c.post_id) || 0) + 1);
          }
        }

        userPosts = postData.map((p: any) => ({
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

  let togglingFollow = $state(false);

  async function toggleFollow() {
    if (!auth.profile || !profile || togglingFollow) return;
    togglingFollow = true;
    const wasFollowing = isFollowing;
    isFollowing = !isFollowing;
    const supabase = createClient();
    try {
      if (wasFollowing) {
        const { error } = await supabase
          .from('follows')
          .delete()
          .eq('follower_id', auth.profile.id)
          .eq('following_id', profile.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('follows')
          .insert({ follower_id: auth.profile.id, following_id: profile.id });
        if (error) throw error;
      }
    } catch {
      isFollowing = wasFollowing;
    } finally {
      togglingFollow = false;
    }
  }

  function openThread(id: string) {
    goto(`/post/${id}`);
  }

  function votePost(id: string, dir: 'up' | 'down') {
    postsStore.votePost(id, dir);
  }

  async function deletePost(id: string) {
    await postsStore.deletePost(id);
    userPosts = userPosts.filter(p => p.id !== id);
  }

  async function editPost(id: string, content: string) {
    await postsStore.editPost(id, content);
    const p = userPosts.find(p => p.id === id);
    if (p) p.content = content;
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
        <button class="follow-btn" class:following={isFollowing} disabled={togglingFollow} onclick={toggleFollow}>
          {isFollowing ? 'Following' : 'Follow'}
        </button>
      {/if}
    </div>

    <div class="stats-row">
      <span class="stat"><strong>{userPosts.length}</strong> posts</span>
      <span class="stat"><strong>{followerCount}</strong> followers</span>
      <span class="stat"><strong>{followingCount}</strong> following</span>
    </div>

    <div class="px-5 pt-6 pb-2">
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
          currentUserId={auth.user?.id}
          onDelete={() => deletePost(post.id)}
          onEdit={(_, c) => editPost(post.id, c)}
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
    border-radius: 8px;
    background: transparent;
    color: var(--accent);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    flex-shrink: 0;
    transition: background 0.15s, color 0.15s, box-shadow 0.15s;
  }
  .follow-btn:hover {
    background: var(--accent-soft);
    box-shadow: var(--shadow-s);
  }
  .follow-btn.following {
    background: var(--accent);
    color: oklch(0.065 0.02 175);
    box-shadow: var(--shadow-s);
  }
  .follow-btn.following:hover {
    background: oklch(0.66 0.14 155);
    color: oklch(0.065 0.02 175);
  }
  .stats-row {
    display: flex;
    gap: 20px;
    padding: 12px 20px;
    border-bottom: 1px solid var(--border);
    font-size: 13px;
    color: var(--text2);
  }
  .stat strong {
    color: var(--text1);
    font-weight: 600;
  }
  .follow-btn:disabled {
    opacity: 0.5;
    cursor: default;
  }
</style>
