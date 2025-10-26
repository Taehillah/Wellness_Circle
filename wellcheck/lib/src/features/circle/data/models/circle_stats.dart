import 'circle_member.dart';

class CircleStats {
  const CircleStats({
    required this.totalMembers,
    required this.needsAttention,
    required this.awaitingSetup,
    this.lastAlertAt,
  });

  final int totalMembers;
  final int needsAttention;
  final int awaitingSetup;
  final DateTime? lastAlertAt;

  static CircleStats fromMembers(
    List<CircleMember> members, {
    DateTime? lastAlertAt,
  }) {
    final needsAttention = members
        .where((member) => member.status == CircleMemberStatus.needsAttention)
        .length;
    final awaitingSetup = members
        .where((member) => member.status == CircleMemberStatus.awaitingSetup)
        .length;
    return CircleStats(
      totalMembers: members.length,
      needsAttention: needsAttention,
      awaitingSetup: awaitingSetup,
      lastAlertAt: lastAlertAt,
    );
  }

  CircleStats copyWith({
    int? totalMembers,
    int? needsAttention,
    int? awaitingSetup,
    DateTime? lastAlertAt,
  }) {
    return CircleStats(
      totalMembers: totalMembers ?? this.totalMembers,
      needsAttention: needsAttention ?? this.needsAttention,
      awaitingSetup: awaitingSetup ?? this.awaitingSetup,
      lastAlertAt: lastAlertAt ?? this.lastAlertAt,
    );
  }
}
