import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/router/app_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../alerts/presentation/need_help_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_user.dart';
import '../../contacts/application/contacts_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../history/application/check_in_controller.dart';
import '../../history/data/models/check_in_stats.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final checkInState = ref.watch(checkInControllerProvider);
    final contactsState = ref.watch(contactsControllerProvider);

    final stats = checkInState.stats;
    final isLoading = checkInState.status == CheckInStatus.loading;
    final greeting = StringUtils.firstName(user?.name ?? 'Friend');

    return Scaffold(
      appBar: AppBar(
        title: const Text('WellCheck'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(checkInControllerProvider.notifier).refresh();
          await ref.read(contactsControllerProvider.notifier).refresh();
          await ref.read(dashboardControllerProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _GreetingCard(user: user, stats: stats, greeting: greeting),
            const SizedBox(height: 24),
            _ActionButtons(isLoading: isLoading, stats: stats, ref: ref),
            const SizedBox(height: 24),
            _StatsGrid(stats: stats, contactsCount: contactsState.contacts.length),
            const SizedBox(height: 24),
            _RecentCheckIns(historyState: checkInState),
            const SizedBox(height: 24),
            _NavigationShortcuts(user: user),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.user,
    required this.stats,
    required this.greeting,
  });

  final AuthUser? user;
  final CheckInStats stats;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi $greeting',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep up the great work! Your wellbeing matters every day.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _Chip(
                icon: LucideIcons.flame,
                label: 'Streak: ${stats.currentStreak} days',
              ),
              if (user?.location != null && user!.location!.isNotEmpty)
                _Chip(
                  icon: LucideIcons.mapPin,
                  label: user!.location!,
                ),
              _Chip(
                icon: LucideIcons.clock3,
                label: stats.lastCheckIn == null
                    ? 'No check-ins yet'
                    : 'Last: ${DateFormatting.relative(stats.lastCheckIn!.timestamp)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isLoading,
    required this.stats,
    required this.ref,
  });

  final bool isLoading;
  final CheckInStats stats;
  final WidgetRef ref;

  void _openNeedHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const NeedHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = stats.hasCheckedInToday || isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: stats.hasCheckedInToday ? 'Checked in today' : 'I\'m doing well',
          isLoading: isLoading,
          onPressed: disabled
              ? null
              : () async {
                  await ref.read(checkInControllerProvider.notifier).recordCheckIn();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Great job! Your check-in was saved.')),
                    );
                  }
                },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _openNeedHelpSheet(context),
          icon: const Icon(LucideIcons.siren),
          label: const Text('Need help now'),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.contactsCount});

  final CheckInStats stats;
  final int contactsCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          shrinkWrap: true,
          childAspectRatio: isWide ? 2.5 : 3.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
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
              subtitle: 'Keep up the momentum!',
              icon: LucideIcons.calendarClock,
            ),
            StatCard(
              label: 'Emergency contacts',
              value: contactsCount.toString(),
              icon: LucideIcons.users,
            ),
          ],
        );
      },
    );
  }
}

class _RecentCheckIns extends StatelessWidget {
  const _RecentCheckIns({required this.historyState});

  final CheckInState historyState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = historyState.history.take(5).toList();
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
                  'Recent check-ins',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (historyState.status == CheckInStatus.loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Text('No check-ins yet. Tap “I\'m doing well” to start your streak!')
            else
              ...history.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.sparkles, color: AppColors.primary),
                  title: Text(DateFormatting.full(entry.timestamp)),
                  subtitle: Text(DateFormatting.relative(entry.timestamp)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationShortcuts extends ConsumerWidget {
  const _NavigationShortcuts({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = user?.isAdmin ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ShortcutButton(
                  label: 'Contacts',
                  icon: LucideIcons.users,
                  onTap: () => context.go(AppRoute.contacts.path),
                ),
                _ShortcutButton(
                  label: 'History',
                  icon: LucideIcons.history,
                  onTap: () => context.go(AppRoute.history.path),
                ),
                if (isAdmin)
                  _ShortcutButton(
                    label: 'Dashboard',
                    icon: LucideIcons.layoutDashboard,
                    onTap: () {
                      ref.read(dashboardControllerProvider.notifier).load();
                      context.go(AppRoute.dashboard.path);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.neutralBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
