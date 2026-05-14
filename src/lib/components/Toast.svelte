<script lang="ts">
  import { toast } from '$lib/stores/toast.svelte';
</script>

{#if toast.messages.length > 0}
  <div class="toast-container">
    {#each toast.messages as msg (msg.id)}
      <div class="toast toast-{msg.type}">
        {#if msg.type === 'success'}✓
        {:else if msg.type === 'error'}✗
        {:else}i{/if}
        {msg.text}
      </div>
    {/each}
  </div>
{/if}

<style>
  .toast-container {
    position: fixed;
    bottom: 24px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 8px;
    align-items: center;
    pointer-events: none;
  }
  .toast {
    padding: 10px 20px;
    border-radius: 10px;
    font-size: 13px;
    font-weight: 500;
    font-family: 'DM Sans', sans-serif;
    pointer-events: auto;
    animation: fadeUp 0.2s ease forwards;
    box-shadow: var(--shadow-m);
    backdrop-filter: blur(12px);
  }
  .toast-success {
    background: oklch(0.76 0.14 155 / 0.92);
    color: oklch(0.06 0 0);
  }
  .toast-error {
    background: oklch(0.65 0.16 25 / 0.92);
    color: white;
  }
  .toast-info {
    background: oklch(0.2 0 0 / 0.92);
    color: var(--text1);
  }
</style>
