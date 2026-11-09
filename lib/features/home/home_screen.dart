import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';
import '../../providers/account_overview_provider.dart';
import '../../providers/notification_unread_provider.dart';
import '../../assets/app_assets.dart';
import '../../models/portfolio_item.dart';
import '../../providers/portfolio_provider.dart';
import '../portfolio/portfolio_screen.dart';
import '../portfolio/portfolio_detail_screen.dart';
import '../services/services_screen.dart';
import '../services/website_design_screen.dart';
import '../services/domain_registration_screen.dart';
import '../plus/plus_screen.dart';
import '../club/club_screen.dart';
import '../orders/orders_screen.dart';
import '../account/account_screen.dart';
import '../notifications/notifications_screen.dart';
import '../support/support_center_screen.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  static const _navAssets = [
    'assets/icons/nav_home.svg',
    'assets/icons/nav_services.svg',
    'assets/icons/nav_orders.svg',
    'assets/icons/nav_account.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentUser = ref.watch(authProvider).user;
    final userName = currentUser?.name ?? 'کاربر مهمان';
    final pages = [
      _homeContent(context, c, userName, ref, currentUser?.id),
      const ServicesScreen(),
      const OrdersScreen(),
      const AccountScreen(),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: const Color(0xFF090E1D), border: Border(top: BorderSide(color: c.line)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .24), blurRadius: 24, offset: const Offset(0, -8))]),
          child: NavigationBar(
            height: 76,
            selectedIndex: _tab,
            backgroundColor: Colors.transparent,
            indicatorColor: c.primary.withValues(alpha: 0.28),
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: List.generate(4, (i) => NavigationDestination(
              icon: SvgPicture.asset(_navAssets[i], width: 22, height: 22, colorFilter: ColorFilter.mode(c.muted, BlendMode.srcIn)),
              selectedIcon: SvgPicture.asset(_navAssets[i], width: 22, height: 22, colorFilter: ColorFilter.mode(c.secondary, BlendMode.srcIn)),
              label: ['خانه', 'خدمات', 'سفارش‌ها', 'حساب من'][i],
            )),
          ),
        ),
      ),
    );
  }

  Widget _homeContent(BuildContext context, AppColors c, String userName, WidgetRef ref, String? userId) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Row(children: [
              Container(width: 48, height: 48, padding: const EdgeInsets.all(7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.primary.withValues(alpha: .25), c.secondary.withValues(alpha: .12)]), border: Border.all(color: c.line)), child: Image.asset(AppAssets.logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: Colors.white))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('علی‌شمس', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text('استودیو دیجیتال', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _roundIcon(c, Icons.support_agent_rounded, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportCenterScreen()))),
                const SizedBox(width: 8),
                Consumer(builder: (context, ref, _) {
                  final count = userId == null
                      ? const AsyncData<int>(0)
                      : ref.watch(notificationUnreadCountProvider(userId));
                  return _notificationIcon(c, count, () async {
                    await _notice(context, userId != null);
                    if (userId != null) {
                      ref.invalidate(notificationUnreadCountProvider(userId));
                    }
                  });
                }),
              ]),
            ]),
            const SizedBox(height: 26),
            Text('سلام، $userName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.4)),
            const SizedBox(height: 6),
            Text('برای ساختن تجربه‌ای بهتر، از اینجا شروع کن.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
            const SizedBox(height: 22),
            _heroCard(context, c),
            const SizedBox(height: 18),
            _portfolioStrip(context, c, ref),
            const SizedBox(height: 22),
            _membershipBanner(context, c, userId == null ? null : ref.watch(accountOverviewProvider(userId)), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlusScreen()))),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('دسترسی سریع', style: Theme.of(context).textTheme.titleMedium),
              Text('خدمات استودیو', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.secondary)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _quickAction(context, c, Icons.language_rounded, 'طراحی سایت', 'سفارش اختصاصی', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WebsiteDesignScreen())))),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(context, c, Icons.alternate_email_rounded, 'ثبت دامنه', 'بررسی و سفارش', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DomainRegistrationScreen())))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _quickAction(context, c, Icons.workspace_premium_outlined, 'پلاس+', 'مزایای عضویت', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlusScreen())))),
              const SizedBox(width: 10),
              Expanded(child: _quickAction(context, c, Icons.emoji_events_outlined, 'باشگاه مشتریان', 'امتیاز و جوایز', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubScreen())))),
            ]),
            const SizedBox(height: 24),
            Text('باشگاه مشتریان', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _clubCard(context, c, userId == null ? null : ref.watch(accountOverviewProvider(userId)), () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubScreen()))),
            const SizedBox(height: 22),
            Text('پیگیری سفارش', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _infoCard(context, c, Icons.track_changes_rounded, 'همه سفارش‌ها در یک نگاه', 'وضعیت سفارش‌هایی را که با همین حساب ثبت کرده‌اید، اینجا ببینید.', 'مشاهده سفارش‌ها', () => setState(() => _tab = 2)),
            const SizedBox(height: 24),
            Center(child: Text('ALISHAMS  •  DIGITAL STUDIO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, letterSpacing: 1.2))),
          ])),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, AppColors c) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      constraints: const BoxConstraints(minHeight: 238),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .28), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(AppAssets.portraitImage, fit: BoxFit.cover, alignment: Alignment.centerLeft,
          errorBuilder: (_, __, ___) => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF152A52), Color(0xFF17102E), Color(0xFF070B18)])))),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft,
          colors: [const Color(0xFF070B18).withValues(alpha: .97), const Color(0xFF10152C).withValues(alpha: .78), const Color(0xFF10152C).withValues(alpha: .12)], stops: const [0, .58, 1]))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 20, 20, 20), child: Align(alignment: Alignment.centerRight,
          child: SizedBox(width: MediaQuery.of(context).size.width * .68, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('استودیو دیجیتال علی‌شمس', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFFBDEFF8), fontWeight: FontWeight.w800)),
              const SizedBox(width: 7), const Icon(Icons.auto_awesome, color: Color(0xFF58D9EE), size: 18),
            ]),
            const SizedBox(height: 14),
            Text('ایده‌ات را\nبه تجربه‌ای دیجیتال تبدیل کن.', textAlign: TextAlign.right, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, height: 1.42, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('از طراحی وب‌سایت تا راهکارهای خلاقانه دیجیتال', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .82), height: 1.7)),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () => setState(() => _tab = 1), icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('مشاهده خدمات'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF211A48)))),
          ]))))),
      ]),
    ),
  );


  Widget _portfolioStrip(BuildContext context, AppColors c, WidgetRef ref) {
    final result = ref.watch(portfolioItemsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('بخشی از دنیای پروژه‌ها', style: Theme.of(context).textTheme.titleMedium)),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PortfolioScreen()),
              ),
              child: const Text('مشاهده همه'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: result.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(portfolioItemsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('دریافت نمونه‌کارها ناموفق بود؛ تلاش دوباره'),
              ),
            ),
            data: (items) {
              final featured = <PortfolioItem>[];
              for (final kind in [
                PortfolioKind.website,
                PortfolioKind.logo,
                PortfolioKind.adImage,
                PortfolioKind.video,
              ]) {
                featured.addAll(items.where((item) => item.kind == kind).take(2));
              }
              if (featured.isEmpty) {
                return Center(
                  child: Text('هنوز نمونه‌کاری منتشر نشده است.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = featured[index];
                  final image = item.isAsset
                      ? Image.asset(item.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: c.surface, child: Icon(Icons.image_not_supported_outlined, color: c.muted)))
                      : Image.network(item.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: c.surface, child: Icon(Icons.image_not_supported_outlined, color: c.muted)));
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PortfolioDetailScreen(item: item)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 184,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            image,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: .84)],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 9,
                              top: 9,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .62), borderRadius: BorderRadius.circular(30)),
                                child: Text(item.categoryLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 9)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            if (item.kind == PortfolioKind.video)
                              const Align(alignment: Alignment.center, child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _membershipBanner(BuildContext context, AppColors c, AsyncValue<AccountOverview>? overview, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Color(0xFF6D28D9), Color(0xFF28216D), Color(0xFF073B59)]),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
      boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .20), blurRadius: 22, offset: const Offset(0, 8))],
    ),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), shape: BoxShape.circle), child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD76A), size: 27)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('عضویت پلاس+', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(overview?.when(data: (v) => v.plusSummary, loading: () => 'در حال دریافت وضعیت عضویت…', error: (_, __) => 'وضعیت عضویت در دسترس نیست') ?? 'برای مشاهده وضعیت عضویت وارد حساب شوید', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
      ])),
      const Icon(Icons.chevron_left_rounded, color: Colors.white70),
    ]),
  ));

  Widget _clubCard(BuildContext context, AppColors c, AsyncValue<AccountOverview>? overview, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.line)),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.stars_rounded, color: c.tertiary, size: 27)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('امتیازها و جایگاه شما', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(overview?.when(data: (v) => 'مجموع امتیازهای ثبت‌شده: ${v.points}', loading: () => 'در حال دریافت امتیازها…', error: (_, __) => 'دریافت امتیازها ممکن نشد') ?? 'برای مشاهده امتیازها وارد حساب شوید', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
      ])),
      Icon(Icons.chevron_left_rounded, color: c.muted),
    ]),
  ));

  Widget _quickAction(BuildContext context, AppColors c, IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c.secondary, size: 23),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
      ]),
    ),
  );

  Widget _infoCard(BuildContext context, AppColors c, IconData icon, String title, String body, String action, VoidCallback onTap) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
    child: Row(children: [
      Icon(icon, color: c.secondary, size: 26),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
        TextButton(onPressed: onTap, child: Text(action)),
      ])),
    ]),
  );

  Widget _simpleTab(BuildContext context, AppColors c, IconData icon, String title, String description) => Center(
    child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: c.secondary),
      const SizedBox(height: 18),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 10),
      Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
      const SizedBox(height: 14),
      Text('این بخش در نسخه‌های بعدی تکمیل می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
    ])),
  );

  Widget _notificationIcon(AppColors c, AsyncValue<int> count, VoidCallback onTap) =>
      Material(
        color: c.surface,
        shape: CircleBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48, height: 48,
            child: Stack(
              clipBehavior: Clip.none, alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, color: c.ink),
                if ((count.valueOrNull ?? 0) > 0)
                  Positioned(
                    top: 5, right: 5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.surface, width: 1.5)),
                      child: Text(
                        (count.valueOrNull ?? 0) > 99 ? '99+' : (count.valueOrNull ?? 0).toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                if (count.isLoading)
                  Positioned(bottom: 5, left: 5, child: SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.secondary))),
              ],
            ),
          ),
        ),
      );

  Widget _roundIcon(AppColors c, IconData icon, VoidCallback onTap) => Material(
    color: c.surface,
    shape: CircleBorder(side: BorderSide(color: c.line)),
    child: IconButton(onPressed: onTap, icon: Icon(icon, color: c.ink)),
  );

  Future<void> _notice(BuildContext context, bool signedIn) async {
    if (!signedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای مشاهده اعلان‌ها ابتدا وارد حساب کاربری شوید.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
