import 'package:wave/core/error/failures.dart';
// ignore: unused_import
// Imported only so the doc comment's [Result] reference below resolves —
// this file has no runtime use for the type itself.
import 'package:wave/core/utils/result.dart';

/// Carries a [Failure] out of a Firestore transaction body.
///
/// `runTransaction`'s callback can only signal "abort" by throwing — there is
/// no other channel back to the caller from inside it. Both order repositories
/// used to throw the [Failure] subtypes directly
/// (`NotFoundFailure`/`PermissionFailure`/`ServerFailure`), which is exactly
/// what `only_throw_errors` exists to flag: `Failure` is this codebase's
/// domain error type, modelling "the operation did not succeed" as a value —
/// see [Result] — not Dart's "something went wrong at the language level"
/// exception hierarchy. Throwing a value type conflates the two: catch
/// clauses elsewhere that filter `on Exception` or `on Error` would silently
/// never see it, and a tool or a reader reasonably assuming `catch (e)` is
/// exhaustive over Dart's real exception types is wrong about this one
/// specific case with no way to tell from the throw site alone.
///
/// This wrapper is the seam: it is a genuine [Exception], so it participates
/// correctly in Dart's exception handling, and it carries the [Failure]
/// verbatim so an `on TransactionAborted catch (a)` handler can unwrap it and
/// return exactly the same [Result] the calling method always returned.
/// Nothing about the public behaviour of the repositories using this changes —
/// only what travels through a transaction's internal throw/catch, which no
/// caller of either repository can observe.
///
/// Shared between order_repository_impl.dart and
/// seller_order_repository_impl.dart rather than defined twice, because the
/// two are literally the same pattern applied to the buyer side and the
/// seller side of the same order — a third order-touching repository added
/// later should reach for this rather than writing a third private copy.
class TransactionAborted implements Exception {
  const TransactionAborted(this.failure);
  final Failure failure;
}
