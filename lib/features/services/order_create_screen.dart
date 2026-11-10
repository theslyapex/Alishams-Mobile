import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../orders/orders_screen.dart';
import '../../theme/app_colors.dart';

class OrderCreateScreen extends ConsumerStatefulWidget {
  final String? initialService;
  final Map<String, int>? initialServiceQuantities;
  const OrderCreateScreen({super.key, this.initialService, this.initialServiceQuantities});
  @override
  ConsumerState<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends ConsumerState<OrderCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _budget = TextEditingController();
  final Map<String, String> _answers = {};
  final Map<String, Set<String>> _multiAnswers = {};
  String _service = 'طراحی وبسایت و قالب وبلاگ';
  bool _busy = false;
  String? _tracking;
  final Map<String, int> _estimatedServices = {};

  static const _services = [
    'موشن‌گرافیک',
    'ریلز و محتوای ویدئویی',
    'امنیت شبکه‌های اجتماعی',
    'تبلیغات و معرفی',
    'طراحی وبسایت و قالب وبلاگ',
    'تیزر تبلیغاتی',
    'نگارش مقاله وب‌سایت',
    'مشاوره کسب‌وکار آنلاین',
    'خدمات شبکه‌های اجتماعی',
    'طراحی لوگو اختصاصی',
    'خدمات SEO',
    'خرید دامنه',
  ];

