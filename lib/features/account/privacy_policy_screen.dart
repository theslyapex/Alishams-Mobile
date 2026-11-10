import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('حریم خصوصی'), backgroundColor: c.background, foregroundColor: c.ink, elevation: 0),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            _intro(c),
            const SizedBox(height: 16),
            _section(c, Icons.database_outlined, '۱. چه اطلاعاتی دریافت می‌شود', [
              'اطلاعات حساب مانند نام، نشانی ایمیل و شناسه حساب برای ورود و ارائه خدمات.',
              'اطلاعاتی که در پروفایل وارد می‌کنید؛ از جمله تصویر پروفایل.',
              'اطلاعات سفارش‌ها، درخواست‌های خدمات، پروژه‌ها، پرداخت‌ها و مکاتبات پشتیبانی که خودتان ثبت می‌کنید.',
              'اطلاعات فنی لازم برای کارکرد اپلیکیشن؛ مانند شناسه دستگاه و توکن اعلان، در صورت فعال‌سازی اعلان‌ها.'
            ]),
            _section(c, Icons.tune_rounded, '۲. چرا از اطلاعات استفاده می‌شود', [
              'ایجاد و مدیریت حساب کاربری و احراز هویت.',
              'ثبت و پیگیری سفارش‌ها، پروژه‌ها، پرداخت‌ها و درخواست‌های پشتیبانی.',
              'ارسال اعلان‌های مرتبط با حساب، سفارش و خدمات؛ در صورت فعال بودن اعلان‌ها.',
              'حفظ امنیت، پیشگیری از سوءاستفاده و رفع خطاهای فنی.'
            ]),
            _section(c, Icons.cloud_outlined, '۳. نگهداری و سرویس‌های زیرساختی', [
              'برای احراز هویت، پایگاه داده و ذخیره‌سازی اطلاعات از زیرساخت Supabase استفاده می‌شود.',
              'برای ارسال اعلان‌های پوش، زیرساخت Firebase Cloud Messaging به‌کار می‌رود.',
              'تصویر پروفایل و اطلاعاتی که برای ارائه خدمات لازم است ممکن است در زیرساخت‌های ابری مربوط نگهداری شود.',
              'این سرویس‌ها تابع سیاست‌ها و شرایط حریم خصوصی ارائه‌دهندگان خود نیز هستند.'
            ]),
            _section(c, Icons.share_outlined, '۴. دسترسی و اشتراک‌گذاری', [
              'اطلاعات فقط در حد نیاز برای ارائه خدمات، پشتیبانی، امنیت و انجام درخواست شما استفاده می‌شود.',
              'اطلاعات سفارش ممکن است در اختیار افراد مجازِ مسئول بررسی و اجرای همان سفارش قرار گیرد.',
              'اطلاعات شخصی شما برای فروش یا تبلیغات شخص ثالث عرضه نمی‌شود.',
              'در صورت الزام قانونی یا ضرورت رسیدگی به سوءاستفاده و حفظ امنیت، اطلاعات ممکن است در حدود قانون ارائه شود.'
            ]),
            _section(c, Icons.lock_outline_rounded, '۵. امنیت حساب', [
              'از رمز عبور منحصربه‌فرد استفاده کنید و آن را در اختیار دیگران قرار ندهید.',
              'در بخش «حریم خصوصی و امنیت» می‌توانید رمز عبور را تغییر دهید، تأیید دومرحله‌ای را تنظیم کنید و نشست‌های سایر دستگاه‌ها را لغو کنید.',
              'فهرست دستگاه‌های اعلان، لزوماً فهرست همه نشست‌های ورود شما نیست.'
            ]),
            _section(c, Icons.manage_accounts_outlined, '۶. کنترل اطلاعات و درخواست‌ها', [
              'می‌توانید اطلاعات پروفایل خود را از بخش حساب کاربری به‌روزرسانی کنید.',
              'برای درخواست بررسی، اصلاح یا حذف اطلاعات حساب، از مرکز پشتیبانی داخل اپلیکیشن پیام ارسال کنید.',
              'رسیدگی به درخواست حذف ممکن است به بررسی مالکیت حساب و الزامات قانونی یا سوابق لازم برای پیگیری سفارش‌ها وابسته باشد.'
            ]),
            _section(c, Icons.link_rounded, '۷. پیوندهای بیرونی', [
              'اپلیکیشن ممکن است شما را به وب‌سایت‌ها یا سرویس‌های بیرونی هدایت کند. استفاده از آن سرویس‌ها تابع سیاست‌های خودشان است و این متن جایگزین سیاست آن‌ها نیست.'
            ]),
            _section(c, Icons.update_rounded, '۸. تغییرات این متن', [
              'در صورت تغییر روش‌های پردازش اطلاعات یا امکانات اپلیکیشن، این صفحه به‌روزرسانی می‌شود. نسخه جاری از همین بخش قابل مشاهده است.'
            ]),
            const SizedBox(height: 8),
            Text('پرسش یا درخواست درباره حریم خصوصی دارید؟ از مسیر حساب من ← ارتباط با پشتیبانی پیام ارسال کنید.',
              style: TextStyle(color: c.muted, fontSize: 12, height: 1.8)),
          ],
        ),
      ),
    );
  }

  Widget _intro(AppColors c) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF243C70), Color(0xFF14283A)]),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.shield_moon_outlined, color: Color(0xFF9BE9F2), size: 30),
      SizedBox(height: 10),
      Text('حریم خصوصی شما اهمیت دارد', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      SizedBox(height: 7),
      Text('در این صفحه توضیح داده‌ایم چه اطلاعاتی برای کارکرد اپلیکیشن دریافت می‌شود، چرا استفاده می‌شود و چگونه می‌توانید درباره آن درخواست ثبت کنید.',
        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.8)),
    ]),
  );

  Widget _section(AppColors c, IconData icon, String title, List<String> points) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: c.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: c.secondary, size: 20), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))]),
      const SizedBox(height: 10),
      ...points.map((point) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 7), child: Container(width: 5, height: 5, decoration: BoxDecoration(color: c.secondary, shape: BoxShape.circle))),
          const SizedBox(width: 9),
          Expanded(child: Text(point, style: TextStyle(color: c.muted, fontSize: 11.5, height: 1.8))),
        ]),
      )),
    ]),
  );
}
