import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class OrderCreateScreen extends ConsumerStatefulWidget {
  const OrderCreateScreen({super.key});
  @override
  ConsumerState<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends ConsumerState<OrderCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _budget = TextEditingController();
  String _service = 'طراحی وب‌سایت';
  bool _busy = false;
  String? _tracking;

  static const _services = ['طراحی وب‌سایت', 'موشن‌گرافیک', 'ویدئوی تبلیغاتی و ریلز', 'بررسی و انتخاب دامنه'];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _name.text = (user?.userMetadata?['full_name'] ?? '').toString();
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _title.dispose(); _details.dispose(); _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    final session = auth.currentSession;
    if (user == null || session == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای ثبت سفارش ابتدا وارد حساب کاربری شوید.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'order-submit',
        headers: {'Origin': 'https://alishams.ir'},
        body: {
          'client_name': _name.text.trim(),
          'client_email': user.email ?? '',
          'contact_info': _phone.text.trim(),
          'services': [_service],
          'service': _service,
          'title': _title.text.trim(),
          'details': _details.text.trim(),
          'budget': _budget.text.trim().isEmpty ? 'فعلاً مشخص نیست' : _budget.text.trim(),
        },
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'ثبت سفارش انجام نشد.') : 'پاسخ نامعتبر از سرور دریافت شد.');
      }
      if (!mounted) return;
      setState(() => _tracking = data['tracking_code']?.toString());
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'ارتباط با سرویس ثبت سفارش برقرار نشد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = ref.watch(authProvider).user;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('ثبت سفارش جدید')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _tracking != null
                ? _success(c)
                : Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('درخواست همکاری', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('سفارش به حساب ${user?.email ?? ''} متصل می‌شود و پس از ثبت، در بخش سفارش‌های من قابل پیگیری است.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
                      const SizedBox(height: 20),
                      _field(_name, 'نام و نام خانوادگی', validator: (v) => (v == null || v.trim().length < 2) ? 'نام را کامل وارد کنید.' : null),
                      const SizedBox(height: 12),
                      _field(_phone, 'شماره تماس', keyboard: TextInputType.phone, validator: (v) => (v == null || v.trim().length < 8) ? 'شماره تماس معتبر وارد کنید.' : null),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _service,
                        decoration: const InputDecoration(labelText: 'خدمت موردنظر'),
                        items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _service = v ?? _service),
                      ),
                      const SizedBox(height: 12),
                      _field(_title, 'عنوان سفارش', validator: (v) => (v == null || v.trim().length < 3) ? 'عنوان سفارش را وارد کنید.' : null),
                      const SizedBox(height: 12),
                      _field(_details, 'توضیحات و جزئیات سفارش', maxLines: 5, validator: (v) => (v == null || v.trim().length < 10) ? 'حداقل ۱۰ نویسه توضیح بنویسید.' : null),
                      const SizedBox(height: 12),
                      _field(_budget, 'بودجه (اختیاری)', hint: 'مثلاً ۵ تا ۸ میلیون تومان'),
                      const SizedBox(height: 20),
                      FilledButton.icon(onPressed: _busy ? null : _submit, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(_busy ? 'در حال ثبت سفارش…' : 'ثبت نهایی درخواست'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54))),
                      const SizedBox(height: 12),
                      Text('با ثبت درخواست، اطلاعات تماس و توضیحات برای بررسی سفارش در اختیار استودیو قرار می‌گیرد.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.7)),
                    ]),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _success(AppColors c) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.line)),
    child: Column(children: [
      Icon(Icons.check_circle_rounded, color: c.success, size: 64),
      const SizedBox(height: 16),
      Text('درخواستت ثبت شد', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('کد پیگیری سفارش'),
      const SizedBox(height: 8),
      SelectableText(_tracking ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.secondary, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Text('برای مشاهده وضعیت، به بخش سفارش‌های من برو.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
      const SizedBox(height: 18),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('بازگشت')),
    ]),
  );

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType keyboard = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) =>
      TextFormField(controller: controller, keyboardType: keyboard, maxLines: maxLines, validator: validator, decoration: InputDecoration(labelText: label, hintText: hint));
}
