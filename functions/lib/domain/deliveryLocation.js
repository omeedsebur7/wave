"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normaliseLocation = normaliseLocation;
const orderTotals_1 = require("./orderTotals");
/** Landmark notes longer than this are prose, not directions. */
const MAX_NOTE_LENGTH = 280;
/**
 * A fix vaguer than this tells a courier nothing while looking authoritative on
 * a map, which is worse than admitting there is no usable pin.
 */
const MAX_ACCURACY_METRES = 2000;
/**
 * Validates and normalises a delivery pin arriving from a client.
 *
 * This is untrusted input that ends up in a courier's map app, so it gets the
 * same treatment as a price: checked server-side, never taken on trust. A
 * malformed pair does not fail visibly — it sends a real person to a real place
 * that is not the delivery address, and the failure surfaces as a missed
 * delivery hours later.
 *
 * Returns `null` when there is no pin at all, which is legitimate: a repeat
 * buyer reusing a saved location does not resend one.
 */
function normaliseLocation(input) {
    if (input === null || input === undefined)
        return null;
    if (typeof input !== "object") {
        throw new orderTotals_1.OrderComputationError("invalid-argument", "Delivery location is malformed");
    }
    const raw = input;
    const lat = Number(raw.lat);
    const lng = Number(raw.lng);
    // `Number(undefined)` is NaN and `Number(null)` is 0 — the second is the
    // dangerous one, because 0,0 is a real coordinate in the Atlantic. Both are
    // caught: NaN by isFinite, 0,0 by the Null Island check below.
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        throw new orderTotals_1.OrderComputationError("invalid-argument", "Delivery location is malformed");
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw new orderTotals_1.OrderComputationError("invalid-argument", "Delivery location is not a real place");
    }
    // Null Island. Almost always an uninitialised value rather than a delivery
    // address, and accepting it would dispatch a courier to the Gulf of Guinea.
    if (lat === 0 && lng === 0) {
        throw new orderTotals_1.OrderComputationError("invalid-argument", "Delivery location is not set");
    }
    const accuracy = Number(raw.accuracy_m);
    const hasAccuracy = Number.isFinite(accuracy) && accuracy > 0;
    if (hasAccuracy && accuracy > MAX_ACCURACY_METRES) {
        throw new orderTotals_1.OrderComputationError("invalid-argument", "That location is too approximate. Move the pin to where you want it.");
    }
    const setBy = raw.set_by;
    const source = setBy === "gps" || setBy === "pin" || setBy === "saved" ? setBy : "pin";
    // Rounded to five decimal places — about a metre.
    //
    // This is a privacy decision rather than a formatting one. Full float
    // precision records where someone lives to within centimetres, which is more
    // than a delivery needs and more than should sit in a document a seller can
    // read.
    const pin = {
        lat: round5(lat),
        lng: round5(lng),
        set_by: source,
    };
    if (typeof raw.note === "string") {
        const note = raw.note.trim().slice(0, MAX_NOTE_LENGTH);
        if (note.length > 0)
            pin.note = note;
    }
    if (hasAccuracy)
        pin.accuracy_m = Math.round(accuracy);
    return pin;
}
function round5(value) {
    return Math.round(value * 1e5) / 1e5;
}
//# sourceMappingURL=deliveryLocation.js.map
