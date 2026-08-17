import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { anon, authed, guest, seedDoc, setupTestEnv } from "./setup";

const SELLER = "seller_1";

let env: RulesTestEnvironment;

const ME = "user_1";
const OTHER = "user_2";

beforeAll(async () => {
  env = await setupTestEnv();
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seedDoc(`users/${ME}`, {
    display_name: "Me",
    phone_verified: false,
    trust_tier: "newSeller",
    avg_rating: 0,
    completed_orders: 0,
    kyc_verified: false,
  });
});

describe("Fields the client must never write", () => {
  it("blocks a client setting phone_verified", async () => {
    // If a client could set this, the entire checkout identity gate would be
    // decorative — it is the single flag standing between a fresh account and
    // placing an order.
    const db = authed(ME).firestore();
    await assertFails(
      updateDoc(doc(db, "users", ME), { phone_verified: true })
    );
  });

  it("blocks a client setting its own trust tier", async () => {
    const db = authed(ME).firestore();
    await assertFails(
      updateDoc(doc(db, "users", ME), { trust_tier: "platinum" })
    );
  });

  it("blocks a client inflating its own rating or order count", async () => {
    const db = authed(ME).firestore();
    await assertFails(updateDoc(doc(db, "users", ME), { avg_rating: 5 }));
    await assertFails(
      updateDoc(doc(db, "users", ME), { completed_orders: 9999 })
    );
  });

  it("blocks a client granting itself KYC verification", async () => {
    const db = authed(ME).firestore();
    await assertFails(
      updateDoc(doc(db, "users", ME), { kyc_verified: true })
    );
  });

  it("still allows ordinary profile edits", async () => {
    // The lock must not be so broad that nobody can change their own name.
    const db = authed(ME).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users", ME), { display_name: "New Name" })
    );
  });
});

describe("Profile ownership", () => {
  it("stops one user editing another's profile", async () => {
    const db = authed(OTHER).firestore();
    await assertFails(
      updateDoc(doc(db, "users", ME), { display_name: "Hacked" })
    );
  });

  it("blocks direct profile deletion, which must cascade through a function",
    async () => {
      const db = authed(ME).firestore();
      await assertFails(deleteDoc(doc(db, "users", ME)));
    });

  it("keeps private subcollections private", async () => {
    await seedDoc(`users/${ME}/addresses/a1`, { city: "Erbil" });
    await seedDoc(`users/${ME}/payment_methods/p1`, { last_four: "4242" });

    const other = authed(OTHER).firestore();
    await assertFails(getDoc(doc(other, `users/${ME}/addresses`, "a1")));
    await assertFails(
      getDoc(doc(other, `users/${ME}/payment_methods`, "p1"))
    );

    const mine = authed(ME).firestore();
    await assertSucceeds(getDoc(doc(mine, `users/${ME}/addresses`, "a1")));
  });
});

describe("Guest limits (§1)", () => {
  beforeEach(async () => {
    await seedDoc("reels/reel_1", {
      author_id: "seller_1",
      status: "published",
      caption: "A reel",
      duration_seconds: 30,
      likes_count: 0,
      views_count: 0,
      comments_count: 0,
      rank_score: 1,
    });
  });

  it("lets a guest read Reels — browsing is the whole point of guest mode",
    async () => {
      const db = guest("guest_1").firestore();
      await assertSucceeds(getDoc(doc(db, "reels", "reel_1")));
    });

  it("stops a guest commenting", async () => {
    // Commenting needs an identity that can be reported and blocked.
    const db = guest("guest_1").firestore();
    await assertFails(
      setDoc(doc(db, "reels/reel_1/comments", "c1"), {
        author_id: "guest_1",
        text: "hello",
      })
    );
  });

  it("stops a guest publishing a Reel", async () => {
    const db = guest("guest_1").firestore();
    await assertFails(
      setDoc(doc(db, "reels", "guest_reel"), {
        author_id: "guest_1",
        duration_seconds: 30,
        likes_count: 0,
        views_count: 0,
        rank_score: 0,
      })
    );
  });

  it("lets a guest still file a report", async () => {
    // Safety tooling must not be gated behind sign-up — the person best placed
    // to report something is often the one just passing through.
    const db = guest("guest_1").firestore();
    await assertSucceeds(
      setDoc(doc(db, "reports", "r1"), {
        reporter_id: "guest_1",
        target_type: "reel",
        target_id: "reel_1",
        reason: "spam",
      })
    );
  });

  it("keeps the report queue unreadable, even to its author", async () => {
    // A readable queue lets a bad actor check whether they have been reported
    // and adapt.
    await seedDoc("reports/r1", { reporter_id: "guest_1" });
    const db = guest("guest_1").firestore();
    await assertFails(getDoc(doc(db, "reports", "r1")));
  });
});

