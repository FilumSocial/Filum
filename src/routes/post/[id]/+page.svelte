<script lang="ts">
  import ThreadView from '$lib/components/ThreadView.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { PostWithScore, CommentWithScore, Profile } from '$lib/types';

  let { data }: { data: { id: string } } = $props();

  let post = $state<PostWithScore | null>(null);
  let comments = $state<CommentWithScore[]>([]);
  let loading = $state(true);

  async function loadThread() {
    if (!auth.initialized) return;
    const supabase = createClient();
    const postId = data.id;

    const { data: postData } = await supabase
      .from('post_scores')
      .select('*')
      .eq('id', postId)
      .single();
    if (!postData) { loading = false; return; }

    const { data: authorData } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', postData.author_id)
      .single();

    let userVote: 'up' | 'down' | null = null;
    if (auth.user) {
      const { data: voteData } = await supabase
        .from('votes')
        .select('vote_type')
        .eq('user_id', auth.user.id)
        .eq('post_id', postId)
        .maybeSingle();
      if (voteData) userVote = voteData.vote_type as 'up' | 'down';
    }

    post = {
      ...postData,
      author: authorData as Profile,
      user_vote: userVote,
      comment_count: 0,
    } as PostWithScore;

    comments = await postsStore.fetchComments(postId, auth.user?.id);
    loading = false;
  }

  $effect(() => {
    if (auth.initialized) loadThread();
  });

  function goBack() { window.location.href = '/'; }

  function votePost(dir: 'up' | 'down') {
    if (!post) return;
    postsStore.votePost(post.id, dir);
    post = postsStore.postMap.get(post.id) || post;
  }

  async function voteComment(id: string, dir: 'up' | 'down') {
    await postsStore.voteComment(id, dir);
    comments = await postsStore.fetchComments(data.id, auth.user?.id);
  }

  async function addComment(content: string): Promise<void> {
    if (!auth.profile || !post) return;
    const newComment = await postsStore.addComment(post.id, content, auth.profile);
    comments = [...comments, newComment];
  }

  async function addReply(parentId: string, content: string): Promise<void> {
    if (!auth.profile || !post) return;
    const newComment = await postsStore.addComment(post.id, content, auth.profile, parentId);
    const inserted = postsStore.insertReplyIntoTree(comments, newComment, parentId);
    if (!inserted) comments = [...comments, newComment];
    comments = comments; // trigger reactivity
  }
</script>

<svelte:head>
  <title>Filum - Thread</title>
</svelte:head>

{#if loading}
  <div class="flex items-center justify-center py-20 text-[var(--text3)]">Loading...</div>
{:else if post}
  <ThreadView
    {post}
    {comments}
    userProfile={auth.profile}
    onBack={goBack}
    onVotePost={votePost}
    onVoteComment={voteComment}
    onAddComment={addComment}
    onAddReply={addReply}
  />
{:else}
  <div class="flex items-center justify-center py-20 text-[var(--text3)]">Post not found</div>
{/if}
