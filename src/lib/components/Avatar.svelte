<script lang="ts">
  let { name, color, size = 36 }: { name: string; color: string; size?: number } = $props();
</script>

<div
  class="flex shrink-0 items-center justify-center rounded-full font-semibold text-neutral-950"
  style="width: {size}px; height: {size}px; background: {color}; font-size: {Math.round(size * 0.4)}px"
>
  {name[0]}
</div>
