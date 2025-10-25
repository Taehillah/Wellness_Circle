import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/string_utils.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../alerts/presentation/need_help_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_user.dart';
import '../../contacts/application/contacts_controller.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../../history/application/check_in_controller.dart';
import '../../history/data/models/check_in_stats.dart';
import '../../../shared/theme/theme_controller.dart';
import '../../../shared/settings/settings_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/router/app_router.dart';

// Triggers a restart of the countdown timer when incremented.
class _CountdownRestart extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final countdownRestartProvider = NotifierProvider<_CountdownRestart, int>(
  _CountdownRestart.new,
);

// Lock state for the "I am up" button. Locked immediately after pressing,
// then unlocked when the countdown expires.
class _CheckInLock extends Notifier<bool> {
  @override
  bool build() => false; // start unlocked

  void lock() => state = true;
  void unlock() => state = false;
}

final checkInLockProvider = NotifierProvider<_CheckInLock, bool>(
  _CheckInLock.new,
);

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
          Consumer(builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider);
            final isDark = mode == ThemeMode.dark;
            return IconButton(
              tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
            );
          }),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRoute.settings.path),
          ),
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
            // Countdown panel sits just below the top greeting card.
            const SizedBox(height: 16),
            _CountdownPanel(stats: stats),
            const SizedBox(height: 24),
            _ActionButtons(isLoading: isLoading, stats: stats, ref: ref),
            const SizedBox(height: 24),
            _StatsGrid(stats: stats, contactsCount: contactsState.contacts.length),
            const SizedBox(height: 24),
            _RecentCheckIns(historyState: checkInState),
          ],
        ),
      ),
    );
  }
}

class _CountdownPanel extends ConsumerStatefulWidget {
  const _CountdownPanel({required this.stats});

  final CheckInStats stats;

  @override
  ConsumerState<_CountdownPanel> createState() => _CountdownPanelState();
}

class _CountdownPanelState extends ConsumerState<_CountdownPanel> {
  // Use ref.read here; watching in initState triggers inherited access errors.
  Duration get _currentDuration => Duration(hours: ref.read(timerHoursProvider));

  late Duration _remaining;
  Timer? _timer;
  bool _alertShown = false;
  ProviderSubscription<int>? _restartSub;
  ProviderSubscription<int>? _timerHoursSub;

  @override
  void initState() {
    super.initState();
    _resetTimer();
    // Listen for external restart requests (e.g., when user taps "I am up").
    _restartSub = ref.listenManual<int>(countdownRestartProvider, (previous, next) {
      _resetTimer();
    });
    // Restart timer when settings change the hours value.
    _timerHoursSub = ref.listenManual<int>(timerHoursProvider, (previous, next) {
      _resetTimer();
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep timer running regardless of check-in status; restart if needed.
    if (_timer == null && _remaining > Duration.zero) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    _restartSub?.close();
    _timerHoursSub?.close();
    super.dispose();
  }

  void _resetTimer() {
    _remaining = _currentDuration;
    _alertShown = false;
    _cancelTimer();
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= const Duration(seconds: 1)) {
        _remaining = Duration.zero;
        timer.cancel();
        _timer = null;
        if (!_alertShown && mounted) {
          _alertShown = true;
          // Prompt the user to press the green primary button below.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Time to check in! Press the rich green 'I am up' button."),
            ),
          );
        }
        // Unlock the check-in button when timer completes.
        ref.read(checkInLockProvider.notifier).unlock();
        // Auto-restart countdown for the next cycle using current settings.
        setState(() {
          _remaining = _currentDuration;
          _alertShown = false;
        });
        _startTimer();
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Center(
          child: Text(
            _format(_remaining),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
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
        // Solid modern blue background for the top panel
        color: const Color(0xFF2563EB), // rich modern blue
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
    final locked = ref.watch(checkInLockProvider);
    final disabled = isLoading || locked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Two circular action buttons side-by-side
        Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: disabled ? 0.6 : 1.0,
                child: InkWell(
                  onTap: disabled
                      ? null
                      : () async {
                          await ref.read(checkInControllerProvider.notifier).recordCheckIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Great job! Your check-in was saved.')),
                            );
                          }
                          ref.read(checkInLockProvider.notifier).lock();
                          ref.read(countdownRestartProvider.notifier).bump();
                        },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 100,
                    constraints: const BoxConstraints(minWidth: 100),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A), // rich green
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'I am doing\nGreat!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _openNeedHelpSheet(context),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 100,
                  constraints: const BoxConstraints(minWidth: 100),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B), // orange
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'I am not\nfeeling well',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size.fromHeight(64),
            // Rich red
            backgroundColor: const Color(0xFFB91C1C),
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

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.stats, required this.contactsCount});

  final CheckInStats stats;
  final int contactsCount;

  Future<void> _callFirstContact(BuildContext context, WidgetRef ref) async {
    final contactsState = ref.read(contactsControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (contactsState.contacts.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No family contacts available to call.')),
      );
      return;
    }
    final phone = contactsState.contacts.first.phone.trim();
    if (phone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selected contact has no phone number.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Cannot launch dialer for $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: 1,
          shrinkWrap: true,
          childAspectRatio: isWide ? 2.5 : 3.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Removed 'Current streak' and 'This week' per request.
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _callFirstContact(context, ref),
              child: StatCard(
                label: 'Call a family member',
                value: contactsCount.toString(),
                icon: LucideIcons.phone,
                backgroundColor: const Color(0xFF2563EB), // solid blue
                foregroundColor: Colors.white,
              ),
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

// Quick actions section removed per request.