describe("Collections that would fail silently without a rule", () => {
  // Every one of these falls to the default-deny catch-all if its block is
  // missing. None of them fails loudly — the feature just quietly does
  // nothing, which is the hardest class of bug to notice in review.

  it("lets a user save and read their own favourites", async () => {
    const db = authed(ME).firestore();
    await assertSucceeds(
      setDoc(doc(db, `users/${ME}/favourites`, "p1"), {
        created_at: new Date(),
      })
    );
    await assertSucceeds(getDoc(doc(db, `users/${ME}/favourites`, "p1")));
  });

  it("stops one user writing another's favourites", async () => {
    const db = authed(OTHER).firestore();
    await assertFails(
      setDoc(doc(db, `users/${ME}/favourites`, "p1"), { created_at: new Date() })
    );
  });

  it("lets a user follow a seller", async () => {
    const db = authed(ME).firestore();
    await assertSucceeds(
      setDoc(doc(db, `users/${ME}/following`, "seller_1"), {
        created_at: new Date(),
      })
    );
  });

  it("stops a seller adding themselves to someone else's following list",
    async () => {
      // Otherwise follower counts — and any future sponsorship pricing keyed
      // off reach — could be manufactured.
      const db = authed(OTHER).firestore();
      await assertFails(
        setDoc(doc(db, `users/${ME}/following`, OTHER), {
          created_at: new Date(),
        })
      );
    });

  it("lets a device register its own FCM token", async () => {
    // Without this rule no token is ever stored and every push has nowhere to
    // go — the whole notification system dies silently.
    const db = authed(ME).firestore();
    await assertSucceeds(
      setDoc(doc(db, `users/${ME}/fcm_tokens`, "token_abc"), {
        token: "token_abc",
        updated_at: new Date(),
      })
    );
  });

  it("keeps FCM tokens unreadable, even by their owner", async () => {
    // A token is a delivery address. The client never needs to read it back.
    await seedDoc(`users/${ME}/fcm_tokens/token_abc`, { token: "token_abc" });
    const db = authed(ME).firestore();
    await assertFails(getDoc(doc(db, `users/${ME}/fcm_tokens`, "token_abc")));
  });

  it("lets a user read their own notifications", async () => {
    await seedDoc(`users/${ME}/notifications/n1`, {
      title: "Order confirmed",
      read: false,
    });
    const db = authed(ME).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${ME}/notifications`, "n1")));
  });

  it("stops a client forging a notification to itself", async () => {
    // Otherwise anyone could fabricate an "order delivered" message.
    const db = authed(ME).firestore();
    await assertFails(
      setDoc(doc(db, `users/${ME}/notifications`, "forged"), {
        title: "Order delivered",
        read: false,
      })
    );
  });

  it("allows marking read, and nothing else", async () => {
    await seedDoc(`users/${ME}/notifications/n1`, {
      title: "Order confirmed",
      read: false,
    });
    const db = authed(ME).firestore();

    await assertSucceeds(
      updateDoc(doc(db, `users/${ME}/notifications`, "n1"), { read: true })
    );
    await assertFails(
      updateDoc(doc(db, `users/${ME}/notifications`, "n1"), {
        title: "Something else",
      })
    );
  });

  it("makes app config world-readable", async () => {
    // The legal-version check runs before sign-in. Gating it behind auth would
    // mean the re-acceptance gate never fires for the people who need it.
    await seedDoc("config/legal_versions", { terms: "1.0" });
    await assertSucceeds(getDoc(doc(anon().firestore(), "config", "legal_versions")));
  });

  it("stops a client rewriting app config", async () => {
    // A client that could set legal_versions could suppress a Terms update.
    const db = authed(ME).firestore();
    await assertFails(
      setDoc(doc(db, "config", "legal_versions"), { terms: "0.1" })
    );
  });
});

describe("Suspension is enforced by the token, not a document", () => {
  it("lets a normal account write", async () => {
    const db = authed(ME).firestore();
    await assertSucceeds(
      setDoc(doc(db, `users/${ME}/favourites`, "p1"), { created_at: new Date() })
    );
  });

  it("blocks writes from a suspended account", async () => {
    // The claim is what the rules read. A Firestore flag alone would leave a
    // suspended account writing freely until something happened to check it.
    const db = authed(ME, { suspended: true }).firestore();
    await assertFails(
      setDoc(doc(db, `users/${ME}/favourites`, "p2"), { created_at: new Date() })
    );
  });

  it("still lets a suspended account READ its own orders", async () => {
    // Deliberate. A suspended seller may have deliveries outstanding, and
    // hiding them would strand the buyers waiting on those orders.
    await seedDoc("orders/o1", { buyer_id: ME, seller_id: SELLER, status: "confirmed" });
    const db = authed(ME, { suspended: true }).firestore();
    await assertSucceeds(getDoc(doc(db, "orders", "o1")));
  });

  it("stops a suspended seller publishing", async () => {
    const db = authed(SELLER, { suspended: true }).firestore();
    await assertFails(
      setDoc(doc(db, "products", "new_p"), {
        seller_id: SELLER,
        title: "Thing",
        price_minor: 1000,
        status: "active",
      })
    );
  });
});

describe("Server-side write throttle", () => {
  it("lets a user stamp their own throttle document", async () => {
    const db = authed(ME).firestore();
    await assertSucceeds(
      setDoc(doc(db, "rate_limits", ME), { last_comment_at: serverTimestamp() })
    );
  });

  it("stops a user stamping someone else's", async () => {
    const db = authed(OTHER).firestore();
    await assertFails(
      setDoc(doc(db, "rate_limits", ME), { last_comment_at: serverTimestamp() })
    );
  });

  it("stops a client backdating its own cooldown", async () => {
    // The whole point: a client that could write an arbitrary timestamp could
    // set its last-comment time to 1970 and never be limited again.
    await seedDoc(`rate_limits/${ME}`, { last_comment_at: new Date() });
    const db = authed(ME).firestore();
    await assertFails(
      updateDoc(doc(db, "rate_limits", ME), {
        last_comment_at: new Date(2000, 1, 1),
      })
    );
  });

  it("stops a client adding fields the rules do not know about", async () => {
    const db = authed(ME).firestore();
    await assertFails(
      setDoc(doc(db, "rate_limits", ME), {
        last_comment_at: serverTimestamp(),
        moderator: true,
      })
    );
  });

  it("keeps the throttle document private", async () => {
    await seedDoc(`rate_limits/${ME}`, { last_comment_at: new Date() });
    const db = authed(OTHER).firestore();
    await assertFails(getDoc(doc(db, "rate_limits", ME)));
  });

  it("never throttles unfollowing", async () => {
    // Making it harder to withdraw attention than to give it is the wrong
    // asymmetry, and someone rate-limited out of unfollowing an account they
    // want away from has a worse problem than the one the limit solves.
    await seedDoc(`users/${ME}/following/${SELLER}`, { created_at: new Date() });
    await seedDoc(`rate_limits/${ME}`, { last_follow_at: new Date() });
    const db = authed(ME).firestore();
    await assertSucceeds(deleteDoc(doc(db, `users/${ME}/following`, SELLER)));
  });
});
