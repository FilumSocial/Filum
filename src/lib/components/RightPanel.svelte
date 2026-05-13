<script lang="ts">
  import Avatar from './Avatar.svelte';
  import type { Profile } from '$lib/types';

  let {
    trending,
    suggestions,
  }: {
    trending: { tag: string; count: string }[];
    suggestions: Profile[];
  } = $props();
</script>

<aside class="right">
  <div class="panel">
    <div class="panel-title">Trending</div>
    {#each trending as item, i}
      <div class="trend-item" class:last={i === trending.length - 1}>
        <div>
          <div class="text-[14px] font-medium">{item.tag}</div>
          <div class="text-[11px] text-[var(--text3)]">{item.count} posts</div>
        </div>
      </div>
    {/each}
  </div>

  <div class="panel">
    <div class="panel-title">Suggestions</div>
    {#each suggestions as user}
      <div class="suggestion-item">
        <Avatar name={user.display_name} color={user.avatar_color} size={34} />
        <div class="flex-1 min-w-0">
          <div class="text-[13px] font-medium">{user.display_name}</div>
          <div class="text-[11px] text-[var(--text3)]">@{user.username}</div>
        </div>
        <button class="follow-btn">Follow</button>
      </div>
    {/each}
  </div>

  <div class="text-[11px] text-[var(--text3)] leading-relaxed">
    Filum &middot; Beta &middot; Made with &#9650;&#9660;
  </div>
</aside>

<style>
  .right {
    width: 260px;
    flex-shrink: 0;
    padding: 20px 14px;
  }
  .panel {
    background: var(--surface);
    border-radius: 14px;
    padding: 16px;
    margin-bottom: 16px;
    box-shadow: var(--shadow-s);
  }
  .panel-title {
    font-size: 11px;
    font-weight: 600;
    color: var(--text3);
    letter-spacing: 0.08em;
    text-transform: uppercase;
    margin-bottom: 10px;
  }
  .trend-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 9px 0;
    border-bottom: 1px solid var(--border);
  }
  .trend-item.last {
    border-bottom: none;
  }
  .suggestion-item {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 12px;
  }
  .follow-btn {
    padding: 5px 12px;
    border: 1px solid var(--accent);
    border-radius: 14px;
    background: transparent;
    color: var(--accent);
    font-family: 'DM Sans', sans-serif;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    flex-shrink: 0;
  }

  @media (max-width: 900px) {
    .right { display: none; }
  }
</style>
