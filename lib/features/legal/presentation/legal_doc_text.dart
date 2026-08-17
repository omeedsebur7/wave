import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/legal/domain/legal_document.dart';

/// The name of a legal document, in the reader's language.
///
/// Lives in the presentation layer because [LegalDocType] is a domain enum with
/// no `BuildContext`. Its `title` field was rendered directly in three places —
/// an app bar, a re-acceptance dialog and a settings list — so all three showed
/// "Terms of Service" to an Arabic reader.
///
/// The ninth instance in this codebase of a label defined next to its value. It
/// reads as good cohesion every time, and it is the one reliable way to make a
/// string permanently English. The `title` field it replaced has been removed
/// from [LegalDocType] outright — a display string with no renderer is still a
/// display string, and the next screen that needs a document name would have
/// found it first.
String legalDocTitle(BuildContext context, LegalDocType type) =>
    switch (type) {
      LegalDocType.terms => context.l10n.termsOfService,
      LegalDocType.privacy => context.l10n.privacyPolicy,
      LegalDocType.sellerAgreement => context.l10n.legalSellerAgreement,
      LegalDocType.contentPolicy => context.l10n.legalContentPolicy,
    };
