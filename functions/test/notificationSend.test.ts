import { deepLinkFor, NotificationType } from "../src/notifications/send";

describe("Deep links match the Dart client's routing", () => {
  // The two resolvers are deliberately duplicated — the client resolves a live
  // push payload, the server resolves the stored record. They must agree, or a
  // notification opened from the centre lands somewhere different from the same
  // one opened from a push.
  const cases: Array<[NotificationType, Record<string, string>, string | null]> = [
    ["order_update", { order_id: "abc" }, "/profile/orders/abc"],
    ["order_placed", {}, "/profile/selling"],
    ["chat_message", {}, "/chat"],
    ["reel_like", { reel_id: "r1" }, "/reels/r1"],
    ["reel_comment", { reel_id: "r1" }, "/reels/r1"],
    ["new_follower", { follower_id: "u1" }, "/seller/u1"],
    ["new_review", {}, "/profile/selling/stats"],
    ["new_rating", {}, "/profile/selling/stats"],
    ["product_back_in_stock", { product_id: "p1" }, "/marketplace/product/p1"],
  ];

  it.each(cases)("resolves %s", (type, data, expected) => {
    expect(deepLinkFor(type, data)).toBe(expected);
  });

  it("returns null when a required id is missing", () => {
    // Better than a link to "/profile/orders/undefined".
    expect(deepLinkFor("order_update", {})).toBeNull();
    expect(deepLinkFor("reel_comment", {})).toBeNull();
    expect(deepLinkFor("new_follower", {})).toBeNull();
  });

  it("only follows a marketing path that is in-app", () => {
    expect(deepLinkFor("marketing", { path: "/marketplace" })).toBe(
      "/marketplace"
    );
    expect(
      deepLinkFor("marketing", { path: "https://evil.example" })
    ).toBeNull();
    expect(deepLinkFor("marketing", {})).toBeNull();
  });

  it("covers every notification type", () => {
    // A type added without a link case would silently return undefined and
    // produce a notification that cannot be opened.
    const types: NotificationType[] = [
      "order_update", "order_placed", "chat_message", "reel_like",
      "reel_comment", "new_follower", "new_review", "new_rating",
      "product_back_in_stock", "marketing",
    ];
    for (const type of types) {
      expect(deepLinkFor(type, {})).not.toBeUndefined();
    }
  });
});
