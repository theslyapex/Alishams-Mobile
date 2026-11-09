import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/account_overview_provider.dart';
import '../../assets/app_assets.dart';
import '../../theme/app_colors.dart';
import '../plus/plus_screen.dart';
import '../club/club_screen.dart';
import '../projects/projects_screen.dart';
import '../notifications/notifications_screen.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final overview = user == null ? null : ref.watch(accountOverviewProvider(user.id));
    final name = user?.name ?? 'کاربر مهمان';
    final email = user?.email ?? 'برای مشاهده اطلاعات وارد حساب شوید';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text('حساب کاربری', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('مدیریت حساب و تنظیمات اپلیکیشن', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
                    const SizedBox(height: 22),
                    _profileCard(context, c, name, email, user != null, onEdit: user == null ? null : () => _editProfileName(context, ref, name)),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'باشگاه و عضویت'),
                    const SizedBox(height: 10),
                    _menuTile(context, c, Icons.workspace_premium_rounded, 'عضویت پلاس+', overview?.when(data: (v) => v.plusSummary, loading: () => 'در حال دریافت وضعیت عضویت…', error: (_, __) => 'دریافت وضعیت عضویت ممکن نشد') ?? 'برای مشاهده وضعیت عضویت وارد حساب شوید', onTap: () { if (user == null) { _message(context, 'ابتدا وارد حساب شوید.'); } else { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlusScreen())); } }, accent: c.tertiary),
                    const SizedBox(height: 9),
                    _menuTile(context, c, Icons.emoji_events_rounded, 'باشگاه مشتریان', overview?.when(data: (v) => 'امتیاز ثبت‌شده: ${v.points}', loading: () => 'در حال دریافت امتیازها…', error: (_, __) => 'دریافت امتیازها ممکن نشد') ?? 'برای مشاهده امتیازها وارد حساب شوید', onTap: () { if (user == null) { _message(context, 'ابتدا وارد حساب شوید.'); } else { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubScreen())); } }, accent: c.secondary),
                    const SizedBox(height: 9),
                    _menuTile(context, c, Icons.folder_copy_outlined, 'پروژه‌ها و پرداخت‌ها', 'پیگیری پروژه‌ها، مشاهده مانده و ارسال رسید پرداخت', onTap: () { if (user == null) { _message(context, 'ابتدا وارد حساب شوید.'); } else { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectsScreen())); } }, accent: c.tertiary),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'تنظیمات و پشتیبانی'),
                    const SizedBox(height: 10),
                    _menuTile(context, c, Icons.notifications_none_rounded, 'اعلان‌ها', 'پیگیری پیام‌های سفارش، پروژه، پرداخت، پلاس و باشگاه', onTap: () { if (user == null) { _message(context, 'ابتدا وارد حساب شوید.'); } else { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())); } }),
                    const SizedBox(height: 9),
                    _menuTile(context, c, Icons.shield_outlined, 'حریم خصوصی و امنیت', 'اطلاعات و امنیت حساب', onTap: () => _message(context, 'بخش حریم خصوصی در حال آماده‌سازی است.')),
                    const SizedBox(height: 9),
                    _menuTile(context, c, Icons.support_agent_rounded, 'ارتباط با پشتیبانی', 'راهنمایی درباره خدمات و سفارش‌ها', onTap: () => _message(context, 'راه ارتباطی پشتیبانی در نسخه بعدی اضافه می‌شود.')),
                    const SizedBox(height: 9),
                    _menuTile(context, c, Icons.info_outline_rounded, 'درباره علی‌شمس', 'استودیو دیجیتال علی‌شمس', onTap: () => _message(context, 'ALISHAMS • Digital Studio')),
                    const SizedBox(height: 22),
                    if (user != null)
                      OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context, ref),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('خروج از حساب'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.danger,
                          side: BorderSide(color: c.danger.withValues(alpha: .45)),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () => context.go('/sign-in'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: c.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('ورود به حساب کاربری'),
                      ),
                    const SizedBox(height: 24),
                    Center(child: Text('ALISHAMS  •  DIGITAL STUDIO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, letterSpacing: 1.1))),
                    const SizedBox(height: 5),
                    Center(child: Text('نسخه آزمایشی اپلیکیشن', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted))),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, AppColors c, String name, String email, bool signedIn, {VoidCallback? onEdit}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.primary.withValues(alpha: .34), c.surface, c.surface]),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withValues(alpha: .24), border: Border.all(color: c.tertiary.withValues(alpha: .55))),
            child: ClipOval(child: Image.asset(AppAssets.portraitImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: c.tertiary, size: 31))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: (signedIn ? c.success : c.warning).withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
                child: Text(signedIn ? 'حساب آزمایشی فعال' : 'وضعیت مهمان', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: signedIn ? c.success : c.warning)),
              ),
            ]),
          ),
          if (onEdit != null) IconButton(onPressed: onEdit, tooltip: 'ویرایش نام', icon: Icon(Icons.edit_outlined, color: c.secondary)),
        ],
      ),
    );
  }

  Future<void> _editProfileName(BuildContext context, WidgetRef ref, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ویرایش نام نمایشی'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'نام و نام خانوادگی'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('ذخیره')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final ok = await ref.read(authProvider.notifier).updateProfileName(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'اطلاعات حساب به‌روزرسانی شد.' : (ref.read(authProvider).error ?? 'ذخیره تغییرات انجام نشد.'))),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800));

  Widget _menuTile(BuildContext context, AppColors c, IconData icon, String title, String subtitle, {required VoidCallback onTap, Color? accent}) {
    final color = accent ?? c.secondary;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: c.line)),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.4)),
            ])),
            const SizedBox(width: 6),
            Icon(Icons.chevron_left_rounded, color: c.muted),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا می‌خواهید از حساب آزمایشی خارج شوید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('خروج')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(authProvider.notifier).signOut();
      context.go('/sign-in');
    }
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
