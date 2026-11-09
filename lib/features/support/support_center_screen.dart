import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final response = await Supabase.instance.client.functions.invoke(
      'mobile-communication-api',
      headers: {'Origin': 'https://alishams.ir'},
      body: body,
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
      throw Exception(data is Map ? (data['error'] ?? 'ارتباط با مرکز پشتیبانی انجام نشد.').toString() : 'پاسخ سرور معتبر نیست.');
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _invoke({'action': 'list'});
      if (!mounted) return;
      setState(() => _requests = (data['requests'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  •  ${two(d.hour)}:${two(d.minute)}';
  }

  String _status(String value) => const {
    'open': 'ثبت‌شده', 'in_progress': 'در حال پیگیری',
    'answered': 'پاسخ داده‌شده', 'closed': 'بسته‌شده',
    'resolved': 'پاسخ داده‌شده',
  }[value] ?? 'در حال بررسی';

  Color _statusColor(AppColors c, String value) {
    if (value == 'answered' || value == 'resolved') return const Color(0xFF42C99A);
    if (value == 'closed') return c.muted;
    return c.secondary;
  }

  Future<void> _createRequest() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NewSupportRequestScreen()),
    );
    if (created == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('مرکز پشتیبانی'),
          actions: [
            IconButton(tooltip: 'درخواست جدید', onPressed: _createRequest, icon: const Icon(Icons.add_comment_rounded)),
            IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topRight, end: Alignment.bottomLeft,
                          colors: [Color(0xFF38206F), Color(0xFF172B4B), Color(0xFF102A35)],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: .12)),
                      ),
                      child: Row(children: [
                        Container(width: 48, height: 48,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.support_agent_rounded, color: Color(0xFF9BE9F2), size: 27)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('همراهت هستیم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          SizedBox(height: 5),
                          Text('درخواست تازه ثبت کن و پاسخ‌ها و فایل‌های پشتیبانی را در همین‌جا دنبال کن.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.7)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _createRequest,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ثبت درخواست پشتیبانی جدید'),
                        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(children: [
                      const Expanded(child: Text('درخواست‌های من', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      Text('${_requests.length} مورد', style: TextStyle(color: c.muted, fontSize: 11)),
                    ]),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _messageCard(c, Icons.error_outline_rounded, _error!, 'تلاش دوباره', _load),
                    ] else if (_requests.isEmpty) ...[
                      const SizedBox(height: 34),
                      Icon(Icons.mark_email_unread_outlined, size: 48, color: c.muted),
                      const SizedBox(height: 12),
                      Text('هنوز مکاتبه‌ای به حساب شما متصل نشده است.',
                        textAlign: TextAlign.center, style: TextStyle(color: c.muted, height: 1.7)),
                      const SizedBox(height: 6),
                      Text('برای شروع، درخواست پشتیبانی جدید ثبت کن.',
                        textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 11, height: 1.7)),
                    ] else ..._requests.map((request) => _requestCard(c, request)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _requestCard(AppColors c, Map<String, dynamic> request) {
    final status = (request['status'] ?? '').toString();
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SupportConversationScreen(
            requestId: request['id'].toString(),
            subject: (request['subject'] ?? 'مکاتبه پشتیبانی').toString(),
          ),
        ));
        if (mounted) _load();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(top: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text((request['subject'] ?? 'بدون عنوان').toString(),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: _statusColor(c, status).withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
              child: Text(_status(status), style: TextStyle(color: _statusColor(c, status), fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.tag_rounded, size: 14, color: c.muted),
            const SizedBox(width: 4),
            Text((request['tracking_code'] ?? '').toString(), style: TextStyle(color: c.muted, fontSize: 10)),
            const Spacer(),
            Text(_date(request['updated_at']), style: TextStyle(color: c.muted, fontSize: 10)),
            const SizedBox(width: 5),
            Icon(Icons.chevron_left_rounded, color: c.muted, size: 18),
          ]),
        ]),
      ),
    );
  }

  Widget _messageCard(AppColors c, IconData icon, String message, String action, VoidCallback onTap) =>
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      child: Column(children: [Icon(icon, color: c.secondary, size: 28), const SizedBox(height: 9),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.ink, height: 1.6)),
        TextButton(onPressed: onTap, child: Text(action)),
      ]));
}

class NewSupportRequestScreen extends StatefulWidget {
  const NewSupportRequestScreen({super.key});
  @override
  State<NewSupportRequestScreen> createState() => _NewSupportRequestScreenState();
}

class _NewSupportRequestScreenState extends State<NewSupportRequestScreen> {
  final _name = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'سؤال عمومی';
  bool _sending = false;

