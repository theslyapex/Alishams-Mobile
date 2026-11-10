import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'order_create_screen.dart';
import 'website_design_screen.dart';
import 'domain_registration_screen.dart';
import 'service_detail_screen.dart';
import 'smart_estimate_card.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _services = <_ServiceItem>[
    _ServiceItem(icon: Icons.movie_creation_outlined, title: 'موشن‌گرافیک', description: 'ساخت تیزر تبلیغاتی ویدیویی از نوع موشن‌گرافیک حرفه‌ای برای معرفی جذاب برند، محصول یا خدمات.', detail: 'ساخت تیزرهای موشن‌گرافیک برای معرفی برند، محصول یا خدمات؛ سبک بصری و سناریو متناسب با هدف پروژه تعیین می‌شود.', tag: 'ویدئو و انیمیشن', url: 'https://alishams.ir/services/motion-graphics.html', isActive: true, accent: Color(0xFF9B7CFF)),
    _ServiceItem(icon: Icons.web_rounded, title: 'طراحی وبسایت و قالب وبلاگ', description: 'رابط کاربری چشم‌نواز، منظم و سازگار با موبایل و دسکتاپ.', detail: 'طراحی رابط کاربری و ساخت وب‌سایت یا قالب وبلاگ با ساختار منظم و نمایش سازگار در موبایل و دسکتاپ. جزئیات و برآورد پروژه پس از بررسی نیازها مشخص می‌شود.', tag: 'طراحی اختصاصی', url: 'https://alishams.ir/services/website-design.html', isActive: true, accent: Color(0xFF58D9EE)),
    _ServiceItem(icon: Icons.smart_display_outlined, title: 'ریلز و محتوای ویدئویی', description: 'ویدئوهای کوتاه با شروع گیرا، ریتم درست و روایت روشن.', detail: 'تولید ویدئوهای کوتاه با شروع جذاب، ریتم مناسب و روایت روشن برای معرفی محتوا یا برند.', tag: 'فعلاً غیرفعال', url: 'https://alishams.ir/services/reels-video.html', isActive: false, accent: Color(0xFF58BFEF)),
    _ServiceItem(icon: Icons.campaign_outlined, title: 'تیزر تبلیغاتی', description: 'معرفی محصول یا خدمات با ساختار تبلیغاتی هدفمند و ماندگار.', detail: 'طراحی و تولید تیزر تبلیغاتی برای معرفی هدفمند محصول یا خدمات با پیام روشن و ساختار ماندگار.', tag: 'تبلیغات و ویدئو', url: 'https://alishams.ir/services/ad-trailer.html', isActive: true, accent: Color(0xFFFFB86B)),
    _ServiceItem(icon: Icons.shield_outlined, title: 'امنیت شبکه‌های اجتماعی', description: 'راهنمایی برای ایمن‌سازی حساب‌ها و کاهش ریسک دسترسی ناخواسته.', detail: 'ارائه راهنمایی برای افزایش امنیت حساب‌های شبکه‌های اجتماعی، بررسی تنظیمات مهم و کاهش ریسک دسترسی ناخواسته.', tag: 'فعلاً غیرفعال', url: 'https://alishams.ir/services/social-security.html', isActive: false, accent: Color(0xFF65D6B2)),
    _ServiceItem(icon: Icons.article_outlined, title: 'نگارش مقاله وب‌سایت', description: 'محتوای خواندنی و ساختارمند با توجه به مخاطب و هدف صفحه.', detail: 'نگارش محتوای خواندنی و ساختارمند با توجه به مخاطب، موضوع و هدف صفحه؛ همراه با توجه به نظم محتوایی و خوانایی.', tag: 'تولید محتوا', url: 'https://alishams.ir/services/website-articles.html', isActive: true, accent: Color(0xFFB69BFF)),
    _ServiceItem(icon: Icons.campaign_rounded, title: 'تبلیغات و معرفی', description: 'طراحی پیام و محتوای معرفی برای رساندن پیشنهاد به مخاطب مناسب.', detail: 'طراحی پیام و محتوای معرفی متناسب با پیشنهاد، مخاطب هدف و بستر انتشار.', tag: 'فعلاً غیرفعال', url: 'https://alishams.ir/services/promotion.html', isActive: false, accent: Color(0xFFFF9F9F)),
    _ServiceItem(icon: Icons.lightbulb_outline_rounded, title: 'مشاوره کسب‌وکار آنلاین', description: 'بررسی ایده، مسیر محتوا و فرصت‌های بهتر برای حضور دیجیتال.', detail: 'بررسی ایده و وضعیت حضور آنلاین، مسیر محتوا و فرصت‌های بهبود برای تصمیم‌گیری آگاهانه‌تر در فضای دیجیتال.', tag: 'مشاوره', url: 'https://alishams.ir/services/online-business-consulting.html', isActive: true, accent: Color(0xFFFFD166)),
    _ServiceItem(icon: Icons.groups_2_outlined, title: 'خدمات شبکه‌های اجتماعی', description: 'خدمات مرتبط با مدیریت و رشد حضور برند در شبکه‌های اجتماعی.', detail: 'خدمات مرتبط با حضور و فعالیت برند در شبکه‌های اجتماعی؛ محدوده و جزئیات هر درخواست پیش از شروع بررسی می‌شود.', tag: 'شبکه‌های اجتماعی', url: 'https://alishams.ir/services/social-media-services.html', isActive: true, accent: Color(0xFF6DB6FF)),
    _ServiceItem(icon: Icons.draw_outlined, title: 'طراحی لوگو اختصاصی', description: 'بررسی ایده، طراحی با جزئیات منحصربه‌فرد برای ماندگاری در ذهن مخاطب.', detail: 'تبدیل ایده و هویت برند به نشان بصری اختصاصی با توجه به جزئیات، کاربردها و ماندگاری در ذهن مخاطب.', tag: 'هویت بصری', url: 'https://alishams.ir/services/custom-logo-design.html', isActive: true, accent: Color(0xFFE8C77A)),
    _ServiceItem(icon: Icons.search_rounded, title: 'خدمات SEO', description: 'بهینه‌سازی فنی و محتوایی وب‌سایت برای درک بهتر موتورهای جست‌وجو و جذب بازدیدکننده مرتبط.', detail: 'بهینه‌سازی فنی و محتوایی وب‌سایت برای کمک به درک بهتر موتورهای جست‌وجو و جذب بازدیدکننده مرتبط و هدفمند.', tag: 'بهینه‌سازی سایت', url: 'https://alishams.ir/services/seo.html', isActive: true, accent: Color(0xFF65D6B2)),
    _ServiceItem(icon: Icons.language_rounded, title: 'خرید دامنه', description: 'انتخاب و ثبت دامنه مناسب برای برند یا وب‌سایت؛ همراه با بررسی نام، پسوند و تعرفه پیش از ثبت نهایی.', detail: 'بررسی نام و پسوندهای مناسب، مشاهده تعرفه و راهنمایی برای ثبت دامنه متناسب با برند یا وب‌سایت.', tag: 'ثبت دامنه', url: 'https://alishams.ir/services/domain-purchase.html', isActive: true, accent: Color(0xFF58D9EE)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(context, c),
                    const SizedBox(height: 22),
                    _introBanner(context, c),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'خدمات استودیو',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        _countBadge(c, _services.length),
                      ],
                    ),
                    const SizedBox(height: 13),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 620;
                        if (!wide) {
                          return Column(
                            children: _services
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 13),
                                    child: _ServiceCard(
                                      item: item,
                                      colors: c,
                                      onTap: () => _openService(context, c, item),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 13,
                            mainAxisSpacing: 13,
                            mainAxisExtent: 270,
                          ),
                          itemBuilder: (context, index) {
                            final item = _services[index];
                            return _ServiceCard(
                              item: item,
                              colors: c,
                              onTap: () => _openService(context, c, item),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    SmartEstimateCard(colors: c),
                    const SizedBox(height: 22),
                    _processCard(context, c),
                    const SizedBox(height: 18),
                    _orderCta(context, c),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        'ALISHAMS  •  DIGITAL STUDIO',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: c.muted,
                              letterSpacing: 1.1,
                            ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCta(BuildContext context, AppColors c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.primary.withValues(alpha: .22), c.surface]), border: Border.all(color: c.secondary.withValues(alpha: .25))),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: c.secondary.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.add_task_rounded, color: c.secondary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('درخواست همکاری داری؟', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('سفارش جدیدت را مستقیم از اپ ثبت کن.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted))])),
          const SizedBox(width: 8),
          FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderCreateScreen())), child: const Text('ثبت سفارش')),
        ]),
      );

  Widget _header(BuildContext context, AppColors c) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خدمات استودیو',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'راهکارهای دیجیتال برای ساختن حضوری متمایز.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: c.muted,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.line),
            ),
            // Icons8 — Material Outlined / Services
            child: Image.network(
              'https://img.icons8.com/material-outlined/96/58D9EE/services.png',
              width: 27,
              height: 27,
              fit: BoxFit.contain,
              color: c.secondary,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.design_services_outlined,
                color: c.secondary,
                size: 27,
              ),
            ),
          ),
        ],
      );

  Widget _introBanner(BuildContext context, AppColors c) => Container(
    height: 262,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      image: DecorationImage(image: const AssetImage(AppAssets.workspaceImage), fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(const Color(0xFF070B18).withValues(alpha: .60), BlendMode.darken)),
      border: Border.all(color: c.line),
      boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .13), blurRadius: 24, offset: const Offset(0, 9))],
    ),
    child: Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [const Color(0xFF070B18).withValues(alpha: .18), const Color(0xFF070B18).withValues(alpha: .08), const Color(0xFF070B18).withValues(alpha: .62)])))),
      Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.all(18),
        child: SizedBox(width: MediaQuery.of(context).size.width * .72,
          child: Directionality(textDirection: TextDirection.rtl, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .16))),
              child: Text('از ایده تا اجرا', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: const Color(0xFFBDEFF8), fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            Text('برای حضوری حرفه‌ای‌تر در دنیای دیجیتال', textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.45, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('هر پروژه با شناخت نیاز شما آغاز می‌شود؛ راهکار و برآورد نهایی پس از بررسی جزئیات ارائه خواهد شد.', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .82), height: 1.7)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('پیشنهاد متناسب با نیاز هر پروژه', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 7), const Icon(Icons.verified_outlined, color: Color(0xFF65E6C0), size: 18),
            ]),
          ]))))),
    ]),
  );

  Widget _countBadge(AppColors c, int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: c.secondary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: c.secondary.withValues(alpha: .24)),
        ),
        child: Text(
          '$count خدمت',
          style: TextStyle(
            color: c.secondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _processCard(BuildContext context, AppColors c) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, color: c.secondary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'مسیر شروع یک پروژه',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const _ProcessStep(number: '۱', title: 'ثبت درخواست', body: 'نیاز و هدف پروژه را مطرح می‌کنید.'),
            const _ProcessStep(number: '۲', title: 'بررسی و پیشنهاد', body: 'جزئیات، زمان‌بندی و هزینه بررسی می‌شود.'),
            const _ProcessStep(number: '۳', title: 'تأیید و اجرا', body: 'پس از توافق، فرایند اجرای پروژه آغاز می‌شود.'),
            const SizedBox(height: 10),
            Text(
              'برای ثبت سفارش، از بخش سفارش در وب‌سایت علی‌شمس استفاده کنید.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.muted,
                    height: 1.7,
                  ),
            ),
          ],
        ),
      );

  void _openService(BuildContext context, AppColors c, _ServiceItem item) {
    if (item.title == 'طراحی وبسایت و قالب وبلاگ') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WebsiteDesignScreen()));
      return;
    }
    if (item.title == 'خرید دامنه') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DomainRegistrationScreen()));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ServiceDetailScreen(
        title: item.title,
        description: item.detail,
        isActive: item.isActive,
        accent: item.accent,
      ),
    ));
  }

  void _showDetails(BuildContext context, AppColors c, _ServiceItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: c.line),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.muted.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(item.icon, color: item.accent, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Text(
                  item.detail,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                        color: c.muted,
                        height: 1.9,
                      ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: c.secondary, size: 19),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'هزینه و زمان انجام پس از بررسی نیازها و محدوده پروژه اعلام می‌شود.',
                          style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                color: c.muted,
                                height: 1.7,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!item.isActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.orange.withValues(alpha: .28)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.pause_circle_outline_rounded, color: Colors.orange, size: 19),
                        SizedBox(width: 8),
                        Expanded(child: Text('این خدمت در حال حاضر غیرفعال است.')),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: item.isActive
                        ? () async {
                            final uri = Uri.parse(item.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(item.isActive ? 'مشاهده صفحه خدمت' : 'به‌زودی فعال می‌شود'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('بستن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String description;
  final String detail;
  final String tag;
  final String url;
  final bool isActive;
  final Color accent;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.tag,
    required this.url,
    required this.isActive,
    required this.accent,
  });
}

class _ProjectItem {
  final String title;
  final String subtitle;
  final String image;

  const _ProjectItem(this.title, this.subtitle, this.image);
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem item;
  final AppColors colors;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 112,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [item.accent.withValues(alpha: .28), colors.background, item.accent.withValues(alpha: .10)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(left: 18, top: 8, child: Icon(item.icon, size: 78, color: item.accent.withValues(alpha: .13))),
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: item.accent.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: item.accent.withValues(alpha: .35)),
                        ),
                        child: Icon(item.icon, color: item.accent, size: 29),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: colors.line),
                        ),
                        child: Text(
                          item.isActive ? item.tag : 'غیرفعال',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: item.isActive ? item.accent : colors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.accent, size: 21),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.muted,
                                  height: 1.6,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                item.isActive ? 'جزئیات خدمت' : 'مشاهده وضعیت خدمت',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_back_rounded, size: 14, color: colors.secondary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _ProcessStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: c.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: c.muted,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
