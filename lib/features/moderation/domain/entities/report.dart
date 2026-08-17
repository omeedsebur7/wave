import 'package:equatable/equatable.dart';

enum ReportTargetType { reel, product, profile, comment, message }

enum ReportReason {
  spam,
  counterfeit,
  prohibited,
  harassment,
  sexual,
  violence,
  intellectualProperty,
  other,
}

/// What a moderator decided.
///
/// `dismissed` is a first-class outcome, not a failure. Most reports on a
/// healthy marketplace are wrong — someone disliking a listing, or reporting a
/// competitor — and a queue that treats dismissal as an exception quietly
/// pressures moderators toward removing content to feel productive.
///
/// `merged` is not a decision: it marks a duplicate folded into another entry
/// by the dedupe trigger.
enum ModerationAction {
  pending,
  merged,
  dismissed,
  contentRemoved,
  accountWarned,
  accountSuspended,
}

class Report extends Equatable {
  const Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.reporterId,
    required this.createdAt,
    this.action = ModerationAction.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.note,
    this.reportCount = 1,
  });

  final String id;
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;

  /// Never rendered in the queue. The reporter was promised confidentiality,
  /// and a moderator who knows who reported whom can be lobbied.
  final String reporterId;

  final DateTime createdAt;
  final ModerationAction action;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? note;

  /// How many separate people reported this same target.
  ///
  /// The most useful number in the queue: one report is an opinion, eight
  /// independent reports on the same Reel is a pattern.
  final int reportCount;

  bool get isPending => action == ModerationAction.pending;

  /// Sexual and violent content jumps the queue regardless of age or count.
  /// The Content Policy treats both as immediate, and a queue sorted purely by
  /// recency would bury them under spam.
  bool get isUrgent =>
      reason == ReportReason.sexual || reason == ReportReason.violence;

  @override
  List<Object?> get props => [id, action, reportCount];
}
