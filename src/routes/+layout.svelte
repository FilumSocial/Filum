<script lang="ts">
  import '../app.css';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import RightPanel from '$lib/components/RightPanel.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';

  let { children } = $props();

  let isAuthPage = $derived($page.url.pathname.startsWith('/login') || $page.url.pathname.startsWith('/register'));

  let currentPage = $derived(
    $page.url.pathname === '/' ? 'home' :
    $page.url.pathname.startsWith('/explore') ? 'explore' :
    $page.url.pathname.startsWith('/profile') ? 'profile' :
    ''
  );

  $effect(() => {
    if (!auth.initialized) auth.init();
  });

  $effect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    function update() { document.body.classList.toggle('light', !mq.matches); }
    mq.addEventListener('change', update);
    return () => mq.removeEventListener('change', update);
  });

  function handleNavigate(page: string) {
    if (page === 'home') goto('/');
    else if (page === 'explore') goto('/explore');
    else if (page === 'profile' && auth.profile) goto(`/profile/${auth.profile.id}`);
  }
</script>

<svelte:head>
  <link rel="icon" href="/favicon.svg" />
  <title>Filum</title>
</svelte:head>

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
      suggestions={[]}
    />
  </div>
{/if}
