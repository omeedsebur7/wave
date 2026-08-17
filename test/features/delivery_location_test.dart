import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// Delivery pin behaviour.
///
/// The pin is the only thing a courier actually navigates to. A postal address
/// in much of this market is a landmark and a phone call, which is why the map
/// exists — and why the coordinate has to survive the trip to the seller
/// intact.

/// Builds a pin, holding constant the fields these tests do not care about.
///
/// `setBy` is [LocationSource.pin] — a hand-dragged map pin — because that is
/// what every scenario below describes. `accuracyMetres` is deliberately left
/// null: the entity's own doc says the concept does not apply to a hand-placed
/// pin, so supplying one here would describe a state the app cannot produce.
DeliveryLocation _pin(double latitude, double longitude, {String? note}) =>
    DeliveryLocation(
      latitude: latitude,
      longitude: longitude,
      setBy: LocationSource.pin,
      note: note,
    );

void main() {
  group('Coordinate validity', () {
    test('accepts a point in Iraq', () {
      final pin = _pin(33.3152, 44.3661);
      expect(pin.isValid, isTrue);
    });

    test('rejects the null island', () {
      // 0,0 is what an uninitialised coordinate looks like, and it is in the
      // Atlantic. A courier dispatched there is a lost order and a lost buyer.
      final pin = _pin(0, 0);
      expect(pin.isValid, isFalse);
    });

    test('rejects out-of-range coordinates', () {
      expect(_pin(91, 44).isValid, isFalse);
      expect(_pin(33, 181).isValid, isFalse);
      expect(_pin(-91, 44).isValid, isFalse);
    });
  });

  group('Precision', () {
    test('rounds to a sane number of decimals', () {
      // Five decimals is about 1.1m. Storing fifteen implies a precision nobody
      // dragging a pin on a phone actually has.
      //
      // Asserting 5 rather than 6, because 5 is what the code does:
      // `rounded` calls toStringAsFixed(5). The entity's doc comment above it
      // says "Six decimal places is about 11cm" — the arithmetic in that
      // sentence is right (6dp is about 11cm, 5dp about 1.1m) but it does not
      // describe the line beneath it. One of the two is wrong and it is worth
      // deciding which: this is called a privacy decision there, so the exact
      // figure is the whole point. The old `lessThanOrEqualTo(6)` passed
      // either way and so pinned nothing.
      final pin = _pin(33.31523456789, 44.36612345678);
      expect(
        pin.rounded.lat.toString().split('.')[1].length,
        lessThanOrEqualTo(5),
      );
    });

    test('two pins at the same place are equal', () {
      // Deliberately NOT const, and this is the whole point of the test.
      //
      // As `const DeliveryLocation(...)` these two were canonicalised by the
      // compiler into a single instance, so `expect(a, b)` passed by identity
      // whether or not the entity implemented `==` at all. The test asserted
      // nothing. Built at runtime it asserts what it claims to.
      final a = _pin(33.315234, 44.366123);
      final b = _pin(33.315234, 44.366123);
      expect(a, b);
    });

    // NOT TESTED, because it does not currently hold.
    //
    // `props` is [latitude, longitude, setBy, note] — the RAW coordinates, not
    // `rounded`. So two pins that round to the same 5dp point but differ in the
    // tenth decimal compare unequal, and the rounding does nothing to prevent
    // it. If equality is meant to mean "the same place" rather than "the same
    // bytes", props should be built from `rounded`. Adding the test before
    // that decision is made would just add a red test to the suite.
  });

  group('What the courier is given', () {
    test('a note survives alongside the coordinate', () {
      // The map gives a point; the note gives the sentence a courier says on
      // the phone. Neither replaces the other here.
      //
      // This was written against a `landmark` field. The entity calls it
      // `note` — same role, per its doc: "Landmark, floor, gate colour —
      // whatever gets someone to the door."
      final pin = _pin(33.3152, 44.3661, note: 'Opposite the blue mosque');
      expect(pin.note, isNotEmpty);
      expect(pin.isValid, isTrue);
    });

    test('a pin with no note is still usable', () {
      // Requiring one would block someone in a place that has no obvious
      // landmark, which is common in new developments.
      final pin = _pin(33.3152, 44.3661);
      expect(pin.note, isNull);
      expect(pin.isValid, isTrue);
    });
  });
}