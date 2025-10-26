import 'circle_alert_summary.dart';
import 'circle_member.dart';
import 'circle_stats.dart';

class CircleOverview {
  const CircleOverview({
    required this.members,
    required this.stats,
    required this.alerts,
    this.isDemoData = false,
  });

  final List<CircleMember> members;
  final CircleStats stats;
  final List<CircleAlertSummary> alerts;
  final bool isDemoData;

  CircleOverview copyWith({
    List<CircleMember>? members,
    CircleStats? stats,
    List<CircleAlertSummary>? alerts,
    bool? isDemoData,
  }) {
    return CircleOverview(
      members: members ?? this.members,
      stats: stats ?? this.stats,
      alerts: alerts ?? this.alerts,
      isDemoData: isDemoData ?? this.isDemoData,
    );
  }
}
