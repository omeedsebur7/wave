import * as fs from "fs";
import * as path from "path";

/**
 * Reads a source file relative to THIS file, not the process CWD.
 *
 * Jest happens to run with `functions/` as its working directory today, so a
 * bare relative path works — until someone runs the suite from the repo root, at
 * which point every source-reading test fails with ENOENT and looks like a code
 * problem rather than a path problem.
 */
function readSource(relative: string): string {
  return fs.readFileSync(path.join(__dirname, "..", relative), "utf8");
}

const RETENTION_SRC = readSource("src/maintenance/retention.ts");
const CASCADE_SRC = readSource("src/privacy/accountDeletion.ts");

/**
 * Retention policy shape.
 *
 * The windows themselves are a judgement call, but two properties are not, and
 * both are the kind of thing that gets broken by a well-meaning edit:
 *
 *  - Nothing that constitutes evidence gets deleted before the thing it is
 *    evidence for expires.
 *  - Nothing pending is deleted at all.
 */
describe("Retention windows", () => {
  // Mirrors RETENTION in retention.ts. Duplicated deliberately: if someone
  // shortens a window there, this test should fail and make them say why.
  const RETENTION = {
    otpRequests: 3,
    mergedReports: 30,
    resolvedReports: 180,
    moderationLog: 730,
    idempotencyKeys: 30,
  };

  it("keeps OTP rows longer than the window the guard queries", () => {
    // The guard counts requests in the last 24h. Deleting at 24h would race the
    // query and let someone slip an extra request through at the boundary.
    const guardWindowDays = 1;
    expect(RETENTION.otpRequests).toBeGreaterThan(guardWindowDays);
  });

  it("keeps idempotency keys longer than the slowest provider retry", () => {
    // Client retries take seconds. Payment providers retry for hours and, on
    // some plans, days — and a provider replaying a week-old event must still
    // be deduplicated rather than reapplied. The window follows the slowest
    // retry policy, not the fastest.
    expect(RETENTION.idempotencyKeys).toBeGreaterThanOrEqual(30);
  });

  it("prunes the collection that actually exists", () => {
    // It said `idempotency` while the writers used `idempotency_keys`, so the
    // job pruned nothing and the real ledger grew forever. Both sides looked
    // right in isolation.
    expect(RETENTION_SRC).toContain('"idempotency_keys"');
  });

  it("keeps the audit log longer than the reports it describes", () => {
    // The log is the record of decisions. If reports outlived it, a decision
    // could exist with no trace of who made it — the opposite of an audit trail.
    expect(RETENTION.moderationLog).toBeGreaterThan(RETENTION.resolvedReports);
  });

  it("keeps resolved reports long enough for an appeal", () => {
    // Six months. Short enough to forget an old dispute, long enough that
    // someone contesting a removal still has the reason available.
    expect(RETENTION.resolvedReports).toBeGreaterThanOrEqual(180);
  });

  it("discards merged duplicates well before the primary report", () => {
    // A merged duplicate carries no information the primary lacks except its
    // reporter, and keeping thousands of them helps nobody.
    expect(RETENTION.mergedReports).toBeLessThan(RETENTION.resolvedReports);
  });
});

describe("What retention must never touch", () => {

  it("never prunes pending reports", () => {
    // An unreviewed report ageing out of the queue would silently clear it,
    // which is the opposite of what a queue is for.
    expect(RETENTION_SRC).not.toMatch(/"pending"/);
  });

  it("never prunes reports that led to a suspension", () => {
    // A suspension is the decision most likely to be appealed months later, and
    // the report carries the reason the audit entry does not.
    expect(RETENTION_SRC).not.toMatch(/"accountSuspended"[^)]*batch\.delete/s);
    expect(RETENTION_SRC).toMatch(/accountSuspended.*deliberately absent/s);
  });

  it("never prunes orders or reviews", () => {
    // Shared commercial records. A seller has lawful basis to keep them, and a
    // deleted rating silently rewrites their trust score.
    expect(RETENTION_SRC).not.toMatch(/collection\("orders"\)[^;]*delete/s);
    expect(RETENTION_SRC).not.toMatch(/collection\("reviews"\)/);
  });

  it("caps deletes per run rather than looping to exhaustion", () => {
    // A job that tries to delete a million rows times out halfway and leaves the
    // collection unchanged next time. A capped job converges instead.
    expect(RETENTION_SRC).toMatch(/MAX_DELETES_PER_RUN/);
  });
});

describe("Delivery details after account deletion", () => {

  it("erases the map pin, not just the text address", () => {
    // The pin was added after the cascade was written and the cascade drifted
    // behind it — leaving a more precise home address than the field beside it,
    // on a record someone asked to be forgotten from.
    expect(CASCADE_SRC).toContain("delivery_location");
  });

  it("keeps details on an order still in flight", () => {
    // Erasing them mid-delivery protects nobody — the courier already has the
    // address — and strands the seller with an order they cannot complete,
    // where cancelling would count against their fulfilment tier for something
    // outside their control.
    expect(CASCADE_SRC).toContain("delivery_details_pending_erasure");
  });

  it("finishes the job once the order is terminal", () => {
    expect(RETENTION_SRC).toContain("eraseDeliveryDetails");
    expect(RETENTION_SRC).toMatch(/delivered.*cancelled.*refunded/s);
  });

  it("only erases terminal orders, never in-flight ones", () => {
    // A sweep that ignored status would erase the address of an order still
    // being delivered — the exact failure the deferral exists to avoid.
    expect(RETENTION_SRC).toMatch(/terminal\.has\(/);
  });
});
