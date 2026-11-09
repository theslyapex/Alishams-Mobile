import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});
  @override
  State<PlusScreen> createState() => _PlusScreenState();
}
class _PlusScreenState extends State<PlusScreen> {
  Map<String,dynamic>? _data;
  bool _loading=true, _busy=false;
  String? _error;
  final _reel=TextEditingController();
  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){_reel.dispose();super.dispose();}
  Future<void> _load() async {
    setState(()=>_loading=true);
    try {
      final r=await Supabase.instance.client.functions.invoke('plus-membership',headers:{'Origin':'https://alishams.ir'},body:{'action':'status'});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true) throw Exception(d is Map?(d['error']??'دریافت وضعیت پلاس انجام نشد.').toString():'پاسخ نامعتبر سرور');
      if(mounted)setState(()=>_data=Map<String,dynamic>.from(d),);
    } catch(e){if(mounted)setState(()=>_error=e.toString().replaceFirst('Exception: ',''));}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _submitReel() async {
    final link=_reel.text.trim();
    if(link.isEmpty)return;
    setState(()=>_busy=true);
    try{
      final r=await Supabase.instance.client.functions.invoke('plus-membership',headers:{'Origin':'https://alishams.ir'},body:{'action':'reel_submit','reel_url':link});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'ثبت درخواست انجام نشد.').toString():'پاسخ نامعتبر');
      _reel.clear();await _load();
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
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:c.background,appBar:AppBar(title:const Text('عضویت پلاس+'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),children:[
      if(_error!=null)_panel(c,Column(children:[Text(_error!,textAlign:TextAlign.center),TextButton(onPressed:_load,child:const Text('تلاش دوباره'))])),
      _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(Icons.workspace_premium_rounded,color:c.tertiary,size:32),const SizedBox(width:10),Expanded(child:Text(active?'عضویت پلاس فعال است':'عضویت پلاس فعال نیست',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)))]),
        const SizedBox(height:12),
        Text(active?'مزایای عضویت برای این حساب فعال است.':'برای فعال‌سازی یا تمدید عضویت، از مسیرهای رسمی سایت اقدام کن.',style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:c.muted,height:1.7)),
        if(active)...[const SizedBox(height:12),_line('درصد تخفیف فعلی','${m?['discount_percent']??10}٪',c),_line('تعداد استفاده از تخفیف','${m?['discount_use_count']??0}',c),_line('پایان اعتبار',end==null?'ثبت نشده':'${end.year}/${end.month.toString().padLeft(2,'0')}/${end.day.toString().padLeft(2,'0')}',c)],
      ])),
      const SizedBox(height:14),
      _panel(c,Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('مزایای پلاس+',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        const Text('• تخفیف خرید خدمات واجد شرایط بر اساس قوانین عضویت\n• امکان ثبت درخواست بازدید هدیه برای ریلز اینستاگرام\n• ثبت و پیگیری درخواست‌های مزایای عضویت'),
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
      if(reels.isNotEmpty)...[const SizedBox(height:18),Text('درخواست‌های بازدید',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...reels.map((x)=>_historyTile(c,'بازدید ریلز • ${x['status']??'در انتظار'}','${x['reel_url']??''}'))],
      if(history.isNotEmpty)...[const SizedBox(height:18),Text('سوابق عضویت و پرداخت',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...history.map((x)=>_historyTile(c,'${x['payment_status']??'نامشخص'} • ${x['amount_toman']??0} تومان','${x['admin_note']??''}'))],
    ]))));
  }
  Widget _panel(AppColors c,Widget child)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:c.line)),child:child);
  Widget _line(String a,String b,AppColors c)=>Padding(padding:const EdgeInsets.only(top:9),child:Row(children:[Expanded(child:Text(a,style:TextStyle(color:c.muted))),Text(b,style:const TextStyle(fontWeight:FontWeight.w700))]));
  Widget _historyTile(AppColors c,String title,String subtitle)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),if(subtitle.isNotEmpty)Text(subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:c.muted,fontSize:12))]));
}
