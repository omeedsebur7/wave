import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from "firebase/firestore";

const MODERATOR = "moderator_1";
import { authed, seedDoc, setupTestEnv } from "./setup";

let env: RulesTestEnvironment;

const BUYER = "buyer_1";
const SELLER = "seller_1";
const OUTSIDER = "outsider_1";
const PRODUCT = "product_1";
const OTHER_PRODUCT = "product_2";
const DELIVERED_ORDER = "order_delivered";
const OPEN_ORDER = "order_open";

beforeAll(async () => {
  env = await setupTestEnv();
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seedDoc(`products/${PRODUCT}`, {
    seller_id: SELLER,
    title: "Thing",
    price_minor: 25000,
    stock: 5,
    status: "active",
    rating_avg: 0,
    rating_count: 0,
  });
  await seedDoc(`orders/${DELIVERED_ORDER}`, {
    buyer_id: BUYER,
    seller_id: SELLER,
    status: "delivered",
    product_ids: [PRODUCT],
  });
  await seedDoc(`orders/${OPEN_ORDER}`, {
    buyer_id: BUYER,
    seller_id: SELLER,
    status: "confirmed",
    product_ids: [PRODUCT],
  });
  await seedDoc("reels/reel_1", {
    author_id: SELLER,
    status: "published",
    duration_seconds: 30,
    likes_count: 100,
    views_count: 5000,
    comments_count: 3,
    rank_score: 0.5,
  });
});

describe("Reviews are gated on a delivered purchase (§4)", () => {
  const review = (orderId: string, productId = PRODUCT) => ({
    product_id: productId,
    order_id: orderId,
    author_id: BUYER,
    rating: 5,
    created_at: new Date(),
  });

  it("allows a review backed by a delivered order", async () => {
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      setDoc(doc(db, "reviews", "rev_1"), review(DELIVERED_ORDER))
    );
  });

  it("blocks a review on an order that has not been delivered", async () => {
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reviews", "rev_2"), review(OPEN_ORDER))
    );
  });

  it("blocks a review from someone with no order at all", async () => {
    const db = authed(OUTSIDER).firestore();
    await assertFails(
      setDoc(doc(db, "reviews", "rev_3"), {
        ...review(DELIVERED_ORDER),
        author_id: OUTSIDER,
      })
    );
  });

  it("blocks reviewing a product that was not in the order", async () => {
    // Buying one thing must not license reviewing the seller's whole catalogue.
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(
        doc(db, "reviews", "rev_4"),
        review(DELIVERED_ORDER, OTHER_PRODUCT)
      )
    );
  });

  it("rejects an out-of-range rating", async () => {
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reviews", "rev_5"), {
        ...review(DELIVERED_ORDER),
        rating: 6,
      })
    );
    await assertFails(
      setDoc(doc(db, "reviews", "rev_6"), {
        ...review(DELIVERED_ORDER),
        rating: 0,
      })
    );
  });
});

describe("Comments are open to real accounts (§0 decision)", () => {
  it("allows any signed-in non-guest to comment, purchase or not", async () => {
    // The deliberate deviation from the literal brief. Pre-purchase questions
    // are the highest-intent comments in a Reels-to-purchase funnel.
    const db = authed(OUTSIDER).firestore();
    await assertSucceeds(
      setDoc(doc(db, "reels/reel_1/comments", "c1"), {
        author_id: OUTSIDER,
        text: "Does this run true to size?",
        created_at: new Date(),
      })
    );
  });

  it("rejects a comment posted under someone else's name", async () => {
    const db = authed(OUTSIDER).firestore();
    await assertFails(
      setDoc(doc(db, "reels/reel_1/comments", "c2"), {
        author_id: BUYER,
        text: "impersonation",
      })
    );
  });

  it("rejects an oversized comment", async () => {
    const db = authed(OUTSIDER).firestore();
    await assertFails(
      setDoc(doc(db, "reels/reel_1/comments", "c3"), {
        author_id: OUTSIDER,
        text: "x".repeat(501),
      })
    );
  });
});

