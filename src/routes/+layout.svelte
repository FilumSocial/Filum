<script lang="ts">
  import '../app.css';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import RightPanel from '$lib/components/RightPanel.svelte';
  import Toast from '$lib/components/Toast.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { theme } from '$lib/stores/theme.svelte';
  import { createClient } from '$lib/supabase/client';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import type { Profile } from '$lib/types';

  let { children } = $props();

  let isAuthPage = $derived($page.url.pathname.startsWith('/login') || $page.url.pathname.startsWith('/register'));

  let currentPage = $derived(
    $page.url.pathname === '/' ? 'home' :
    $page.url.pathname.startsWith('/explore') ? 'explore' :
    $page.url.pathname.startsWith('/notifications') ? 'notif' :
    $page.url.pathname.startsWith('/search') ? 'search' :
    $page.url.pathname.startsWith('/settings') ? 'settings' :
    $page.url.pathname.startsWith('/profile') ? 'profile' :
    ''
  );

  let suggestions = $state<Profile[]>([]);

  async function loadSuggestions() {
    if (!auth.profile) { suggestions = []; return; }
    const supabase = createClient();
    const { data: followingData } = await supabase
      .from('follows')
      .select('following_id')
      .eq('follower_id', auth.profile.id) as { data: { following_id: string }[] | null };
    const excludeIds = [auth.profile.id, ...(followingData?.map(f => f.following_id) || [])];
    const { data: profiles } = await supabase
      .from('profiles')
      .select('*')
      .not('id', 'in', `(${excludeIds.join(',')})`)
      .limit(3) as { data: Profile[] | null };
    suggestions = profiles || [];
  }

  $effect(() => {
    if (!auth.initialized) auth.init();
  });

  $effect(() => {
    if (!theme.mode) theme.init();
  });

  $effect(() => {
    if (auth.initialized && auth.profile) loadSuggestions();
  });

  function handleNavigate(page: string) {
    if (page === 'home') goto('/');
    else if (page === 'explore') goto('/explore');
    else if (page === 'search') goto('/search');
    else if (page === 'notif') goto('/notifications');
    else if (page === 'settings') goto('/settings');
    else if (page === 'profile' && auth.profile) goto(`/profile/${auth.profile.id}`);
  }
</script>

<svelte:head>
  <link rel="icon" href="/favicon.svg" />
  <title>Filum</title>
</svelte:head>

<Toast />
{#if isAuthPage}
  {@render children()}
{:else}
  <div class="shell">
    <Sidebar
      userProfile={auth.profile}
      {currentPage}
      onNavigate={handleNavigate}
    />
    <main class="main">
      {@render children()}
    </main>
    <RightPanel
      trending={[
        { tag: '#Svelte', count: '4.1k' },
        { tag: '#Supabase', count: '2.8k' },
        { tag: '#Design', count: '1.9k' },
        { tag: '#WebDev', count: '1.2k' },
        { tag: '#OpenSource', count: '934' },
      ]}
      {suggestions}
      onFollow={loadSuggestions}
    />
  </div>
{/if}
