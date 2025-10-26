import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/string_utils.dart';
import '../../alerts/presentation/need_help_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_user.dart';
import '../../contacts/application/contacts_controller.dart';
import '../../contacts/data/models/contact.dart';
import '../../history/application/check_in_controller.dart';
import '../../history/data/models/check_in_stats.dart';
import '../../../shared/theme/theme_controller.dart';
import '../../../shared/settings/settings_controller.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/widgets/three_circles_logo.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/router/app_router.dart';
import '../../../shared/services/preferences_service.dart';

const List<Color> _heroGradientColors = [
  Color(0xFF1E3A8A),
  Color(0xFF2563EB),
  Color(0xFF38BDF8),
];

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
    final checkInStats = ref.watch(checkInControllerProvider).stats;
    final greeting = StringUtils.firstName(user?.name ?? 'Friend');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wellness Circle'),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: _HomeModeTabBar(),
          ),
          actions: [
            _StreakBadge(streak: checkInStats.currentStreak),
            Consumer(
              builder: (context, ref, _) {
                final mode = ref.watch(themeModeProvider);
                final isDark = mode == ThemeMode.dark;
                return IconButton(
                  tooltip: isDark
                      ? 'Switch to light theme'
                      : 'Switch to dark theme',
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).toggleLightDark(),
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final contactsState = ref.watch(contactsControllerProvider);
                final totalMembers = contactsState.contacts.length;
                return IconButton(
                  tooltip: 'Circle updates',
                  onPressed: () {
                    final controller = DefaultTabController.of(context);
                    controller.animateTo(1);
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(LucideIcons.mail),
                      if (totalMembers > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: _CountBadge(count: totalMembers),
                        ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoute.settings.path),
            ),
          ],
        ),
        body: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            _SelfModeView(user: user, greeting: greeting),
            const _CircleModeView(),
          ],
        ),
      ),
    );
  }
}

