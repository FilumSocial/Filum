# Filum Project Analysis

> **Last updated:** 2026-05-14 — See [Changelog](#changelog) at bottom for fixes applied.

## Architecture Overview

- **Framework:** Svelte 5 (runes) + SvelteKit 2
- **Database:** PostgreSQL 17 via Supabase
- **Auth:** Supabase Auth (GoTrue), email/password only
- **Real-time:** Supabase Realtime enabled on DB but **NOT used in frontend**
- **Deployment:** Vercel (adapter-vercel, Node.js 22.x)
- **Styling:** Tailwind CSS v4
- **Data flow:** All operations go directly from browser to Supabase via client SDK — **no custom server-side API routes**

### Key Files

| File | Purpose |
|------|---------|
| `src/lib/supabase/schema.sql` | Full DB schema (tables, RLS, views, functions, triggers) |
| `src/lib/stores/posts.svelte.ts` | Posts store (feed, voting, comments, optimistic updates) |
| `src/lib/stores/auth.svelte.ts` | Auth store (sign in/up/out, session, profile loading) |
| `src/lib/supabase/client.ts` | Browser Supabase client (singleton, proxy fallback) |
| `src/lib/components/VoteRow.svelte` | Upvote/downvote buttons with score display |
| `src/lib/components/CommentNode.svelte` | Recursive threaded comment component |
| `src/lib/components/ThreadView.svelte` | Full post + comments thread view |
| `src/lib/components/FeedView.svelte` | Main feed (Following/Recommended tabs, New/Top sort) |
| `src/lib/components/PostCard.svelte` | Individual post card in feed |
| `src/lib/components/ComposeBox.svelte` | Textarea for composing posts/comments |
| `src/lib/types.ts` | TypeScript interfaces |
| `src/routes/post/[id]/+page.svelte` | Thread page (post + comments) |
| `src/routes/+page.svelte` | Home page |
| `src/routes/explore/+page.svelte` | Explore page |
| `src/routes/profile/[id]/+page.svelte` | Profile page |

---

## Bugs

### ~~1. Race condition in vote RPC functions~~ ✅ FIXED
**Files:** `schema.sql:196-218`, `supabase/migrations/20260513000001_initial_schema.sql:112-141`, `supabase/seed.sql:211-241`

**Fix:** Replaced read-then-write with atomic CTE upsert:
```sql
WITH toggled_off AS (
  DELETE FROM votes WHERE user_id = auth.uid() AND post_id = p_post_id AND vote_type = p_vote_type
  RETURNING 1
)
INSERT INTO votes (user_id, post_id, vote_type)
SELECT auth.uid(), p_post_id, p_vote_type
WHERE NOT EXISTS (SELECT 1 FROM toggled_off)
ON CONFLICT (user_id, post_id) DO UPDATE SET vote_type = EXCLUDED.vote_type;
```
The DELETE + INSERT/ON CONFLICT is a single atomic statement — no race window. Also fixed `handle_new_user` `search_path` in the migration file.

### ~~2. Optimistic vote error recovery (partial)~~ ✅ FIXED
**File:** `posts.svelte.ts`

**Fix:** `votePost` now saves previous state before optimistic update, wraps RPC in try/catch, and reverts on failure.

Still outstanding: no real-time sync for other users' votes. Local scores can still diverge from server if another user votes concurrently.

### ~~3. Comment voting re-fetches everything, destroying UI state~~ ✅ FIXED
**File:** `post/[id]/+page.svelte:72-75`

**Fix:** Replaced full re-fetch with local optimistic tree mutation (`applyCommentVote`). On RPC failure, falls back to re-fetch. Collapse states are preserved; no flicker.

### ~~4. Missing error handling in `votePost`~~ ✅ FIXED
**File:** `posts.svelte.ts:93-117`

**Fix:** Added try/catch around RPC call. On failure, reverts optimistic update so UI stays in sync with DB.

### ~~5. `voteComment` in store — error propagates to caller~~ ✅ FIXED
**File:** `posts.svelte.ts:196-199`

**Fix:** Error from RPC is thrown to caller. Thread page catches it and re-fetches on failure (see bug #3 fix).

### ~~6. `author` cast as empty object~~ ✅ FIXED
**Files:** `posts.svelte.ts`

**Fix:** Replaced `({} as Profile)` with `missingProfile()` — a proper fallback object with safe defaults.

### ~~7. Comment count query~~ ✅ FIXED
**File:** `posts.svelte.ts`

**Fix:** Changed from fetching all rows to per-post `{ count: 'exact', head: true }` queries. Still N+1 but no longer transfers full row data.

### ~~8. Feed data race on re-fetch~~ ✅ FIXED
**File:** `posts.svelte.ts`

**Fix:** Added `#feedGen` generation counter. Each non-append `fetchFeed` call increments the generation. Stale checks (`#isStale()`) after each DB query prevent out-of-order responses from overwriting newer data.

### ~~9. No loading state on vote buttons / double-click hazard~~ ✅ FIXED
**File:** `VoteRow.svelte`

**Fix:** Added local `voting` state with 400ms cooldown timer. Buttons are visually dimmed and non-functional during cooldown. Combined with DB-level atomic upsert and client-side rate limiter, rapid clicking is now safe on all layers.

---

## Security Issues

### 1. `SECURITY DEFINER` on vote functions
**File:** `schema.sql:199, 224`

Both `vote_post` and `vote_comment` run as `SECURITY DEFINER`. This means they bypass RLS on the `votes` table. This is **intentional** (the functions need to INSERT/UPDATE/DELETE on behalf of users), but it creates a risk: if there's a bug in the function logic, RLS won't save you. The functions correctly use `auth.uid()` internally, so they can only act for the authenticated user.

### 2. No email verification
**File:** `supabase/config.toml:221` (`enable_confirmations = false`)

Anyone can sign up with any email address — no confirmation required. This enables spam/bot accounts trivially.

### 3. No rate limiting on any operation
- Voting has no rate limit — a bot can send 1000 votes/second
- Posting has no rate limit
- Commenting has no rate limit
- The only rate limits are at the Supabase Auth level (sign-in, token refresh)

### 4. Supabase anon key exposed to client
**File:** `client.ts:5`

Normal for Supabase architecture, but the entire security model depends on RLS being correct. If any RLS policy is too permissive, the anon key grants access.

### 5. RLS on follows allows any authenticated user to follow anyone
**File:** `schema.sql:145-147`

The INSERT policy for follows only checks `auth.role() = 'authenticated'` — no check on whether the follow action is legitimate.

### 6. No input sanitization or validation server-side
**Files:** `schema.sql:32, 63`

Content length is checked via CHECK constraints (500 chars for posts, 2000 for comments), but there's no additional server-side validation (profanity filter, spam detection, content moderation).

---

## Robustness Issues

### 1. Entire app breaks if Supabase goes down
There is no fallback, no offline mode, no local cache. If the Supabase API is unreachable, the app shows error toasts or silently fails.

### ~~2. No request deduplication~~ ✅ FIXED
Multiple rapid clicks on vote buttons are now throttled via:
- VoteRow local 400ms cooldown (prevents UI-level double-clicks)
- Store-level `#voteCooldowns` Map (500ms per target)
- DB-level atomic upsert (last write wins, no constraint violation)

The `submitting` guard in `ComposeBox.svelte` still covers posts/comments.

### 3. Single Supabase client singleton
**File:** `client.ts:7-39`

All concurrent requests share the same client instance. If one request causes an auth token refresh, other in-flight requests might fail.

### 4. `$effect` dependencies not cleaned up on navigation
**File:** `+page.svelte:26-33`

The `$effect` that watches `feedMode` and `sortMode` continues to run even after navigating away.

---

## Scalability Issues (hundreds/thousands of users)

### ~~CRITICAL: No pagination anywhere~~ ✅ FIXED
**Files:** `posts.svelte.ts:23-24`, `posts.svelte.ts:119-126`

**Fix:** Added `.range()` with `FEED_PAGE_SIZE = 50`, `hasMore` tracking, and `append` mode. Both home and explore pages show a "Show more" button. Feed no longer fetches unbounded result sets.

Still outstanding: comment tree for threads with 1000+ comments has no pagination.

### Score views perform full-table scans under load
**Files:** `schema.sql:158-184`

`post_scores` and `comment_scores` are views that aggregate over `votes` using `COUNT + FILTER`. As votes grow into the millions, these queries become expensive. The view is re-aggregated on every SELECT — it's not materialized.

### Comment count query (optimized, still N+1)
**File:** `posts.svelte.ts`

Changed to `{ count: 'exact', head: true }` per post. No longer transfers full row data, but still N+1 queries. Better approach: store `comment_count` as a denormalized column on `posts` updated via triggers.

### No caching anywhere
Every page load hits the database directly. No:
- React Query / SWR-style client cache
- Service worker cache
- CDN cache
- Server-side response cache

### Infinite scroll / load-more
**Fix:** IntersectionObserver sentinel triggers automatic page fetch when user scrolls near bottom. Pages load 50 posts at a time. No manual button click needed.

### Good: Index coverage
Indexes on `posts(author_id)`, `posts(created_at DESC)`, `comments(post_id)`, `comments(parent_id)`, `votes(post_id)`, `votes(comment_id)`, `votes(user_id)`, `follows(follower_id)`, `follows(following_id)` are all appropriate.

---

## Concurrent Behavior

### What happens if many people vote at the same time

| Scenario | Outcome |
|----------|---------|
| **100 users upvote same post simultaneously** | Each INSERT is atomic. PostgreSQL handles this fine. 100 rows inserted into `votes`, the `post_scores` view correctly counts them. No issue. |
| **Same user clicks upvote twice rapidly** | ✅ **FIXED** — Atomic CTE upsert means the DELETE + INSERT/ON CONFLICT is a single statement. No race window. Both calls are serialized by PostgreSQL. |
| **Same user toggles upvote ↔ downvote rapidly** | ✅ **FIXED** — The CTE approach handles all three cases (new, toggle-off, switch) atomically in a single statement. No read-then-write race. |
| **100 users vote on comments simultaneously** | ✅ **PARTIALLY FIXED** — No more re-fetch on vote (optimistic local update). But no real-time sync, so users still see stale scores from other users' votes. |

### Comment reordering

Comments are sorted by `score DESC, created_at ASC` (`posts.svelte.ts`):
- Every vote changes the score, which changes the sort position
- Comments don't visibly "fly around" in real-time (no real-time channel)
- ✅ **FIXED:** No more full re-fetch on vote. Local optimistic update preserves collapse state. No flicker.

### With many concurrent voters on the same thread
1. ✅ **FIXED:** User votes → local optimistic update → no re-fetch → collapse state preserved
2. Still outstanding: users never see other users' votes or new comments without manual refresh
3. ✅ **FIXED:** Each vote triggers exactly 1 RPC call (no cascade of re-fetches)

---

## Summary by Severity

| Category | Issue | Severity |
|----------|-------|----------|
| **Bug** | Race condition in vote RPC (read-then-write) | High |
| **Bug** | Optimistic vote update never re-synced with server | Medium |
| **Bug** | Comment vote re-fetch destroys all collapse states | High |
| **Bug** | `votePost` silently swallows errors, UI diverges from DB | High |
| **Bug** | `voteComment` doesn't optimistically update local state | Medium |
| **Bug** | Missing profile → empty object cast as `Profile` | Medium |
| **Bug** | Comment count fetches all rows instead of counting in DB | Medium |
| **Bug** | Feed data race on re-fetch | Low |
| **Sec** | `SECURITY DEFINER` functions bypass RLS | Low (by design) |
| **Sec** | No email verification | Medium |
| **Sec** | No rate limiting on any operation | High |
| **Robust** | No offline/fallback | Medium |
| **Robust** | No request deduplication | Medium | ✅ |
| **Robust** | No retry logic | Low | ❌ |
| **Scale** | **No pagination** (fetches all posts/comments) | **Critical** |
| **Scale** | Score views aggregate full votes table on every query | High |
| **Scale** | Comment count is O(n) JS aggregation | High |
| **Scale** | No caching anywhere | High |
| **Scale** | No infinite scroll | Medium |
| **Concur** | Two rapid clicks from same user = unique constraint violation | High | ✅ |
| **Concur** | Comment re-fetch creates thundering herd on vote | High | ✅ |
| **Concur** | Local data always stale, no real-time sync | Medium | ❌ |
| **UX** | Comment tree flashes/collapses on every vote | High | ✅ |

---

## Changelog

### 2026-05-14 — First pass of fixes

| # | Issue | Files Changed | Status |
|---|-------|---------------|--------|
| 1 | Vote RPC race condition | `schema.sql`, `migration`, `seed.sql` | ✅ Fixed — atomic CTE upsert |
| 2 | Optimistic vote error recovery | `posts.svelte.ts` | ✅ Fixed — revert on failure |
| 3 | Comment vote re-fetch destroys UI state | `post/[id]/+page.svelte`, `posts.svelte.ts` | ✅ Fixed — local tree mutation |
| 4 | Missing error handling in votePost | `posts.svelte.ts` | ✅ Fixed — try/catch + revert |
| 5 | voteComment no optimistic update | `posts.svelte.ts`, `post/[id]/+page.svelte` | ✅ Fixed — local mutation |
| 6 | Empty profile cast | `posts.svelte.ts` | ✅ Fixed — `missingProfile()` fallback |
| 7 | Comment count fetches all rows | `posts.svelte.ts` | ✅ Fixed — `head: true` per-post |
| 8 | No pagination | `posts.svelte.ts`, `+page.svelte`, `explore/+page.svelte`, `FeedView.svelte` | ✅ Fixed — `range()` + "Show more" button |
| 9 | handle_new_user search_path in migration | `migration` | ✅ Fixed — `search_path = ''`→`'public'` |
| 10 | VoteRow double-click spam | `VoteRow.svelte` | ✅ Fixed — 400ms local cooldown + disabled state |
| 11 | Feed data race on re-fetch | `posts.svelte.ts` | ✅ Fixed — `#feedGen` generation counter with stale checks |
| 12 | Vote rate limiting | `posts.svelte.ts` | ✅ Fixed — 500ms cooldown per target via `#voteCooldowns` |
| 13 | Follow/unfollow error handling | `profile/[id]/+page.svelte` | ✅ Fixed — optimistic toggle + revert on failure |
| 14 | Infinite scroll | `FeedView.svelte`, `explore/+page.svelte` | ✅ Fixed — IntersectionObserver sentinel replaces "Show more" button |
| 15 | User suggestions | `+layout.svelte`, `RightPanel.svelte` | ✅ Fixed — fetches 3 random profiles not followed, with follow button |
| 16 | Character count | `ComposeBox.svelte` | ✅ Added — remaining chars display, near/over limit colors, maxlength enforcement |
| 17 | Post delete UI | `PostCard.svelte`, `FeedView.svelte`, `+page.svelte`, `explore/+page.svelte`, `profile/[id]/+page.svelte` | ✅ Added — delete button on own posts with confirmation |
| 18 | Comment delete UI | `CommentNode.svelte`, `ThreadView.svelte`, `post/[id]/+page.svelte` | ✅ Added — delete button on own comments |
| 19 | Real-time vote sync | `post/[id]/+page.svelte` | ✅ Added — Supabase Realtime channel for live post score updates from other users |
| 20 | Edit own posts | `PostCard.svelte`, `posts.svelte.ts`, `FeedView.svelte`, pages | ✅ Added — inline edit button + textarea with save/cancel |
| 21 | Profile stats | `profile/[id]/+page.svelte` | ✅ Added — follower count, following count, post count |
| 22 | Clickable hashtags | `PostCard.svelte`, `utils.ts`, `explore/+page.svelte` | ✅ Added — #tag and @mention parsing, ?tag= search filter |
| 23 | Notifications page | `notifications/+page.svelte`, `+layout.svelte` | ✅ Added — follow/vote/reply activity timeline |
