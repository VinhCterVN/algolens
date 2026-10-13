import 'package:algolens/features/authentication/data/auth_repository.dart';
import 'package:algolens/features/authentication/presentation/view_models/auth_session_controller.dart';
import 'package:algolens/features/authentication/presentation/views/forgot_password_view.dart';
import 'package:algolens/features/authentication/presentation/views/register_view.dart';
import 'package:algolens/features/authentication/presentation/views/sign_in_view.dart';
import 'package:algolens/features/home/presentation/views/home_view.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(AuthRepository repository, AuthSessionController session) => GoRouter(
  initialLocation: '/home',
  refreshListenable: session,
  redirect: (context, state) {
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
    GoRoute(
      path: '/login',
      builder: (context, state) => SignInView(repository: repository),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterView(repository: repository),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordView(repository: repository, session: session),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => HomeView(repository: repository),
    ),
  ],
);
