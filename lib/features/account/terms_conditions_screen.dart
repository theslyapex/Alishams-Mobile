import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('شرایط و قوانین'), backgroundColor: c.background, foregroundColor: c.ink, elevation: 0),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF38206F), Color(0xFF172B4B), Color(0xFF102A35)]),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.gavel_rounded, color: Color(0xFF9BE9F2), size: 30),
                SizedBox(height: 10),
                Text('قوانین استفاده از اپلیکیشن علی‌شمس', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                SizedBox(height: 7),
                Text('استفاده از اپلیکیشن و ثبت درخواست خدمات به معنی پذیرش چارچوب‌های زیر است. شرایط اختصاصی هر سفارش می‌تواند در پیش‌فاکتور یا توافق جداگانه مشخص شود.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.8)),
              ]),
            ),
            const SizedBox(height: 16),
            _section(c, '۱. حساب کاربری', [
              'اطلاعات حساب را صحیح و به‌روز وارد کنید و مسئولیت حفظ محرمانگی رمز عبور و دسترسی به حساب خود را بر عهده داشته باشید.',
              'هرگونه استفاده از حساب خود را بررسی کنید و در صورت مشاهده فعالیت مشکوک، از تنظیمات امنیتی یا مرکز پشتیبانی اقدام کنید.'
            ]),
            _section(c, '۲. ثبت درخواست و ارائه خدمات', [
              'ثبت فرم به‌تنهایی به معنی پذیرش نهایی پروژه، شروع اجرا یا تأیید قیمت نیست.',
              'جزئیات نهایی دامنه کار، زمان‌بندی، هزینه، خروجی‌ها و اصلاحات پس از بررسی درخواست و در پیشنهاد یا توافق مربوط مشخص می‌شود.',
              'شروع کار پس از تأیید شرایط و انجام پیش‌نیازهای اعلام‌شده، از جمله پرداخت توافق‌شده، خواهد بود.',
              'زمان تحویل به کامل بودن اطلاعات و فایل‌های موردنیاز و همکاری به‌موقع مشتری وابسته است.'
            ]),
            _section(c, '۳. قیمت و پرداخت', [
              'مبلغ نهایی پس از بررسی نیازمندی‌ها اعلام می‌شود؛ مبلغ یا بودجه اولیه فرم لزوماً قیمت قطعی نیست.',
              'شرایط پرداخت، پیش‌پرداخت، اقساط احتمالی و هزینه‌های جانبی باید در پیشنهاد یا توافق همان سفارش مشخص شود.',
              'ثبت دامنه تابع موجود بودن نام، مقررات ثبت‌کننده و هزینه‌های روز است. ثبت درخواست دامنه تضمین‌کننده امکان ثبت آن نیست.'
            ]),
            _section(c, '۴. تعهدات مشتری', [
              'اطلاعات، متن‌ها، تصاویر، نشان‌ها و فایل‌هایی را ارسال کنید که مجاز به استفاده از آن‌ها هستید.',
              'مسئولیت صحت اطلاعات و قانونی بودن محتوای ارسالی بر عهده ارسال‌کننده است.',
              'برای اجرای سفارش، دسترسی‌ها و اطلاعات ضروری را فقط از مسیرهای امن و به میزان موردنیاز ارائه کنید؛ رمز اصلی حساب‌های شخصی خود را ارسال نکنید.'
            ]),
            _section(c, '۵. مالکیت فکری و استفاده از خروجی', [
              'حقوق استفاده و مالکیت فایل‌ها و خروجی نهایی هر پروژه باید در پیشنهاد یا توافق همان سفارش مشخص شود.',
              'استفاده از محتوا، فونت، تصویر، موسیقی، نرم‌افزار یا دارایی متعلق به دیگران باید با رعایت مجوز و حقوق صاحب اثر باشد.',
              'تا زمان تسویه تعهدات مالی، تحویل یا انتقال حقوق خروجی می‌تواند تابع شرایط توافق‌شده همان پروژه باشد.'
            ]),
            _section(c, '۶. محدودیت استفاده', [
              'استفاده از اپلیکیشن برای ارسال محتوای غیرقانونی، نقض حقوق دیگران، ایجاد اختلال، تلاش برای دسترسی غیرمجاز یا سوءاستفاده از خدمات مجاز نیست.',
              'در صورت مشاهده سوءاستفاده یا خطر امنیتی، ممکن است دسترسی به قابلیت مربوط محدود و موضوع بررسی شود.'
            ]),
            _section(c, '۷. ارتباطات و پشتیبانی', [
              'پیگیری رسمی درخواست‌ها و پاسخ‌ها از طریق بخش پشتیبانی اپلیکیشن یا راه ارتباطی اعلام‌شده انجام می‌شود.',
              'زمان پاسخ‌گویی ممکن است با توجه به نوع درخواست و حجم پیام‌ها متفاوت باشد؛ مگر آنکه زمان مشخصی جداگانه توافق شده باشد.'
            ]),
            _section(c, '۸. تغییر قوانین', [
              'این شرایط ممکن است متناسب با تغییر خدمات یا الزامات اجرایی به‌روزرسانی شود. نسخه جاری در همین صفحه منتشر می‌شود.',
              'شرایط اختصاصی که برای یک سفارش به‌صورت جداگانه و روشن تأیید شده، در محدوده همان توافق ملاک عمل خواهد بود.'
            ]),
            const SizedBox(height: 8),
            Text('برای پرسش درباره این شرایط، از مسیر حساب من ← ارتباط با پشتیبانی پیام ارسال کنید.',
              style: TextStyle(color: c.muted, fontSize: 12, height: 1.8)),
          ],
        ),
      ),
    );
  }

  Widget _section(AppColors c, String title, List<String> points) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: c.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