  @override
  void dispose() { _name.dispose(); _subject.dispose(); _message.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    if (user == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برای ثبت درخواست، ابتدا وارد حساب کاربری شو.')));
      return;
    }
    if (_name.text.trim().isEmpty || _subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('همه فیلدها را تکمیل کن.')));
      return;
    }
    setState(() => _sending = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'mobile-communication-api',
        headers: {'Origin': 'https://alishams.ir'},
        body: {'action':'create','name':_name.text.trim(),'email':email,'subject':_subject.text.trim(),
          'category':_category,'message':_message.text.trim()},
      );
      final data = response.data;
      if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'ثبت درخواست انجام نشد.').toString() : 'پاسخ سرور معتبر نیست.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('درخواست با کد ${data['tracking_code'] ?? ''} ثبت شد.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  InputDecoration _decoration(String label, AppColors c, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint, filled: true, fillColor: c.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: c.line)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: c.line)),
  );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('درخواست پشتیبانی جدید')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text('جزئیات درخواست', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text('درخواست به حساب کاربری و ایمیل تأییدشده‌ات متصل می‌شود.', style: TextStyle(color: c.muted, fontSize: 12, height: 1.7)),
        const SizedBox(height: 20),
        TextField(controller: _name, maxLength: 80, decoration: _decoration('نام و نام خانوادگی', c)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(15), border: Border.all(color: c.line)),
          child: Row(children: [
            Icon(Icons.verified_user_outlined, color: c.secondary),
            const SizedBox(width: 10),
            Expanded(child: Text(Supabase.instance.client.auth.currentUser?.email ?? 'ایمیل حساب کاربری',
              style: TextStyle(color: c.ink, fontSize: 12))),
            Text('تأییدشده', style: TextStyle(color: const Color(0xFF42C99A), fontSize: 10)),
          ])),
        const SizedBox(height: 12),
        TextField(controller: _subject, maxLength: 120, decoration: _decoration('موضوع درخواست', c)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: _decoration('دسته‌بندی', c),
          items: const ['سؤال عمومی','سفارش و خدمات','پروژه و پرداخت','حساب کاربری','پلاس+ و باشگاه','گزارش مشکل فنی']
            .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (v) { if (v != null) setState(() => _category = v); },
        ),
        const SizedBox(height: 12),
        TextField(controller: _message, minLines: 5, maxLines: 9, maxLength: 5000,
          decoration: _decoration('شرح درخواست', c, hint: 'توضیحات کامل را بنویس…')),
        const SizedBox(height: 8),
        SizedBox(height: 52, child: FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.send_rounded),
          label: Text(_sending ? 'در حال ثبت…' : 'ثبت درخواست'),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        )),
      ]),
    ));
  }
}

class SupportConversationScreen extends StatefulWidget {
  const SupportConversationScreen({super.key, required this.requestId, required this.subject});
  final String requestId;
  final String subject;
  @override
  State<SupportConversationScreen> createState() => _SupportConversationScreenState();
}

