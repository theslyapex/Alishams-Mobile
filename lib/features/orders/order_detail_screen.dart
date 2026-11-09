import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/customer_orders_provider.dart';
import '../../theme/app_colors.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});
  final CustomerOrder order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _termsAccepted = false;
  bool _earlyStartConsent = false;
  bool _submitting = false;
  bool _offerAccepted = false;

  CustomerOrder get order => widget.order;

  Future<void> _acceptOffer() async {
    if (!_termsAccepted || _submitting) return;
    setState(() => _submitting = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'order-account-actions',
        body: {
          'action': 'accept_offer',
          'order_id': order.id,
          'accept_offer': true,
          'early_start_consent': _earlyStartConsent,
        },
      );
      final payload = response.data;
      if (response.status < 200 || response.status >= 300 ||
          payload is! Map || payload['ok'] != true) {
        final message = payload is Map ? payload['error']?.toString() : null;
        throw Exception(message?.isNotEmpty == true ? message : 'ثبت پذیرش پیشنهاد انجام نشد.');
      }
      if (!mounted) return;
      setState(() {
        _offerAccepted = true;
        _submitting = false;
      });
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) ref.invalidate(customerOrdersProvider(userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(payload['message']?.toString() ?? 'پیشنهاد پذیرفته شد.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final date = _date(order.createdAt);
    final eta = _date((order.data['eta_date'] ?? '').toString());
    final money = NumberFormat('#,##0');
    final payable = order.payableAmount > 0 ? order.payableAmount : order.quotedPrice;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('جزئیات سفارش')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('کد پیگیری: ${order.trackingCode}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.muted)),
                const SizedBox(height: 14),
                _statusPill(context, c, order.status),
              ])),
              const SizedBox(height: 12),
              _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _heading(context, 'اطلاعات درخواست', c),
                _row(context, 'خدمت', order.service.isEmpty ? 'ثبت نشده' : order.service, c),
                _row(context, 'تاریخ ثبت', date == null ? 'نامشخص' : DateFormat('yyyy/MM/dd – HH:mm').format(date), c),
                _row(context, 'بودجه اعلامی', (order.data['budget'] ?? '—').toString(), c),
                _row(context, 'زمان برآوردی', eta == null ? 'هنوز اعلام نشده' : DateFormat('yyyy/MM/dd').format(eta), c),
                const SizedBox(height: 8),
                Text('شرح درخواست', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.muted)),
                const SizedBox(height: 6),
                Text((order.data['details'] ?? 'توضیحی ثبت نشده است.').toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.9)),
              ])),
              const SizedBox(height: 12),
              _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _heading(context, 'پیشنهاد مالی', c),
                _row(context, 'مبلغ پیشنهادی', order.quotedPrice > 0 ? '${money.format(order.quotedPrice)} تومان' : 'هنوز اعلام نشده', c),
                _row(context, 'درصد تخفیف', '${order.discountPercent.toStringAsFixed(0)}٪', c),
                _row(context, 'مبلغ قابل پرداخت', payable > 0 ? '${money.format(payable)} تومان' : 'هنوز مشخص نشده', c, emphasize: true),
                _row(context, 'پذیرش پیشنهاد', order.data['offer_accepted_at'] == null ? 'ثبت نشده' : 'پذیرفته شده', c),
                _row(context, 'رضایت شروع زودتر خدمت', order.data['early_start_consent'] == true ? 'ثبت شده' : 'ثبت نشده', c),
                if ((order.data['offer_terms_version'] ?? '').toString().isNotEmpty)
                  _row(context, 'نسخه شرایط پیشنهاد', order.data['offer_terms_version'].toString(), c),
              ])),
              if (!_offerAccepted &&
                  order.data['offer_accepted_at'] == null &&
                  ['awaiting_customer', 'ready_to_convert', 'approved'].contains(order.status) &&
                  order.quotedPrice > 0) ...[
                const SizedBox(height: 12),
                _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _heading(context, 'تأیید پیشنهاد نهایی', c),
                  Text(
                    'مبلغ نهایی و شرایط سفارش را با دقت بررسی کن. با تأیید این بخش، پذیرش پیشنهاد به‌صورت امن به حساب کاربری تو ثبت می‌شود.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: _submitting ? null : (value) => setState(() => _termsAccepted = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('پیشنهاد نهایی، مبلغ و شرایط را مطالعه کرده‌ام و می‌پذیرم.'),
                    subtitle: const Text('پذیرش این گزینه برای ثبت توافق لازم است.'),
                  ),
                  CheckboxListTile(
                    value: _earlyStartConsent,
                    onChanged: _submitting ? null : (value) => setState(() => _earlyStartConsent = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('با شروع خدمت پیش از پایان مهلت قانونی انصراف، در موارد قابل اعمال، موافقم.'),
                    subtitle: const Text('این گزینه اختیاری است و نپذیرفتن آن مانع پذیرش پیشنهاد نیست.'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _termsAccepted && !_submitting ? _acceptOffer : null,
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.verified_outlined),
                      label: Text(_submitting ? 'در حال ثبت توافق…' : 'تأیید پیشنهاد و ثبت توافق'),
                    ),
                  ),
                ])),
              ],
              if (_offerAccepted) ...[
                const SizedBox(height: 12),
                _panel(c, const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(child: Text('پیشنهاد با موفقیت پذیرفته شد. وضعیت سفارش به‌روزرسانی شده است.')),
                ])),
              ],
              if (order.publicMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _heading(context, 'پیام استودیو', c),
                  Text(order.publicMessage, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.9)),
                ])),
              ],
              const SizedBox(height: 12),
              _panel(c, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _heading(context, 'روند سفارش', c),
                if (order.events.isEmpty)
                  Text('هنوز رویداد تازه‌ای برای این سفارش ثبت نشده است.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted))
                else
                  ...order.events.map((event) {
                    final at = _date((event['created_at'] ?? '').toString());
                    final message = (event['public_message'] ?? '').toString();
                    final status = (event['status'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(message.isEmpty ? _statusLabel(status) : message, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7, fontWeight: FontWeight.w600)),
                          if (at != null) Text(DateFormat('yyyy/MM/dd – HH:mm').format(at), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted)),
                        ])),
                      ]),
                    );
                  }),
              ])),
              const SizedBox(height: 12),
              Text('اطلاعات این صفحه از سوابق ثبت‌شده سفارش دریافت می‌شود. پرداخت پس از تبدیل سفارش به پروژه و اعلام مرحله پرداخت در دسترس قرار می‌گیرد.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(AppColors c, Widget child) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(19), border: Border.all(color: c.line)),
    child: child,
  );

  Widget _heading(BuildContext context, String text, AppColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
  );

  Widget _row(BuildContext context, String label, String value, AppColors c, {bool emphasize = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 126, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted))),
      Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600, color: emphasize ? c.secondary : null))),
    ]),
  );

  Widget _statusPill(BuildContext context, AppColors c, String status) {
    final color = status == 'rejected' ? c.danger : (status == 'approved' || status == 'converted') ? c.success : status == 'awaiting_payment' ? c.warning : c.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withValues(alpha: .35))),
      child: Text(_statusLabel(status), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
    );
  }

  DateTime? _date(String value) => DateTime.tryParse(value)?.toLocal();

  String _statusLabel(String status) {
    const labels = {
      'new': 'ثبت‌شده',
      'reviewing': 'در حال بررسی',
      'awaiting_customer': 'منتظر پاسخ شما',
      'awaiting_payment': 'در انتظار پرداخت',
      'approved': 'تأییدشده',
      'rejected': 'ردشده',
      'converted': 'تبدیل‌شده به پروژه',
      'ready_to_convert': 'آماده تبدیل به پروژه',
    };
    return labels[status] ?? (status.isEmpty ? 'نامشخص' : status);
  }
}
