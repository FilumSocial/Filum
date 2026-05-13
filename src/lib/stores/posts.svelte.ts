import { createClient } from '$lib/supabase/client';
import type { PostWithScore, CommentWithScore, Profile, VoteType, CommentRow } from '$lib/types';

class PostsStore {
  posts = $state<PostWithScore[]>([]);
  postMap = $state<Map<string, PostWithScore>>(new Map());
  loading = $state(false);
  error = $state<string | null>(null);

  async fetchFeed(followingIds: string[], sort: 'chron' | 'top' = 'chron', userId?: string) {
    this.loading = true;
    this.error = null;
    const supabase = createClient();

    try {
      let query = supabase
        .from('post_scores')
        .select('*');

      if (followingIds.length > 0) {
        query = query.in('author_id', followingIds);
      }

      const { data: postsData, error: postsError } = await query
        .order(sort === 'top' ? 'score' : 'created_at', { ascending: sort !== 'top' });

      if (postsError) throw postsError;

      const authorIds = [...new Set(postsData.map(p => p.author_id))];

      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', authorIds);

      const profileMap = new Map((profiles || []).map(p => [p.id, p]));

      let userVotes: Map<string, 'up' | 'down'> = new Map();
      if (userId) {
        const { data: votes } = await supabase
          .from('votes')
          .select('post_id, vote_type')
          .eq('user_id', userId)
          .in('post_id', postsData.map(p => p.id))
          .not('post_id', 'is', null);

        if (votes) {
          for (const v of votes) {
            if (v.post_id) userVotes.set(v.post_id, v.vote_type as 'up' | 'down');
          }
        }
      }

      const commentCounts = await this.fetchCommentCounts(postsData.map(p => p.id));

      const enriched: PostWithScore[] = postsData.map(p => ({
        ...p,
        author: profileMap.get(p.author_id) as Profile || {} as Profile,
        user_vote: userVotes.get(p.id) || null,
        comment_count: commentCounts.get(p.id) || 0,
      }));

      this.posts = enriched;
      const map = new Map<string, PostWithScore>();
      enriched.forEach(p => map.set(p.id, p));
      this.postMap = map;
    } catch (e) {
      this.error = e instanceof Error ? e.message : 'Failed to fetch posts';
    } finally {
      this.loading = false;
    }
  }

  async fetchCommentCounts(postIds: string[]): Promise<Map<string, number>> {
    if (postIds.length === 0) return new Map();
    const supabase = createClient();
    const { data } = await supabase
      .from('comments')
      .select('post_id')
      .in('post_id', postIds);

    const counts = new Map<string, number>();
    if (data) {
      for (const c of data) {
        counts.set(c.post_id, (counts.get(c.post_id) || 0) + 1);
      }
    }
    return counts;
  }

  async createPost(content: string, authorProfile: Profile) {
    const supabase = createClient();
    const { data, error } = await supabase
      .from('posts')
      .insert({ author_id: authorProfile.id, content })
      .select()
      .single();

    if (error) throw error;

    const newPost: PostWithScore = {
      ...data,
      upvotes: 0,
      downvotes: 0,
      score: 0,
      author: authorProfile,
      user_vote: null,
      comment_count: 0,
    };

    this.posts = [newPost, ...this.posts];
    this.postMap.set(newPost.id, newPost);
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
      if (post.user_vote === 'down') { post.downvotes++; post.score++; }
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
      .order('created_at', { ascending: true });

    if (error) throw error;

    const authorIds = [...new Set(commentsData.map(c => c.author_id))];
    const { data: profiles } = await supabase
      .from('profiles')
      .select('*')
      .in('id', authorIds);

    const profileMap = new Map((profiles || []).map(p => [p.id, p]));

    let userVotes: Map<string, 'up' | 'down'> = new Map();
    if (userId) {
      const { data: votes } = await supabase
        .from('votes')
        .select('comment_id, vote_type')
        .eq('user_id', userId)
        .in('comment_id', commentsData.map(c => c.id))
        .not('comment_id', 'is', null);

      if (votes) {
        for (const v of votes) {
          if (v.comment_id) userVotes.set(v.comment_id, v.vote_type as 'up' | 'down');
        }
      }
    }

    const enriched: CommentWithScore[] = commentsData.map(c => ({
      ...c,
      author: profileMap.get(c.author_id) as Profile || {} as Profile,
      user_vote: userVotes.get(c.id) || null,
      replies: [],
    }));

    const map = new Map<string, CommentWithScore>();
    const roots: CommentWithScore[] = [];

    for (const c of enriched) {
      map.set(c.id, c);
      if (!c.parent_id) {
        roots.push(c);
      } else {
        const parent = map.get(c.parent_id);
        if (parent) parent.replies.push(c);
        else roots.push(c);
      }
    }

    return roots;
  }

  async addComment(postId: string, content: string, authorProfile: Profile, parentId?: string): Promise<CommentWithScore | null> {
    const supabase = createClient();
    const commentData: Partial<CommentRow> = {
      post_id: postId,
      author_id: authorProfile.id,
      content,
    };
    if (parentId) commentData.parent_id = parentId;

    const { data, error } = await supabase
      .from('comments')
      .insert(commentData)
      .select()
      .single();

    if (error) throw error;

    // Update comment count
    const post = this.postMap.get(postId);
    if (post) post.comment_count++;

    return {
      ...data,
      upvotes: 0,
      downvotes: 0,
      score: 0,
      author: authorProfile,
      user_vote: null,
      replies: [],
    };
  }

  async voteComment(commentId: string, voteType: VoteType) {
    const supabase = createClient();
    await supabase.rpc('vote_comment', { p_comment_id: commentId, p_vote_type: voteType });
  }

  subscribeToVotes(postId: string, callback: () => void) {
    const supabase = createClient();
    const channel = supabase
      .channel(`votes:${postId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'votes',
          filter: `post_id=eq.${postId}`,
        },
        () => callback()
      )
      .subscribe();

    return () => supabase.removeChannel(channel);
  }

  subscribeToNewPosts(callback: () => void) {
    const supabase = createClient();
    const channel = supabase
      .channel('new-posts')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'posts',
        },
        () => callback()
      )
      .subscribe();

    return () => supabase.removeChannel(channel);
  }
}

export const postsStore = new PostsStore();