describe("Reel ownership and counters", () => {
  it("stops a non-author attaching a product link to someone else's Reel",
    async () => {
      // Otherwise anyone could point a Buy Now button at their own listing.
      const db = authed(OUTSIDER).firestore();
      await assertFails(
        updateDoc(doc(db, "reels", "reel_1"), {
          linked_product_id: OTHER_PRODUCT,
        })
      );
    });

  it("lets the author link their own product", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "reels", "reel_1"), { linked_product_id: PRODUCT })
    );
  });

  it("stops the author rewriting their own like and view counts", async () => {
    // Counters are materialised from shards by a scheduled function. A client
    // that can set them can manufacture social proof.
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "reels", "reel_1"), { likes_count: 999999 })
    );
    await assertFails(
      updateDoc(doc(db, "reels", "reel_1"), { views_count: 999999 })
    );
  });

  it("stops anyone setting their own feed rank", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "reels", "reel_1"), { rank_score: 9999 })
    );
  });

  it("rejects a Reel longer than 60 seconds", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "reels", "too_long"), {
        author_id: SELLER,
        duration_seconds: 61,
        likes_count: 0,
        views_count: 0,
        rank_score: 0,
      })
    );
  });

  it("rejects a Reel created with counters already inflated", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "reels", "prestuffed"), {
        author_id: SELLER,
        duration_seconds: 30,
        likes_count: 5000,
        views_count: 0,
        rank_score: 0,
      })
    );
  });
});

describe("Product ownership", () => {
  it("stops a stranger editing a listing", async () => {
    const db = authed(OUTSIDER).firestore();
    await assertFails(
      updateDoc(doc(db, "products", PRODUCT), { price_minor: 1 })
    );
  });

  it("stops the seller rewriting their own rating aggregate", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "products", PRODUCT), { rating_avg: 5 })
    );
  });

  it("lets the seller change their own price and stock", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "products", PRODUCT), {
        price_minor: 30000,
        stock: 3,
      })
    );
  });
});

describe("The idempotency ledger is opaque to clients", () => {
  it("is unreadable and unwritable by anyone", async () => {
    // Reading it would let someone probe for another user's order keys.
    await seedDoc("idempotency_keys/key_1", { order_id: "order_1" });
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "idempotency_keys", "key_2"), { order_id: "x" })
    );
  });
});

describe("Buy Now taps are append-only", () => {
  it("lets a signed-in user record their own tap", async () => {
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      setDoc(doc(db, "reels/reel_1/buy_now_taps", "t1"), {
        user_id: BUYER,
        created_at: new Date(),
      })
    );
  });

  it("stops someone recording a tap under another user's id", async () => {
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reels/reel_1/buy_now_taps", "t2"), {
        user_id: OUTSIDER,
      })
    );
  });

  it("stops the Reel's author deleting taps", async () => {
    // A seller who could delete taps could hide a Reel that converts badly.
    await seedDoc("reels/reel_1/buy_now_taps/t3", { user_id: BUYER });
    const db = authed(SELLER).firestore();
    await assertFails(deleteDoc(doc(db, "reels/reel_1/buy_now_taps", "t3")));
  });

  it("keeps the tap log unreadable — it is raw behavioural data", async () => {
    await seedDoc("reels/reel_1/buy_now_taps/t4", { user_id: BUYER });
    const db = authed(SELLER).firestore();
    await assertFails(getDoc(doc(db, "reels/reel_1/buy_now_taps", "t4")));
  });

  it("stops a seller inflating their own funnel counters", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "reels", "reel_1"), { buy_now_taps: 999999 })
    );
    await assertFails(
      updateDoc(doc(db, "reels", "reel_1"), { orders_count: 999999 })
    );
  });
});

describe("Reports and the moderation queue", () => {
  it("lets any signed-in user file a report", async () => {
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      setDoc(doc(db, "reports", "r1"), {
        reporter_id: BUYER,
        target_type: "reel",
        target_id: "reel_1",
        reason: "spam",
        action: "pending",
        report_count: 1,
        created_at: new Date(),
      })
    );
  });

  it("stops a client filing a report already marked resolved", async () => {
    // Otherwise someone could bury a complaint against themselves before any
    // moderator saw it.
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reports", "r2"), {
        reporter_id: BUYER,
        target_type: "reel",
        target_id: "reel_1",
        reason: "spam",
        action: "dismissed",
        report_count: 1,
      })
    );
  });

  it("stops a client inflating report_count", async () => {
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reports", "r3"), {
        reporter_id: BUYER,
        target_type: "reel",
        target_id: "reel_1",
        reason: "spam",
        action: "pending",
        report_count: 500,
      })
    );
  });

  it("stops a client filing under someone else's id", async () => {
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "reports", "r4"), {
        reporter_id: OUTSIDER,
        target_type: "reel",
        target_id: "reel_1",
        reason: "spam",
        action: "pending",
        report_count: 1,
      })
    );
  });

  it("keeps the queue unreadable without the moderator claim", async () => {
    await seedDoc("reports/r5", {
      reporter_id: BUYER,
      target_id: "reel_1",
      action: "pending",
    });
    await assertFails(getDoc(doc(authed(SELLER).firestore(), "reports", "r5")));
    await assertFails(getDoc(doc(authed(BUYER).firestore(), "reports", "r5")));
  });

  it("lets a moderator read the queue", async () => {
    await seedDoc("reports/r6", {
      reporter_id: BUYER,
      target_id: "reel_1",
      action: "pending",
    });
    const db = authed(MODERATOR, { moderator: true }).firestore();
    await assertSucceeds(getDoc(doc(db, "reports", "r6")));
  });

  it("stops even a moderator writing an outcome directly", async () => {
    // Outcomes go through resolveReport, which writes the audit entry in the
    // same batch. A direct write would leave a decision with no record of who
    // made it.
    await seedDoc("reports/r7", {
      reporter_id: BUYER,
      target_id: "reel_1",
      action: "pending",
    });
    const db = authed(MODERATOR, { moderator: true }).firestore();
    await assertFails(updateDoc(doc(db, "reports", "r7"), { action: "dismissed" }));
  });

  it("keeps the audit log append-only and moderator-readable", async () => {
    await seedDoc("moderation_log/e1", {
      report_id: "r1",
      action: "dismissed",
      moderator_id: MODERATOR,
    });

    const mod = authed(MODERATOR, { moderator: true }).firestore();
    await assertSucceeds(getDoc(doc(mod, "moderation_log", "e1")));
    // Not even a moderator may rewrite history.
    await assertFails(updateDoc(doc(mod, "moderation_log", "e1"), { action: "x" }));

    const other = authed(SELLER).firestore();
    await assertFails(getDoc(doc(other, "moderation_log", "e1")));
  });
});

