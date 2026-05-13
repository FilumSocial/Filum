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
    {
      id: 'home', label: 'Home',
      icon: '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M2 8l7-6 7 6v8a1 1 0 01-1 1H3a1 1 0 01-1-1V8z"/><path d="M6 15V9h6v6"/></svg>',
    },
    {
      id: 'explore', label: 'Explore',
      icon: '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="9" cy="9" r="7"/><path d="M6 12l2-5 5-2-2 5-5 2z"/></svg>',
    },
    {
      id: 'notif', label: 'Notifications',
      icon: '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M13 7a4 4 0 00-8 0c0 3-1 5-2 6h12c-1-1-2-3-2-6"/><path d="M7.5 15a1.5 1.5 0 003 0"/></svg>',
    },
    {
      id: 'profile', label: 'Profile',
      icon: '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="9" cy="6" r="3"/><path d="M3 16c0-3.3 2.7-6 6-6s6 2.7 6 6"/></svg>',
    },
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
      {@html item.icon}
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
  .sign-in-btn {
    display: block;
    text-align: center;
    padding: 9px 10px;
    border-radius: 8px;
    background: var(--accent);
    color: oklch(0.06 0 0);
    font-size: 14px;
    font-weight: 600;
    text-decoration: none;
    transition: opacity 0.15s, transform 0.15s;
    box-shadow: var(--shadow-s);
  }
  .sign-in-btn:hover {
    opacity: 0.87;
    transform: scale(1.02);
  }
  .sign-in-btn:active {
    transform: scale(0.96);
  }

  @media (max-width: 640px) {
    .sidebar { display: none; }
  }
</style>
