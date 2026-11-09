import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../notifications/notifications_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authProvider.notifier).updatePassword(_password.text);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'رمز عبور با موفقیت تغییر کرد.' : (auth.error ?? 'تغییر رمز عبور انجام نشد.')),
      ),
    );
    if (ok) {
      _password.clear();
      _confirm.clear();
    }
  }

  Future<void> _sendResetLink() async {
    final email = ref.read(authProvider).user?.email ?? '';
    if (email.isEmpty) return;
    final ok = await ref.read(authProvider.notifier).sendResetLink(email);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'اگر این ایمیل در سامانه ثبت شده باشد، لینک بازیابی برای آن ارسال می‌شود.'
            : (auth.error ?? 'ارسال لینک بازیابی انجام نشد.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = ref.watch(authProvider);
    final email = auth.user?.email ?? '—';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('حریم خصوصی و امنیت'),
          backgroundColor: c.background,
          foregroundColor: c.ink,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: c.success, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حساب شما محافظت می‌شود', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text('برای تغییرات مهم حساب، اعلان امنیتی ثبت می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('حساب متصل', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: c.secondary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(email, textDirection: TextDirection.ltr, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('تغییر رمز عبور', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('رمز جدید باید حداقل ۸ نویسه داشته باشد.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
              const SizedBox(height: 14),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'رمز عبور جدید',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 8 ? 'رمز عبور باید حداقل ۸ نویسه باشد.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscureConfirm,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'تکرار رمز عبور جدید',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => value != _password.text ? 'تکرار رمز عبور یکسان نیست.' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: auth.isLoading ? null : _changePassword,
                        icon: const Icon(Icons.security_rounded),
                        label: Text(auth.isLoading ? 'در حال ذخیره…' : 'ذخیره رمز عبور جدید'),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: auth.isLoading ? null : _sendResetLink,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('ارسال لینک بازیابی به ایمیل'),
              ),
              const SizedBox(height: 26),
              Text('فعالیت‌های امنیتی', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('ورودها و تغییرات مهم حساب در مرکز اعلان‌ها ثبت می‌شوند.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.5)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(initialCategory: 'account'),
                )),
                icon: const Icon(Icons.history_rounded),
                label: const Text('مشاهده اعلان‌ها و فعالیت‌ها'),
              ),
              const SizedBox(height: 18),
              Text(
                'برای حفظ امنیت، رمز عبور خود را در اختیار دیگران قرار ندهید.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
