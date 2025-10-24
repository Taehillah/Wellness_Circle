import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../dashboard/application/dashboard_metrics_provider.dart';
import '../../dashboard/data/models/dashboard_metrics.dart';
import '../../alerts/data/models/help_request.dart';
import '../../contacts/data/models/contact.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(
          child: Text('This area is restricted to administrators.'),
        ),
      );
    }

    final metrics = ref.watch(dashboardMetricsProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);
    final dashboardController = ref.read(dashboardControllerProvider.notifier);
    final authController = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WellCheck admin dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoute.home.path),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to home'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => authController.logout(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await dashboardController.load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (metrics != null) ...[
                _MetricsRow(metrics: metrics),
                const SizedBox(height: 16),
                _WeeklyActivityCard(activity: metrics.weeklyActivity),
                const SizedBox(height: 16),
                _ContactsCard(contacts: metrics.contacts),
                const SizedBox(height: 16),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              _HelpRequestsCard(state: dashboardState),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final stats = metrics.stats;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 2.8 : 3.0,
          children: [
            StatCard(
              label: 'Total check-ins',
              value: stats.total.toString(),
              icon: LucideIcons.calendarDays,
            ),
            StatCard(
              label: 'Current streak',
              value: '${stats.currentStreak} days',
              icon: LucideIcons.flame,
              color: AppColors.secondary,
            ),
            StatCard(
              label: 'This week',
              value: stats.thisWeek.toString(),
              icon: LucideIcons.calendarClock,
            ),
            StatCard(
              label: 'Contacts',
              value: metrics.totalContacts.toString(),
              icon: LucideIcons.users,
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.activity});

  final List<WeeklyActivityDay> activity;

  @override
  Widget build(BuildContext context) {
    final maxCount = activity.isEmpty
        ? 1
        : activity
            .map((day) => day.count)
            .reduce((value, element) => element > value ? element : value);
    final normalizedMax = maxCount == 0 ? 1 : maxCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7-day activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${activity.fold<int>(0, (sum, day) => sum + day.count)} total check-ins',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: activity
                  .map(
                    (day) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              day.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: activity.isEmpty ? 0 : (day.count / normalizedMax),
                              backgroundColor: AppColors.neutralBackground,
                              color: AppColors.primary,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${day.count}')
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.contacts});

  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top contacts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (contacts.isEmpty)
              const Text('No contacts added yet.')
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: contacts
                    .take(4)
                    .map(
                      (contact) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.neutralBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(contact.phone),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpRequestsCard extends StatelessWidget {
  const _HelpRequestsCard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent help requests',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            if (state.helpRequests.isEmpty)
              const Text('No emergency requests yet. Stay vigilant!')
            else
              ...state.helpRequests.take(5).map(
                    (request) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _HelpRequestTile(request: request),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _HelpRequestTile extends StatelessWidget {
  const _HelpRequestTile({required this.request});

  final HelpRequest request;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.danger.withValues(alpha: 0.15),
        child: const Icon(LucideIcons.siren, color: AppColors.danger),
      ),
      title: Text(request.message?.isNotEmpty == true
          ? request.message!
          : 'Assistance requested'),
      subtitle: Text(
        '${request.user?.name ?? 'Anonymous'} • ${DateFormatting.relative(request.createdAt)}',
      ),
      trailing: request.location == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Location'),
                Text(
                  '${request.location!.lat.toStringAsFixed(2)}, ${request.location!.lng.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}