class _HomeModeTabBar extends StatelessWidget {
  const _HomeModeTabBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const baseBlue = Color(0xFF2563EB);
    final containerColor = baseBlue.withOpacity(0.16);
    final unselected = baseBlue.withOpacity(0.78);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseBlue.withOpacity(0.25)),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return baseBlue.withOpacity(0.2);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return baseBlue.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          labelColor: Colors.white,
          unselectedLabelColor: unselected,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Self'),
            Tab(text: 'Circle'),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBlue = const Color(0xFF2563EB);
    final label = '$streak';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: baseBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseBlue.withOpacity(0.35)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.flame, size: 16, color: baseBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: baseBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : '$count';
    final baseStyle = Theme.of(context).textTheme.labelSmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: (baseStyle ?? const TextStyle(fontSize: 10)).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelfModeView extends ConsumerWidget {
  const _SelfModeView({required this.user, required this.greeting});

  final AuthUser? user;
  final String greeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(checkInControllerProvider);
    final contactsState = ref.watch(contactsControllerProvider);
    final stats = checkInState.stats;
    final isLoading = checkInState.status == CheckInStatus.loading;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < 640) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GreetingCard(user: user, stats: stats, greeting: greeting),
                const SizedBox(height: 18),
                SizedBox(height: 140, child: _CountdownPanel(stats: stats)),
                const SizedBox(height: 18),
                _ActionButtons(isLoading: isLoading, ref: ref),
                const SizedBox(height: 18),
                SizedBox(
                  height: 60,
                  child: _StatsGrid(
                    contactsCount: contactsState.contacts.length,
                  ),
                ),
              ],
            ),
          );
        }
        final isRoomy = constraints.maxHeight > 780;
        final gap = isRoomy ? 18.0 : 12.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GreetingCard(user: user, stats: stats, greeting: greeting),
              SizedBox(height: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _CountdownPanel(stats: stats)),
                    SizedBox(height: gap),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: isRoomy ? 150 : 132,
                      ),
                      child: _ActionButtons(isLoading: isLoading, ref: ref),
                    ),
                    SizedBox(height: gap),
                    SizedBox(
                      height: 60,
                      child: _StatsGrid(
                        contactsCount: contactsState.contacts.length,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleModeView extends ConsumerWidget {
  const _CircleModeView();

  Future<void> _callContact(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This member has no phone number listed.'),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: trimmed);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to open your dialer for $trimmed')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsState = ref.watch(contactsControllerProvider);
    final preferredId = ref.watch(preferredContactProvider);
    final contacts = contactsState.contacts;

    final content = <Widget>[
      _CircleModeHeader(memberCount: contacts.length),
      const SizedBox(height: 16),
    ];

    if (contactsState.status == ContactsStatus.loading && contacts.isEmpty) {
      content.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else if (contacts.isEmpty) {
      content.add(const _EmptyCircleState());
    } else {
      for (var i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        final isPreferred = preferredId != null && preferredId == contact.id;
        content.add(
          _CircleMemberCard(
            contact: contact,
            isPreferred: isPreferred,
            onCall: () => _callContact(context, contact.phone),
          ),
        );
        if (i != contacts.length - 1) {
          content.add(const SizedBox(height: 12));
        }
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(contactsControllerProvider.notifier).refresh();
      },
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: content,
      ),
    );
  }
}

class _CircleModeHeader extends StatelessWidget {
  const _CircleModeHeader({required this.memberCount});

  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: _heroGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(LucideIcons.users, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Circle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memberCount == 0
                      ? 'Invite loved ones to stay connected and informed.'
                      : 'You\'re checking in on $memberCount ${memberCount == 1 ? 'member' : 'members'}. Keep them close.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCircleState extends StatelessWidget {
  const _EmptyCircleState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: _heroGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No circle members yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add trusted contacts in Settings → Family contacts to build your support circle.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleMemberCard extends StatelessWidget {
  const _CircleMemberCard({
    required this.contact,
    required this.isPreferred,
    required this.onCall,
  });

  final Contact contact;
  final bool isPreferred;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = contact.name.trim();
    final initials = trimmedName.isEmpty ? '?' : trimmedName[0].toUpperCase();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _heroGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
              ),
              padding: const EdgeInsets.all(18),
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trimmedName.isEmpty ? 'Unnamed contact' : trimmedName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (isPreferred)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Preferred',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contact.phone,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added ${DateFormatting.relative(contact.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
              ),
              onPressed: onCall,
              icon: const Icon(LucideIcons.phone),
              label: const Text('Call'),
            ),
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
  Duration get _currentDuration =>
      Duration(hours: ref.read(timerHoursProvider));

  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _alertShown = false;
  ProviderSubscription<int>? _restartSub;
  ProviderSubscription<int>? _timerHoursSub;
  late final PreferencesService _prefs;
  static const String _kEndAtKey = 'wellcheck.countdown.end_at';
  DateTime? _endAt;
  void _scheduleUnlockAndReminders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(checkInLockProvider.notifier).unlock();
      unawaited(
        ref
            .read(notificationsServiceProvider)
            .startMinuteReminder(
              title: 'Time to check in',
              body: 'Tap the app and confirm: I am doing Great!',
            ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _prefs = ref.read(preferencesServiceProvider);
    _bootstrapFromPersistedEndTime();
    // Listen for external restart requests (e.g., when user taps "I am up").
    _restartSub = ref.listenManual<int>(countdownRestartProvider, (
      previous,
      next,
    ) {
      _resetTimer();
    });
    // Restart timer when settings change the hours value.
    _timerHoursSub = ref.listenManual<int>(timerHoursProvider, (
      previous,
      next,
    ) {
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
    final now = DateTime.now();
    final end = now.add(_currentDuration);
    _endAt = end;
    // Persist target end time so countdown continues across background/terminations.
    unawaited(
      _prefs.setString(_kEndAtKey, end.millisecondsSinceEpoch.toString()),
    );
    _remaining = end.difference(now);
    _alertShown = false;
    _cancelTimer();
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      // Recompute remaining from persisted endAt to keep accurate while backgrounded.
      var end = _endAt;
      if (end == null) {
        end = now.add(_currentDuration);
        _endAt = end;
        unawaited(
          _prefs.setString(_kEndAtKey, end.millisecondsSinceEpoch.toString()),
        );
      }
      _remaining = end.difference(now);
      if (_remaining <= const Duration(seconds: 1)) {
        _remaining = Duration.zero;
        timer.cancel();
        _timer = null;
        if (!_alertShown && mounted) {
          _alertShown = true;
          // Prompt the user to press the green primary button below.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Time to check in! Press the rich green 'I am up' button.",
              ),
            ),
          );
        }
        // Unlock the check-in button when timer completes.
        ref.read(checkInLockProvider.notifier).unlock();
        // Start minute-by-minute reminder notifications until the user checks in.
        unawaited(
          ref
              .read(notificationsServiceProvider)
              .startMinuteReminder(
                title: 'Time to check in',
                body: 'Tap the app and confirm: I am doing Great!',
              ),
        );
        // Auto-restart countdown for the next cycle using current settings.
        setState(() {
          final nextEnd = now.add(_currentDuration);
          _endAt = nextEnd;
          unawaited(
            _prefs.setString(
              _kEndAtKey,
              nextEnd.millisecondsSinceEpoch.toString(),
            ),
          );
          _remaining = nextEnd.difference(now);
          _alertShown = false;
        });
        _startTimer();
      } else {
        setState(() {});
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _bootstrapFromPersistedEndTime() {
    final saved = _prefs.getString(_kEndAtKey);
    final dur = _currentDuration;
    final now = DateTime.now();
    if (saved != null) {
      final ms = int.tryParse(saved);
      if (ms != null) {
        var end = DateTime.fromMillisecondsSinceEpoch(ms);
        // If past, advance by whole cycles to the next end time, matching auto-restart behavior.
        if (!end.isAfter(now) && dur > Duration.zero) {
          final spanSec = dur.inSeconds;
          final diffSec = now.difference(end).inSeconds;
          final cycles = (diffSec ~/ spanSec) + 1;
          // Unlock and start reminders since at least one cycle completed while backgrounded.
          _scheduleUnlockAndReminders();
          end = end.add(Duration(seconds: cycles * spanSec));
        }
        _endAt = end;
        unawaited(
          _prefs.setString(_kEndAtKey, end.millisecondsSinceEpoch.toString()),
        );
        _remaining = end.difference(now);
        _alertShown = false;
        _cancelTimer();
        _startTimer();
        setState(() {});
        return;
      }
    }
    // Fallback: no persisted time; start a fresh countdown.
    _resetTimer();
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: Text(
            _format(_remaining),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              // Improve contrast in dark mode
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.onSurface.withOpacity(0.95)
                  : AppColors.textPrimary,
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
        gradient: const LinearGradient(
          colors: _heroGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.14),
                ),
                padding: const EdgeInsets.all(8),
                child: const ThreeCirclesLogo(
                  size: 48,
                  color: Colors.white,
                  strokeWidth: 4,
                  overlap: 16,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellness Circle',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modern wellbeing for every season of life.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hi $greeting',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep up the great work—your wellbeing matters daily.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (stats.lastCheckIn != null)
                _Chip(
                  icon: LucideIcons.clock3,
                  label:
                      'Last: ${DateFormatting.relative(stats.lastCheckIn!.timestamp)}',
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.isLoading, required this.ref});

  final bool isLoading;
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
                          await ref
                              .read(checkInControllerProvider.notifier)
                              .recordCheckIn();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Great job! Your check-in was saved.',
                                ),
                              ),
                            );
                          }
                          ref.read(checkInLockProvider.notifier).lock();
                          ref.read(countdownRestartProvider.notifier).bump();
                          // Stop reminder notifications upon check-in.
                          unawaited(
                            ref
                                .read(notificationsServiceProvider)
                                .cancelReminders(),
                          );
                        },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 96,
                    constraints: const BoxConstraints(minWidth: 96),
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
                  height: 96,
                  constraints: const BoxConstraints(minWidth: 96),
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
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            minimumSize: const Size.fromHeight(60),
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
  const _StatsGrid({required this.contactsCount});

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
    // Use preferred contact if selected, else first.
    final preferredId = ref.read(preferredContactProvider);
    final target = preferredId == null
        ? contactsState.contacts.first
        : (contactsState.contacts.firstWhere(
            (c) => c.id == preferredId,
            orElse: () => contactsState.contacts.first,
          ));
    final phone = target.phone.trim();
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
    final contactsState = ref.watch(contactsControllerProvider);
    final hasContact = contactsState.contacts.isNotEmpty;
    final preferredId = ref.watch(preferredContactProvider);
    final primary = hasContact
        ? (preferredId == null
              ? contactsState.contacts.first
              : (contactsState.contacts.firstWhere(
                  (c) => c.id == preferredId,
                  orElse: () => contactsState.contacts.first,
                )))
        : null;
    final cardLabel = hasContact
        ? 'Call ${primary!.name}'
        : 'Call a family member';
    final cardValue = hasContact ? primary!.phone : contactsCount.toString();

    final buttonLabel = hasContact ? 'Call ${primary!.name}' : cardLabel;
    final subtitle = hasContact ? ' • $cardValue' : '';

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        minimumSize: const Size.fromHeight(60),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _callFirstContact(context, ref),
      icon: const Icon(LucideIcons.phone),
      label: Text(
        '$buttonLabel$subtitle',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
