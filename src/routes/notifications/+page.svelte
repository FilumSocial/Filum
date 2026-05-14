<script lang="ts">
  import { goto } from '$app/navigation';
  import Avatar from '$lib/components/Avatar.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { createClient } from '$lib/supabase/client';
  import { ago } from '$lib/utils';
  import type { Profile } from '$lib/types';

  interface Notification {
    type: 'follow' | 'vote' | 'reply';
    user: Profile;
    created_at: string;
    post_id?: string;
    post_content?: string;
  }

  let notifications = $state<Notification[]>([]);
  let loading = $state(true);

  async function loadNotifications() {
    if (!auth.initialized) return;
    const supabase = createClient();
    const userId = auth.user!.id;

    try {
      const [followRes, voteRes, replyRes] = await Promise.all([
        supabase.from('follows').select('follower_id, created_at').eq('following_id', userId).order('created_at', { ascending: false }).limit(20),
        supabase.from('votes').select('user_id, vote_type, created_at, post_id').not('post_id', 'is', null).neq('user_id', userId).in('post_id',
          (await supabase.from('posts').select('id').eq('author_id', userId) as any).data?.map((p: any) => p.id) || []
        ).order('created_at', { ascending: false }).limit(20),
        supabase.from('comments').select('author_id, created_at, content, post_id').neq('author_id', userId).in('post_id',
          (await supabase.from('posts').select('id').eq('author_id', userId) as any).data?.map((p: any) => p.id) || []
        ).order('created_at', { ascending: false }).limit(20),
      ]) as any;

      const list: Notification[] = [];
      const userIds = new Set<string>();

      for (const f of (followRes.data || [])) {
        userIds.add(f.follower_id);
        list.push({ type: 'follow', user: null!, created_at: f.created_at });
      }
      for (const v of (voteRes.data || [])) {
        userIds.add(v.user_id);
        list.push({ type: 'vote', user: null!, created_at: v.created_at, post_id: v.post_id });
      }
      for (const c of (replyRes.data || [])) {
        userIds.add(c.author_id);
        list.push({ type: 'reply', user: null!, created_at: c.created_at, post_id: c.post_id, post_content: c.content });
      }

      const { data: profiles } = await supabase.from('profiles').select('*').in('id', [...userIds]) as { data: Profile[] | null };
      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      for (const n of list) {
        const uid = n.type === 'follow'
          ? (followRes.data?.find((f: any) => f.created_at === n.created_at)?.follower_id)
          : n.type === 'vote'
            ? (voteRes.data?.find((v: any) => v.created_at === n.created_at && v.post_id === n.post_id)?.user_id)
            : (replyRes.data?.find((c: any) => c.created_at === n.created_at && c.post_id === n.post_id)?.author_id);
        n.user = profileMap.get(uid) || { id: '', username: 'unknown', display_name: 'Unknown', avatar_color: '#888', bio: '', created_at: '' };
      }

      list.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
      notifications = list.slice(0, 50);
    } catch (e) {
      console.error('Failed to load notifications', e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    if (auth.initialized && auth.user) loadNotifications();
  });
</script>

<svelte:head>
  <title>Filum - Notifications</title>
</svelte:head>

<div>
  <div class="sticky-hd">
    <span class="font-semibold text-[15px]">Notifications</span>
  </div>

  {#if loading}
    <div class="flex items-center justify-center py-20 text-[var(--text3)]">Loading...</div>
  {:else if notifications.length === 0}
    <div class="text-[var(--text3)] text-center py-[60px] px-5 text-[14px]">
      No notifications yet.
    </div>
  {:else}
    {#each notifications as n (n.created_at + n.type + (n.post_id || ''))}
      <button class="notif-card" onclick={() => n.post_id ? goto(`/post/${n.post_id}`) : goto(`/profile/${n.user.id}`)}>
        <Avatar name={n.user.display_name} color={n.user.avatar_color} size={36} />
        <div class="flex-1 min-w-0 text-left">
          <div class="text-[13px] leading-relaxed">
            <span class="font-semibold text-[var(--text1)]">@{n.user.username}</span>
            {#if n.type === 'follow'}
              <span class="text-[var(--text2)]"> followed you</span>
            {:else if n.type === 'vote'}
              <span class="text-[var(--text2)]"> voted on your post</span>
            {:else if n.type === 'reply'}
              <span class="text-[var(--text2)]"> replied to your post</span>
            {/if}
          </div>
          <div class="text-[11px] text-[var(--text3)] mt-0.5">{ago(n.created_at)}</div>
        </div>
      </button>
    {/each}
  {/if}
</div>

<style>
  .sticky-hd {
    display: flex;
    align-items: center;
    height: 48px;
    padding: 0 20px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(14px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .notif-card {
    display: flex;
    align-items: center;
    gap: 12px;
    width: 100%;
    padding: 12px 20px;
    background: none;
    border: none;
    border-bottom: 1px solid var(--border);
    font: inherit;
    color: inherit;
    cursor: pointer;
    text-align: left;
    transition: background 0.1s;
  }
  .notif-card:hover {
    background: var(--surface);
  }
</style>
