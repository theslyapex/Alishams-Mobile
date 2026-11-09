import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import 'order_create_screen.dart';
import '../portfolio/portfolio_screen.dart';

class WebsiteDesignScreen extends StatelessWidget {
  const WebsiteDesignScreen({super.key});

  static final Uri _websitePage = Uri.parse('https://alishams.ir/services/website-design.html');
  static final Uri _pricingPage = Uri.parse('https://alishams.ir/pricing.html#catalog');

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('طراحی وب‌سایت')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _hero(context, c),
              const SizedBox(height: 18),
              _sectionTitle(context, 'طراحی متناسب با هدف شما'),
              Text(
                'وب‌سایت فقط ظاهر صفحه نیست؛ ساختار صفحات، مسیر حرکت کاربر، خوانایی محتوا و دسترسی به بخش‌های مهم هم در تجربه نهایی نقش دارند.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.9),
              ),
              const SizedBox(height: 18),
              _feature(context, c, Icons.devices_rounded, 'نمایش واکنش‌گرا', 'چیدمان سازگار با موبایل، تبلت و دسکتاپ.'),
              _feature(context, c, Icons.account_tree_outlined, 'ساختار و تجربه کاربری', 'صفحات منظم و مسیر روشن برای رسیدن مخاطب به اطلاعات موردنیاز.'),
              _feature(context, c, Icons.palette_outlined, 'هویت بصری اختصاصی', 'هماهنگی رنگ، تایپوگرافی و اجزای رابط با هویت برند.'),
              _feature(context, c, Icons.code_rounded, 'پیاده‌سازی و تحویل', 'تعیین محدوده اجرا و خروجی‌ها پیش از آغاز پروژه.'),
              const SizedBox(height: 18),
              _priceCard(context, c, 'طراحی وب‌سایت', '۵ تا ۱۰۰ میلیون تومان', 'بسته به امکانات، تعداد صفحات و حجم پروژه.'),
              const SizedBox(height: 10),
              _priceCard(context, c, 'طراحی قالب اختصاصی وبلاگ', '۶۵۰ هزار تومان', 'تعرفه درج‌شده در صفحه خدمت؛ جزئیات نهایی پیش از ثبت سفارش تأیید می‌شود.'),
              const SizedBox(height: 10),
              Text(
                'این مبالغ راهنمای اولیه و مطابق اطلاعات درج‌شده در وب‌سایت هستند؛ مبلغ نهایی پس از بررسی امکانات و محدوده پروژه تأیید می‌شود.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.8),
              ),
              const SizedBox(height: 22),
              _sectionTitle(context, 'مراحل انجام پروژه'),
              _step(context, c, '۰۱', 'شناخت و برنامه‌ریزی', 'بررسی هدف، مخاطبان و نیازهای پروژه.'),
              _step(context, c, '۰۲', 'طراحی و پیاده‌سازی', 'تعیین ساختار، طراحی رابط و اجرای موارد توافق‌شده.'),
              _step(context, c, '۰۳', 'بازبینی و تحویل', 'بررسی نمایش در اندازه‌های مختلف و جمع‌بندی خروجی.'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OrderCreateScreen(initialService: 'طراحی وبسایت و قالب وبلاگ'),
                )),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('ثبت درخواست طراحی وب‌سایت'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () => _open(_websitePage),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('مشاهده توضیحات کامل در وب‌سایت'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PortfolioScreen())),
                icon: const Icon(Icons.collections_outlined),
                label: const Text('مشاهده نمونه‌کارها'),
              ),
              TextButton(onPressed: () => _open(_pricingPage), child: const Text('مشاهده صفحه تعرفه‌ها')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, AppColors c) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: c.secondary.withValues(alpha: .25)),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [c.primary.withValues(alpha: .28), c.surface, c.background],
      ),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(color: c.secondary.withValues(alpha: .13), borderRadius: BorderRadius.circular(17)),
        child: Icon(Icons.web_rounded, color: c.secondary, size: 29),
      ),
      const SizedBox(height: 16),
      Text('WEB DESIGN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.secondary, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('وب‌سایتی که\nبرای هدف شما ساخته می‌شود.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.5)),
      const SizedBox(height: 8),
      Text('طراحی منظم، تجربه کاربری سنجیده و نمایش سازگار در همه نمایشگرها.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
    ]),
  );

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
  );

  Widget _feature(BuildContext context, AppColors c, IconData icon, String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: c.secondary.withValues(alpha: .11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: c.secondary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.6)),
      ])),
    ]),
  );

  Widget _priceCard(BuildContext context, AppColors c, String title, String price, String note) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: c.secondary.withValues(alpha: .22)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(price, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.secondary, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text(note, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.6)),
    ]),
  );

  Widget _step(BuildContext context, AppColors c, String n, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: c.primary.withValues(alpha: .18), shape: BoxShape.circle), child: Text(n, style: TextStyle(color: c.secondary, fontWeight: FontWeight.w800, fontSize: 11))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.7)),
      ])),
    ]),
  );
}
