import {
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";
import { anon, authed, patchDoc, seedDoc, setupTestEnv } from "./setup";

let env: RulesTestEnvironment;

const BUYER = "buyer_1";
const SELLER = "seller_1";
const STRANGER = "stranger_1";
const ORDER = "order_1";

beforeAll(async () => {
  env = await setupTestEnv();
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seedDoc(`orders/${ORDER}`, {
    buyer_id: BUYER,
    seller_id: SELLER,
    status: "confirmed",
    total_minor: 25000,
    currency: "IQD",
    product_ids: ["product_1"],
    idempotency_key: "key_1",
  });
});

describe("Order visibility", () => {
  it("lets the buyer read their own order", async () => {
    const db = authed(BUYER).firestore();
    await assertSucceeds(getDoc(doc(db, "orders", ORDER)));
  });

  it("lets the seller read an order placed with them", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(getDoc(doc(db, "orders", ORDER)));
  });

  it("hides the order from everyone else", async () => {
    // Order documents carry a delivery address and a phone number.
    const db = authed(STRANGER).firestore();
    await assertFails(getDoc(doc(db, "orders", ORDER)));
  });

  it("hides it from signed-out users", async () => {
    await assertFails(getDoc(doc(anon().firestore(), "orders", ORDER)));
  });
});

describe("Orders are never created by a client", () => {
  it("rejects a client-created order even from the buyer", async () => {
    // The whole point: a client that can create an order is a client that can
    // set its own price. placeOrder re-reads products server-side.
    const db = authed(BUYER).firestore();
    await assertFails(
      setDoc(doc(db, "orders", "forged"), {
        buyer_id: BUYER,
        seller_id: SELLER,
        status: "confirmed",
        total_minor: 1,
      })
    );
  });
});

describe("Buyer cancellation window (§5.2)", () => {
  it("allows a cancel while still confirmed", async () => {
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", ORDER), { status: "cancelled" })
    );
  });

  it("blocks a cancel once the courier has it", async () => {
    await patchDoc(`orders/${ORDER}`, { status: "handedToCourier" });
    const db = authed(BUYER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "cancelled" })
    );
  });

  it("does not let the buyer smuggle other fields through a cancel", async () => {
    // Without the affectedKeys() clause, "cancel" would be a licence to
    // rewrite the total.
    const db = authed(BUYER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), {
        status: "cancelled",
        total_minor: 1,
      })
    );
  });

  it("does not let a buyer mark their own order delivered", async () => {
    // That would unlock the rating prompt on something never shipped.
    const db = authed(BUYER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "delivered" })
    );
  });
});

describe("Seller transition state machine", () => {
  it("allows confirmed to packed", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", ORDER), { status: "packed" })
    );
  });

  it("blocks the jump from confirmed straight to delivered", async () => {
    // The single most important rule here. Skipping to delivered bypasses the
    // point where the buyer's cancellation window closes.
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "delivered" })
    );
  });

  it("walks the full legal path to delivered", async () => {
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", ORDER), { status: "packed" })
    );
    await assertSucceeds(
      updateDoc(doc(db, "orders", ORDER), { status: "handedToCourier" })
    );
    await assertSucceeds(
      updateDoc(doc(db, "orders", ORDER), { status: "delivered" })
    );
  });

  it("treats delivered as terminal", async () => {
    // If an order could come back, a seller could bounce it out of a rateable
    // state to erase a bad rating.
    await patchDoc(`orders/${ORDER}`, { status: "delivered" });
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "confirmed" })
    );
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "outForDelivery" })
    );
  });

  it("blocks a seller cancel once the courier has it", async () => {
    await patchDoc(`orders/${ORDER}`, { status: "handedToCourier" });
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "cancelled" })
    );
  });

  it("stops a stranger advancing someone else's order", async () => {
    const db = authed(STRANGER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), { status: "packed" })
    );
  });

  it("does not let the seller rewrite the total while advancing", async () => {
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", ORDER), {
        status: "packed",
        total_minor: 999999,
      })
    );
  });
});

