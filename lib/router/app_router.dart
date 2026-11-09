import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/notifications/push_notification_service.dart';
import '../motion/motion.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: pushNavigatorKey,
    initialLocation: '/',
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
