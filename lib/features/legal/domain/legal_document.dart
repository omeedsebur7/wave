import 'package:equatable/equatable.dart';

enum LegalDocType {
  terms('terms'),
  privacy('privacy'),
  sellerAgreement('seller-agreement'),
  contentPolicy('content-policy');

  const LegalDocType(this.slug);

  /// The document's stable identifier, used in routes and Firestore keys.
  ///
  /// There was a `title` field beside this holding four English strings, and it
  /// was rendered in three places — an app bar, the re-acceptance dialog and a
  /// settings list — so all three showed English to an Arabic reader. Naming is
  /// now `legalDocTitle(context, type)`, which has a BuildContext to name it
  /// with. The field is gone rather than merely unused, because an unused
  /// display string is one import away from being rendered again.
  final String slug;

  static LegalDocType fromSlug(String slug) => LegalDocType.values.firstWhere(
        (d) => d.slug == slug,
        orElse: () => LegalDocType.terms,
      );

  /// Only these two gate the app. A change to the Seller Agreement matters to
  /// sellers, but blocking a buyer from opening the app over it would be
  /// disproportionate — it is surfaced in the publish flow instead.
  bool get requiresAcceptance =>
      this == LegalDocType.terms || this == LegalDocType.privacy;
}

class LegalDocument extends Equatable {
  const LegalDocument({
    required this.type,
    required this.version,
    required this.body,
    required this.updatedAt,
    this.changeSummary,
  });

  final LegalDocType type;

  /// Semantic-ish string, e.g. "1.2". Compared as a plain string: any
  /// difference from what the user accepted triggers re-acceptance, which is
  /// the safe direction to be wrong in.
  final String version;

  final String body;
  final DateTime updatedAt;

  /// A plain-language note about what actually changed.
  ///
  /// "We updated our terms" tells the user nothing and trains them to dismiss
  /// without reading, which defeats the purpose of asking at all.
  final String? changeSummary;

  @override
  List<Object?> get props => [type, version, updatedAt];
}

/// What the user has accepted, and whether that is still current.
class AcceptanceState extends Equatable {
  const AcceptanceState({
    required this.acceptedVersions,
    required this.currentVersions,
  });

  final Map<LegalDocType, String> acceptedVersions;
  final Map<LegalDocType, String> currentVersions;

  /// Documents needing acceptance now.
  ///
  /// A document with no current version on the server is skipped rather than
  /// treated as stale — a failed config fetch must not lock everyone out of
  /// the app.
  List<LegalDocType> get outstanding => [
        for (final type in LegalDocType.values)
          if (type.requiresAcceptance)
            if (currentVersions[type] != null &&
                acceptedVersions[type] != currentVersions[type])
              type,
      ];

  bool get isCurrent => outstanding.isEmpty;

  /// A user who has accepted nothing is at sign-up, not mid-update. The copy
  /// differs, so the distinction is worth carrying.
  bool get isFirstAcceptance => acceptedVersions.isEmpty;

  @override
  List<Object?> get props => [acceptedVersions, currentVersions];
}
