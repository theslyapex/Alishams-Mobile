import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});
  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _code = TextEditingController();
  String? _factorId;
  String? _qr;
  String? _secret;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<dynamic> _factors = [];

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _client.auth.mfa.listFactors();
      if (!mounted) return;
      setState(() {
        _factors = result.data.totp.where((f) => f.status == FactorStatus.verified).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'وضعیت تأیید دومرحله‌ای دریافت نشد.'; });
    }
  }

  Future<void> _beginEnrollment() async {
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: 'ALISHAMS Authenticator',
      );
      if (!mounted) return;
      setState(() {
        _factorId = result.id;
        _qr = result.totp?.qrCode;
        _secret = result.totp?.secret;
        _busy = false;
      });
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'ساخت کد اتصال انجام نشد. دوباره تلاش کنید.'; });
    }
  }

  Future<void> _verifyEnrollment() async {
    final factorId = _factorId;
    final code = _code.text.trim();
    if (factorId == null || !RegExp(r'^\d{6}).hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی برنامه احراز هویت را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);
      await _client.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
      if (!mounted) return;
      _code.clear();
      setState(() { _factorId = null; _qr = null; _secret = null; _busy = false; });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأیید دومرحله‌ای فعال شد.')));
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'کد تأیید معتبر نیست یا منقضی شده است.'; });
    }
  }

  Future<void> _removeFactor(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('غیرفعال‌سازی تأیید دومرحله‌ای'),
        content: const Text('پس از غیرفعال‌سازی، ورود با رمز عبور به‌تنهایی انجام می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('غیرفعال‌سازی')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _client.auth.mfa.unenroll(id);
      await _client.auth.refreshSession();
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'برای غیرفعال‌سازی، ابتدا ورود دومرحله‌ای همین نشست را تکمیل کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('تأیید دومرحله‌ای'), backgroundColor: c.background, foregroundColor: c.ink),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('ورود امن‌تر با برنامه احراز هویت', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text('پس از فعال‌سازی، هنگام ورود علاوه بر رمز عبور باید کد موقت برنامه احراز هویت را وارد کنید.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.6)),
              const SizedBox(height: 18),
              if (_loading) const Center(child: CircularProgressIndicator())
              else if (_factors.isNotEmpty)
                ..._factors.map((factor) => Card(
                  color: c.surface,
                  child: ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: c.success),
                    title: const Text('تأیید دومرحله‌ای فعال است'),
                    subtitle: Text(factor.friendlyName ?? 'برنامه احراز هویت'),
                    trailing: IconButton(onPressed: _busy ? null : () => _removeFactor(factor.id), icon: Icon(Icons.delete_outline_rounded, color: c.danger)),
                  ),
                ))
              else if (_factorId == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _beginEnrollment,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(_busy ? 'در حال آماده‌سازی…' : 'فعال‌سازی تأیید دومرحله‌ای'),
                )
              else ...[
                if (_qr != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: SvgPicture.string(_qr!, height: 220, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 12),
                Text('اگر امکان اسکن QR را ندارید، این کلید را دستی در برنامه احراز هویت وارد کنید:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
                const SizedBox(height: 8),
                SelectableText(_secret ?? '', textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                TextButton.icon(
                  onPressed: _secret == null ? null : () => Clipboard.setData(ClipboardData(text: _secret!)),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کپی کلید'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'کد شش‌رقمی برنامه', counterText: ''),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _verifyEnrollment,
                  child: Text(_busy ? 'در حال بررسی…' : 'تأیید و فعال‌سازی'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: c.danger)),
              ],
              const SizedBox(height: 18),
              Text('کدهای موقت هر ۳۰ ثانیه تغییر می‌کنند. کلید اتصال را در اختیار دیگران قرار ندهید.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class MfaVerifyScreen extends ConsumerStatefulWidget {
  const MfaVerifyScreen({super.key});
  @override
  ConsumerState<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends ConsumerState<MfaVerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\\d{6}$').hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final factors = await client.auth.mfa.listFactors();
      final verified = factors.data.totp.where((f) => f.status == FactorStatus.verified).toList();
      if (verified.isEmpty) throw Exception('No verified factor');
      final factor = verified.first;
      final challenge = await client.auth.mfa.challenge(factorId: factor.id);
      await client.auth.mfa.verify(factorId: factor.id, challengeId: challenge.id, code: code);
      ref.read(authProvider.notifier).completeMfaLogin();
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'کد واردشده صحیح نیست. کد جدید برنامه را وارد کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('تأیید ورود'), backgroundColor: c.background, foregroundColor: c.ink),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.lock_person_rounded, size: 56, color: c.secondary),
              const SizedBox(height: 16),
              Text('کد تأیید دومرحله‌ای', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('کد شش‌رقمی برنامه احراز هویت را وارد کنید تا وارد حساب شوید.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
              const SizedBox(height: 22),
              TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'کد یک‌بارمصرف', counterText: '')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: c.danger), textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'در حال بررسی…' : 'تأیید و ورود')),
              TextButton(onPressed: _busy ? null : () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) context.go('/sign-in'); }, child: const Text('خروج از حساب')),
            ],
          ),
        ),
      ),
    );
  }
}
).hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی برنامه احراز هویت را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);
      await _client.auth.mfa.verify(factorId: factorId, challengeId: challenge.id, code: code);
      if (!mounted) return;
      _code.clear();
      setState(() { _factorId = null; _qr = null; _secret = null; _busy = false; });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأیید دومرحله‌ای فعال شد.')));
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'کد تأیید معتبر نیست یا منقضی شده است.'; });
    }
  }

  Future<void> _removeFactor(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('غیرفعال‌سازی تأیید دومرحله‌ای'),
        content: const Text('پس از غیرفعال‌سازی، ورود با رمز عبور به‌تنهایی انجام می‌شود.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('غیرفعال‌سازی')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _client.auth.mfa.unenroll(id);
      await _client.auth.refreshSession();
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'برای غیرفعال‌سازی، ابتدا ورود دومرحله‌ای همین نشست را تکمیل کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('تأیید دومرحله‌ای'), backgroundColor: c.background, foregroundColor: c.ink),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('ورود امن‌تر با برنامه احراز هویت', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text('پس از فعال‌سازی، هنگام ورود علاوه بر رمز عبور باید کد موقت برنامه احراز هویت را وارد کنید.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.6)),
              const SizedBox(height: 18),
              if (_loading) const Center(child: CircularProgressIndicator())
              else if (_factors.isNotEmpty)
                ..._factors.map((factor) => Card(
                  color: c.surface,
                  child: ListTile(
                    leading: Icon(Icons.verified_user_rounded, color: c.success),
                    title: const Text('تأیید دومرحله‌ای فعال است'),
                    subtitle: Text(factor.friendlyName ?? 'برنامه احراز هویت'),
                    trailing: IconButton(onPressed: _busy ? null : () => _removeFactor(factor.id), icon: Icon(Icons.delete_outline_rounded, color: c.danger)),
                  ),
                ))
              else if (_factorId == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _beginEnrollment,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(_busy ? 'در حال آماده‌سازی…' : 'فعال‌سازی تأیید دومرحله‌ای'),
                )
              else ...[
                if (_qr != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: SvgPicture.string(_qr!, height: 220, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 12),
                Text('اگر امکان اسکن QR را ندارید، این کلید را دستی در برنامه احراز هویت وارد کنید:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
                const SizedBox(height: 8),
                SelectableText(_secret ?? '', textDirection: TextDirection.ltr, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                TextButton.icon(
                  onPressed: _secret == null ? null : () => Clipboard.setData(ClipboardData(text: _secret!)),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کپی کلید'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'کد شش‌رقمی برنامه', counterText: ''),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _verifyEnrollment,
                  child: Text(_busy ? 'در حال بررسی…' : 'تأیید و فعال‌سازی'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: c.danger)),
              ],
              const SizedBox(height: 18),
              Text('کدهای موقت هر ۳۰ ثانیه تغییر می‌کنند. کلید اتصال را در اختیار دیگران قرار ندهید.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class MfaVerifyScreen extends ConsumerStatefulWidget {
  const MfaVerifyScreen({super.key});
  @override
  ConsumerState<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends ConsumerState<MfaVerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() { _code.dispose(); super.dispose(); }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}).hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final factors = await client.auth.mfa.listFactors();
      final verified = factors.data.totp.where((f) => f.status == FactorStatus.verified).toList();
      if (verified.isEmpty) throw Exception('No verified factor');
      final factor = verified.first;
      final challenge = await client.auth.mfa.challenge(factorId: factor.id);
      await client.auth.mfa.verify(factorId: factor.id, challengeId: challenge.id, code: code);
      ref.read(authProvider.notifier).completeMfaLogin();
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'کد واردشده صحیح نیست. کد جدید برنامه را وارد کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('تأیید ورود'), backgroundColor: c.background, foregroundColor: c.ink),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.lock_person_rounded, size: 56, color: c.secondary),
              const SizedBox(height: 16),
              Text('کد تأیید دومرحله‌ای', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('کد شش‌رقمی برنامه احراز هویت را وارد کنید تا وارد حساب شوید.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
              const SizedBox(height: 22),
              TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'کد یک‌بارمصرف', counterText: '')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: c.danger), textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'در حال بررسی…' : 'تأیید و ورود')),
              TextButton(onPressed: _busy ? null : () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) context.go('/sign-in'); }, child: const Text('خروج از حساب')),
            ],
          ),
        ),
      ),
    );
  }
}
).hasMatch(code)) {
      setState(() => _error = 'کد شش‌رقمی را وارد کنید.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final factors = await client.auth.mfa.listFactors();
      final verified = factors.data.totp.where((f) => f.status == FactorStatus.verified).toList();
      if (verified.isEmpty) throw Exception('No verified factor');
      final factor = verified.first;
      final challenge = await client.auth.mfa.challenge(factorId: factor.id);
      await client.auth.mfa.verify(factorId: factor.id, challengeId: challenge.id, code: code);
      ref.read(authProvider.notifier).completeMfaLogin();
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'کد واردشده صحیح نیست. کد جدید برنامه را وارد کنید.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('تأیید ورود'), backgroundColor: c.background, foregroundColor: c.ink),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(Icons.lock_person_rounded, size: 56, color: c.secondary),
              const SizedBox(height: 16),
              Text('کد تأیید دومرحله‌ای', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('کد شش‌رقمی برنامه احراز هویت را وارد کنید تا وارد حساب شوید.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
              const SizedBox(height: 22),
              TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, textDirection: TextDirection.ltr, decoration: const InputDecoration(labelText: 'کد یک‌بارمصرف', counterText: '')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: c.danger), textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'در حال بررسی…' : 'تأیید و ورود')),
              TextButton(onPressed: _busy ? null : () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) context.go('/sign-in'); }, child: const Text('خروج از حساب')),
            ],
          ),
        ),
      ),
    );
  }
}
