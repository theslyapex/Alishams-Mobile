import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});
  @override
  State<ClubScreen> createState()=>_ClubScreenState();
}
class _ClubScreenState extends State<ClubScreen>{
  Map<String,dynamic>? _data;bool _loading=true,_busy=false;String? _error;
  final _brief = TextEditingController();
  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){_brief.dispose();super.dispose();}
  Future<void> _load()async{
    setState(()=>_loading=true);
    try{final r=await Supabase.instance.client.functions.invoke('club-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'status'});final d=r.data;if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'دریافت اطلاعات باشگاه انجام نشد.').toString():'پاسخ نامعتبر');if(mounted)setState(()=>_data=Map<String,dynamic>.from(d));}
    catch(e){if(mounted)setState(()=>_error=e.toString().replaceFirst('Exception: ',''));}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _redeem(int points,int reward)async{
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('دریافت پاداش'),content:Text('برای تبدیل $points امتیاز به پاداش $reward تومان مطمئنی؟ این عملیات قابل بازگشت نیست.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('تأیید دریافت'))]));
    if(ok!=true)return;setState(()=>_busy=true);
    try{final r=await Supabase.instance.client.functions.invoke('club-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'redeem','points':points,'reward_toman':reward});final d=r.data;if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'صدور پاداش انجام نشد.').toString():'پاسخ نامعتبر');await _load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('کد پاداش صادر شد.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  Future<void> _submitTeaser() async {
    final brief=_brief.text.trim();
    if(brief.length<20){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('توضیحات باید حداقل ۲۰ نویسه باشد.')));return;}
    setState(()=>_busy=true);
    try{
      final r=await Supabase.instance.client.functions.invoke('club-api',headers:{'Origin':'https://alishams.ir'},body:{'action':'teaser_submit','brief':brief});
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true)throw Exception(d is Map?(d['error']??'ثبت درخواست انجام نشد.').toString():'پاسخ نامعتبر');
      _brief.clear();await _load();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('درخواست تیزر ثبت شد.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override
  Widget build(BuildContext context){
    final c=AppColors.of(context);final balance=(_data?['balance'] as num?)?.toInt()??0;final lifetime=(_data?['lifetime'] as num?)?.toInt()??0;final tier=(_data?['tier']??'none').toString();final ledger=(_data?['ledger'] as List? ?? const []);final vouchers=(_data?['vouchers'] as List? ?? const []);final rewards=(_data?['reward_options'] as List? ?? const []);final teasers=(_data?['teaser_requests'] as List? ?? const []);final diamond=_data?['diamond_eligible']==true;final nextTier=(_data?['next_tier']??'').toString();final pointsRemaining=(_data?['points_to_next_tier'] as num?)?.toInt()??0;
    const tierNames={'none':'بدون لیگ','bronze':'برنزی','silver':'نقره‌ای','gold':'طلایی','diamond':'الماس'};
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(backgroundColor:c.background,appBar:AppBar(title:const Text('باشگاه مشتریان'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),body:_loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(20),children:[
      if(_error!=null)Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(16)),child:Column(children:[Text(_error!,textAlign:TextAlign.center),TextButton(onPressed:_load,child:const Text('تلاش دوباره'))])),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:LinearGradient(colors:[c.primary,c.surface]),borderRadius:BorderRadius.circular(22),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('سطح عضویت شما',style:TextStyle(color:c.muted)),const SizedBox(height:6),Text(tierNames[tier]??tier,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:14),
        Row(children:[Expanded(child:_metric('امتیاز قابل استفاده',balance.toString())),Expanded(child:_metric('مجموع امتیاز کسب‌شده',lifetime.toString()))]),
        const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:((_data?['progress'] as num?)?.toDouble()??0)/100,minHeight:9)),
        const SizedBox(height:7),Text(diamond?'به بالاترین لیگ باشگاه رسیده‌ای.':'تا لیگ ${tierNames[nextTier]??nextTier}، $pointsRemaining امتیاز دیگر لازم است.',style:TextStyle(color:c.muted,fontSize:12)),
      ])),
      const SizedBox(height:18),Text('پاداش‌های قابل دریافت',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
      ...rewards.map((e){final points=(e['points'] as num?)?.toInt()??0;final reward=(e['reward_toman'] as num?)?.toInt()??0;final claimed=vouchers.any((v)=>(v['points_spent'] as num?)?.toInt()==points);return Container(margin:const EdgeInsets.only(top:9),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(16),border:Border.all(color:c.line)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('$points امتیاز',style:const TextStyle(fontWeight:FontWeight.w800)),Text('$reward تومان اعتبار پاداش',style:TextStyle(color:c.muted,fontSize:12))])),FilledButton(onPressed:_busy||claimed||balance<points?null:()=>_redeem(points,reward),child:Text(claimed?'دریافت‌شده':balance<points?'امتیاز ناکافی':'دریافت'))]));}),

      if(diamond)...[
        const SizedBox(height:18),
        Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(18),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('تیزر تبلیغاتی رایگان هفتگی',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:6),
          Text('مزیت ویژه اعضای لیگ الماس؛ توضیحات تیزر را برای مدیریت ارسال کن.',style:TextStyle(color:c.muted,fontSize:12,height:1.5)),
          const SizedBox(height:10),
          TextField(controller:_brief,minLines:3,maxLines:5,maxLength:1200,decoration:const InputDecoration(labelText:'شرح تیزر و پیام تبلیغاتی')),
          const SizedBox(height:8),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:_busy?null:_submitTeaser,child:Text(_busy?'در حال ثبت…':'ثبت درخواست تیزر'))),
        ])),
      ],
      if(teasers.isNotEmpty)...[
        const SizedBox(height:18),Text('درخواست‌های تیزر من',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        ...teasers.map((x)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(14),border:Border.all(color:c.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('وضعیت: ${x['status']??'در انتظار'}',style:const TextStyle(fontWeight:FontWeight.w700)),
          Text((x['brief']??'').toString(),style:TextStyle(color:c.muted,fontSize:12)),
          if((x['admin_note']??'').toString().isNotEmpty)Text('یادداشت مدیریت: ${x['admin_note']}',style:TextStyle(color:c.warning,fontSize:12)),
          if((x['delivery_url']??'').toString().isNotEmpty)TextButton.icon(onPressed:()=>Clipboard.setData(ClipboardData(text:x['delivery_url'].toString())),icon:const Icon(Icons.copy,size:16),label:const Text('کپی لینک تحویل')),
        ]))),
      ],

      if(vouchers.isNotEmpty)...[const SizedBox(height:18),Text('کدهای پاداش من',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...vouchers.map((v)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:c.line)),child:Row(children:[Expanded(child:Text('${v['code']??'کد پاداش'}',style:const TextStyle(fontWeight:FontWeight.w800))),Text('${v['reward_toman']??0} تومان')])))] ,
      if(ledger.isNotEmpty)...[const SizedBox(height:18),Text('تاریخچه امتیازها',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),...ledger.map((x)=>Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(13),border:Border.all(color:c.line)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((x['description']??x['event_type']??'تغییر امتیاز').toString()),Text((x['event_type']??'').toString(),style:TextStyle(color:c.muted,fontSize:11))])),Text('${(x['points'] as num?)?.toInt()??0}',style:TextStyle(fontWeight:FontWeight.w900,color:((x['points'] as num?)?.isNegative??false)?c.danger:c.success))])))] ,
      const SizedBox(height:12),Text('امتیازها و پاداش‌ها از سرویس رسمی باشگاه دریافت می‌شوند؛ صدور پاداش فقط پس از تأیید سرور انجام می‌شود.',style:TextStyle(color:c.muted,fontSize:11,height:1.6)),
    ]))));
  }
  Widget _metric(String label,String value)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(color:Colors.white.withValues(alpha:.75),fontSize:11)),const SizedBox(height:4),Text(value,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:21))]);
}