class _SupportConversationScreenState extends State<SupportConversationScreen> {
  List<Map<String, dynamic>> _messages = [];
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true, _sending = false, _uploading = false;
  String? _error;
  Map<String, dynamic>? _request;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final response = await Supabase.instance.client.functions.invoke(
      'mobile-communication-api',
      headers: {'Origin': 'https://alishams.ir'}, body: body,
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map || data['ok'] != true) {
      throw Exception(data is Map ? (data['error'] ?? 'عملیات انجام نشد.').toString() : 'پاسخ سرور معتبر نیست.');
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _composer.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _invoke({'action': 'detail', 'request_id': widget.requestId});
      if (!mounted) return;
      setState(() {
        _request = Map<String, dynamic>.from(data['request'] as Map);
        _messages = (data['messages'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _invoke({'action': 'reply', 'request_id': widget.requestId, 'message': text});
      _composer.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  String _mime(String ext) => const {
    'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif',
    'mp4':'video/mp4','webm':'video/webm','mov':'video/quicktime',
    'mp3':'audio/mpeg','m4a':'audio/x-m4a','aac':'audio/aac','ogg':'audio/ogg','wav':'audio/wav',
    'pdf':'application/pdf','zip':'application/zip','doc':'application/msword',
    'docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt':'text/plain','csv':'text/csv',
  }[ext] ?? 'application/octet-stream';

  String _kind(String mime) {
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    return 'file';
  }

  Future<void> _attachFile() async {
    if (_uploading || _sending) return;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single, bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) throw Exception('خواندن فایل انتخاب‌شده ممکن نشد.');
      if (bytes.length > 50 * 1024 * 1024) throw Exception('حجم فایل نباید بیشتر از ۵۰ مگابایت باشد.');
      final mime = _mime((file.extension ?? '').toLowerCase());
      if (mime == 'application/octet-stream') throw Exception('این نوع فایل پشتیبانی نمی‌شود.');
      setState(() => _uploading = true);
      final init = await _invoke({'action':'upload_init','request_id':widget.requestId,
        'file_name':file.name,'mime_type':mime,'size_bytes':bytes.length});
      await Supabase.instance.client.storage.from('communication-attachments').uploadBinaryToSignedUrl(
        init['path'].toString(), init['token'].toString(), bytes,
        fileOptions: FileOptions(contentType: mime),
      );
      await _invoke({'action':'upload_complete','request_id':widget.requestId,'path':init['path'],
        'file_name':file.name,'mime_type':mime,'size_bytes':bytes.length,'message_kind':_kind(mime)});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فایل با موفقیت ارسال شد.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally { if (mounted) setState(() => _uploading = false); }
  }

  Future<void> _download(Map<String, dynamic> attachment) async {
    try {
      final data = await _invoke({'action':'download','request_id':widget.requestId,'attachment_id':attachment['id']});
      final uri = Uri.tryParse(data['signed_url'].toString());
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('باز کردن فایل انجام نشد.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  •  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(widget.subject, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(children: [
        if (_request != null) Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.line))),
          child: Row(children: [
            Expanded(child: Text('کد پیگیری: ${_request!['tracking_code'] ?? ''}', style: TextStyle(color: c.muted, fontSize: 11))),
            Text(((_request!['status'] ?? '').toString() == 'answered') ? 'پاسخ جدید' : 'گفت‌وگو',
              style: TextStyle(color: c.secondary, fontWeight: FontWeight.w700, fontSize: 11)),
          ])),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, textAlign: TextAlign.center), TextButton(onPressed: _load, child: const Text('تلاش دوباره')),
              ])))
            : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                controller: _scroll, physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(15), itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final item = _messages[index], mine = item['sender_type'] == 'visitor';
                  final body = (item['message_body'] ?? item['caption'] ?? '').toString();
                  final attachments = (item['attachments'] as List? ?? const []);
                  return Align(alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .84),
                      margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                      decoration: BoxDecoration(
                        color: mine ? c.primary.withValues(alpha: .16) : c.surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: mine ? c.primary.withValues(alpha: .28) : c.line),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(mine ? 'شما' : 'پشتیبانی', style: TextStyle(color: mine ? c.secondary : c.tertiary, fontSize: 10, fontWeight: FontWeight.w800)),
                        if (body.isNotEmpty) ...[const SizedBox(height: 6), Text(body, style: TextStyle(color: c.ink, height: 1.7, fontSize: 13))],
                        for (final raw in attachments) ...[
                          const SizedBox(height: 8),
                          InkWell(onTap: () => _download(Map<String,dynamic>.from(raw as Map)),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.attach_file_rounded, size: 17, color: c.secondary),
                                const SizedBox(width: 7),
                                Flexible(child: Text((raw['original_name'] ?? 'پیوست').toString(), maxLines: 1,
                                  overflow: TextOverflow.ellipsis, style: TextStyle(color: c.secondary, fontSize: 11))),
                                const SizedBox(width: 5), Icon(Icons.download_rounded, size: 16, color: c.muted),
                              ]),
                            )),
                        ],
                        const SizedBox(height: 7),
                        Text(_date(item['created_at']), style: TextStyle(color: c.muted, fontSize: 9)),
                      ]),
                    ));
                },
              )),
        ),
        Container(padding: EdgeInsets.fromLTRB(10, 9, 10, MediaQuery.paddingOf(context).bottom + 9),
          decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton(
              tooltip: 'ارسال فایل',
              onPressed: (_uploading || _sending) ? null : _attachFile,
              icon: _uploading ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.attach_file_rounded),
            ),
            Expanded(child: TextField(
              controller: _composer, minLines: 1, maxLines: 4, maxLength: 5000,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(hintText: 'پیام خود را بنویسید…', counterText: '',
                filled: true, fillColor: c.background, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.line))),
            )),
            const SizedBox(width: 8),
            SizedBox(width: 48, height: 48, child: FilledButton(
              onPressed: (_sending || _uploading) ? null : _send,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 19),
            )),
          ]),
        ),
      ]),
    ));
  }
}
