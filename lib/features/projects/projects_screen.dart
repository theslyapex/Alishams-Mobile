import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String,dynamic>> _projects = [];
  List<Map<String,dynamic>> _payments = [];
  List<Map<String,dynamic>> _files = [];
  List<Map<String,dynamic>> _history = [];
  final _money = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String,dynamic>> _invoke(String action, [Map<String,dynamic> body = const {}]) async {
    final response = await Supabase.instance.client.functions.invoke(
      'mobile-project-account',
      body: {'action': action, ...body},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(message?.isNotEmpty == true ? message : 'ارتباط با سرویس پروژه‌ها انجام نشد.');
    }
    return Map<String,dynamic>.from(data);
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _invoke('dashboard');
      if (!mounted) return;
      setState(() {
        _projects = (data['projects'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
        _payments = (data['payments'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
        _files = (data['files'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
        _history = (data['history'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _uploadReceipt(Map<String,dynamic> project) async {
    final id = (project['id'] ?? '').toString();
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800, maxHeight: 1800);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _message('حجم تصویر باید حداکثر ۵ مگابایت باشد.');
        return;
      }
      final ext = image.name.toLowerCase();
      final mime = ext.endsWith('.png') ? 'image/png' : (ext.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      setState(() => _loading = true);
      final result = await _invoke('upload_payment_receipt', {
        'project_id': id,
        'mime_type': mime,
        'image_base64': 'data:$mime;base64,${base64Encode(bytes)}',
      });
      if (!mounted) return;
      _message(result['message']?.toString() ?? 'رسید برای بررسی ارسال شد.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _downloadFile(Map<String,dynamic> file) async {
    try {
      final result = await _invoke('download_file', {'file_id': file['id']});
      final uri = Uri.tryParse((result['url'] ?? '').toString());
      if (uri == null || !uri.hasScheme) throw Exception('لینک دریافت فایل معتبر نیست.');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('باز کردن فایل انجام نشد.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString());
    if (date == null) return '—';
    return DateFormat('yyyy/MM/dd  HH:mm').format(date.toLocal());
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _status(String value) => const {
    'awaiting_payment':'در انتظار پرداخت','not_started':'شروع نشده','in_progress':'در حال اجرا',
    'review':'در انتظار بررسی','on_hold':'متوقف موقت','completed':'تکمیل‌شده','cancelled':'لغوشده'
  }[value] ?? value;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('پروژه‌های من'),
          actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded), tooltip: 'به‌روزرسانی')],
        ),
        body: SafeArea(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded, size: 42, color: c.muted),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
                  ]),
                ))
              : _projects.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_open_rounded, size: 52, color: c.muted),
                      const SizedBox(height: 14),
                      Text('هنوز پروژه‌ای برای این حساب ثبت نشده است.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('پس از پذیرش پیشنهاد و تبدیل سفارش توسط استودیو، پروژه و مراحل پرداخت در این بخش نمایش داده می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8), textAlign: TextAlign.center),
                    ]),
                  ))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                      children: [
                        Text('پیگیری اجرا و تسویه', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('وضعیت پروژه، پرداخت‌های تأییدشده و مانده حساب در این بخش همگام می‌شود.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
                        const SizedBox(height: 18),
                        ..._projects.map((p) => _projectCard(context, c, p)),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _projectCard(BuildContext context, AppColors c, Map<String,dynamic> p) {
    final id = (p['id'] ?? '').toString();
    final payments = _payments.where((x)=>x['project_id']==id).toList();
    final files = _files.where((x)=>x['project_id']==id).toList();
    final receipts = files.where((x)=>(x['file_name']??'').toString().startsWith('رسید کارت‌به‌کارت') || (x['description']??'').toString().contains('رسید پرداخت کارت‌به‌کارت')).toList();
    final history = _history.where((x)=>x['project_id']==id).toList();
    final total = (p['payable_amount'] as num?)?.toDouble() ?? ((p['total_price'] as num?)?.toDouble() ?? 0);
    final paid = (p['paid_amount'] as num?)?.toDouble() ?? 0;
    final remaining = (p['remaining_amount'] as num?)?.toDouble() ?? (total-paid).clamp(0,double.infinity);
    final progress = ((p['progress'] as num?)?.toDouble() ?? 0).clamp(0,100);
    final status = (p['status'] ?? '').toString();
    final hasBalance = remaining > 0 && status != 'cancelled';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:.12), blurRadius: 18, offset: const Offset(0,8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text((p['title']??'پروژه').toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration: BoxDecoration(color:c.primary.withValues(alpha:.14),borderRadius:BorderRadius.circular(20)), child: Text(_status(status),style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.secondary))),
        ]),
        const SizedBox(height:8),
        Text('کد پروژه: ${p['tracking_code'] ?? '—'}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
        const SizedBox(height:5),
        Text('آخرین به‌روزرسانی: ${_dateLabel(p['updated_at'])}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
        if ((p['description']??'').toString().trim().isNotEmpty) ...[
          const SizedBox(height:10),
          Text(p['description'].toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.8)),
        ],
        const SizedBox(height:15),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text('پیشرفت پروژه',style:Theme.of(context).textTheme.labelMedium?.copyWith(color:c.muted)),
          Text('${progress.toStringAsFixed(0)}٪',style:Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight:FontWeight.w800)),
        ]),
        const SizedBox(height:7),
        ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:progress/100,minHeight:7,backgroundColor:c.line,color:c.secondary)),
        const SizedBox(height:16),
        _moneyRow(context,'مبلغ نهایی پروژه',total,c),
        _moneyRow(context,'پرداخت تأییدشده',paid,c,positive:true),
        _moneyRow(context,'مانده قابل پرداخت',remaining,c,emphasize:true),
        if (history.isNotEmpty) ...[
          const SizedBox(height:16),
          Text('روند اجرای پروژه',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:9),
          ...history.take(8).map((event)=>Padding(
            padding:const EdgeInsets.only(bottom:11),
            child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Padding(padding:const EdgeInsets.only(top:3),child:Icon(Icons.radio_button_checked_rounded,size:16,color:c.secondary)),
              const SizedBox(width:9),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(_status((event['status']??'').toString()),style:Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight:FontWeight.w800)),
                if((event['note']??'').toString().trim().isNotEmpty) Text(event['note'].toString(),style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.7)),
                Text(_dateLabel(event['created_at']),style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
              ])),
            ]),
          )),
        ],
        if (payments.isNotEmpty) ...[
          const SizedBox(height:12),
          Text('سوابق پرداخت',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:7),
          ...payments.map((x)=>Padding(
            padding:const EdgeInsets.only(bottom:7),
            child:Row(children:[
              Icon(x['confirmed']==true?Icons.check_circle_outline:Icons.hourglass_top_rounded,size:17,color:x['confirmed']==true?c.success:c.warning),
              const SizedBox(width:8),
              Expanded(child:Text('${_money.format((x['amount'] as num?)??0)} تومان · ${(x['confirmed']==true)?'تأییدشده':'در انتظار تأیید'}',style:Theme.of(context).textTheme.bodySmall)),
            ]),
          )),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height:14),
          Text('فایل‌ها و رسیدها',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:7),
          ...files.map((file)=>Padding(
            padding:const EdgeInsets.only(bottom:7),
            child:Container(
              padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
              decoration:BoxDecoration(color:c.background,borderRadius:BorderRadius.circular(12),border:Border.all(color:c.line)),
              child:Row(children:[
                Icon((file['file_name']??'').toString().contains('رسید')?Icons.receipt_long_rounded:Icons.attach_file_rounded,size:18,color:c.secondary),
                const SizedBox(width:8),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text((file['file_name']??'فایل پروژه').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight:FontWeight.w700)),
                  Text(_dateLabel(file['created_at']),style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
                ])),
                IconButton(tooltip:'دریافت فایل',onPressed:()=>_downloadFile(file),icon:const Icon(Icons.download_rounded,size:20)),
              ]),
            ),
          )),
        ],
        if (receipts.isNotEmpty) ...[
          const SizedBox(height:3),
          Text('${receipts.length} رسید ثبت‌شده در سوابق پروژه',style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
        ],
        if (hasBalance) ...[
          const SizedBox(height:16),
          Container(
            padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(color:c.background,borderRadius:BorderRadius.circular(16),border:Border.all(color:c.line)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('پرداخت کارت‌به‌کارت',style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Text('شماره کارت',style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
              const SizedBox(height:4),
              Row(children:[
                const Expanded(child:Text('6219 8619 2709 9035',textDirection:ui.TextDirection.ltr,style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:.5))),
                IconButton(tooltip:'کپی شماره کارت',onPressed:()=>Clipboard.setData(const ClipboardData(text:'6219861927099035')).then((_){_message('شماره کارت کپی شد.');}),icon:const Icon(Icons.copy_rounded,size:18)),
              ]),
              Text('به نام: علی شمس الدینی',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted)),
              const SizedBox(height:8),
              Text('پس از انتقال وجه، تصویر رسید را ارسال کن. پرداخت تا زمان بررسی مدیر به‌عنوان پرداخت تأییدشده محاسبه نمی‌شود.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted,height:1.8)),
              const SizedBox(height:10),
              SizedBox(width:double.infinity,child:OutlinedButton.icon(
                onPressed:()=>_uploadReceipt(p),
                icon:const Icon(Icons.upload_file_rounded),
                label:const Text('انتخاب و ارسال تصویر رسید'),
              )),
              Text('JPG، PNG یا WebP · حداکثر ۵ مگابایت',style:Theme.of(context).textTheme.labelSmall?.copyWith(color:c.muted)),
            ]),
          ),
        ] else if (status!='cancelled') ...[
          const SizedBox(height:12),
          Row(children:[Icon(Icons.verified_rounded,color:c.success,size:18),const SizedBox(width:7),const Expanded(child:Text('این پروژه تسویه شده است.',style:TextStyle(fontWeight:FontWeight.w700)))])
        ],
      ]),
    );
  }

  Widget _moneyRow(BuildContext context,String label,double value,AppColors c,{bool positive=false,bool emphasize=false}) => Padding(
    padding:const EdgeInsets.symmetric(vertical:4),
    child:Row(children:[
      Expanded(child:Text(label,style:Theme.of(context).textTheme.bodySmall?.copyWith(color:c.muted))),
      Text('${_money.format(value)} تومان',style:Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight:emphasize?FontWeight.w900:FontWeight.w600,color:positive?c.success:emphasize?c.secondary:null)),
    ]),
  );
}
