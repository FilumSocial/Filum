import { createClient } from '$lib/supabase/client';
import type { PostWithScore, CommentWithScore, Profile, VoteType, CommentRow } from '$lib/types';

type SortMode = 'chron' | 'top';

class PostsStore {
  posts = $state<PostWithScore[]>([]);
  postMap = $state<Map<string, PostWithScore>>(new Map());
  loading = $state(false);
  error = $state<string | null>(null);
  #sortMode: SortMode = 'chron';

  async fetchFeed(followingIds: string[], sort: SortMode = 'chron', userId?: string) {
    this.#sortMode = sort;
    this.loading = true;
    this.error = null;
    const supabase = createClient();

    try {
      let query = supabase.from('post_scores').select('*');
      if (followingIds.length > 0) query = query.in('author_id', followingIds);

      const { data: postsData, error: postsError } = await query
        .order(sort === 'top' ? 'score' : 'created_at', { ascending: false });

      if (postsError) throw postsError;

      const authorIds = [...new Set(postsData.map(p => p.author_id))];

      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', authorIds);

      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      const userVotes = userId ? await this.fetchUserPostVotes(userId, postsData.map(p => p.id)) : new Map();

      const commentCounts = await this.fetchCommentCounts(postsData.map(p => p.id));

      this.posts = postsData.map(p => ({
        ...p,
        author: (profileMap.get(p.author_id) || {}) as Profile,
        user_vote: userVotes.get(p.id) || null,
        comment_count: commentCounts.get(p.id) || 0,
      }));
      this.postMap = new Map(this.posts.map(p => [p.id, p]));
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Failed to fetch posts';
    } finally {
      this.loading = false;
    }
  }

  private async fetchUserPostVotes(userId: string, postIds: string[]): Promise<Map<string, 'up' | 'down'>> {
    const supabase = createClient();
    const { data } = await supabase
      .from('votes')
      .select('post_id, vote_type')
      .eq('user_id', userId)
      .in('post_id', postIds)
      .not('post_id', 'is', null);

    const map = new Map<string, 'up' | 'down'>();
    if (data) for (const v of data) { if (v.post_id) map.set(v.post_id, v.vote_type as 'up' | 'down'); }
    return map;
  }

  private async fetchCommentCounts(postIds: string[]): Promise<Map<string, number>> {
    if (postIds.length === 0) return new Map();
    const supabase = createClient();
    const { data } = await supabase.from('comments').select('post_id').in('post_id', postIds);
    const counts = new Map<string, number>();
    if (data) for (const c of data) counts.set(c.post_id, (counts.get(c.post_id) || 0) + 1);
    return counts;
  }

  async createPost(content: string, authorProfile: Profile): Promise<PostWithScore> {
    const supabase = createClient();
    const { data, error } = await supabase
      .from('posts')
      .insert({ author_id: authorProfile.id, content })
      .select()
      .single();
    if (error) throw error;

    const newPost: PostWithScore = { ...data, upvotes: 0, downvotes: 0, score: 0, author: authorProfile, user_vote: null, comment_count: 0 };
    this.posts = [newPost, ...this.posts];
    this.postMap.set(newPost.id, newPost);
    return newPost;
  }

  async votePost(postId: string, voteType: VoteType) {
    const supabase = createClient();
    await supabase.rpc('vote_post', { p_post_id: postId, p_vote_type: voteType });

    const post = this.postMap.get(postId);
    if (!post) return;

    if (post.user_vote === voteType) {
      post.score += post.user_vote === 'up' ? -1 : 1;
      post.upvotes += post.user_vote === 'up' ? -1 : 0;
      post.downvotes += post.user_vote === 'down' ? -1 : 0;
      post.user_vote = null;
    } else {
      if (post.user_vote === 'up') { post.upvotes--; post.score--; }
      if (post.user_vote === 'down') { post.downvotes--; post.score++; }
      post.score += voteType === 'up' ? 1 : -1;
      post.upvotes += voteType === 'up' ? 1 : 0;
      post.downvotes += voteType === 'down' ? 1 : 0;
      post.user_vote = voteType;
    }

    if (this.#sortMode === 'top') {
      this.posts = [...this.posts].sort((a, b) => b.score - a.score || b.created_at.localeCompare(a.created_at));
    }
  }

  async fetchComments(postId: string, userId?: string): Promise<CommentWithScore[]> {
    const supabase = createClient();
    const { data: commentsData, error } = await supabase
      .from('comment_scores')
      .select('*')
      .eq('post_id', postId)
      .order('score', { ascending: false })
      .order('created_at', { ascending: true });
    if (error) throw error;

    const authorIds = [...new Set(commentsData.map(c => c.author_id))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('id', authorIds);
    const profileMap = new Map((profiles || []).map(p => [p.id, p]));

    const userVotes = userId ? await this.fetchUserCommentVotes(userId, commentsData.map(c => c.id)) : new Map();

    const enriched: CommentWithScore[] = commentsData.map(c => ({
      ...c, author: (profileMap.get(c.author_id) || {}) as Profile, user_vote: userVotes.get(c.id) || null, replies: [],
    }));

    const map = new Map<string, CommentWithScore>();
    for (const c of enriched) map.set(c.id, c);

    const roots: CommentWithScore[] = [];
    for (const c of enriched) {
      if (c.parent_id) {
        const parent = map.get(c.parent_id);
        if (parent) parent.replies.push(c);
        else roots.push(c);
      } else {
        roots.push(c);
      }
    }
    return roots;
  }

  private async fetchUserCommentVotes(userId: string, commentIds: string[]): Promise<Map<string, 'up' | 'down'>> {
    if (commentIds.length === 0) return new Map();
    const supabase = createClient();
    const { data } = await supabase
      .from('votes')
      .select('comment_id, vote_type')
      .eq('user_id', userId)
      .in('comment_id', commentIds)
      .not('comment_id', 'is', null);
    const map = new Map<string, 'up' | 'down'>();
    if (data) for (const v of data) { if (v.comment_id) map.set(v.comment_id, v.vote_type as 'up' | 'down'); }
    return map;
  }

  async addComment(postId: string, content: string, authorProfile: Profile, parentId?: string): Promise<CommentWithScore> {
    const supabase = createClient();
    const { data, error } = await supabase
      .from('comments')
      .insert({ post_id: postId, author_id: authorProfile.id, content, ...(parentId ? { parent_id: parentId } : {}) })
      .select()
      .single();
    if (error) throw error;

    const post = this.postMap.get(postId);
    if (post) post.comment_count++;

    return { ...data, upvotes: 0, downvotes: 0, score: 0, author: authorProfile, user_vote: null, replies: [] };
  }

  /** Insert a new comment into an existing comment tree by parent id */
  insertReplyIntoTree(comments: CommentWithScore[], newComment: CommentWithScore, parentId: string): boolean {
    function findParent(nodes: CommentWithScore[]): boolean {
      for (const n of nodes) {
        if (n.id === parentId) { n.replies = [...n.replies, newComment]; return true; }
        if (n.replies.length && findParent(n.replies)) return true;
      }
      return false;
    }
    return findParent(comments);
  }

  async voteComment(commentId: string, voteType: VoteType) {
    const supabase = createClient();
    await supabase.rpc('vote_comment', { p_comment_id: commentId, p_vote_type: voteType });
  }
}

export const postsStore = new PostsStore();
