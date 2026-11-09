import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  static const int _price = 2890000;
  static const String _cardNumber = '6219861927099035';
  static const String _cardOwner = 'علی شمس الدینی';

  Map<String,dynamic>? _data;
  bool _loading=true, _busy=false, _level3Approved=false, _levelLoading=true;
  String? _error, _levelMessage;
  XFile? _receipt;
  final _reel=TextEditingController();
  final _brand=TextEditingController();
  final _domain=TextEditingController();
  final _relatedOrder=TextEditingController();

  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){_reel.dispose();_brand.dispose();_domain.dispose();_relatedOrder.dispose();super.dispose();}

  Future<void> _load() async {
    if(mounted)setState(()=>_loading=true);
    await Future.wait([_loadStatus(),_loadLevel()]);
    if(mounted)setState(()=>_loading=false);
  }

  Future<void> _loadStatus() async {
    try {
      final r=await Supabase.instance.client.functions.invoke('mobile-plus-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'status'});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true) throw Exception(d is Map?(d['error']??'دریافت وضعیت پلاس انجام نشد.').toString():'پاسخ نامعتبر سرور');
      if(mounted)setState(()=>_data=Map<String,dynamic>.from(d),);
    } catch(e){if(mounted)setState(()=>_error=e.toString().replaceFirst('Exception: ',''));}
  }

  Future<void> _loadLevel() async {
    if(mounted)setState(()=>_levelLoading=true);
    try {
      final result=await Supabase.instance.client.rpc('get_my_account_level_status');
      final data=result is List ? (result.isNotEmpty ? result.first : null) : result;
      final level=data is Map ? int.tryParse((data['level']??0).toString())??0 : 0;
      final status=data is Map ? (data['level3_status']??'').toString() : '';
      final approved=level==3&&status=='approved';
      String message;
      if(approved){message='سطح ۳ حساب شما تأیید شده است؛ امکان ارسال رسید فراهم است.';}
      else if(status=='pending'){message='درخواست ارتقای سطح ۳ در انتظار بررسی مدیریت است. پس از تأیید می‌توانی رسید پرداخت را ارسال کنی.';}
      else if(status=='rejected'){message='درخواست سطح ۳ تأیید نشده است. توضیح مدیریت را در پروفایل حساب بررسی کن.';}
      else if(level==0){message='ابتدا ایمیل حساب کاربری را تأیید کن تا به سطح ۱ برسی.';}
      else if(level==1){message='حساب GitHub را از بخش پروفایل متصل کن و سپس درخواست سطح ۳ را برای بررسی مدیریت بفرست.';}
      else {message='برای خرید پلاس+ باید درخواست ارتقای سطح ۳ را از پروفایل ارسال کنی و منتظر تأیید مدیریت بمانی.';}
      if(mounted)setState(()=>{_level3Approved=approved,_levelMessage=message});
    } catch(_){
      if(mounted)setState(()=>{_level3Approved=false,_levelMessage='امکان بررسی سطح حساب وجود ندارد. برای جلوگیری از ثبت درخواست ناقص، ارسال رسید تا زمان تأیید سطح ۳ غیرفعال است.'});
    } finally {if(mounted)setState(()=>_levelLoading=false);}
  }

  Future<void> _pickReceipt() async {
    try {
      final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:88);
      if(file==null)return;
      final bytes=await file.length();
      if(bytes>5*1024*1024){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('حجم تصویر رسید باید حداکثر ۵ مگابایت باشد.')));
        return;
      }
      final ext=file.name.toLowerCase();
      if(!(ext.endsWith('.jpg')||ext.endsWith('.jpeg')||ext.endsWith('.png')||ext.endsWith('.webp'))){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فقط تصویر JPG، PNG یا WebP پذیرفته می‌شود.')));
        return;
      }
      if(mounted)setState(()=>_receipt=file);
    } catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('انتخاب تصویر انجام نشد: $e')));
    }
  }

  Future<void> _submitReceipt() async {
    final file=_receipt;
    if(file==null||!_level3Approved)return;
    setState(()=>_busy=true);
    try {
      final bytes=await file.readAsBytes();
      final mime=file.name.toLowerCase().endsWith('.png')?'image/png':file.name.toLowerCase().endsWith('.webp')?'image/webp':'image/jpeg';
      final r=await Supabase.instance.client.functions.invoke(
        'mobile-plus-api',
        headers:{'Origin':'https://alishams.ir'},
        body:{'action':'manual_submit','mime_type':mime,'image_base64':base64Encode(bytes)},
      );
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'ارسال رسید انجام نشد.').toString():'پاسخ نامعتبر');
      if(!mounted)return;
      setState(()=>_receipt=null);
      await _load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رسید با موفقیت ثبت شد و در انتظار بررسی مدیریت است.')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
    }finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _copyCard() async {
    await Clipboard.setData(const ClipboardData(text:_cardNumber));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شماره کارت کپی شد.')));
  }


  Future<void> _submitDomain() async {
    final brand=_brand.text.trim(),domain=_domain.text.trim().toLowerCase(),order=_relatedOrder.text.trim();
    if(brand.isEmpty||domain.isEmpty||order.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('همه فیلدهای درخواست دامنه را تکمیل کن.')));return;}
    setState(()=>_busy=true);
    try{
      final r=await Supabase.instance.client.functions.invoke('mobile-plus-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'domain_submit','brand_name':brand,'desired_domain':domain,'related_order':order});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'ثبت درخواست دامنه انجام نشد.').toString():'پاسخ نامعتبر');
      _brand.clear();_domain.clear();_relatedOrder.clear();await _loadStatus();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('درخواست دامنه ثبت شد و برای بررسی ارسال شد.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _submitReel() async {
    final link=_reel.text.trim();
    if(link.isEmpty)return;
    setState(()=>_busy=true);
    try{
      final r=await Supabase.instance.client.functions.invoke('mobile-plus-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'reel_submit','reel_url':link});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'ثبت درخواست انجام نشد.').toString():'پاسخ نامعتبر');
      _reel.clear();await _loadStatus();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('درخواست بازدید ثبت شد.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override
  Widget build(BuildContext context){
    final c=AppColors.of(context);
    final m=_data?['membership'] as Map?;
    final active=m?['is_active']==true;
    final end=DateTime.tryParse((m?['ends_at']??'').toString())?.toLocal();
    final history=(_data?['purchase_history'] as List? ?? const []);
    final reels=(_data?['reels'] as List? ?? const []);
    final domains=(_data?['domains'] as List? ?? const []);
    final reelUsed=(_data?['reel_quota_used'] as num?)?.toInt()??0;
    final reelLimit=(_data?['reel_quota_limit'] as num?)?.toInt()??30;
    final latest=_data?['latest_manual_payment'] as Map?;
    final manualHistory=history.where((x)=>x is Map&&x['payment_provider']=='card_transfer').toList();
    final latestNote=manualHistory.isNotEmpty?(manualHistory.first as Map)['admin_note']?.toString():null;
    final pending=latest?['payment_status']=='pending';
    final failed=latest?['payment_status']=='failed';
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      backgroundColor:c.background,
      appBar:AppBar(title:const Text('عضویت پلاس+'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),
      body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),children:[
        if(_error!=null)_panel(c,Column(children:[Text(_error!,textAlign:TextAlign.center),TextButton(onPressed:_load,child:const Text('تلاش دوباره'))])),
        _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(Icons.workspace_premium_rounded,color:c.tertiary,size:32),const SizedBox(width:10),Expanded(child:Text(active?'عضویت پلاس فعال است':'عضویت پلاس فعال نیست',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)))]),
          const SizedBox(height:12),
          Text(active?'مزایای عضویت برای این حساب فعال است.':'عضویت با پرداخت یک‌باره و تأیید رسید توسط مدیریت فعال می‌شود.',style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:c.muted,height:1.7)),
          if(active)...[const SizedBox(height:12),_line('درصد تخفیف فعلی','${m?['discount_percent']??10}٪',c),_line('تعداد استفاده از تخفیف','${m?['discount_use_count']??0}',c),_line('پایان اعتبار',end==null?'ثبت نشده':'${end.year}/${end.month.toString().padLeft(2,'0')}/${end.day.toString().padLeft(2,'0')}',c),_line('سهمیه درخواست بازدید','${reelUsed} از ${reelLimit} درخواست در این دوره',c)],
        ])),
        const SizedBox(height:14),
        _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('خرید یا تمدید پلاس+',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          Text('۲٬۸۹۰٬۰۰۰ تومان',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900,color:c.secondary)),
          Text('برای یک دوره ۳۰ روزه • بدون تمدید خودکار',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted)),
          const SizedBox(height:16),
          Text('اطلاعات واریز',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:c.background,borderRadius:BorderRadius.circular(15),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('شماره کارت',style:TextStyle(color:c.muted,fontSize:12)),
            const SizedBox(height:5),
            SelectableText('6219 8619 2709 9035',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900,letterSpacing:1)),
            Text('به نام: علی شمس الدینی',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted)),
            Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:_copyCard,icon:const Icon(Icons.copy_rounded,size:17),label:const Text('کپی شماره کارت'))),
          ])),
          const SizedBox(height:12),
          if(_levelLoading)const LinearProgressIndicator(),
          if(!_levelLoading&&!_level3Approved)_notice(c,_levelMessage??'برای خرید پلاس+ سطح ۳ حساب لازم است.',Icons.lock_outline_rounded),
          if(_level3Approved&&!pending)...[
            if(failed&&latestNote!=null&&latestNote.isNotEmpty)_notice(c,'رسید قبلی تأیید نشد: $latestNote',Icons.info_outline_rounded),
            OutlinedButton.icon(onPressed:_busy?null:_pickReceipt,icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(_receipt==null?'انتخاب تصویر رسید':'تغییر تصویر رسید')),
            if(_receipt!=null)...[
              const SizedBox(height:8),
              ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.file(File(_receipt!.path),height:170,width:double.infinity,fit:BoxFit.contain)),
              Text(_receipt!.name,style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted),maxLines:1,overflow:TextOverflow.ellipsis),
            ],
            const SizedBox(height:10),
            SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy||_receipt==null?null:_submitReceipt,icon:_busy?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.cloud_upload_outlined),label:Text(_busy?'در حال ارسال امن رسید…':active?'ارسال رسید برای تمدید عضویت':'ارسال رسید برای بررسی مدیر'))),
          ],
          if(pending)_notice(c,'رسید شما ثبت شده و در انتظار بررسی مدیریت است. تا اعلام نتیجه، امکان ارسال رسید جدید وجود ندارد.',Icons.hourglass_top_rounded),
          const SizedBox(height:8),
          Text('فعال‌سازی پس از بررسی و تأیید رسید توسط مدیریت انجام می‌شود. ارسال رسید به‌تنهایی عضویت را فعال نمی‌کند.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.7)),
        ])),
        const SizedBox(height:14),
        _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('مزایای پلاس+',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          const Text('• تخفیف خرید اول و دوم عضویت: ۱۰٪\n• تخفیف از سومین خرید عضویت به بعد: ۱۸٪\n• سهمیه ۳۰ درخواست بازدید ریلز در هر دوره عضویت\n• امکان درخواست دامنه .ir با شرایط مشخص'),
          const SizedBox(height:8),
          Text('خرید دامنه به‌تنهایی مشمول تخفیف پلاس نیست.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.warning)),
        ])),
        if(active)...[
          const SizedBox(height:14),
          _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('درخواست بازدید هدیه ریلز',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
            const SizedBox(height:6),Text('لینک مستقیم Reel اینستاگرام را وارد کن. سهمیه و امکان ثبت درخواست توسط سرور بررسی می‌شود.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.6)),
            const SizedBox(height:12),TextField(controller:_reel,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'لینک ریلز اینستاگرام',hintText:'https://www.instagram.com/reel/...')),
            const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:_busy?null:_submitReel,child:Text(_busy?'در حال ثبت…':'ثبت درخواست'))),
          ])),
        ],

        if(active)...[
          const SizedBox(height:14),
          _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('درخواست دامنه .ir',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
            const SizedBox(height:6),
            Text('این درخواست فقط برای اعضای فعال پلاس و سفارش واجد شرایط طراحی وب‌سایت قابل ثبت است. دامنه به‌تنهایی تخفیف پلاس نمی‌گیرد.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.6)),
            const SizedBox(height:10),
            TextField(controller:_brand,decoration:const InputDecoration(labelText:'نام برند')),
            const SizedBox(height:8),
            TextField(controller:_domain,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'دامنه درخواستی',hintText:'example.ir')),
            const SizedBox(height:8),
            TextField(controller:_relatedOrder,decoration:const InputDecoration(labelText:'عنوان دقیق سفارش طراحی سایت')),
            const SizedBox(height:10),
            SizedBox(width:double.infinity,child:FilledButton(onPressed:_busy?null:_submitDomain,child:Text(_busy?'در حال ثبت…':'ثبت درخواست دامنه'))),
          ])),
        ],
        if(domains.isNotEmpty)...[
          const SizedBox(height:16),
          Text('درخواست‌های دامنه من',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
          ...domains.map((x)=>_historyTile(c,'${x['desired_domain']??'دامنه'} • ${x['status']??'در انتظار'}','${x['brand_name']??''} • ${x['admin_note']??''}')),
        ],

        if(reels.isNotEmpty)...[const SizedBox(height:18),Text('درخواست‌های بازدید',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...reels.map((x)=>_historyTile(c,'بازدید ریلز • ${x['status']??'در انتظار'}','${x['reel_url']??''}'))],
        if(history.isNotEmpty)...[const SizedBox(height:18),Text('سوابق عضویت و پرداخت',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...history.map((x)=>_historyTile(c,'${x['payment_status']??'نامشخص'} • ${x['amount_toman']??0} تومان','${x['admin_note']??''}'))],
      ])),
    ));
  }

  Widget _panel(AppColors c,Widget child)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:c.line)),child:child);
  Widget _notice(AppColors c,String text,IconData icon)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:c.background,borderRadius:BorderRadius.circular(13),border:Border.all(color:c.line)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:c.warning,size:20),const SizedBox(width:9),Expanded(child:Text(text,style:Theme.of(context).textTheme.bodySmall?.copyWith(height:1.6)))]));
  Widget _line(String a,String b,AppColors c)=>Padding(padding:const EdgeInsets.only(top:9),child:Row(children:[Expanded(child:Text(a,style:TextStyle(color:c.muted))),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]));
  Widget _historyTile(AppColors c,String title,String subtitle)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),if(subtitle.isNotEmpty)Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:c.muted,fontSize:12))]));
}
