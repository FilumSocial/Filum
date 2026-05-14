<script lang="ts">
  import Avatar from './Avatar.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import type { Profile } from '$lib/types';

  let {
    userProfile,
    currentPage,
    onNavigate,
  }: {
    userProfile: Profile | null;
    currentPage: string;
    onNavigate: (page: string) => void;
  } = $props();

  const navItems = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'explore', label: 'Explore', icon: 'explore' },
    { id: 'notif', label: 'Notifications', icon: 'notifications' },
    { id: 'profile', label: 'Profile', icon: 'person' },
  ];
</script>

<nav class="sidebar">
  <div class="logo">Filum</div>
  {#each navItems as item}
    <button
      class="nav-btn"
      class:active={currentPage === item.id}
      onclick={() => onNavigate(item.id)}
    >
      <span class="mat-icon" style="font-size:20px">{item.icon}</span>
      {item.label}
    </button>
  {/each}
  <div class="flex-1"></div>
  {#if userProfile}
    <div class="user-card">
      <Avatar name={userProfile.display_name} color={userProfile.avatar_color} size={30} />
      <div>
        <div class="text-[13px] font-medium">{userProfile.display_name}</div>
        <div class="text-[11px] text-[var(--text3)]">@{userProfile.username}</div>
      </div>
      <button class="logout-btn" onclick={() => auth.signOut()} title="Sign out">
        <span class="mat-icon" style="font-size:18px">logout</span>
      </button>
    </div>
  {:else}
    <a href="/login" class="sign-in-btn">Sign in</a>
  {/if}
</nav>

<style>
  .sidebar {
    width: 210px;
    flex-shrink: 0;
    padding: 20px 12px;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    /* Base layer — darkest */
    background: var(--bg);
  }
  .logo {
    font-family: 'Cormorant Garamond', serif;
    font-size: 22px;
    color: var(--accent);
    letter-spacing: -0.02em;
    padding: 8px 10px;
    margin-bottom: 6px;
  }
  .nav-btn {
    display: flex;
    align-items: center;
    gap: 11px;
    width: 100%;
    padding: 9px 10px;
    border: none;
    border-radius: 8px;
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    text-align: left;
    transition: background 0.15s, color 0.15s;
  }
  .nav-btn:hover {
    background: var(--surface);
    color: var(--text1);
  }
  .nav-btn.active {
    background: var(--accent-soft);
    color: var(--accent);
    border: 1px solid var(--accent);
    /* box-shadow: var(--shadow-inset); */
  }
  .user-card {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 10px;
  }
  .logout-btn {
    margin-left: auto;
    background: none;
    border: none;
    color: var(--text3);
    cursor: pointer;
    padding: 4px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.15s, background 0.15s;
  }
  .logout-btn:hover {
    color: var(--accent);
    background: var(--accent-soft);
  }
  .sign-in-btn {
    display: block;
    text-align: center;
    padding: 9px 10px;
    border-radius: 8px;
    background: var(--accent-soft);
    color: var(--accent);
    font-size: 14px;
    font-weight: 600;
    text-decoration: none;
    transition: background 0.15s;
  }
  .sign-in-btn:hover {
    background: var(--accent-soft);
    opacity: 0.8;
  }

  @media (max-width: 640px) {
    .sidebar { display: none; }
  }
</style>
