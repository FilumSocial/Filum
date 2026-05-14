<script lang="ts">
  import { goto } from '$app/navigation';
  import Avatar from '$lib/components/Avatar.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { Profile } from '$lib/types';
  import { ago } from '$lib/utils';

  let query = $state('');
  let userResults = $state<Profile[]>([]);
  let searching = $state(false);
  let timer: ReturnType<typeof setTimeout>;

  async function doSearch(q: string) {
    if (!q.trim()) { userResults = []; return; }
    searching = true;
    const supabase = createClient();
    const { data: profiles } = await supabase
      .from('profiles')
      .select('*')
      .or(`username.ilike.%${q}%,display_name.ilike.%${q}%`)
      .limit(20) as { data: Profile[] | null };
    userResults = profiles || [];
    searching = false;
  }

  function handleInput() {
    clearTimeout(timer);
    timer = setTimeout(() => doSearch(query), 250);
  }
</script>

<svelte:head>
  <title>Filum - Search</title>
</svelte:head>

<div>
  <div class="sticky-hd">
    <div class="search-wrap">
      <span class="mat-icon" style="font-size:18px;color:var(--text3)">search</span>
      <input
        class="search-input"
        type="text"
        placeholder="Search users..."
        bind:value={query}
        oninput={handleInput}
      />
    </div>
  </div>

  {#if searching}
    <div class="text-[var(--text3)] text-center py-10 text-[14px]">Searching...</div>
  {:else if query && userResults.length === 0}
    <div class="text-[var(--text3)] text-center py-10 text-[14px]">No users found.</div>
  {:else if userResults.length > 0}
    {#each userResults as user}
      <button class="user-row" onclick={() => goto(`/profile/${user.id}`)}>
        <Avatar name={user.display_name} color={user.avatar_color} size={38} />
        <div class="flex-1 min-w-0 text-left">
          <div class="font-semibold text-[14px] text-[var(--text1)]">{user.display_name}</div>
          <div class="text-[12px] text-[var(--text3)]">@{user.username}</div>
        </div>
      </button>
    {/each}
  {:else}
    <div class="text-[var(--text3)] text-center py-20 px-5 text-[14px]">
      Find other users to follow.
    </div>
  {/if}
</div>

<style>
  .sticky-hd {
    display: flex;
    align-items: center;
    height: 48px;
    padding: 0 12px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(14px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .search-wrap {
    display: flex;
    align-items: center;
    gap: 8px;
    flex: 1;
    background: var(--surface);
    border-radius: 8px;
    padding: 0 10px;
    border: 1px solid var(--border);
  }
  .search-input {
    flex: 1;
    background: transparent;
    border: none;
    outline: none;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    padding: 8px 0;
  }
  .search-input::placeholder {
    color: var(--text3);
  }
  .user-row {
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
  .user-row:hover {
    background: var(--surface);
  }
</style>
