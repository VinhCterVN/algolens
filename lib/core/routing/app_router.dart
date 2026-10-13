import 'package:algolens/core/theme/app_motion.dart';
import 'package:algolens/features/authentication/data/auth_repository_provider.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_session_controller.dart';
import 'package:algolens/features/authentication/presentation/views/forgot_password_view.dart';
import 'package:algolens/features/authentication/presentation/views/register_view.dart';
import 'package:algolens/features/authentication/presentation/views/sign_in_view.dart';
import 'package:algolens/features/home/presentation/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final refresh = ValueNotifier(0);
  ref.listen(authSessionProvider, (_, next) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final path = state.uri.path;
      final authRoute = ['/login', '/register', '/forgot-password'].contains(path);
      if (session.isRecovering && session.isSignedIn) {
        return path == '/forgot-password' ? null : '/forgot-password';
      }
      if (!session.isSignedIn) return authRoute ? null : '/login';
      return authRoute || path == '/' ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/login', pageBuilder: (context, state) => _authPage(context, state, const SignInView())),
      GoRoute(path: '/register', pageBuilder: (context, state) => _authPage(context, state, const RegisterView())),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _authPage(context, state, const ForgotPasswordView()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeView(repository: repository),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

Page<void> _authPage(BuildContext context, GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: AppMotion.duration(context, AppMotion.page),
  reverseTransitionDuration: AppMotion.duration(context, AppMotion.fast),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (AppMotion.reduced(context)) return child;
    final eased = animation.drive(CurveTween(curve: AppMotion.curve));
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(begin: AppMotion.pageOffset, end: Offset.zero).animate(eased),
        child: child,
      ),
    );
  },
);
