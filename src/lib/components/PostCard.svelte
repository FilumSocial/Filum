<script lang="ts">
  import { goto } from '$app/navigation';
  import Avatar from './Avatar.svelte';
  import VoteRow from './VoteRow.svelte';
  import { ago, parseContent } from '$lib/utils';
  import type { PostWithScore } from '$lib/types';

  let {
    post,
    onClick,
    onVote,
    onDelete,
    onEdit,
    currentUserId,
    following = false,
  }: {
    post: PostWithScore;
    onClick: () => void;
    onVote: (dir: 'up' | 'down') => void;
    onDelete?: () => void;
    onEdit?: (id: string, content: string) => Promise<void>;
    currentUserId?: string | null;
    following?: boolean;
  } = $props();

  let isOwn = $derived(!!currentUserId && currentUserId === post.author_id);
  let editing = $state(false);
  let editText = $state('');
  let saving = $state(false);

  function startEdit(e: MouseEvent) {
    e.stopPropagation();
    editText = post.content;
    editing = true;
  }

  async function saveEdit() {
    if (!editText.trim() || !onEdit) return;
    saving = true;
    try {
      await onEdit(post.id, editText.trim());
      editing = false;
    } finally {
      saving = false;
    }
  }

  function cancelEdit(e: MouseEvent) {
    e.stopPropagation();
    editing = false;
  }

  function handleTagClick(e: MouseEvent, tag: string) {
    e.stopPropagation();
    goto(`/explore?tag=${encodeURIComponent(tag.slice(1))}`);
  }

  function handleMentionClick(e: MouseEvent, mention: string) {
    e.stopPropagation();
    goto(`/profile/${mention.slice(1)}`);
  }
</script>

<div
  class="pcard fade-up cursor-pointer"
  onclick={editing ? undefined : onClick}
  role="button"
  tabindex="0"
  onkeydown={(e) => { if (e.key === 'Enter' && !editing) onClick(); }}
>
  <button class="user-row" onclick={(e) => { e.stopPropagation(); goto(`/profile/${post.author.id}`); }}>
    <Avatar name={post.author.display_name} color={post.author.avatar_color} size={38} />
    <div class="flex-1 min-w-0 text-left">
      <div class="flex items-center gap-1.5 flex-wrap">
        <span class="font-semibold text-[14px] text-[var(--text1)] hover:underline">{post.author.display_name}</span>
        {#if following}
          <span class="following-badge">following</span>
        {/if}
        <span class="text-[12px] text-[var(--text3)]">@{post.author.username}</span>
      </div>
    </div>
    <span class="text-[12px] text-[var(--text3)] shrink-0">{ago(post.created_at)}</span>
  </button>

  {#if editing}
    <div role="presentation" class="edit-box" onclick={(e) => e.stopPropagation()}>
      <textarea class="edit-ta" bind:value={editText} maxlength="500" disabled={saving}></textarea>
      <div class="flex justify-end gap-1.5 mt-1.5">
        <button class="cancel-btn" onclick={(e) => cancelEdit(e)} disabled={saving}>Cancel</button>
        <button class="sm-post-btn" onclick={saveEdit} disabled={!editText.trim() || saving}>{saving ? 'Saving...' : 'Save'}</button>
      </div>
    </div>
  {:else}
    <p class="post-content">
      {#each parseContent(post.content) as seg}
        {#if seg.type === 'tag'}
          <button class="hashtag" onclick={(e) => handleTagClick(e, seg.value)}>{seg.value}</button>
        {:else if seg.type === 'mention'}
          <button class="hashtag" onclick={(e) => handleMentionClick(e, seg.value)}>{seg.value}</button>
        {:else}
          {seg.value}
        {/if}
      {/each}
    </p>
  {/if}

  <div class="flex items-center gap-1">
    <VoteRow
      upvotes={post.upvotes}
      downvotes={post.downvotes}
      userVote={post.user_vote}
      onVote={onVote}
    />
    <button class="act-btn" onclick={(e) => { e.stopPropagation(); }}>
      <span class="mat-icon" style="font-size:16px">chat_bubble_outline</span>
      <span class="text-[13px]">{post.comment_count}</span>
    </button>
    <button class="act-btn" aria-label="Share" onclick={(e) => { e.stopPropagation(); }}>
      <span class="mat-icon" style="font-size:16px">share</span>
    </button>
    {#if isOwn}
      {#if onEdit && !editing}
        <button class="act-btn" aria-label="Edit" onclick={startEdit}>
          <span class="mat-icon" style="font-size:16px">edit</span>
        </button>
      {/if}
      {#if onDelete}
        <button class="act-btn delete" aria-label="Delete" onclick={(e) => { e.stopPropagation(); onDelete(); }}>
          <span class="mat-icon" style="font-size:16px">delete</span>
        </button>
      {/if}
    {/if}
  </div>
</div>

<style>
  .pcard {
    margin: 0 12px 24px;
    padding: 16px 20px;
    background: var(--surface);
    border-radius: 12px;
    border: 1px solid var(--border);
    transition: border-color 0.15s;
  }
  .pcard:first-of-type {
    margin-top: 12px;
  }
  .pcard:hover {
    border-color: var(--text3);
  }
  .post-content {
    font-size: 15px;
    line-height: 1.6;
    color: var(--text1);
    margin: 6px 0 16px 0;
    white-space: pre-wrap;
  }
  .hashtag {
    background: none;
    border: none;
    padding: 0;
    font: inherit;
    font-size: inherit;
    color: var(--accent);
    cursor: pointer;
    display: inline;
  }
  .hashtag:hover {
    text-decoration: underline;
  }
  .edit-box {
    margin: 6px 0 16px 0;
  }
  .edit-ta {
    width: 100%;
    background: var(--surface2);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 10px;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    resize: none;
    min-height: 80px;
    line-height: 1.6;
  }
  .edit-ta:focus {
    outline: none;
    border-color: var(--accent);
  }
  .following-badge {
    font-size: 10px;
    padding: 1px 6px;
    border-radius: 10px;
    background: var(--accent-soft);
    color: var(--accent);
    font-weight: 600;
  }
  .act-btn {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 5px 8px;
    border: none;
    border-radius: 8px;
    background: transparent;
    color: var(--text2);
    font-size: 13px;
    cursor: pointer;
    transition: all 0.1s;
  }
  .act-btn:hover {
    background: var(--surface2);
    color: var(--text1);
  }
  .act-btn.delete:hover {
    color: oklch(0.65 0.16 25);
  }
  .fade-up {
    animation: fadeUp 0.18s ease forwards;
  }
  .user-row {
    display: flex;
    gap: 12px;
    margin-bottom: 10px;
    align-items: center;
    width: 100%;
    background: none;
    border: none;
    padding: 0;
    font: inherit;
    color: inherit;
    cursor: pointer;
    text-align: left;
  }
  .user-row:hover { opacity: 0.85; }
  .cancel-btn {
    padding: 5px 13px;
    border: none;
    border-radius: 8px;
    background: var(--surface2);
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 12px;
    cursor: pointer;
  }
  .sm-post-btn {
    padding: 5px 13px;
    border: none;
    border-radius: 8px;
    background: var(--accent);
    color: oklch(0.06 0 0);
    font-family: 'DM Sans', sans-serif;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
  }
  .sm-post-btn:disabled {
    opacity: 0.35;
    cursor: default;
  }
  .cancel-btn:disabled {
    opacity: 0.4;
    cursor: default;
  }
</style>
