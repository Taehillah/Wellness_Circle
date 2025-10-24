import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_view.dart';
import '../../features/auth/presentation/register_view.dart';
import '../../features/auth/presentation/splash_view.dart';
import '../../features/contacts/presentation/contacts_view.dart';
import '../../features/dashboard/presentation/dashboard_view.dart';
import '../../features/history/presentation/history_view.dart';
import '../../features/home/presentation/home_view.dart';

enum AppRoute {
  splash('/splash'),
  login('/auth/login'),
  register('/auth/register'),
  home('/home'),
  contacts('/contacts'),
  history('/history'),
  dashboard('/dashboard');

  const AppRoute(this.path);
  final String path;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isAuthenticated = authState.isAuthenticated;
  final status = authState.status;

  return GoRouter(
    initialLocation: AppRoute.splash.path,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoute.register.path,
        name: AppRoute.register.name,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: AppRoute.contacts.path,
        name: AppRoute.contacts.name,
        builder: (context, state) => const ContactsView(),
      ),
      GoRoute(
        path: AppRoute.history.path,
        name: AppRoute.history.name,
        builder: (context, state) => const HistoryView(),
      ),
      GoRoute(
        path: AppRoute.dashboard.path,
        name: AppRoute.dashboard.name,
        builder: (context, state) => const DashboardView(),
      ),
    ],
    redirect: (context, state) {
      final atAuthRoute = state.matchedLocation == AppRoute.login.path ||
          state.matchedLocation == AppRoute.register.path;

      if (status == AuthStatus.restoring) {
        return state.matchedLocation == AppRoute.splash.path
            ? null
            : AppRoute.splash.path;
      }

      if (!isAuthenticated) {
        if (atAuthRoute) {
          return null;
        }
        return AppRoute.login.path;
      }

      if (isAuthenticated && (state.matchedLocation == AppRoute.splash.path || atAuthRoute)) {
        return AppRoute.home.path;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Something went wrong: ${state.error}'),
      ),
    ),
  );
});
