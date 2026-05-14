<script lang="ts">
  import { goto } from '$app/navigation';
  import ThreadView from '$lib/components/ThreadView.svelte';
  import { auth } from '$lib/stores/auth.svelte';
  import { postsStore } from '$lib/stores/posts.svelte';
  import { toast } from '$lib/stores/toast.svelte';
  import { createClient } from '$lib/supabase/client';
  import type { PostWithScore, CommentWithScore, Profile, VoteType } from '$lib/types';

  let { params } = $props();

  let post = $state<PostWithScore | null>(null);
  let comments = $state<CommentWithScore[]>([]);
  let loading = $state(true);
  let voteChannel: ReturnType<ReturnType<typeof createClient>['channel']> | null = null;

  async function loadThread() {
    if (!auth.initialized) return;
    const supabase = createClient();
    const postId = params.id;

    const { data: postData } = await supabase
      .from('posts')
      .select('*')
      .eq('id', postId)
      .maybeSingle();
    if (!postData) { loading = false; return; }

    const [authorRes, votesRes, commentCountRes] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', postData.author_id).single() as Promise<{ data: Profile; error: any }>,
      supabase.from('votes').select('vote_type').eq('post_id', postId) as Promise<{ data: { vote_type: string }[] | null; error: any }>,
      supabase.from('comments').select('id', { count: 'exact', head: true }).eq('post_id', postId),
    ]);

    const upvotes = votesRes.data?.filter(v => v.vote_type === 'up').length || 0;
    const downvotes = votesRes.data?.filter(v => v.vote_type === 'down').length || 0;

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
      upvotes, downvotes,
      score: upvotes - downvotes,
      author: authorRes.data as Profile,
      user_vote: userVote,
      comment_count: commentCountRes.count || 0,
    } as PostWithScore;

    comments = await postsStore.fetchComments(postId, auth.user?.id);
    loading = false;
  }

  $effect(() => {
    if (auth.initialized) loadThread();
  });

  $effect(() => {
    if (!post || !auth.initialized) return;
    if (voteChannel) return;
    const supabase = createClient();
    voteChannel = supabase.channel(`votes:${post.id}`)
      .on('postgres_changes',
        { event: '*', schema: 'public', table: 'votes', filter: `post_id=eq.${post.id}` },
        (payload: any) => {
          if (!post) return;
          const uid = payload.new?.user_id || payload.old?.user_id;
          if (uid === auth.user?.id) return;
          if (payload.eventType === 'INSERT') {
            if (payload.new.vote_type === 'up') post.upvotes++;
            else post.downvotes++;
          } else if (payload.eventType === 'DELETE') {
            if (payload.old.vote_type === 'up') post.upvotes = Math.max(0, post.upvotes - 1);
            else post.downvotes = Math.max(0, post.downvotes - 1);
          } else if (payload.eventType === 'UPDATE') {
            if (payload.old.vote_type === 'up') post.upvotes = Math.max(0, post.upvotes - 1);
            else post.downvotes = Math.max(0, post.downvotes - 1);
            if (payload.new.vote_type === 'up') post.upvotes++;
            else post.downvotes++;
          }
          post.score = post.upvotes - post.downvotes;
        })
      .subscribe();
    return () => {
      if (voteChannel) supabase.removeChannel(voteChannel);
      voteChannel = null;
    };
  });

  function goBack() { goto('/'); }

  async function votePost(dir: 'up' | 'down') {
    if (!post) return;
    const prev = post.user_vote;
    if (prev === dir) {
      post.score += prev === 'up' ? -1 : 1;
      post.upvotes += prev === 'up' ? -1 : 0;
      post.downvotes += prev === 'down' ? -1 : 0;
      post.user_vote = null;
    } else {
      if (prev === 'up') { post.upvotes--; post.score--; }
      if (prev === 'down') { post.downvotes--; post.score++; }
      post.score += dir === 'up' ? 1 : -1;
      post.upvotes += dir === 'up' ? 1 : 0;
      post.downvotes += dir === 'down' ? 1 : 0;
      post.user_vote = dir;
    }
    const { error } = await createClient().rpc('vote_post', { p_post_id: post.id, p_vote_type: dir });
    if (error) loadThread();
  }

  function applyCommentVote(nodes: CommentWithScore[], id: string, dir: VoteType) {
    for (const n of nodes) {
      if (n.id === id) {
        const prev = n.user_vote;
        if (prev === dir) {
          n.score += prev === 'up' ? -1 : 1;
          n.upvotes += prev === 'up' ? -1 : 0;
          n.downvotes += prev === 'down' ? -1 : 0;
          n.user_vote = null;
        } else {
          if (prev === 'up') { n.upvotes--; n.score--; }
          if (prev === 'down') { n.downvotes--; n.score++; }
          n.score += dir === 'up' ? 1 : -1;
          n.upvotes += dir === 'up' ? 1 : 0;
          n.downvotes += dir === 'down' ? 1 : 0;
          n.user_vote = dir;
        }
        return;
      }
      if (n.replies.length) applyCommentVote(n.replies, id, dir);
    }
  }

  function sortCommentTree(nodes: CommentWithScore[]) {
    nodes.sort((a, b) => b.score - a.score || a.created_at.localeCompare(b.created_at));
    for (const n of nodes) {
      if (n.replies.length) sortCommentTree(n.replies);
    }
  }

  async function voteComment(id: string, dir: 'up' | 'down') {
    applyCommentVote(comments, id, dir);
    sortCommentTree(comments);
    comments = comments;
    try {
      await postsStore.voteComment(id, dir);
    } catch {
      comments = await postsStore.fetchComments(params.id, auth.user?.id);
    }
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
    comments = comments;
  }

  async function deleteComment(id: string) {
    await postsStore.deleteComment(id);
    postsStore.removeCommentFromTree(comments, id);
    comments = comments;
    if (post) post.comment_count = Math.max(0, post.comment_count - 1);
    toast.success('Comment deleted');
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
    currentUserId={auth.user?.id}
    onBack={goBack}
    onVotePost={votePost}
    onVoteComment={voteComment}
    onAddComment={addComment}
    onAddReply={addReply}
    onDeleteComment={deleteComment}
  />
{:else}
  <div class="flex items-center justify-center py-20 text-[var(--text3)]">Post not found</div>
{/if}
