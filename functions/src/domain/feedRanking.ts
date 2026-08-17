/**
 * Feed ranking heuristic (§4), extracted for testability.
 *
 * An explicit non-goal for Phase 1 is a real recommendation model. This only
 * has to beat "no ranking at all", which it does for almost nothing — and it
 * is what makes the Buy-Now conversion funnel worth optimising once Phase 2
 * data arrives.
 */
export const HALF_LIFE_HOURS = 48;
export const FOLLOW_BOOST = 1.15;

/** Smoothing constant. See [rankScore]. */
export const VIEW_SMOOTHING = 50;

export interface RankInput {
  likes: number;
  comments: number;
  views: number;
  createdAtMs: number;
  authorIsPopular: boolean;
}

/**
 * score = engagementRate * recencyDecay * followBoost
 *
 * Engagement RATE rather than raw count, or a Reel from launch week with 50k
 * views outranks everything new forever and the feed calcifies.
 *
 * The +50 view smoothing stops a Reel with 1 view and 1 like scoring a perfect
 * 100% engagement rate and dominating the feed — the single most likely way a
 * naive version of this goes wrong.
 *
 * Comments count double: leaving one costs more than tapping a heart, so it is
 * the stronger signal of genuine interest.
 *
 * Recency decays exponentially with a 48-hour half-life — fast enough to keep
 * the feed alive, slow enough that a genuinely good Reel gets more than a day.
 */
export function rankScore(input: RankInput, nowMs: number): number {
  const engagementRate =
    (input.likes + input.comments * 2) /
    Math.max(input.views + VIEW_SMOOTHING, 1);

  const ageHours = Math.max(0, (nowMs - input.createdAtMs) / (1000 * 60 * 60));
  const recencyDecay = Math.pow(0.5, ageHours / HALF_LIFE_HOURS);

  const boost = input.authorIsPopular ? FOLLOW_BOOST : 1;

  return Number((engagementRate * recencyDecay * boost).toFixed(6));
}
