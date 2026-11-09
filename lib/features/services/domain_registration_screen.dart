import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import 'order_create_screen.dart';

class DomainRegistrationScreen extends StatelessWidget {
  const DomainRegistrationScreen({super.key});

  static final Uri _domainLab = Uri.parse('https://alishams.ir/domain-lab.html');
  static final Uri _servicePage = Uri.parse('https://alishams.ir/services/domain-purchase.html');

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
        appBar: AppBar(title: const Text('خرید و ثبت دامنه')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _hero(context, c),
              const SizedBox(height: 18),
              Text('آدرس اختصاصی برندت را انتخاب کن', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Text(
                'نام و پسوند مناسب را بررسی کن، وضعیت دامنه را ببین و پس از تأیید امکان ثبت و هزینه، درخواستت را ارسال کن.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted, height: 1.9),
              ),
              const SizedBox(height: 18),
              Text('پسوندهای قابل انتخاب در آزمایشگاه دامنه', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ext in ['.com', '.ir', '.net', '.org', '.co', '.info', '.biz', '.xyz', '.online', '.store'])
                    _extensionChip(context, c, ext),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'این‌ها ۱۰ پسوند موجود در فهرست جست‌وجوی آزمایشگاه دامنه هستند. ثبت پسوندهای دیگر نیز در صورت پشتیبانی مرجع ثبت، قابل استعلام و پیگیری است.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: c.line)),
                child: Text(
                  'تعرفه‌های دامنه به‌صورت زنده در آزمایشگاه دامنه وب‌سایت نمایش داده می‌شوند. مبلغ نهایی هنگام بررسی سفارش و پیش از ثبت تأیید خواهد شد.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                ),
              ),
              const SizedBox(height: 20),
              Text('مراحل ثبت دامنه', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _step(context, c, '۰۱', 'انتخاب نام', 'نام برند یا پروژه و پسوند دلخواه را مشخص کن.'),
              _step(context, c, '۰۲', 'بررسی وضعیت دامنه', 'وضعیت نهایی از مرجع ثبت همان پسوند بررسی می‌شود.'),
              _step(context, c, '۰۳', 'تأیید تعرفه و ثبت', 'پس از اعلام هزینه و تأیید تو، فرایند ثبت پیگیری می‌شود.'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withValues(alpha: .25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 19),
                    const SizedBox(width: 8),
                    Expanded(child: Text('نکات مهم پیش از ثبت', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'نمایش آزاد بودن دامنه در جست‌وجو، تضمین ثبت قطعی نیست. اطلاعات مالک باید واقعی و مطابق مشخصات متقاضی باشد. تمدید سال‌های بعد ممکن است هزینه جداگانه داشته باشد.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: c.primary.withValues(alpha: .28)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('شرایط تخفیف', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'خرید دامنه به‌تنهایی شامل تخفیف عمومی، کد تخفیف یا تخفیف پلاس+ نمی‌شود. تخفیف پلاس+ فقط در سفارش ترکیبی که طراحی وب‌سایت نیز در همان سفارش انتخاب شده باشد، مطابق شرایط خدمات مشمول قابل محاسبه است.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: c.secondary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.secondary.withValues(alpha: .25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.open_in_new_rounded, color: c.secondary, size: 19),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'آزمایشگاه دامنه در وب‌سایت',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                      )),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      'برای مشاهده فهرست کامل پسوندها، تعرفه‌های به‌روز و بررسی هم‌زمان نام دامنه‌ها وارد صفحه آزمایشگاه دامنه شو.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _open(_domainLab),
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: const Text('ورود به آزمایشگاه دامنه وب‌سایت'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OrderCreateScreen(initialService: 'خرید دامنه'),
                )),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('ثبت درخواست خرید دامنه'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              ),
              TextButton(onPressed: () => _open(_servicePage), child: const Text('مشاهده توضیحات کامل در وب‌سایت')),
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
      gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.primary.withValues(alpha: .27), c.surface, c.background]),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(color: c.secondary.withValues(alpha: .13), borderRadius: BorderRadius.circular(17)), child: Icon(Icons.language_rounded, color: c.secondary, size: 29)),
      const SizedBox(height: 16),
      Text('DOMAIN REGISTRATION', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.secondary, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('نامی ماندگار،\nآدرسی اختصاصی.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.5)),
      const SizedBox(height: 8),
      Text('بررسی نام، انتخاب پسوند و پیگیری ثبت دامنه متناسب با برند شما.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
    ]),
  );

  Widget _extensionChip(BuildContext context, AppColors c, String ext) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.line),
    ),
    child: Text(
      ext,
      textDirection: TextDirection.ltr,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: c.secondary,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _extension(BuildContext context, AppColors c, String ext, String label) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.line)),
    child: Row(children: [
      Text(ext, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c.secondary, fontWeight: FontWeight.w900)),
      const SizedBox(width: 12),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
      const Spacer(),
      Icon(Icons.check_circle_outline_rounded, color: c.secondary, size: 19),
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
