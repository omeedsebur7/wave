import { HALF_LIFE_HOURS, rankScore } from "../src/domain/feedRanking";

const NOW = Date.UTC(2026, 7, 4, 12);
const hoursAgo = (h: number) => NOW - h * 60 * 60 * 1000;

const base = {
  likes: 100,
  comments: 10,
  views: 1000,
  createdAtMs: hoursAgo(1),
  authorIsPopular: false,
};

describe("Feed ranking heuristic", () => {
  it("ranks a fresher Reel above an identical older one", () => {
    const fresh = rankScore({ ...base, createdAtMs: hoursAgo(1) }, NOW);
    const old = rankScore({ ...base, createdAtMs: hoursAgo(72) }, NOW);
    expect(fresh).toBeGreaterThan(old);
  });

  it("halves the score every 48 hours", () => {
    const now = rankScore({ ...base, createdAtMs: NOW }, NOW);
    const later = rankScore(
      { ...base, createdAtMs: hoursAgo(HALF_LIFE_HOURS) },
      NOW
    );
    expect(later / now).toBeCloseTo(0.5, 2);
  });

  it("does NOT let one lucky view dominate the feed", () => {
    // The single most likely way a naive version of this goes wrong: a Reel
    // with 1 view and 1 like scoring a perfect 100% engagement rate.
    const lucky = rankScore(
      { likes: 1, comments: 0, views: 1, createdAtMs: NOW, authorIsPopular: false },
      NOW
    );
    const genuine = rankScore(
      { likes: 500, comments: 50, views: 2000, createdAtMs: NOW, authorIsPopular: false },
      NOW
    );
    expect(genuine).toBeGreaterThan(lucky);
  });

  it("uses a rate, so an old viral Reel cannot calcify the feed", () => {
    const oldViral = rankScore(
      {
        likes: 50000,
        comments: 5000,
        views: 1000000,
        createdAtMs: hoursAgo(24 * 30),
        authorIsPopular: true,
      },
      NOW
    );
    const newModest = rankScore(
      { likes: 20, comments: 5, views: 100, createdAtMs: NOW, authorIsPopular: false },
      NOW
    );
    expect(newModest).toBeGreaterThan(oldViral);
  });

  it("weights a comment above a like", () => {
    // Leaving a comment costs more than tapping a heart, so it is the
    // stronger signal.
    const withComments = rankScore(
      { ...base, likes: 100, comments: 20, createdAtMs: NOW },
      NOW
    );
    const likesOnly = rankScore(
      { ...base, likes: 120, comments: 0, createdAtMs: NOW },
      NOW
    );
    expect(withComments).toBeGreaterThan(likesOnly);
  });

  it("applies the follow boost", () => {
    const boosted = rankScore({ ...base, authorIsPopular: true }, NOW);
    const plain = rankScore({ ...base, authorIsPopular: false }, NOW);
    expect(boosted).toBeGreaterThan(plain);
    expect(boosted / plain).toBeCloseTo(1.15, 2);
  });

  it("never returns NaN or a negative score", () => {
    for (const input of [
      { likes: 0, comments: 0, views: 0, createdAtMs: NOW, authorIsPopular: false },
      // A clock-skewed future timestamp must not produce a runaway score.
      { likes: 5, comments: 0, views: 10, createdAtMs: NOW + 999999, authorIsPopular: false },
    ]) {
      const score = rankScore(input, NOW);
      expect(Number.isFinite(score)).toBe(true);
      expect(score).toBeGreaterThanOrEqual(0);
    }
  });
});
