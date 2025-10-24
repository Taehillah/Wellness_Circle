import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/stat_card.dart';
import '../application/check_in_controller.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkInControllerProvider);
    final controller = ref.read(checkInControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in history'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatsRow(state: state),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: state.history.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text('No check-ins yet. Keep using WellCheck to build your progress!'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: state.history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = state.history[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                LucideIcons.sparkle,
                                color: AppColors.primary,
                              ),
                              title: Text(DateFormatting.full(entry.timestamp)),
                              subtitle: Text(DateFormatting.relative(entry.timestamp)),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          shrinkWrap: true,
          childAspectRatio: isWide ? 2.6 : 3.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              label: 'Total check-ins',
              value: state.stats.total.toString(),
              icon: LucideIcons.calendarDays,
            ),
            StatCard(
              label: 'Current streak',
              value: '${state.stats.currentStreak} days',
              icon: LucideIcons.flame,
              color: AppColors.secondary,
            ),
            StatCard(
              label: 'This week',
              value: state.stats.thisWeek.toString(),
              icon: LucideIcons.calendarRange,
            ),
          ],
        );
      },
    );
  }
}
