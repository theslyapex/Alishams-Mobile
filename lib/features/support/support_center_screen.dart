import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _invoke({'action': 'list'});
      if (!mounted) return;
      setState(() => _requests = (data['requests'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('مرکز پشتیبانی'),
          actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))],
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
                          Text('مکاتبات و پاسخ‌های پشتیبانی متصل به حساب کاربری‌ات را اینجا دنبال کن.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.7)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 20),
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
                      Text('درخواست‌هایی که با همین حساب ثبت شوند، اینجا نمایش داده می‌شوند.',
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
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Map<String, dynamic>? _request;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final response = await Supabase.instance.client.functions.invoke(
      'mobile-communication-api',
      headers: {'Origin': 'https://alishams.ir'},
      body: body,
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
                Text(_error!, textAlign: TextAlign.center),
                TextButton(onPressed: _load, child: const Text('تلاش دوباره')),
              ])))
            : RefreshIndicator(onRefresh: _load, child: ListView.builder(
                controller: _scroll, physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(15), itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final item = _messages[index];
                  final mine = item['sender_type'] == 'visitor';
                  final body = (item['message_body'] ?? item['caption'] ?? '').toString();
                  return Align(alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
                      margin: const EdgeInsets.only(bottom: 11),
                      padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                      decoration: BoxDecoration(
                        color: mine ? c.primary.withValues(alpha: .16) : c.surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: mine ? c.primary.withValues(alpha: .28) : c.line),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(mine ? 'شما' : 'پشتیبانی', style: TextStyle(color: mine ? c.secondary : c.tertiary, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        if (body.isNotEmpty) Text(body, style: TextStyle(color: c.ink, height: 1.7, fontSize: 13)),
                        if ((item['attachments'] as List? ?? const []).isNotEmpty) ...[
                          const SizedBox(height: 7),
                          for (final file in (item['attachments'] as List))
                            Row(children: [
                              Icon(Icons.attach_file_rounded, size: 15, color: c.secondary),
                              Expanded(child: Text((file['original_name'] ?? 'پیوست').toString(),
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.secondary, fontSize: 11))),
                            ]),
                        ],
                        const SizedBox(height: 7),
                        Text(_date(item['created_at']), style: TextStyle(color: c.muted, fontSize: 9)),
                      ]),
                    ));
                },
              )),
        ),
        Container(padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.paddingOf(context).bottom + 10),
          decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
              onPressed: _sending ? null : _send,
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
