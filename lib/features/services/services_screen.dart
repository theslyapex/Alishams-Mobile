import 'package:flutter/material.dart';

import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _services = <_ServiceItem>[
    _ServiceItem(
      icon: Icons.language_rounded,
      title: 'طراحی وب‌سایت',
      description: 'طراحی و پیاده‌سازی وب‌سایت متناسب با هویت برند، هدف کسب‌وکار و نیاز کاربران.',
      detail: 'از ساختار صفحات و تجربه کاربری تا طراحی رابط، پیاده‌سازی و آماده‌سازی برای انتشار؛ جزئیات هر پروژه پس از بررسی نیازها مشخص می‌شود.',
      tag: 'طراحی اختصاصی',
      image: AppAssets.iranMaImage,
      accent: Color(0xFF9B7CFF),
    ),
    _ServiceItem(
      icon: Icons.alternate_email_rounded,
      title: 'بررسی و انتخاب دامنه',
      description: 'کمک به انتخاب نام و پسوند مناسب برای هویت آنلاین کسب‌وکار.',
      detail: 'نام پیشنهادی و پسوندهای مناسب بررسی می‌شوند تا انتخاب دامنه با نام برند و هدف وب‌سایت هماهنگ باشد.',
      tag: 'آزمایشگاه دامنه',
      image: AppAssets.workspaceImage,
      accent: Color(0xFF58D9EE),
    ),
    _ServiceItem(
      icon: Icons.movie_creation_outlined,
      title: 'موشن‌گرافیک',
      description: 'ساخت محتوای متحرک برای معرفی خدمات، محصولات و ایده‌های برند.',
      detail: 'سبک بصری، مدت‌زمان و خروجی موردنیاز بر اساس کاربرد محتوا و بستر انتشار تعیین می‌شود.',
      tag: 'محتوای متحرک',
      image: AppAssets.iranMaSocialImage,
      accent: Color(0xFFB69BFF),
    ),
    _ServiceItem(
      icon: Icons.smart_display_outlined,
      title: 'ویدئوی تبلیغاتی و ریلز',
      description: 'تولید ویدئوهای کوتاه و هدفمند برای معرفی حرفه‌ای برند در فضای دیجیتال.',
      detail: 'ایده و سناریو، لحن بصری و قالب خروجی با توجه به مخاطب و شبکه انتشار برنامه‌ریزی می‌شود.',
      tag: 'ویدئوی تبلیغاتی',
      image: AppAssets.apexImage,
      accent: Color(0xFF58BFEF),
    ),
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
                                      onTap: () => _showDetails(context, c, item),
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
                              onTap: () => _showDetails(context, c, item),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _projectsSection(context, c),
                    const SizedBox(height: 22),
                    _processCard(context, c),
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
            child: Icon(Icons.auto_awesome_rounded, color: c.secondary),
          ),
        ],
      );

  Widget _introBanner(BuildContext context, AppColors c) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          image: DecorationImage(
            image: const AssetImage(AppAssets.workspaceImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0xFF070B18).withValues(alpha: .68),
              BlendMode.darken,
            ),
          ),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: .13),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: .16)),
              ),
              child: Text(
                'از ایده تا اجرا',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFBDEFF8),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'برای حضوری حرفه‌ای‌تر در دنیای دیجیتال',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'هر پروژه با شناخت نیاز شما آغاز می‌شود؛ راهکار و برآورد نهایی پس از بررسی جزئیات ارائه خواهد شد.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: .78),
                    height: 1.8,
                  ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF65E6C0), size: 18),
                const SizedBox(width: 7),
                Text(
                  'پیشنهاد متناسب با نیاز هر پروژه',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _projectsSection(BuildContext context, AppColors c) {
    final projects = <_ProjectItem>[
      _ProjectItem('ایران ما', 'وب‌سایت و محتوای دیجیتال', AppAssets.iranMaImage),
      _ProjectItem('جعبه ابزار نوا', 'ابزارهای کاربردی تصویر', AppAssets.novaImage),
      _ProjectItem('فشرده‌ساز ویدئو', 'ابزار آنلاین ویدئو', AppAssets.apexImage),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'پروژه‌ها و محصولات دیجیتال',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          'نمونه‌هایی از پروژه‌های اجراشده در مجموعه.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 11),
            itemBuilder: (context, index) {
              final project = projects[index];
              return SizedBox(
                width: 205,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        project.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: c.surface,
                          child: Icon(Icons.image_not_supported_outlined, color: c.muted),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: .88),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        left: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              project.subtitle,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('متوجه شدم'),
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
  final String image;
  final Color accent;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.detail,
    required this.tag,
    required this.image,
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
              SizedBox(
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.surfaceContainer,
                        child: Icon(item.icon, color: item.accent, size: 32),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .04),
                            Colors.black.withValues(alpha: .58),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 13,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: .18)),
                        ),
                        child: Text(
                          item.tag,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
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
                                'جزئیات خدمت',
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
