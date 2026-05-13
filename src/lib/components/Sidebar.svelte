<script lang="ts">
  import Avatar from './Avatar.svelte';
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
    { id: 'home', icon: '\u2302', label: 'Home' },
    { id: 'explore', icon: '\u25CB', label: 'Explore' },
    { id: 'notif', icon: '\uD83D\uDD14', label: 'Notifications' },
    { id: 'profile', icon: '\u25EF', label: 'Profile' },
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
      <span class="text-[17px]">{item.icon}</span>
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
    border-right: 1px solid var(--border);
    position: sticky;
    top: 0;
    height: 100vh;
    display: flex;
    flex-direction: column;
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
    border-radius: 9px;
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    text-align: left;
    transition: all 0.12s;
  }
  .nav-btn:hover {
    background: var(--surface2);
    color: var(--text1);
  }
  .nav-btn.active {
    background: var(--accent-soft);
    color: var(--accent);
  }
  .user-card {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 10px;
  }
  .sign-in-btn {
    display: block;
    text-align: center;
    padding: 9px 10px;
    border-radius: 9px;
    background: var(--accent);
    color: #0c0b0a;
    font-size: 14px;
    font-weight: 600;
    text-decoration: none;
    transition: opacity 0.12s;
  }
  .sign-in-btn:hover {
    opacity: 0.87;
  }

  @media (max-width: 640px) {
    .sidebar { display: none; }
  }
</style>
