import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'order_create_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final bool isActive;
  final Color accent;

  const ServiceDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.isActive,
    required this.accent,
  });

  static const Map<String, List<String>> _features = {
    'موشن‌گرافیک': ['ایده‌پردازی و تعیین مسیر بصری', 'طراحی حرکت و عناصر گرافیکی', 'هماهنگی موسیقی و ریتم با پیام', 'خروجی متناسب با بستر انتشار'],
    'ریلز و محتوای ویدئویی': ['تعیین ساختار و سناریوی ویدئوی کوتاه', 'تدوین و ریتم‌بندی محتوا', 'آماده‌سازی خروجی متناسب با پلتفرم', 'هماهنگی با هویت بصری برند'],
    'تیزر تبلیغاتی': ['تعیین هدف و پیام اصلی تبلیغ', 'طراحی روایت و ساختار ویدئو', 'تولید و تدوین محتوای تبلیغاتی', 'آماده‌سازی نسخه نهایی انتشار'],
    'امنیت شبکه‌های اجتماعی': ['بررسی تنظیمات امنیتی حساب', 'راهنمایی برای فعال‌سازی محافظت‌های موجود', 'بررسی نشست‌ها و دسترسی‌های متصل', 'ارائه چک‌لیست اقدامات پیشنهادی'],
    'نگارش مقاله وب‌سایت': ['تعیین موضوع و مخاطب مقاله', 'ساختاربندی تیترها و بخش‌ها', 'نگارش متن خوانا و هدفمند', 'رعایت اصول پایه سئوی محتوایی در صورت درخواست'],
    'تبلیغات و معرفی': ['شناخت محصول و مخاطب هدف', 'تدوین پیام و پیشنهاد تبلیغاتی', 'انتخاب قالب و بستر مناسب', 'برنامه‌ریزی محتوای معرفی'],
    'مشاوره کسب‌وکار آنلاین': ['بررسی وضعیت فعلی حضور آنلاین', 'شناخت هدف و چالش‌های کسب‌وکار', 'ارائه مسیرهای پیشنهادی و اولویت‌ها', 'جمع‌بندی اقدامات قابل اجرا'],
    'خدمات شبکه‌های اجتماعی': ['بررسی پلتفرم‌ها و نیاز برند', 'برنامه‌ریزی محتوایی و انتشار', 'هماهنگی هویت بصری محتوا', 'تعیین محدوده خدمات پیش از شروع'],
    'طراحی لوگو اختصاصی': ['شناخت برند و مخاطب', 'تعیین مسیر و سبک بصری', 'طراحی نشان متناسب با کاربرد', 'آماده‌سازی خروجی‌های توافق‌شده'],
    'خدمات SEO': ['بررسی وضعیت فنی و محتوایی سایت', 'شناخت کلمات و موضوعات هدف', 'اولویت‌بندی اصلاحات سئو', 'ارائه پیشنهادهای قابل اندازه‌گیری'],
  };

  static const Map<String, List<String>> _deliverables = {
    'موشن‌گرافیک': ['ویدئوی نهایی با فرمت توافق‌شده', 'نسخه متناسب با ابعاد انتشار در صورت توافق'],
    'ریلز و محتوای ویدئویی': ['فایل ویدئوی نهایی', 'نسخه عمودی متناسب با پلتفرم انتخابی'],
    'تیزر تبلیغاتی': ['نسخه نهایی تیزر', 'خروجی با ابعاد و فرمت مورد توافق'],
    'نگارش مقاله وب‌سایت': ['متن نهایی مقاله', 'ساختار تیترها و توضیحات متای توافق‌شده'],
    'طراحی لوگو اختصاصی': ['فایل‌های خروجی توافق‌شده', 'نسخه‌های مناسب کاربردهای تعیین‌شده'],
    'خدمات SEO': ['گزارش بررسی اولیه', 'فهرست اقدامات و اولویت‌های پیشنهادی'],
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final features = _features[title] ?? ['بررسی نیاز و هدف درخواست', 'تعیین محدوده و اولویت‌های اجرا', 'هماهنگی جزئیات و زمان‌بندی', 'ارائه پیشنهاد متناسب با درخواست'];
    final outputs = _deliverables[title] ?? ['شرح محدوده خدمات و اقدامات توافق‌شده', 'جمع‌بندی و تحویل موارد تعیین‌شده در سفارش'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withValues(alpha: .28)),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [accent.withValues(alpha: .19), c.surface, c.background],
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.auto_awesome_rounded, color: accent, size: 27)),
                  const SizedBox(height: 18),
                  Text('ALISHAMS DIGITAL STUDIO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.9)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(isActive ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded, color: isActive ? c.success : Colors.orange, size: 18),
                    const SizedBox(width: 7),
                    Text(isActive ? 'پذیرش درخواست این خدمت فعال است' : 'پذیرش سفارش این خدمت فعلاً غیرفعال است', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: isActive ? c.success : Colors.orange, fontWeight: FontWeight.w700)),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              _heading(context, 'چه مواردی در این خدمت انجام می‌شود؟'),
              ...features.map((e) => _bullet(context, c, e)),
              const SizedBox(height: 20),
              _heading(context, 'خروجی و محدوده تحویل'),
              ...outputs.map((e) => _bullet(context, c, e)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: c.line)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.fact_check_outlined, color: c.secondary, size: 21),
                  const SizedBox(width: 11),
                  Expanded(child: Text('هزینه و زمان نهایی پس از دریافت جزئیات درخواست، بررسی محدوده کار و هماهنگی با شما اعلام می‌شود. پیش از شروع، موارد قابل تحویل و شرایط اجرا مشخص خواهند شد.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.9))),
                ]),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isActive ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderCreateScreen(initialService: title))) : null,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: Text(isActive ? 'ثبت درخواست $title' : 'ثبت سفارش فعلاً در دسترس نیست'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
  );

  Widget _bullet(BuildContext context, AppColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.check_rounded, color: c.secondary, size: 19),
      const SizedBox(width: 9),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7))),
    ]),
  );
}