  static const Map<String, List<_OrderField>> _formFields = {
    'ریلز و محتوای ویدئویی': [
      _OrderField('مدت ویدئو', isRequired: true, choices: ['۱۵ تا ۳۰ ثانیه', '۳۰ تا ۶۰ ثانیه', '۱ تا ۲ دقیقه', 'بیش از ۲ دقیقه']),
      _OrderField('سبک ویدئو', choices: ['تدوین ویدئو', 'موشن‌گرافیک', 'ترکیبی', 'نیاز به پیشنهاد دارم']),
      _OrderField('سناریو یا توضیحات محتوا', multiline: true, hint: 'موضوع و هدف ریلز را شرح دهید.'),
      _OrderField('تعداد ویدئو', isRequired: true, choices: ['۱', '۲ تا ۵', '۶ تا ۱۰', 'بیش از ۱۰']),
    ],
    'امنیت شبکه‌های اجتماعی': [
      _OrderField('پلتفرم موردنظر', isRequired: true, multi: true, choices: ['اینستاگرام', 'تلگرام', 'واتساپ', 'سایر']),
      _OrderField('نوع نیاز امنیتی', isRequired: true, choices: ['بررسی امنیت حساب', 'افزایش امنیت و تنظیمات', 'بازیابی دسترسی', 'مشاوره و پایش دوره‌ای']),
      _OrderField('توضیحات تکمیلی', multiline: true),
    ],
    'تبلیغات و معرفی': [
      _OrderField('خدمت یا محصول مورد تبلیغ', isRequired: true),
      _OrderField('بستر تبلیغاتی', isRequired: true, multi: true, choices: ['اینستاگرام', 'تلگرام', 'وب‌سایت', 'آپارات', 'سایر']),
      _OrderField('هدف کمپین', choices: ['آگاهی از برند', 'معرفی محصول یا خدمت', 'جذب مخاطب', 'افزایش فروش']),
      _OrderField('توضیحات و بودجه مدنظر', multiline: true),
    ],
    'طراحی وبسایت و قالب وبلاگ': [
      _OrderField('نوع وب‌سایت', isRequired: true, choices: ['شرکتی', 'فروشگاهی', 'شخصی و رزومه', 'خبری و مجله‌ای', 'وبلاگ', 'آموزشی', 'خدماتی', 'سایر']),
      _OrderField('تعداد صفحات تقریبی', isRequired: true, choices: ['۱ تا ۵ صفحه', '۶ تا ۱۰ صفحه', '۱۱ تا ۲۰ صفحه', 'بیش از ۲۰ صفحه', 'نیاز به مشاوره دارم']),
      _OrderField('دامنه موردنظر', hint: 'مثلاً example.com یا هنوز انتخاب نکرده‌ام'),
      _OrderField('مهلت تحویل', isRequired: true, choices: ['کمتر از یک هفته', '۱ تا ۲ هفته', '۲ تا ۴ هفته', '۱ تا ۲ ماه', 'شناور / با مشورت']),
      _OrderField('امکانات موردنیاز', multi: true, choices: ['فروشگاه و سبد خرید', 'درگاه پرداخت', 'پنل مدیریت', 'عضویت و ورود کاربران', 'فرم تماس و درخواست', 'چندزبانه', 'رزرو و نوبت‌دهی', 'گالری تصاویر و ویدئو', 'اتصال به شبکه‌های اجتماعی']),
      _OrderField('سئوی سایت', choices: ['بله، سئوی پایه', 'بله، سئوی کامل‌تر', 'خیر', 'نیاز به مشاوره دارم']),
      _OrderField('وبلاگ داشته باشد؟', choices: ['بله', 'خیر', 'بعداً تصمیم می‌گیرم']),
      _OrderField('ویژگی‌های اختصاصی', multiline: true, hint: 'هر قابلیت یا نمونه‌ای که مدنظر دارید توضیح دهید.'),
    ],
    'خرید دامنه': [
      _OrderField('نام دامنه (بدون پسوند)', isRequired: true, hint: 'مثلاً mybrand'),
      _OrderField('پسوندهای موردنظر', isRequired: true, multi: true, choices: ['.com', '.ir', '.net', '.org', '.co', '.info', '.biz', '.xyz', '.online', '.store', 'سایر پسوندها']),
      _OrderField('وضعیت درخواست', choices: ['ثبت دامنه جدید', 'انتقال دامنه فعلی', 'تمدید دامنه']),
      _OrderField('مدت ثبت', choices: ['۱ سال', '۲ سال', '۵ سال', 'نیاز به راهنمایی']),
      _OrderField('نام مالک دامنه', hint: 'نام شخص یا مجموعه‌ای که دامنه به نام او ثبت می‌شود'),
    ],
    'موشن‌گرافیک': [
      _OrderField('مدت ویدئو', isRequired: true, choices: ['۱۵ تا ۳۰ ثانیه', '۳۰ تا ۶۰ ثانیه', '۱ تا ۲ دقیقه', 'بیش از ۲ دقیقه', 'نیاز به پیشنهاد دارم']),
      _OrderField('سبک بصری', isRequired: true, choices: ['مینیمال', 'دو‌بعدی', 'سه‌بعدی', 'تایپوگرافی متحرک', 'ترکیبی', 'پیشنهاد استودیو']),
      _OrderField('سناریو', choices: ['آماده دارم', 'ایده اولیه دارم', 'نیاز به سناریونویسی دارم']),
      _OrderField('گویندگی و موسیقی', choices: ['گویندگی و موسیقی', 'فقط موسیقی', 'بدون صدا', 'نیاز به مشاوره']),
      _OrderField('متن یا توضیح سناریو', multiline: true),
      _OrderField('ابعاد خروجی', choices: ['عمودی ۹:۱۶', 'افقی ۱۶:۹', 'مربعی ۱:۱', 'چند خروجی']),
    ],
    'تیزر تبلیغاتی': [
      _OrderField('محصول یا خدمت مورد تبلیغ', isRequired: true, hint: 'نام و توضیح کوتاه'),
      _OrderField('هدف تیزر', choices: ['معرفی برند', 'معرفی محصول', 'افزایش فروش', 'معرفی خدمات', 'کمپین تبلیغاتی']),
      _OrderField('مدت تیزر', choices: ['۱۵ تا ۳۰ ثانیه', '۳۰ تا ۶۰ ثانیه', '۱ تا ۲ دقیقه', 'بیش از ۲ دقیقه']),
      _OrderField('سبک تولید', choices: ['موشن‌گرافیک', 'ویدئوی واقعی و تدوین', 'ترکیبی', 'پیشنهاد استودیو']),
      _OrderField('بستر انتشار', choices: ['اینستاگرام', 'وب‌سایت', 'آپارات و پلتفرم ویدئویی', 'نمایشگر و تبلیغات محیطی', 'چند بستر']),
      _OrderField('توضیحات و پیام اصلی', multiline: true),
    ],
    'نگارش مقاله وب‌سایت': [
      _OrderField('موضوع یا حوزه مقاله', isRequired: true, hint: 'موضوع دقیق یا حوزه کلی'),
      _OrderField('تعداد مقاله', choices: ['۱ مقاله', '۲ تا ۵ مقاله', '۶ تا ۱۰ مقاله', 'بیش از ۱۰ مقاله']),
      _OrderField('حجم هر مقاله', choices: ['۵۰۰ تا ۸۰۰ کلمه', '۸۰۰ تا ۱۲۰۰ کلمه', '۱۲۰۰ تا ۲۰۰۰ کلمه', 'بیش از ۲۰۰۰ کلمه', 'پیشنهاد نویسنده']),
      _OrderField('لحن نگارش', choices: ['رسمی و تخصصی', 'آموزشی و ساده', 'تبلیغاتی', 'صمیمی و محاوره‌ای']),
      _OrderField('نیاز به سئوی محتوا', choices: ['بله', 'خیر', 'نیاز به مشاوره']),
      _OrderField('مخاطب و منابع مدنظر', multiline: true),
    ],
    'مشاوره کسب‌وکار آنلاین': [
      _OrderField('حوزه فعالیت', isRequired: true, hint: 'مثلاً فروشگاه، خدمات، آموزش و ...'),
      _OrderField('مرحله کسب‌وکار', choices: ['ایده اولیه', 'شروع فعالیت', 'فعال و نیازمند توسعه', 'فعال و نیازمند بازطراحی مسیر']),
      _OrderField('موضوع مشاوره', isRequired: true, choices: ['شروع کسب‌وکار آنلاین', 'استراتژی و بازاریابی', 'برندینگ', 'محتوا و شبکه‌های اجتماعی', 'وب‌سایت و فروش آنلاین', 'سایر']),
      _OrderField('هدف اصلی و چالش فعلی', multiline: true),
      _OrderField('شیوه ترجیحی', choices: ['جلسه آنلاین', 'مشاوره متنی', 'فرقی ندارد']),
    ],
    'خدمات شبکه‌های اجتماعی': [
      _OrderField('پلتفرم‌های موردنظر', isRequired: true, multi: true, choices: ['اینستاگرام', 'تلگرام', 'لینکدین', 'یوتیوب', 'سایر']),
      _OrderField('نوع خدمات', isRequired: true, multi: true, choices: ['برنامه‌ریزی محتوا', 'طراحی پست و استوری', 'تقویم انتشار', 'مدیریت صفحه', 'ایده‌پردازی و سناریو', 'تحلیل عملکرد']),
      _OrderField('تعداد صفحات یا حساب‌ها', choices: ['۱', '۲ تا ۳', '۴ تا ۵', 'بیش از ۵']),
      _OrderField('آدرس صفحات فعلی', multiline: true, hint: 'در صورت وجود، لینک صفحات را وارد کنید.'),
      _OrderField('هدف فعالیت', multiline: true),
    ],
    'طراحی لوگو اختصاصی': [
      _OrderField('نام برند یا نوشته لوگو', isRequired: true, hint: 'نام دقیق با املای صحیح'),
      _OrderField('حوزه فعالیت برند', hint: 'زمینه کاری برند'),
      _OrderField('سبک موردنظر', choices: ['مینیمال', 'لوکس و رسمی', 'مدرن', 'تایپوگرافی', 'نمادین', 'ترکیبی', 'پیشنهاد طراح']),
      _OrderField('رنگ‌های ترجیحی', hint: 'مثلاً مشکی و طلایی یا بدون محدودیت'),
      _OrderField('موارد استفاده', multi: true, choices: ['وب‌سایت', 'شبکه‌های اجتماعی', 'چاپ و بسته‌بندی', 'کارت و سربرگ', 'همه موارد']),
      _OrderField('توضیحات و نمونه‌های الهام‌بخش', multiline: true),
    ],
    'خدمات SEO': [
      _OrderField('آدرس وب‌سایت', isRequired: true, hint: 'https://example.com'),
      _OrderField('وضعیت فعلی سایت', choices: ['سایت تازه راه‌اندازی شده', 'سایت فعال با بازدید کم', 'سایت فعال با افت بازدید', 'نیازمند بررسی']),
      _OrderField('خدمات موردنیاز', isRequired: true, multi: true, choices: ['بررسی فنی', 'سئوی داخلی', 'سئوی محتوا', 'تحقیق کلمات کلیدی', 'بهبود سرعت', 'بررسی ساختار صفحات', 'گزارش و مشاوره']),
      _OrderField('هدف یا کلمات کلیدی مهم', multiline: true),
      _OrderField('دسترسی به سرچ کنسول', choices: ['دارم', 'ندارم', 'اطلاع ندارم']),
    ],
  };

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _name.text = (user?.userMetadata?['full_name'] ?? '').toString();
    if (widget.initialService != null && _services.contains(widget.initialService)) {
      _service = widget.initialService!;
    }
    final requested = widget.initialServiceQuantities ?? const <String, int>{};
    for (final entry in requested.entries) {
      if (_services.contains(entry.key)) _estimatedServices[entry.key] = entry.value.clamp(1, 100);
    }
    if (_estimatedServices.isNotEmpty) _service = _estimatedServices.keys.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _title.dispose();
    _details.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    final session = auth.currentSession;
    if (user == null || session == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای ثبت سفارش ابتدا وارد حساب کاربری شوید.')));
      return;
    }
    final requiredMultiMissing = _formFields[_service]!
        .where((field) => field.isRequired && field.multi)
        .where((field) => (_multiAnswers[field.label] ?? <String>{}).isEmpty)
        .map((field) => field.label)
        .toList();
    if (requiredMultiMissing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لطفاً این موارد را انتخاب کن: ${requiredMultiMissing.join('، ')}')),
      );
      return;
    }
    final answerLines = <String>[
      for (final entry in _answers.entries)
        if (entry.value.trim().isNotEmpty) '• ${entry.key}: ${entry.value.trim()}',
      for (final entry in _multiAnswers.entries)
        if (entry.value.isNotEmpty) '• ${entry.key}: ${entry.value.join('، ')}',
    ];
    final fullDetails = [
      if (answerLines.isNotEmpty) 'اطلاعات اختصاصی خدمت:\n${answerLines.join('\n')}',
      if (_estimatedServices.isNotEmpty) 'خدمات انتخاب‌شده در برآورد هوشمند:\n${_estimatedServices.entries.map((e) => '• ${e.key} × ${e.value}').join('\n')}',
      if (_details.text.trim().isNotEmpty) 'توضیحات تکمیلی:\n${_details.text.trim()}',
    ].join('\n\n');

    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'mobile-order-submit',
        headers: {'Origin': 'https://alishams.ir'},
        body: {
          'client_name': _name.text.trim(),
          'client_email': user.email ?? '',
          'contact_info': _phone.text.trim(),
          'services': _estimatedServices.isEmpty ? [_service] : _estimatedServices.keys.toList(),
          'service': _service,
          'title': _title.text.trim().isEmpty ? 'درخواست $_service' : _title.text.trim(),
          'details': fullDetails,
          'budget': _budget.text.trim().isEmpty ? 'فعلاً مشخص نیست' : _budget.text.trim(),
        },
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'ثبت سفارش انجام نشد.') : 'پاسخ نامعتبر از سرور دریافت شد.');
      }
      if (!mounted) return;
      ref.invalidate(customerOrdersProvider(user.id));
      setState(() => _tracking = data['tracking_code']?.toString());
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error']?.toString() : null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message ?? 'ارتباط با سرویس ثبت سفارش برقرار نشد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDomainLab() async {
    final uri = Uri.parse('https://alishams.ir/domain-lab.html');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = ref.watch(authProvider).user;
    final fields = _formFields[_service] ?? const <_OrderField>[];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('ثبت سفارش جدید')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _tracking != null
                ? _success(c)
                : Form(
                    key: _form,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('درخواست همکاری', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('ابتدا خدمت را انتخاب کن؛ فرم متناسب با همان خدمت نمایش داده می‌شود. درخواست به حساب ${user?.email ?? ''} متصل خواهد شد.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _service,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'خدمت موردنظر'),
                        items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: _busy ? null : (v) => setState(() {
                          _service = v ?? _service;
                          _answers.clear();
                          _multiAnswers.clear();
                          _title.clear();
                          _details.clear();
                        }),
                      ),
                      if (_estimatedServices.length > 1) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: c.secondary.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.secondary.withValues(alpha: .25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('خدمات انتخاب‌شده در برآورد', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 7),
                              ..._estimatedServices.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(children: [
                                  Expanded(child: Text(entry.key, style: Theme.of(context).textTheme.bodySmall)),
                                  Text('× ${entry.value}', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: c.secondary)),
                                ]),
                              )),
                              const SizedBox(height: 7),
                              Text('فرم جزئیات زیر برای خدمت اصلی نمایش داده می‌شود؛ سایر خدمات و تعدادشان نیز همراه درخواست ارسال می‌شوند.',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionTitle(context, c, 'مشخصات اختصاصی خدمت'),
                      ...fields.map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: _dynamicField(context, c, field),
                      )),
                      if (_service == 'خرید دامنه') ...[
                        const SizedBox(height: 2),
                        OutlinedButton.icon(
                          onPressed: _openDomainLab,
                          icon: const Icon(Icons.travel_explore_rounded),
                          label: const Text('بررسی آزاد بودن و تعرفه در آزمایشگاه دامنه'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Text('فهرست کامل پسوندها و تعرفه‌های به‌روز در آزمایشگاه دامنه قابل بررسی است. نتیجه جست‌وجو، تضمین ثبت قطعی نیست.', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.7)),
                        ),
                      ],
                      const Divider(height: 28),
                      _sectionTitle(context, c, 'اطلاعات تماس و برآورد'),
                      _field(_name, 'نام و نام خانوادگی', validator: (v) => (v == null || v.trim().length < 2) ? 'نام را کامل وارد کنید.' : null),
                      const SizedBox(height: 12),
                      _field(_phone, 'شماره تماس', keyboard: TextInputType.phone, validator: (v) => (v == null || v.trim().length < 8) ? 'شماره تماس معتبر وارد کنید.' : null),
                      const SizedBox(height: 12),
                      _field(_title, 'عنوان درخواست (اختیاری)', hint: 'در صورت خالی بودن، عنوان خودکار ساخته می‌شود.'),
                      const SizedBox(height: 12),
                      _field(_details, 'توضیحات تکمیلی', maxLines: 4, hint: 'هر نکته‌ای که در گزینه‌های بالا نبود بنویسید.'),
                      const SizedBox(height: 12),
                      _field(_budget, 'بودجه پیشنهادی (اختیاری)', hint: 'مثلاً ۵ تا ۸ میلیون تومان', keyboard: TextInputType.text),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                        label: Text(_busy ? 'در حال ثبت سفارش…' : 'ثبت نهایی درخواست'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                      ),
                      const SizedBox(height: 12),
                      Text('پاسخ‌های این فرم همراه درخواست برای بررسی در اختیار استودیو قرار می‌گیرد.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.7)),
                    ]),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _dynamicField(BuildContext context, AppColors c, _OrderField field) {
    if (field.multi) {
      final selected = _multiAnswers.putIfAbsent(field.label, () => <String>{});
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(field.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: field.choices!.map((option) {
          final active = selected.contains(option);
          return FilterChip(
            label: Text(option),
            selected: active,
            onSelected: (value) => setState(() {
              if (value) selected.add(option); else selected.remove(option);
            }),
          );
        }).toList()),
      ]);
    }
    if (field.choices != null) {
      return DropdownButtonFormField<String>(
        key: ValueKey('$_service:${field.label}'),
        value: _answers[field.label],
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        validator: field.isRequired
            ? (value) => (value == null || value.isEmpty) ? 'این گزینه را انتخاب کن.' : null
            : null,
        items: field.choices!.map((value) => DropdownMenuItem(value: value, child: Text(value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (value) => setState(() => _answers[field.label] = value ?? ''),
      );
    }
    return TextFormField(
      key: ValueKey('$_service:${field.label}'),
      initialValue: _answers[field.label],
      minLines: field.multiline ? 3 : 1,
      maxLines: field.multiline ? 5 : 1,
      onChanged: (value) => _answers[field.label] = value,
      validator: field.isRequired
          ? (value) => (value == null || value.trim().isEmpty) ? 'این فیلد را تکمیل کن.' : null
          : null,
      decoration: InputDecoration(labelText: field.label, hintText: field.hint),
    );
  }

  Widget _sectionTitle(BuildContext context, AppColors c, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: c.secondary)),
  );

  Widget _success(AppColors c) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.line)),
    child: Column(children: [
      Icon(Icons.check_circle_rounded, color: c.success, size: 64),
      const SizedBox(height: 16),
      Text('درخواستت ثبت شد', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('کد پیگیری سفارش'),
      const SizedBox(height: 8),
      SelectableText(_tracking ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.secondary, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Text('برای مشاهده وضعیت، به بخش سفارش‌های من برو.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('مشاهده سفارش‌های من'),
      )),
      const SizedBox(height: 8),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('بازگشت')),
    ]),
  );

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType keyboard = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) =>
      TextFormField(controller: controller, keyboardType: keyboard, maxLines: maxLines, validator: validator, decoration: InputDecoration(labelText: label, hintText: hint));
}

class _OrderField {
  final String label;
  final String? hint;
  final List<String>? choices;
  final bool multiline;
  final bool multi;
  final bool isRequired;

  const _OrderField(this.label, {this.hint, this.choices, this.multiline = false, this.multi = false, this.isRequired = false});
}
