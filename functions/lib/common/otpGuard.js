"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkOtpAllowance = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Server-side OTP rate limiting (Â§1).
 *
 * The client throttle is keyed by phone number and can only see this device.
 * It stops an accidental burst; it cannot stop the attack that matters.
 *
 * The attack that matters is SMS pumping: an attacker cycles through numbers
 * on a premium-rate range they control, collects a share of the carrier fee,
 * and the victim is whoever pays the SMS bill. Every request looks like a
 * different, plausible new user. Only the server can see the pattern, because
 * only the server sees every device at once.
 *
 * App Check makes each request attributable to a real app instance; this makes
 * that attribution count for something.
 *
 * Called by the client immediately BEFORE requesting an OTP. That ordering is
 * deliberate â€” checking afterwards would mean the SMS has already been sent
 * and paid for.
 */
exports.checkOtpAllowance = (0, https_1.onCall)({ cors: true }, async (request) => {
    const db = (0, firestore_1.getFirestore)();
    const phoneNumber = String(request.data?.phoneNumber ?? "");
    if (!/^\+[1-9]\d{7,14}$/.test(phoneNumber)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid phone number");
    }
    // App Check identifies the app instance. Without it, a device cap is
    // trivially defeated by clearing app data.
    const deviceId = request.app?.appId ?? request.auth?.uid;
    if (!deviceId) {
        throw new https_1.HttpsError("failed-precondition", "This request could not be verified");
    }
    const config = await db.collection("config").doc("otp_limits").get();
    const perNumber = Number(config.get("max_per_number_per_day") ?? 5);
    const perDevice = Number(config.get("max_per_device_per_day") ?? 10);
    const since = firestore_1.Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
    const [numberCount, deviceCount] = await Promise.all([
        db.collection("otp_requests")
            .where("phone_number", "==", phoneNumber)
            .where("created_at", ">", since)
            .count()
            .get(),
        db.collection("otp_requests")
            .where("device_id", "==", deviceId)
            .where("created_at", ">", since)
            .count()
            .get(),
    ]);
    if (numberCount.data().count >= perNumber) {
        throw new https_1.HttpsError("resource-exhausted", "Too many codes sent to that number today. Try tomorrow.");
    }
    // The message is deliberately identical for both limits. Telling an attacker
    // which cap they hit tells them which axis to vary.
    if (deviceCount.data().count >= perDevice) {
        throw new https_1.HttpsError("resource-exhausted", "Too many codes sent to that number today. Try tomorrow.");
    }
    // Recorded before the SMS is sent, not after. A crash between the two should
    // over-count rather than under-count â€” the failure mode of over-counting is
    // one user waiting, and of under-counting is an unbounded bill.
    await db.collection("otp_requests").add({
        phone_number: phoneNumber,
        device_id: deviceId,
        created_at: firestore_1.FieldValue.serverTimestamp(),
    });
    return { allowed: true };
});
//# sourceMappingURL=otpGuard.js.map