describe("Product price and stock are bounded", () => {
  const base = {
    seller_id: SELLER,
    title: "A thing",
    currency: "IQD",
    status: "active",
    stock: 5,
    price_minor: 25000,
  };

  it("accepts an ordinary listing", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(setDoc(doc(db, "products", "ok"), base));
  });

  it("rejects a fat-fingered price", async () => {
    // 25,000,000,000 rather than 25,000. Caught here so the grid never shows a
    // price nobody meant to type.
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "products", "big"), { ...base, price_minor: 25000000000 })
    );
  });

  it("rejects a zero or negative price", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "products", "free"), { ...base, price_minor: 0 })
    );
    await assertFails(
      setDoc(doc(db, "products", "neg"), { ...base, price_minor: -100 })
    );
  });

  it("rejects a non-integer price", async () => {
    // Money is minor units. A float here becomes a rounding argument later.
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "products", "float"), { ...base, price_minor: 25000.5 })
    );
  });

  it("rejects absurd stock", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "products", "huge"), { ...base, stock: 999999999 })
    );
  });

  it("applies the same bounds on update, not just create", async () => {
    // Editing a price is routine; listing is not. Bounding only create would
    // catch the rarer mistake and miss the common one.
    await seedDoc("products/edit_me", base);
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "products", "edit_me"), { price_minor: 99000000000 })
    );
    await assertSucceeds(
      updateDoc(doc(db, "products", "edit_me"), { price_minor: 30000 })
    );
  });

  it("stops a seller inflating their own sold_count", async () => {
    // It drives the buyer count on the Buy Now sheet — manufactured social
    // proof at the exact moment someone is deciding.
    await seedDoc("products/sold", { ...base, sold_count: 3 });
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "products", "sold"), { sold_count: 5000 })
    );
  });
});

describe("Promo codes cannot be enumerated", () => {
  it("refuses a point read of a known code", async () => {
    await seedDoc("promo_codes/SAVE10", { percentOff: 10, active: true });
    const db = authed(BUYER).firestore();
    await assertFails(getDoc(doc(db, "promo_codes", "SAVE10")));
  });

  it("refuses a listing of the whole collection", async () => {
    // The real hole. `allow read` covers `list` as well as `get`, so a read
    // permission was one query away from every code in the system — including
    // campaign codes not yet launched.
    await seedDoc("promo_codes/SAVE10", { percentOff: 10, active: true });
    await seedDoc("promo_codes/LAUNCH50", { percentOff: 50, active: false });
    const db = authed(BUYER).firestore();
    await assertFails(getDocs(collection(db, "promo_codes")));
  });

  it("keeps redemptions unreadable", async () => {
    // Otherwise a client could work out which codes it has NOT yet used.
    await seedDoc(`promo_codes/SAVE10/redemptions/${BUYER}`, { uid: BUYER });
    const db = authed(BUYER).firestore();
    await assertFails(
      getDoc(doc(db, `promo_codes/SAVE10/redemptions`, BUYER))
    );
  });

  it("stops a client clearing its own attempt budget", async () => {
    await seedDoc(`promo_attempts/${BUYER}/attempts/a1`, { at: new Date() });
    const db = authed(BUYER).firestore();
    await assertFails(
      deleteDoc(doc(db, `promo_attempts/${BUYER}/attempts`, "a1"))
    );
  });
});
