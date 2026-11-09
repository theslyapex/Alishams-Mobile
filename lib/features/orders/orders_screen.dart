import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import 'order_detail_screen.dart';
import '../../providers/customer_orders_provider.dart';
import '../../theme/app_colors.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final user = ref.watch(authProvider).user;
    final orders = user == null ? null : ref.watch(customerOrdersProvider(user.id));
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                ref.invalidate(customerOrdersProvider(user.id));
                await ref.read(customerOrdersProvider(user.id).future);
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    Row(children: [
                      Expanded(child: Text('سفارش‌های من', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                      IconButton(
                        tooltip: 'به‌روزرسانی',
                        onPressed: user == null ? null : () => ref.invalidate(customerOrdersProvider(user.id)),
                        icon: Icon(Icons.refresh_rounded, color: c.secondary),
                      ),
                    ]),
                    const SizedBox(height: 7),
                    Text('وضعیت درخواست‌ها و سفارش‌های شما در یک نگاه.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
                    const SizedBox(height: 22),
                    if (user == null)
                      _MessagePanel(icon: Icons.lock_outline_rounded, title: 'ابتدا وارد حساب کاربری شوید', message: 'برای مشاهده سفارش‌های شخصی، باید با حساب خود وارد اپلیکیشن شده باشید.', color: c)
                    else
                      orders!.when(
                        loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 70), child: Center(child: CircularProgressIndicator())),
                        error: (_, __) => _MessagePanel(
                          icon: Icons.cloud_off_rounded,
                          title: 'دریافت سفارش‌ها انجام نشد',
                          message: 'اتصال را بررسی کنید و دوباره تلاش کنید. اطلاعات سفارش‌ها فقط از مسیر امن حساب شما خوانده می‌شود.',
                          color: c,
                          action: TextButton.icon(
                            onPressed: () => ref.invalidate(customerOrdersProvider(user.id)),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('تلاش دوباره'),
                          ),
                        ),
                        data: (items) => items.isEmpty
                            ? _MessagePanel(
                                icon: Icons.receipt_long_rounded,
                                title: 'هنوز سفارشی ثبت نشده',
                                message: 'سفارش‌هایی که پس از ورود با همین حساب در سایت یا اپلیکیشن ثبت کنید، در این بخش نمایش داده می‌شوند.',
                                color: c,
                              )
                            : Column(children: [
                                _SummaryStrip(count: items.length, color: c),
                                const SizedBox(height: 14),
                                ...items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 13),
                                  child: _OrderCard(order: item, color: c),
                                )),
                              ]),
                      ),
                    const SizedBox(height: 18),
                    Center(child: Text('ALISHAMS  •  DIGITAL STUDIO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, letterSpacing: 1.1))),
                  ])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.count, required this.color});
  final int count;
  final AppColors color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: color.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.line)),
    child: Row(children: [
      Icon(Icons.receipt_long_rounded, color: color.secondary),
      const SizedBox(width: 10),
      Expanded(child: Text('سفارش‌های متصل به این حساب', style: Theme.of(context).textTheme.bodyMedium)),
      Text(count.toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color.secondary, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.color});
  final CustomerOrder order;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(order.status);
    final statusColor = order.status == 'rejected'
        ? color.danger
        : (order.status == 'approved' || order.status == 'converted')
            ? color.success
            : order.status == 'awaiting_payment' ? color.warning : color.secondary;
    final date = DateTime.tryParse(order.createdAt)?.toLocal();
    final price = order.payableAmount > 0 ? order.payableAmount : order.quotedPrice;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
      child: Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.line),
        boxShadow: [BoxShadow(color: color.primary.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.primary.withValues(alpha: .15), borderRadius: BorderRadius.circular(13)), child: Icon(Icons.receipt_long_rounded, color: color.secondary)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(order.trackingCode, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.muted, letterSpacing: .5)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: statusColor.withValues(alpha: .35))),
            child: Text(status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (order.service.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(order.service, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.muted)),
        ],
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Tag(icon: Icons.calendar_today_rounded, text: date == null ? 'تاریخ نامشخص' : DateFormat('yyyy/MM/dd').format(date), color: color),
          if (price > 0) _Tag(icon: Icons.payments_outlined, text: NumberFormat('#,##0').format(price) + ' تومان', color: color),
          if (order.discountPercent > 0) _Tag(icon: Icons.local_offer_outlined, text: 'تخفیف ' + order.discountPercent.toStringAsFixed(0) + '٪', color: color),
        ]),
        if (order.publicMessage.isNotEmpty) ...[
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.surfaceContainer, borderRadius: BorderRadius.circular(13)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: color.secondary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(order.publicMessage, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7))),
            ]),
          ),
        ],
        if (order.events.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('تاریخچه وضعیت', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...order.events.take(4).map((event) {
            final eventDate = DateTime.tryParse((event['created_at'] ?? '').toString())?.toLocal();
            final message = (event['public_message'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 7), decoration: BoxDecoration(color: color.secondary, shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(message.isEmpty ? _statusLabel((event['status'] ?? '').toString()) : message, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6)),
                  if (eventDate != null) Text(DateFormat('yyyy/MM/dd  HH:mm').format(eventDate), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.muted)),
                ])),
              ]),
            );
          }),
        ],
      ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final AppColors color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: color.surfaceContainer, borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color.secondary),
      const SizedBox(width: 6),
      Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.muted)),
    ]),
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.icon, required this.title, required this.message, required this.color, this.action});
  final IconData icon;
  final String title;
  final String message;
  final AppColors color;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: color.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: color.line)),
    child: Column(children: [
      Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: color.primary.withValues(alpha: .14)), child: Icon(icon, size: 30, color: color.secondary)),
      const SizedBox(height: 15),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.muted, height: 1.8)),
      if (action != null) ...[const SizedBox(height: 8), action!],
    ]),
  );
}

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
