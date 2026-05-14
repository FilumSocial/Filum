import { createClient } from '$lib/supabase/client';
import type { PostWithScore, CommentWithScore, Profile, VoteType } from '$lib/types';

const FEED_PAGE_SIZE = 50;

type SortMode = 'chron' | 'top';

interface PostScoreRow {
  id: string; author_id: string; content: string; created_at: string;
  upvotes: number; downvotes: number; score: number;
}
interface CommentScoreRow {
  id: string; post_id: string; author_id: string; parent_id: string | null;
  content: string; created_at: string; upvotes: number; downvotes: number; score: number;
}

function missingProfile(): Profile {
  return { id: '', username: 'unknown', display_name: 'Unknown', avatar_color: '#888', bio: '', created_at: '' };
}

class PostsStore {
  posts = $state<PostWithScore[]>([]);
  postMap = $state<Map<string, PostWithScore>>(new Map());
  loading = $state(false);
  error = $state<string | null>(null);
  hasMore = $state(true);
  #sortMode: SortMode = 'chron';
  #feedGen = 0;
  #voteCooldowns = new Map<string, number>();
  #VOTE_COOLDOWN_MS = 500;

  #isStale(gen: number): boolean {
    return gen !== this.#feedGen;
  }

  async fetchFeed(followingIds: string[], sort: SortMode = 'chron', userId?: string, append = false) {
    this.#sortMode = sort;
    if (!append) {
      this.#feedGen++;
      this.loading = true;
      this.error = null;
    }
    const gen = this.#feedGen;
    const supabase = createClient();

    try {
      let query = supabase.from('post_scores').select('*', { count: 'exact', head: false });
      if (followingIds.length > 0) query = query.in('author_id', followingIds);

      const offset = append ? this.posts.length : 0;
      const { data: postsData, error: postsError } = await query
        .order(sort === 'top' ? 'score' : 'created_at', { ascending: false })
        .range(offset, offset + FEED_PAGE_SIZE - 1) as { data: PostScoreRow[] | null; error: any };

      if (postsError) throw postsError;
      if (!postsData) { this.hasMore = false; return; }

      if (this.#isStale(gen)) return;
      this.hasMore = postsData.length === FEED_PAGE_SIZE;

      const authorIds = [...new Set(postsData.map(p => p.author_id))];

      if (this.#isStale(gen)) return;
      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', authorIds) as { data: Profile[] | null };

      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      if (this.#isStale(gen)) return;
      const userVotes = userId ? await this.fetchUserPostVotes(userId, postsData.map(p => p.id)) : new Map();

      const commentCounts = await this.fetchCommentCounts(postsData.map(p => p.id));

      if (this.#isStale(gen)) return;
      const enriched = postsData.map(p => ({
        ...p,
        author: profileMap.get(p.author_id) || missingProfile(),
        user_vote: userVotes.get(p.id) || null,
        comment_count: commentCounts.get(p.id) || 0,
      }));

      if (append) {
        this.posts = [...this.posts, ...enriched];
        for (const p of enriched) this.postMap.set(p.id, p);
      } else {
        this.posts = enriched;
        this.postMap = new Map(enriched.map(p => [p.id, p]));
      }
    } catch (e) {
      if (!append) this.error = e instanceof Error ? e.message : 'Failed to fetch posts';
    } finally {
      if (!append) this.loading = false;
    }
  }

  private async fetchUserPostVotes(userId: string, postIds: string[]): Promise<Map<string, 'up' | 'down'>> {
    if (postIds.length === 0) return new Map();
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
    const counts = new Map<string, number>();
    for (const pid of postIds) {
      const { count } = await supabase
        .from('comments')
        .select('*', { count: 'exact', head: true })
        .eq('post_id', pid);
      if (count !== null) counts.set(pid, count);
    }
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
    const post = this.postMap.get(postId);
    if (!post) return;

    const cooldownKey = `post:${postId}`;
    const now = Date.now();
    const lastVote = this.#voteCooldowns.get(cooldownKey);
    if (lastVote && now - lastVote < this.#VOTE_COOLDOWN_MS) return;
    this.#voteCooldowns.set(cooldownKey, now);

    const prev = { user_vote: post.user_vote, upvotes: post.upvotes, downvotes: post.downvotes, score: post.score };
    this.#applyPostVoteOptimistic(post, voteType);

    const { error } = await supabase.rpc('vote_post', { p_post_id: postId, p_vote_type: voteType });
    if (error) {
      Object.assign(post, prev);
      throw error;
    }

    if (this.#sortMode === 'top') {
      this.posts = [...this.posts].sort((a, b) => b.score - a.score || b.created_at.localeCompare(a.created_at));
    }
  }

  #applyPostVoteOptimistic(post: PostWithScore, voteType: VoteType) {
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
  }

  async fetchComments(postId: string, userId?: string): Promise<CommentWithScore[]> {
    const supabase = createClient();
    const { data: commentsData, error } = await supabase
      .from('comment_scores')
      .select('*')
      .eq('post_id', postId)
      .order('score', { ascending: false })
      .order('created_at', { ascending: true }) as { data: CommentScoreRow[] | null; error: any };
    if (error) throw error;
    if (!commentsData) return [];

    const authorIds = [...new Set(commentsData.map(c => c.author_id))];
    const { data: profiles } = await supabase.from('profiles').select('*').in('id', authorIds) as { data: Profile[] | null };
    const profileMap = new Map((profiles || []).map(p => [p.id, p]));

    const userVotes = userId ? await this.fetchUserCommentVotes(userId, commentsData.map(c => c.id)) : new Map();

    const enriched: CommentWithScore[] = commentsData.map(c => ({
      ...c, author: profileMap.get(c.author_id) || missingProfile(), user_vote: userVotes.get(c.id) || null, replies: [],
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
    const cooldownKey = `comment:${commentId}`;
    const now = Date.now();
    const lastVote = this.#voteCooldowns.get(cooldownKey);
    if (lastVote && now - lastVote < this.#VOTE_COOLDOWN_MS) return;
    this.#voteCooldowns.set(cooldownKey, now);

    const supabase = createClient();
    const { error } = await supabase.rpc('vote_comment', { p_comment_id: commentId, p_vote_type: voteType });
    if (error) throw error;
  }
}

export const postsStore = new PostsStore();
