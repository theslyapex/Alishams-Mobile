import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String,dynamic>> _items=[];
  bool _loading=true,_busy=false;
  String? _error;
  String _filter='all';

  @override
  void initState(){super.initState();_load();}

  Future<void> _load() async {
    if(mounted)setState(()=>_loading=true);
    try{
      final r=await Supabase.instance.client.functions.invoke(
        'mobile-project-account',
        headers:{'Origin':'https://alishams.ir'},
        body:{'action':'notifications'},
      );
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true){
        throw Exception(d is Map?(d['error']??'دریافت اعلان‌ها انجام نشد.').toString():'پاسخ نامعتبر');
      }
      final raw=d['notifications'] as List? ?? const [];
      if(mounted)setState((){
        _items=raw.map((x)=>Map<String,dynamic>.from(x as Map)).toList();
        _error=null;
      });
    }catch(e){
      if(mounted)setState(()=>_error=e.toString().replaceFirst('Exception: ',''));
    }finally{if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _markRead(List<String> ids) async {
    if(ids.isEmpty||_busy)return;
    setState(()=>_busy=true);
    try{
      final r=await Supabase.instance.client.functions.invoke(
        'mobile-project-account',
        headers:{'Origin':'https://alishams.ir'},
        body:{'action':'mark_notifications_read','notification_ids':ids},
      );
      final d=r.data;
      if(r.status<200||r.status>=300||d is! Map||d['ok']!=true){
        throw Exception(d is Map?(d['error']??'تغییر وضعیت اعلان انجام نشد.').toString():'پاسخ نامعتبر');
      }
      await _load();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))),
      );
    }finally{if(mounted)setState(()=>_busy=false);}
  }

  String _categoryName(String key)=>const {
    'all':'همه','orders':'سفارش‌ها','projects':'پروژه‌ها',
    'payments':'پرداخت‌ها','club':'باشگاه','plus':'پلاس+','account':'حساب کاربری',
  }[key]??'حساب کاربری';

  IconData _icon(String key)=>const {
    'orders':Icons.receipt_long_rounded,'projects':Icons.folder_copy_rounded,
    'payments':Icons.payments_rounded,'club':Icons.emoji_events_rounded,
    'plus':Icons.workspace_premium_rounded,'account':Icons.notifications_active_rounded,
  }[key]??Icons.notifications_rounded;

  String _date(dynamic value){
    final d=DateTime.tryParse((value??'').toString())?.toLocal();
    if(d==null)return '';
    final two=(int n)=>n.toString().padLeft(2,'0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  •  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context){
    final c=AppColors.of(context);
    final unread=_items.where((x)=>x['read_at']==null).length;
    final visible=_filter=='all'?_items:_items.where((x)=>x['category']==_filter).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      backgroundColor:c.background,
      appBar:AppBar(
        title:const Text('اعلان‌ها'),
        actions:[
          if(unread>0)TextButton(
            onPressed:_busy?null:()=>_markRead(_items.where((x)=>x['read_at']==null).map((x)=>x['id'].toString()).toList()),
            child:const Text('خواندن همه'),
          ),
          IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded)),
        ],
      ),
      body:_loading?const Center(child:CircularProgressIndicator()):
        RefreshIndicator(onRefresh:_load,child:ListView(
          padding:const EdgeInsets.fromLTRB(16,12,16,28),
          children:[
            Container(
              padding:const EdgeInsets.all(16),
              decoration:BoxDecoration(
                color:c.surface,borderRadius:BorderRadius.circular(18),
                border:Border.all(color:c.line),
              ),
              child:Row(children:[
                Container(width:44,height:44,decoration:BoxDecoration(
                  color:c.primary.withValues(alpha:.14),borderRadius:BorderRadius.circular(14)),
                  child:Icon(Icons.notifications_active_outlined,color:c.primary)),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Text('مرکز اطلاع‌رسانی',style:TextStyle(fontWeight:FontWeight.w800)),
                  const SizedBox(height:3),
                  Text(unread==0?'همه اعلان‌ها خوانده شده‌اند.':'$unread اعلان خوانده‌نشده داری.',
                    style:TextStyle(color:c.muted,fontSize:12)),
                ])),
                Text(unread.toString(),style:TextStyle(color:c.secondary,fontWeight:FontWeight.w900,fontSize:22)),
              ]),
            ),
            const SizedBox(height:14),
            SizedBox(height:42,child:ListView(
              scrollDirection:Axis.horizontal,
              children:[
                for(final item in const [
                  ['all','همه'],['orders','سفارش‌ها'],['projects','پروژه‌ها'],
                  ['payments','پرداخت‌ها'],['club','باشگاه'],['plus','پلاس+'],['account','حساب'],
                ])
                  Padding(padding:const EdgeInsets.only(left:7),child:ChoiceChip(
                    label:Text(item[1]),selected:_filter==item[0],
                    onSelected:(_)=>setState(()=>_filter=item[0]),
                  )),
              ],
            )),
            if(_error!=null)Container(
              margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(15),border:Border.all(color:c.line)),
              child:Column(children:[
                Text(_error!,textAlign:TextAlign.center),
                TextButton(onPressed:_load,child:const Text('تلاش دوباره')),
              ]),
            ),
            if(visible.isEmpty&&_error==null)Padding(
              padding:const EdgeInsets.only(top:70),
              child:Column(children:[
                Icon(Icons.notifications_off_outlined,size:42,color:c.muted),
                const SizedBox(height:12),
                Text('اعلانی در این بخش وجود ندارد.',style:TextStyle(color:c.muted)),
              ]),
            ),
            ...visible.map((item){
              final category=(item['category']??'account').toString();
              final isRead=item['read_at']!=null;
              return Container(
                margin:const EdgeInsets.only(top:10),
                padding:const EdgeInsets.all(15),
                decoration:BoxDecoration(
                  color:c.surface,borderRadius:BorderRadius.circular(17),
                  border:Border.all(color:isRead?c.line:c.primary.withValues(alpha:.55)),
                ),
                child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Container(width:42,height:42,decoration:BoxDecoration(
                    color:c.secondary.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),
                    child:Icon(_icon(category),color:c.secondary)),
                  const SizedBox(width:11),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[
                      Expanded(child:Text((item['title']??'اعلان جدید').toString(),
                        style:TextStyle(fontWeight:isRead?FontWeight.w600:FontWeight.w900))),
                      if(!isRead)Container(width:7,height:7,decoration:BoxDecoration(color:c.primary,shape:BoxShape.circle)),
                    ]),
                    const SizedBox(height:5),
                    Text((item['body']??'').toString(),style:TextStyle(color:c.muted,fontSize:12,height:1.6)),
                    const SizedBox(height:8),
                    Row(children:[
                      Text(_categoryName(category),style:TextStyle(color:c.secondary,fontSize:10)),
                      const SizedBox(width:8),
                      Expanded(child:Text(_date(item['created_at']),style:TextStyle(color:c.muted,fontSize:10))),
                      if(!isRead)TextButton(
                        onPressed:_busy?null:()=>_markRead([item['id'].toString()]),
                        child:const Text('خواندم',style:TextStyle(fontSize:11)),
                      ),
                    ]),
                  ])),
                ]),
              );
            }),
            const SizedBox(height:20),
            Text('اعلان‌های سفارش و پروژه، پرداخت‌ها، پلاس+ و باشگاه مشتریان در این بخش نمایش داده می‌شوند.',
              textAlign:TextAlign.center,style:TextStyle(color:c.muted,fontSize:11,height:1.6)),
          ],
        )),
    ));
  }
}
