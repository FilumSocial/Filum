export interface Profile {
  id: string;
  username: string;
  display_name: string;
  avatar_color: string;
  bio: string;
  created_at: string;
}

export interface PostRow {
  id: string;
  author_id: string;
  content: string;
  created_at: string;
}

export interface PostWithScore extends PostRow {
  upvotes: number;
  downvotes: number;
  score: number;
  author: Profile;
  user_vote: 'up' | 'down' | null;
  comment_count: number;
}

export interface CommentRow {
  id: string;
  post_id: string;
  author_id: string;
  parent_id: string | null;
  content: string;
  created_at: string;
}

export interface CommentWithScore extends CommentRow {
  upvotes: number;
  downvotes: number;
  score: number;
  author: Profile;
  user_vote: 'up' | 'down' | null;
  replies: CommentWithScore[];
}

export type VoteType = 'up' | 'down';
export type SortMode = 'chron' | 'top';
export type FeedMode = 'following' | 'rec';
