<script lang="ts">
  let {
    upvotes = 0,
    downvotes = 0,
    userVote,
    onVote,
    compact = false,
  }: {
    upvotes: number;
    downvotes: number;
    userVote: 'up' | 'down' | null;
    onVote: (dir: 'up' | 'down') => void;
    compact?: boolean;
  } = $props();

  let score = $derived(upvotes - downvotes);
</script>

<div class="flex items-center gap-0.5">
  <button
    class="vote-btn up"
    class:on={userVote === 'up'}
    onclick={(e) => { e.stopPropagation(); onVote('up'); }}
  >
    <span class="text-[14px] leading-none">&#9650;</span>
    {#if !compact}
      <span>{upvotes.toLocaleString()}</span>
    {/if}
  </button>

  <span
    class="score"
    class:pos={score > 0}
    class:neg={score < 0}
  >
    {score > 0 ? '+' : ''}{compact ? score : score.toLocaleString()}
  </span>

  <button
    class="vote-btn down"
    class:on={userVote === 'down'}
    onclick={(e) => { e.stopPropagation(); onVote('down'); }}
  >
    <span class="text-[14px] leading-none">&#9660;</span>
    {#if !compact}
      <span>{downvotes.toLocaleString()}</span>
    {/if}
  </button>
</div>

<style>
  .vote-btn {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 5px 8px;
    border: none;
    border-radius: 8px;
    background: transparent;
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: background 0.15s, color 0.15s;
  }
  .vote-btn:hover {
    background: var(--surface);
  }
  .vote-btn.up.on {
    color: var(--up);
    background: var(--accent-soft);
  }
  .vote-btn.down.on {
    color: var(--down);
    background: var(--down-soft);
  }
  .vote-btn:active {
    transform: scale(0.94);
  }
  .score {
    font-size: 12px;
    font-weight: 600;
    min-width: 26px;
    text-align: center;
    color: var(--text2);
    transition: color 0.15s;
  }
  .score.pos {
    color: var(--up);
  }
  .score.neg {
    color: var(--down);
  }
</style>
