import 'package:riverpod/riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/circle_repository.dart';
import '../data/models/circle_overview.dart';

final currentCircleIdProvider = Provider<String>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    return 'circle-demo';
  }
  return 'circle-${session.user.id}';
});

final circleOverviewProvider = StreamProvider<CircleOverview>((ref) {
  final circleId = ref.watch(currentCircleIdProvider);
  final repository = ref.watch(circleRepositoryProvider);
  return repository.watchOverview(circleId: circleId);
});
