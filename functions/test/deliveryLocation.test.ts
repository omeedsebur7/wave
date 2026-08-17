import { normaliseLocation } from "../src/domain/deliveryLocation";

/**
 * A delivery pin is untrusted input that ends up in a courier's map app.
 *
 * That is what makes it different from most malformed data: it does not fail
 * visibly. A bad pair sends a real person to a real place that is not the
 * buyer's address, and the failure surfaces hours later as a missed delivery
 * nobody can explain.
 */
describe("Delivery pin validation", () => {
  const valid = { lat: 36.1911, lng: 44.0092, set_by: "pin" };

  it("accepts a real coordinate", () => {
    const pin = normaliseLocation(valid);
    expect(pin?.lat).toBe(36.1911);
    expect(pin?.set_by).toBe("pin");
  });

  it("treats a missing location as absent, not invalid", () => {
    // A repeat buyer reusing a saved pin does not resend one.
    expect(normaliseLocation(null)).toBeNull();
    expect(normaliseLocation(undefined)).toBeNull();
  });

  it("rejects Null Island", () => {
    // 0,0 is in the Gulf of Guinea and is almost always an uninitialised
    // value. Accepting it dispatches a courier to the Atlantic.
    expect(() => normaliseLocation({ ...valid, lat: 0, lng: 0 })).toThrow(
      /not set/
    );
  });

  it("rejects coordinates outside the possible range", () => {
    expect(() => normaliseLocation({ ...valid, lat: 91 })).toThrow(/real place/);
    expect(() => normaliseLocation({ ...valid, lng: -181 })).toThrow(
      /real place/
    );
  });

  it("rejects NaN and non-numeric input", () => {
    expect(() => normaliseLocation({ ...valid, lat: "north" })).toThrow(
      /malformed/
    );
    expect(() => normaliseLocation({ ...valid, lat: undefined })).toThrow(
      /malformed/
    );
    expect(() => normaliseLocation("36.19,44.00")).toThrow(/malformed/);
  });

  it("rejects a fix too vague to be useful", () => {
    // A ±5km pin tells a courier nothing while looking authoritative on a map,
    // which is worse than admitting there is no usable location.
    expect(() =>
      normaliseLocation({ ...valid, accuracy_m: 5000 })
    ).toThrow(/too approximate/);
  });

  it("accepts a plausible GPS fix and keeps its accuracy", () => {
    const pin = normaliseLocation({ ...valid, set_by: "gps", accuracy_m: 45.7 });
    expect(pin?.accuracy_m).toBe(46);
    expect(pin?.set_by).toBe("gps");
  });

  it("rounds coordinates to about a metre", () => {
    // A privacy decision, not a formatting one. Full float precision records
    // where somebody lives to within centimetres — more than a delivery needs
    // and more than belongs in a document a seller can read.
    const pin = normaliseLocation({ ...valid, lat: 36.19112345678 });
    expect(pin?.lat).toBe(36.19112);
  });

  it("falls back to 'pin' for an unrecognised source", () => {
    // Rather than trusting an arbitrary string into a typed field.
    const pin = normaliseLocation({ ...valid, set_by: "teleport" });
    expect(pin?.set_by).toBe("pin");
  });

  it("trims and caps the landmark note", () => {
    const pin = normaliseLocation({ ...valid, note: "  " + "x".repeat(400) });
    expect(pin?.note?.length).toBe(280);
  });

  it("drops an empty note rather than storing a blank field", () => {
    expect(normaliseLocation({ ...valid, note: "   " })?.note).toBeUndefined();
  });
});
