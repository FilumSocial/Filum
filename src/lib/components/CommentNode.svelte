<script lang="ts">
  import Avatar from './Avatar.svelte';
  import VoteRow from './VoteRow.svelte';
  import CommentNode from './CommentNode.svelte';
  import { ago } from '$lib/utils';
  import type { CommentWithScore, Profile } from '$lib/types';

  let {
    comment,
    depth = 0,
    userProfile,
    onVote,
    onReply,
  }: {
    comment: CommentWithScore;
    depth?: number;
    userProfile: Profile | null;
    onVote: (id: string, dir: 'up' | 'down') => void;
    onReply: (parentId: string, content: string) => Promise<void> | void;
  } = $props();

  let collapsed = $state(false);
  let replying = $state(false);
  let replyText = $state('');

  const depthColors = ['oklch(0.76 0.14 155)', 'oklch(0.62 0.12 175)', 'oklch(0.50 0.08 155)', 'oklch(0.40 0.06 175)', 'oklch(0.60 0.10 145)', 'oklch(0.55 0.08 185)'];
  let color = $derived(depthColors[depth % depthColors.length]);

  function submitReply() {
    if (!replyText.trim()) return;
    onReply(comment.id, replyText.trim());
    replyText = '';
    replying = false;
  }
</script>

<div class="cmt">
  <div class="cmt-meta">
    <button class="user-btn" onclick={() => window.location.href = `/profile/${comment.author.id}`}>
      <Avatar name={comment.author.display_name} color={comment.author.avatar_color} size={27} />
    </button>
    <button class="user-btn" onclick={() => window.location.href = `/profile/${comment.author.id}`}>
      <span class="font-semibold text-[13px] text-[var(--text1)] hover:underline">{comment.author.display_name}</span>
    </button>
    <button class="user-btn" onclick={() => window.location.href = `/profile/${comment.author.id}`}>
      <span class="text-[12px] text-[var(--text3)]">@{comment.author.username}</span>
    </button>
    <span class="text-[12px] text-[var(--text3)] ml-auto">{ago(comment.created_at)}</span>
    {#if comment.replies.length > 0}
      <button
        class="collapse-btn"
        style="color: {color}"
        onclick={() => collapsed = !collapsed}
      >
        {collapsed ? `\u25B6 ${comment.replies.length}` : '\u25BC'}
      </button>
    {/if}
  </div>

  {#if !collapsed}
    <p class="cmt-content">{comment.content}</p>
    <div class="flex items-center gap-1">
      <VoteRow
        upvotes={comment.upvotes}
        downvotes={comment.downvotes}
        userVote={comment.user_vote}
        onVote={(dir) => onVote(comment.id, dir)}
        compact
      />
      {#if userProfile}
        <button class="act-btn text-[12px]" onclick={() => replying = !replying}>
          &#8617; Reply
        </button>
      {/if}
    </div>

    {#if replying}
      <div class="reply-box">
        <textarea
          class="reply-ta"
          placeholder="Reply to @{comment.author.username}..."
          bind:value={replyText}
        ></textarea>
        <div class="flex justify-end gap-1.5 mt-1.5">
          <button class="cancel-btn" onclick={() => { replying = false; replyText = ''; }}>Cancel</button>
          <button
            class="sm-post-btn"
            disabled={!replyText.trim()}
            onclick={submitReply}
          >Reply</button>
        </div>
      </div>
    {/if}

    {#if comment.replies.length > 0}
      <div class="replies-wrap" style="border-left-color: {color}">
        {#each comment.replies as reply}
          <CommentNode
            comment={reply}
            depth={depth + 1}
            {userProfile}
            onVote={onVote}
            {onReply}
          />
        {/each}
      </div>
    {/if}
  {/if}
</div>

<style>
  .cmt {
    padding: 12px 20px;
  }
  .cmt-meta {
    display: flex;
    align-items: center;
    gap: 7px;
  }
  .cmt-content {
    font-size: 14px;
    line-height: 1.6;
    color: var(--text1);
    margin: 6px 0 8px 0;
    white-space: pre-wrap;
  }
  .replies-wrap {
    border-left: 2px solid oklch(1 0 0 / 0.06);
    margin-left: 0;
    padding-left: 28px;
    margin-top: 6px;
  }
  .user-btn {
    background: none;
    border: none;
    padding: 0;
    font: inherit;
    color: inherit;
    cursor: pointer;
    line-height: 1;
  }
  .user-btn:hover { opacity: 0.85; }
  .reply-box {
    margin-top: 8px;
    padding: 10px 12px;
    background: var(--surface2);
    border-radius: 10px;
    border: 1px solid var(--border);
  }
  .reply-ta {
    width: 100%;
    background: transparent;
    border: none;
    outline: none;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    resize: none;
    line-height: 1.5;
    min-height: 56px;
  }
  .reply-ta::placeholder {
    color: var(--text3);
  }
  .collapse-btn {
    font-size: 11px;
    background: transparent;
    border: none;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    font-weight: 600;
    padding-left: 4px;
    flex-shrink: 0;
  }
  .act-btn {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 5px 8px;
    border: none;
    border-radius: 6px;
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
  .sm-post-btn {
    padding: 5px 13px;
    border: none;
    border-radius: 14px;
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
  .cancel-btn {
    padding: 5px 13px;
    border: none;
    border-radius: 14px;
    background: var(--surface2);
    color: var(--text2);
    font-family: 'DM Sans', sans-serif;
    font-size: 12px;
    cursor: pointer;
  }
</style>
