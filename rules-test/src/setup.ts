import {
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { Firestore, doc, setDoc, updateDoc } from "firebase/firestore";
import * as fs from "fs";
import * as path from "path";

export let testEnv: RulesTestEnvironment;

export async function setupTestEnv(): Promise<RulesTestEnvironment> {
  testEnv = await initializeTestEnvironment({
    projectId: "wave-rules-test",
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8"
      ),
    },
  });
  return testEnv;
}

/**
 * A signed-in, non-anonymous user — what the rules call a "real user".
 *
 * The sign_in_provider claim is load-bearing: several rules turn on the
 * difference between a guest and a real account, and a test that omits it
 * would silently exercise the wrong branch and pass for the wrong reason.
 */
export function authed(uid: string, claims?: Record<string, unknown>) {
  return testEnv.authenticatedContext(uid, {
    firebase: { sign_in_provider: "google.com" },
    // Extra claims — `{ moderator: true }` for the review queue. Passed as a
    // token claim rather than seeded as a document, deliberately: the rules
    // check the token, so a test that seeded a document would pass without
    // exercising the thing being asserted.
    ...(claims ?? {}),
  });
}

/** An anonymous session — browsing works, writing mostly does not. */
export function guest(uid: string) {
  return testEnv.authenticatedContext(uid, {
    firebase: { sign_in_provider: "anonymous" },
  });
}

export function anon() {
  return testEnv.unauthenticatedContext();
}

/**
 * Seeds documents with rules DISABLED.
 *
 * This is the one place bypassing rules is correct: establishing a
 * precondition is not the thing under test, and forcing fixtures through the
 * rules would make it impossible to test what happens to data the rules
 * forbid creating in the first place — such as an order, which no client may
 * ever create.
 *
 * Note this is the v9 modular client with enforcement off, NOT the Admin SDK,
 * so writes go through `setDoc`/`updateDoc` rather than `db.doc().set()`.
 */
export async function seedDoc(path_: string, data: Record<string, unknown>) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Firestore;
    await setDoc(doc(db, path_), data);
  });
}

export async function patchDoc(
  path_: string,
  data: Record<string, unknown>
) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore() as unknown as Firestore;
    await updateDoc(doc(db, path_), data);
  });
}
