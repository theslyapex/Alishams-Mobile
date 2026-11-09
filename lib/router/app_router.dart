import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/mfa_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/notifications/push_notification_service.dart';
import '../motion/motion.dart';
import '../providers/auth_provider.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isSignedIn != next.isSignedIn ||
        previous?.requiresMfa != next.requiresMfa ||
        previous?.isLoading != next.isLoading) {
      refreshNotifier.refresh();
    }
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: pushNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;
      const publicPaths = {'/', '/sign-in', '/sign-up', '/forgot-password'};
      const authPaths = {'/sign-in', '/sign-up', '/forgot-password'};

      // Wait until the persisted Supabase session and its AAL are resolved.
      if (auth.isLoading) return null;

      if (auth.requiresMfa) {
        return path == '/mfa-verify' ? null : '/mfa-verify';
      }

      if (auth.isSignedIn) {
        if (authPaths.contains(path) || path == '/mfa-verify' || path == '/') {
          return '/home';
        }
        return null;
      }

      if (!publicPaths.contains(path) && path != '/mfa-verify') {
        return '/sign-in';
      }
      if (path == '/mfa-verify') return '/sign-in';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'splash',
          to: 'splash',
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'splash',
          to: 'sign_in',
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'sign_in',
          to: 'sign_up',
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'sign_in',
          to: 'forgot_password',
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/mfa-verify',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'sign_in',
          to: 'mfa_verify',
          child: const MfaVerifyScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => motionPage(
          state,
          from: 'sign_in',
          to: 'home',
          child: const HomeScreen(),
        ),
      ),
    ],
  );
});
