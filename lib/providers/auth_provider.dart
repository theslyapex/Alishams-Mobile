import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../features/notifications/push_notification_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.notice,
    this.requiresMfa = false,
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;
  final String? notice;
  final bool requiresMfa;

  bool get isSignedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    String? notice,
    bool clearUser = false,
    bool clearError = false,
    bool clearNotice = false,
    bool? requiresMfa,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      requiresMfa: requiresMfa ?? this.requiresMfa,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _subscription = _client.auth.onAuthStateChange.listen((event) {
      unawaited(_applySession(event.session));
    });
    final current = _client.auth.currentSession;
    if (current != null) unawaited(_applySession(current));
  }

  final SupabaseClient _client = Supabase.instance.client;
  late final StreamSubscription<dynamic> _subscription;

  Future<void> _applySession(Session? session) async {
    if (session == null) {
      state = const AuthState();
      return;
    }
    try {
      final assurance = await _client.auth.mfa.getAuthenticatorAssuranceLevel();
      final current = assurance.data.currentLevel;
      final next = assurance.data.nextLevel;
      final requiresMfa = next == 'aal2' && current != 'aal2';
      if (!mounted) return;
      state = AuthState(user: _mapUser(session.user), requiresMfa: requiresMfa);
      if (!requiresMfa) {
        unawaited(PushNotificationService.instance.registerForUser());
      }
    } catch (_) {
      if (!mounted) return;
      // Keep the account visible, but sensitive server actions independently
      // enforce AAL2 for users who have enrolled a verified factor.
      state = AuthState(user: _mapUser(session.user));
    }
  }

  AppUser _mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = (metadata['full_name'] ??
            metadata['name'] ??
            user.email?.split('@').first ??
            'کاربر')
        .toString();
    return AppUser(
      id: user.id,
      name: displayName,
      email: user.email ?? '',
    );
  }

  Future<void> _recordSecurityEvent(String event) async {
    try {
      await _client.functions.invoke(
        'mobile-account-security',
        body: {'event': event},
      );
    } catch (_) {
      // Security alerts must never block sign-in or account updates.
    }
  }

  String _friendlyError(Object error) {
    final message = error is AuthException ? error.message : error.toString();
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'ایمیل یا رمز عبور صحیح نیست.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'ابتدا ایمیل خود را تأیید کنید و سپس وارد شوید.';
    }
    if (normalized.contains('user already registered')) {
      return 'این ایمیل قبلاً ثبت‌نام کرده است؛ وارد حساب شوید.';
    }
    if (normalized.contains('password should be at least')) {
      return 'رمز عبور باید حداقل ۶ کاراکتر باشد.';
    }
    if (normalized.contains('rate limit')) {
      return 'تعداد درخواست‌ها زیاد است. کمی بعد دوباره تلاش کنید.';
    }
    return message;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.session == null || response.user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'ورود کامل نشد؛ وضعیت تأیید ایمیل را بررسی کنید.',
          clearUser: true,
        );
        return false;
      }
      final assurance = await _client.auth.mfa.getAuthenticatorAssuranceLevel();
      final requiresMfa = assurance.data.nextLevel == 'aal2' &&
          assurance.data.currentLevel != 'aal2';
      state = AuthState(user: _mapUser(response.user!), requiresMfa: requiresMfa);
      if (!requiresMfa) {
        unawaited(PushNotificationService.instance.registerForUser());
        unawaited(_recordSecurityEvent('login'));
      }
      return true;
    } catch (error) {
      state = AuthState(error: _friendlyError(error));
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'full_name': name.trim()},
      );
      final user = response.user;
      if (user == null) {
        state = const AuthState(
          error: 'ساخت حساب انجام نشد. دوباره تلاش کنید.',
        );
        return false;
      }
      try {
        await _client.from('user_profiles').upsert({
          'user_id': user.id,
          'display_name': name.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (_) {
        // Profile enrichment is non-blocking; Auth remains the source of truth.
      }
      if (response.session == null) {
        state = const AuthState(
          notice: 'حساب ساخته شد. لینک تأیید به ایمیل شما ارسال شد؛ پس از تأیید وارد شوید.',
        );
        return false;
      }
      state = AuthState(user: _mapUser(user));
      unawaited(PushNotificationService.instance.registerForUser());
      unawaited(_recordSecurityEvent('signup'));
      return true;
    } catch (error) {
      state = AuthState(error: _friendlyError(error));
      return false;
    }
  }

  Future<bool> updateProfileName(String name) async {
    final cleanName = name.trim();
    if (cleanName.length < 2 || cleanName.length > 60) {
      state = state.copyWith(error: 'نام باید بین ۲ تا ۶۰ نویسه باشد.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: {'full_name': cleanName}),
      );
      final user = response.user;
      if (user == null) throw const AuthException('به‌روزرسانی حساب انجام نشد.');
      await _client.from('user_profiles').upsert({
        'user_id': user.id,
        'display_name': cleanName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      state = AuthState(user: _mapUser(user), notice: 'نام حساب با موفقیت به‌روزرسانی شد.');
      unawaited(_recordSecurityEvent('profile_updated'));
      return true;
    } catch (error) {
      state = AuthState(user: state.user, error: _friendlyError(error));
      return false;
    }
  }

  Future<bool> updatePassword(String password) async {
    if (password.length < 8) {
      state = state.copyWith(error: 'رمز عبور باید حداقل ۸ نویسه باشد.');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: password),
      );
      final user = response.user;
      if (user == null) throw const AuthException('به‌روزرسانی رمز عبور انجام نشد.');
      state = AuthState(
        user: _mapUser(user),
        notice: 'رمز عبور با موفقیت تغییر کرد.',
      );
      unawaited(_recordSecurityEvent('password_updated'));
      return true;
    } catch (error) {
      state = AuthState(user: state.user, error: _friendlyError(error));
      return false;
    }
  }

  Future<bool> sendResetLink(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearNotice: true);
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      state = state.copyWith(
        isLoading: false,
        notice: 'اگر این ایمیل در سیستم ثبت شده باشد، لینک بازیابی برای آن ارسال می‌شود.',
        clearError: true,
      );
      return true;
    } catch (error) {
      state = AuthState(user: state.user, error: _friendlyError(error));
      return false;
    }
  }

  void completeMfaLogin() {
    final user = state.user;
    state = AuthState(user: user);
    unawaited(PushNotificationService.instance.registerForUser());
    unawaited(_recordSecurityEvent('login'));
  }

  Future<void> signOutOtherSessions() async {
    await _client.auth.signOut(scope: SignOutScope.others);
  }

  void clearError() => state = state.copyWith(clearError: true);
  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterForCurrentUser();
    await _client.auth.signOut();
    state = const AuthState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
