<script lang="ts">
  import Avatar from './Avatar.svelte';
  import VoteRow from './VoteRow.svelte';
  import CommentNode from './CommentNode.svelte';
  import ComposeBox from './ComposeBox.svelte';
  import { ago } from '$lib/utils';
  import type { PostWithScore, CommentWithScore, Profile } from '$lib/types';

  let {
    post,
    comments,
    userProfile,
    onBack,
    onVotePost,
    onVoteComment,
    onAddComment,
    onAddReply,
  }: {
    post: PostWithScore;
    comments: CommentWithScore[];
    userProfile: Profile | null;
    onBack: () => void;
    onVotePost: (dir: 'up' | 'down') => void;
    onVoteComment: (id: string, dir: 'up' | 'down') => void;
    onAddComment: (content: string) => Promise<void> | void;
    onAddReply: (parentId: string, content: string) => Promise<void> | void;
  } = $props();
</script>

<div class="slide-in">
  <div class="sticky-hd flex items-center gap-3">
    <button class="back-btn" onclick={onBack}>&larr; Back</button>
    <span class="font-semibold text-[15px]">Thread</span>
  </div>

  <div class="full-post">
    <button class="user-btn flex gap-3 mb-3 items-start" onclick={() => window.location.href = `/profile/${post.author.id}`}>
      <Avatar name={post.author.display_name} color={post.author.avatar_color} size={42} />
      <div class="text-left">
        <div class="font-semibold text-[15px] hover:underline">{post.author.display_name}</div>
        <div class="text-[13px] text-[var(--text3)]">@{post.author.username} &middot; {ago(post.created_at)}</div>
      </div>
    </button>
    <p class="text-[17px] leading-relaxed text-[var(--text1)] mb-3.5 whitespace-pre-wrap">{post.content}</p>
    <div class="mt-3 -mx-1">
      <VoteRow
        upvotes={post.upvotes}
        downvotes={post.downvotes}
        userVote={post.user_vote}
        onVote={onVotePost}
      />
    </div>
  </div>

  {#if userProfile}
    <div class="border-b border-[var(--border)]">
      <ComposeBox
        profile={userProfile}
        placeholder="Write a comment..."
        buttonLabel="Post"
        compact
        onSubmit={onAddComment}
      />
    </div>
  {/if}

  <div class="px-5 pb-10">
    {#if comments.length === 0}
      <div class="text-[var(--text3)] text-center py-10 text-[14px]">
        No comments yet. Be the first!
      </div>
    {:else}
      {#each comments as comment}
        <CommentNode
          comment={comment}
          depth={0}
          {userProfile}
          onVote={onVoteComment}
          onReply={onAddReply}
        />
      {/each}
    {/if}
  </div>
</div>

<style>
  .sticky-hd {
    padding: 14px 20px;
    position: sticky;
    top: 0;
    background: oklch(0.065 0.006 55 / 0.92);
    backdrop-filter: blur(14px);
    z-index: 20;
    box-shadow:
      inset 0 -1px 0 oklch(1 0 0 / 0.03),
      0 1px 3px oklch(0 0 0 / 0.2);
  }
  .back-btn {
    padding: 6px 12px;
    border: none;
    border-radius: 8px;
    background: var(--surface);
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    cursor: pointer;
    transition: background 0.15s;
  }
  .back-btn:hover {
    background: var(--surface2);
    box-shadow: var(--shadow-s);
  }
  .full-post {
    padding: 18px 20px;
    border-bottom: 1px solid var(--border);
  }
  .slide-in {
    animation: slideIn 0.18s ease forwards;
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
</style>