describe("Cancellation attribution cannot be faked", () => {
  // It feeds the fulfilment gate on the seller's trust tier, so a field either
  // side could set freely would be a field either side could lie in.

  it("lets a buyer cancel, attributed to them", async () => {
    await seedDoc("orders/o_buyer", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "confirmed",
    });
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", "o_buyer"), {
        status: "cancelled",
        cancelled_by: "buyer",
        cancelled_at: new Date(),
      })
    );
  });

  it("stops a buyer blaming the seller for their own cancellation", async () => {
    // Would inflate the seller's cancellation count and drag their tier down.
    await seedDoc("orders/o_blame", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "confirmed",
    });
    const db = authed(BUYER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", "o_blame"), {
        status: "cancelled",
        cancelled_by: "seller",
      })
    );
  });

  it("stops a seller hiding their cancellation as the buyer's", async () => {
    // The exact move the gate exists to measure.
    await seedDoc("orders/o_dodge", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "confirmed",
    });
    const db = authed(SELLER).firestore();
    await assertFails(
      updateDoc(doc(db, "orders", "o_dodge"), {
        status: "cancelled",
        cancelled_by: "buyer",
      })
    );
  });

  it("lets a seller cancel when they own it", async () => {
    await seedDoc("orders/o_seller", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "confirmed",
    });
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", "o_seller"), {
        status: "cancelled",
        cancelled_by: "seller",
        cancelled_at: new Date(),
      })
    );
  });

  it("does not require attribution on a non-cancelling transition", async () => {
    await seedDoc("orders/o_pack", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "confirmed",
    });
    const db = authed(SELLER).firestore();
    await assertSucceeds(
      updateDoc(doc(db, "orders", "o_pack"), { status: "packed" })
    );
  });
});

describe("Self-dealing is blocked at the rules layer too", () => {
  // placeOrder refuses a self-purchase, so these should be unreachable — which
  // is exactly why they are asserted. One self-order predating that check, or
  // created by a future code path, would otherwise mint a five-star review.

  it("stops a seller reviewing a product on their own order", async () => {
    await seedDoc("orders/o_self", {
      buyer_id: SELLER,
      seller_id: SELLER,
      status: "delivered",
      product_ids: ["p1"],
    });
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "reviews", "rev_self"), {
        author_id: SELLER,
        order_id: "o_self",
        product_id: "p1",
        rating: 5,
        created_at: new Date(),
      })
    );
  });

  it("stops a seller rating themselves", async () => {
    // This is the number the entire trust tier is computed from.
    await seedDoc("orders/o_self2", {
      buyer_id: SELLER,
      seller_id: SELLER,
      status: "delivered",
    });
    const db = authed(SELLER).firestore();
    await assertFails(
      setDoc(doc(db, "seller_ratings", "o_self2"), {
        author_id: SELLER,
        seller_id: SELLER,
        rating: 5,
        created_at: new Date(),
      })
    );
  });

  it("still lets a real buyer rate a real seller", async () => {
    await seedDoc("orders/o_real", {
      buyer_id: BUYER,
      seller_id: SELLER,
      status: "delivered",
    });
    const db = authed(BUYER).firestore();
    await assertSucceeds(
      setDoc(doc(db, "seller_ratings", "o_real"), {
        author_id: BUYER,
        seller_id: SELLER,
        rating: 5,
        created_at: new Date(),
      })
    );
  });
});

describe("A phone number is not public", () => {
  it("keeps the number in a subcollection only its owner can read", async () => {
    // The parent user document is readable by any signed-in account, because a
    // seller page must show a name and rating to a stranger. Firestore cannot
    // return a subset of fields, so a number stored beside them is a number
    // handed to everyone.
    await seedDoc(`users/${SELLER}/private/contact`, {
      phone_number: "+9647700000001",
    });

    await assertSucceeds(
      getDoc(doc(authed(SELLER).firestore(), `users/${SELLER}/private`, "contact"))
    );
    await assertFails(
      getDoc(doc(authed(BUYER).firestore(), `users/${SELLER}/private`, "contact"))
    );
  });

  it("still lets a stranger read the public half of a profile", async () => {
    await seedDoc(`users/${SELLER}`, {
      display_name: "A Seller",
      trust_tier: "gold",
      phone_verified: true,
    });
    await assertSucceeds(
      getDoc(doc(authed(BUYER).firestore(), "users", SELLER))
    );
  });
});
