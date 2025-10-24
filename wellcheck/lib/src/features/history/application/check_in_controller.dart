import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/data/seed_data.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_session.dart';
import '../data/check_in_repository.dart';
import '../data/models/check_in_entry.dart';
import '../data/models/check_in_stats.dart';

class CheckInState {
  const CheckInState({
    required this.history,
    required this.stats,
    required this.status,
    this.errorMessage,
  });

  final List<CheckInEntry> history;
  final CheckInStats stats;
  final CheckInStatus status;
  final String? errorMessage;

  bool get hasCheckedInToday => stats.hasCheckedInToday;

  CheckInState copyWith({
    List<CheckInEntry>? history,
    CheckInStats? stats,
    CheckInStatus? status,
    String? errorMessage,
  }) {
    return CheckInState(
      history: history ?? this.history,
      stats: stats ?? this.stats,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  factory CheckInState.initial() => CheckInState(
        history: const [],
        stats: const CheckInStats(
          total: 0,
          currentStreak: 0,
          thisWeek: 0,
          lastCheckIn: null,
          hasCheckedInToday: false,
        ),
        status: CheckInStatus.idle,
      );
}

enum CheckInStatus { idle, loading, ready, error }

class CheckInController extends Notifier<CheckInState> {
  late final CheckInRepository _repository;
  final _uuid = const Uuid();

  AuthSession? _session;

  @override
  CheckInState build() {
    _repository = ref.read(checkInRepositoryProvider);
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      unawaited(onSessionChanged(next));
    }, fireImmediately: true);
    return CheckInState.initial();
  }

  Future<void> onSessionChanged(AuthSession? session) async {
    _session = session;
    if (session == null) {
      state = CheckInState.initial();
      return;
    }
    state = state.copyWith(status: CheckInStatus.loading, errorMessage: null);
    try {
      final seeded = _buildSeededEntries(session.user.email);
      final history = await _repository.loadHistory(
        userId: session.user.id,
        seeded: seeded,
      );
      _emit(history);
    } catch (error) {
      state = state.copyWith(
        status: CheckInStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> recordCheckIn() async {
    final session = _session;
    if (session == null) {
      return;
    }
    if (state.stats.hasCheckedInToday) {
      return;
    }
    state = state.copyWith(status: CheckInStatus.loading);
    try {
      final updatedHistory = [...state.history];
      final entry = await _repository.addCheckIn(
        userId: session.user.id,
        currentHistory: updatedHistory,
      );
      updatedHistory.add(entry);
      _emit(updatedHistory);
    } catch (error) {
      state = state.copyWith(
        status: CheckInStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    final session = _session;
    if (session == null) {
      return;
    }
    state = state.copyWith(status: CheckInStatus.loading);
    try {
      final history = await _repository.loadHistory(
        userId: session.user.id,
      );
      _emit(history);
    } catch (error) {
      state = state.copyWith(
        status: CheckInStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  List<CheckInEntry> _buildSeededEntries(String email) {
    if (!SeedData.shouldSeed(email)) {
      return const [];
    }
    return SeedData.seededCheckIns(email)
        .map(
          (date) => CheckInEntry(
            id: _uuid.v4(),
            timestamp: date,
          ),
        )
        .toList();
  }

  void _emit(List<CheckInEntry> history) {
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final stats = CheckInStats.fromHistory(history);
    state = state.copyWith(
      history: history,
      stats: stats,
      status: CheckInStatus.ready,
      errorMessage: null,
    );
  }
}

final checkInControllerProvider =
    NotifierProvider<CheckInController, CheckInState>(CheckInController.new);
