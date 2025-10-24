import 'package:riverpod/riverpod.dart';

import '../../alerts/data/alerts_repository.dart';
import '../../alerts/data/models/help_request.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/auth_session.dart';

class DashboardState {
  const DashboardState({
    required this.isLoading,
    required this.helpRequests,
    this.errorMessage,
  });

  final bool isLoading;
  final List<HelpRequest> helpRequests;
  final String? errorMessage;

  DashboardState copyWith({
    bool? isLoading,
    List<HelpRequest>? helpRequests,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      helpRequests: helpRequests ?? this.helpRequests,
      errorMessage: errorMessage,
    );
  }

  factory DashboardState.initial() => const DashboardState(
        isLoading: false,
        helpRequests: [],
      );
}

class DashboardController extends Notifier<DashboardState> {
  late final AlertsRepository _alertsRepository;
  AuthSession? _session;

  @override
  DashboardState build() {
    _alertsRepository = ref.read(alertsRepositoryProvider);
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      onSessionChanged(next);
    }, fireImmediately: true);
    return DashboardState.initial();
  }

  void onSessionChanged(AuthSession? session) {
    _session = session;
    if (session?.user.isAdmin != true) {
      state = DashboardState.initial();
    } else {
      load();
    }
  }

  Future<void> load() async {
    final session = _session;
    if (session?.user.isAdmin != true) {
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final requests = await _alertsRepository.fetchRecentRequests();
      state = state.copyWith(
        isLoading: false,
        helpRequests: requests,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);
