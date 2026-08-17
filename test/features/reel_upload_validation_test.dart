import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';

void main() {
  group('Reel upload constraints (§4, §6)', () {
    test('the duration cap is 60 seconds', () {
      expect(ReelUploadService.maxDurationSeconds, 60);
    });

    test('the resolution ceiling is 720p', () {
      // Above 720p rarely reads as sharper on a phone-sized full-screen Reel
      // and meaningfully raises storage and CDN egress cost.
      expect(ReelUploadService.targetMaxHeight, 720);
    });

    test('a stage with no fraction cannot render a progress bar', () {
      // Renamed from 'processing reports no fake progress fraction', which
      // claimed more than it checked: `fraction` is an optional constructor
      // parameter defaulting to null, so the old assertion held for EVERY
      // stage, including `uploading`, which does carry a real fraction in use.
      // It could not have caught a service that started passing a fake one.
      //
      // What it does guard is worth keeping, so it is stated plainly here: the
      // default is null rather than 0. A default of 0 would render a bar
      // sitting at 0% through the whole of server-side transcoding — precisely
      // the lie the field's own doc warns about — and no call site would have
      // to change for that to happen.
      const progress = ReelUploadProgress(ReelUploadStage.processing);
      expect(progress.fraction, isNull);
    });
  });

  // REMOVED: 'every upload stage has a human-readable label'.
  //
  // Not a rename — ReelUploadProgress says so itself:
  //
  //   // Deliberately carries no `label`.
  //   // This is a data-layer value object and has no `BuildContext`, so a
  //   // label defined here is guaranteed never to translate — the same trap
  //   // already removed from four enums and `ProductSort`. Resolved by
  //   // `uploadStageLabel` in the presentation layer.
  //
  // Pointing the test at some other getter on this class would fight that
  // decision. But the thing it checked is real and now has no coverage: add a
  // stage to ReelUploadStage, forget the matching case in uploadStageLabel,
  // and the sheet shows an empty string at that step with nothing failing.
  //
  // Because uploadStageLabel needs a BuildContext, that test belongs beside
  // the presentation layer, roughly:
  //
  //   testWidgets('every upload stage has a label', (tester) async {
  //     await tester.pumpWidget(const MaterialApp(
  //       localizationsDelegates: AppLocalizations.localizationsDelegates,
  //       supportedLocales: AppLocalizations.supportedLocales,
  //       home: SizedBox.shrink(),
  //     ));
  //     final context = tester.element(find.byType(SizedBox));
  //     for (final stage in ReelUploadStage.values) {
  //       expect(uploadStageLabel(context, stage), isNotEmpty,
  //           reason: '${stage.name} has no label');
  //     }
  //   });
  //
  // Worth running in each supported locale, since a missing ARB entry in one
  // language is the failure this actually catches.
}