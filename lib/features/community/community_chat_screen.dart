import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'community_image_editor.dart';
import 'community_voice_recorder.dart';
import 'community_voice_message.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  static const _adminId = '20e3df23-9f5a-4d88-8adc-093f75feb5df';
  final _client = Supabase.instance.client;
  final _input = TextEditingController();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _imagePicker = ImagePicker();
  final Map<String, String> _attachmentUrls = {};
  int _onlineCount = 0;
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, Map<String, dynamic>> _profiles = {};
  RealtimeChannel? _channel;
  Map<String, dynamic>? _reply;
  Map<String, dynamic>? _pinned;
  String? _userId;
  String? _displayName;
  bool _loading = true;
  bool _sending = false;
  bool _profileReady = false;
  bool _isAdmin = false;
  final Set<String> _plusUserIds = {};
  bool _searching = false;
  bool _loadingOlder = false;
  bool _hasMore = true;
  String? _error;
  String _query = '';
  Timer? _searchDebounce;
  String? _oldest;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _scroll.addListener(_onScroll);
    _initialize();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _channel?.unsubscribe();
    _input.dispose();
    _search.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() { _loading = false; _error = 'برای ورود به گفت‌وگوی عمومی، ابتدا وارد حساب کاربری شوید.'; });
        return;
      }
      _userId = user.id;
      _isAdmin = user.id == _adminId;
      final profile = await _client.from('user_profiles')
          .select('user_id,display_name,avatar_url')
          .eq('user_id', user.id).maybeSingle();
      if (profile == null || (profile['avatar_url'] as String?)?.trim().isEmpty != false) {
        setState(() {
          _loading = false;
          _error = 'برای حضور در گفت‌وگوی عمومی، ابتدا تصویر پروفایل خود را از بخش حساب من تکمیل کنید.';
        });
        return;
      }
      _profileReady = true;
      _displayName = (profile['display_name'] as String?)?.trim();
      _profiles[user.id] = profile;
      try {
        final plus = await _client.rpc('community_plus_user_ids');
        if (plus is List) {
          _plusUserIds.addAll(plus.map((item) => item is String ? item : (item is Map ? item['community_plus_user_ids'] ?? item['user_id'] : null)).whereType<String>());
        }
      } catch (_) {}
      await _loadMessages();
      await _loadPinned();
      await _subscribe();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'اتصال به انجمن برقرار نشد. اتصال اینترنت را بررسی و دوباره تلاش کنید.'; });
    }
  }

  Future<void> _loadProfiles(Iterable<String> ids) async {
    final missing = ids.where((id) => !_profiles.containsKey(id)).toSet().toList();
    if (missing.isEmpty) return;
    final rows = await _client.from('user_profiles')
        .select('user_id,display_name,avatar_url').inFilter('user_id', missing);
    for (final row in rows) {
      _profiles[row['user_id'] as String] = Map<String, dynamic>.from(row);
    }
  }

  Future<void> _loadMessages({bool older = false}) async {
    if (older && (_loadingOlder || !_hasMore || _oldest == null)) return;
    if (older) setState(() => _loadingOlder = true);
    try {
      var request = _client.from('community_messages').select().isFilter('deleted_at', null);
      if (older) request = request.lt('created_at', _oldest!);
      final rows = await request.order('created_at', ascending: false).limit(35);
      final batch = rows.map((row) => Map<String, dynamic>.from(row)).toList().reversed.toList();
      if (batch.isNotEmpty) {
        await _loadProfiles(batch.map((m) => m['user_id'] as String));
        _oldest = batch.first['created_at'] as String;
        if (mounted) {
          setState(() {
            if (older) {
              _messages.insertAll(0, batch);
            } else {
              _messages
                ..clear()
                ..addAll(batch);
            }
          });
        }
      }
      _hasMore = rows.length == 35;
    } catch (_) {
      if (!older && mounted) setState(() => _error = 'دریافت پیام‌ها با خطا روبه‌رو شد.');
    } finally {
      if (older && mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _loadPinned() async {
    try {
      final rows = await _client.from('community_messages')
          .select('id,body,message_type,attachment_name')
          .eq('is_pinned', true).isFilter('deleted_at', null)
          .order('pinned_at', ascending: false).limit(1);
      if (mounted) setState(() => _pinned = rows.isEmpty ? null : Map<String, dynamic>.from(rows.first));
    } catch (_) {}
  }

  Future<void> _subscribe() async {
    final channel = _client.channel('community-public-room');
    channel
      ..onPresenceSync((_) {
        final state = channel.presenceState();
        final ids = <String>{};
        for (final entries in state.values) {
          for (final presence in entries) {
            final id = presence.payload['user_id']?.toString();
            if (id != null) ids.add(id);
          }
        }
        if (mounted) setState(() => _onlineCount = ids.length);
      })
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'community_messages',
        callback: (payload) async {
          final row = Map<String, dynamic>.from(payload.newRecord);
          if (row['deleted_at'] != null) return;
          if (!_messages.any((m) => m['id'] == row['id'])) {
            await _loadProfiles([row['user_id'] as String]);
            await _loadAttachmentUrl(row);
            if (mounted) setState(() => _messages.add(row));
            _scrollToBottom();
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'community_messages',
        callback: (payload) {
          final row = Map<String, dynamic>.from(payload.newRecord);
          if (!mounted) return;
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == row['id']);
            if (row['deleted_at'] != null) {
              if (index >= 0) _messages.removeAt(index);
            } else if (index >= 0) {
              _messages[index] = row;
            }
          });
          _loadPinned();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'community_messages',
        callback: (payload) {
          final id = payload.oldRecord['id'];
          if (id != null && mounted) setState(() => _messages.removeWhere((m) => m['id'] == id));
          _loadPinned();
        },
      );
    _channel = channel;
    await channel.subscribe();
    await channel.track({'user_id': _userId, 'display_name': _displayName ?? 'عضو', 'online_at': DateTime.now().toUtc().toIso8601String()});
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.pixels < 90 && !_loadingOlder) {
      _loadMessages(older: true);
    }
  }

  List<Map<String, dynamic>> get _visibleMessages {
    if (_query.isEmpty) return _messages;
    return _messages.where((m) => (m['body'] as String? ?? '').toLowerCase().contains(_query)).toList();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _userId == null) return;
    setState(() => _sending = true);
    try {
      final sent = await _client.from('community_messages').insert({
        'user_id': _userId,
        'body': text,
        'message_type': 'text',
        'reply_to': _reply?['id'],
      }).select().single();
      await _loadProfiles([_userId!]);
      await _notifyCommunity(sent['id'].toString());
      if (mounted && !_messages.any((m) => m['id'] == sent['id'])) {
        setState(() => _messages.add(Map<String, dynamic>.from(sent)));
      }
      _input.clear();
      setState(() => _reply = null);
      _scrollToBottom();
    } on PostgrestException catch (e) {
      _toast(e.code == '42501' ? 'دسترسی ارسال پیام برای این حساب محدود شده است.' : 'ارسال پیام انجام نشد: ${e.message}');
    } catch (_) {
      _toast('ارسال پیام انجام نشد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }


  Future<void> _notifyCommunity(String messageId) async {
    try {
      await _client.functions.invoke('community-chat-notify', body: {'message_id': messageId});
    } catch (e) {
      debugPrint('Community notification dispatch failed: $e');
    }
  }

  Future<void> _loadAttachmentUrl(Map<String, dynamic> message) async {
    final path = message['attachment_path'] as String?;
    if (path == null || path.isEmpty || _attachmentUrls.containsKey(path)) return;
    try {
      final url = await _client.storage.from('community-chat').createSignedUrl(path, 3600);
      _attachmentUrls[path] = url;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _uploadAndSend(Uint8List bytes, String fileName, String mime, String kind) async {
    if (_userId == null || bytes.isEmpty || _sending) return;
    if (bytes.length > 50 * 1024 * 1024) {
      _toast('حجم فایل نباید بیشتر از ۵۰ مگابایت باشد.');
      return;
    }
    setState(() => _sending = true);
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot).toLowerCase() : '';
    final safeExt = ext.isEmpty ? '.bin' : ext;
    final path = '$_userId/${DateTime.now().microsecondsSinceEpoch}$safeExt';
    try {
      await _client.storage.from('community-chat').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );
      final row = await _client.from('community_messages').insert({
        'user_id': _userId,
        'body': '',
        'message_type': kind,
        'attachment_path': path,
        'attachment_name': fileName,
        'attachment_mime': mime,
        'attachment_size': bytes.length,
        'reply_to': _reply?['id'],
      }).select().single();
      _attachmentUrls[path] = await _client.storage.from('community-chat').createSignedUrl(path, 3600);
      await _loadProfiles([_userId!]);
      await _notifyCommunity(row['id'].toString());
      if (mounted && !_messages.any((m) => m['id'] == row['id'])) {
        setState(() => _messages.add(Map<String, dynamic>.from(row)));
      }
      if (mounted) setState(() => _reply = null);
      _scrollToBottom();
    } on PostgrestException catch (e) {
      try { await _client.storage.from('community-chat').remove([path]); } catch (_) {}
      _toast(e.code == '42501' ? 'ارسال پیوست برای این حساب مجاز نیست.' : 'ارسال پیوست انجام نشد: ${e.message}');
    } catch (_) {
      try { await _client.storage.from('community-chat').remove([path]); } catch (_) {}
      _toast('بارگذاری فایل انجام نشد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showAttachmentMenu() async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171D2D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ارسال پیوست', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 18),
          Row(children: [
            _attachmentAction(Icons.photo_library_rounded, 'گالری', const Color(0xFF9B79FF), () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            _attachmentAction(Icons.camera_alt_rounded, 'دوربین', const Color(0xFF47C9D8), () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            _attachmentAction(Icons.insert_drive_file_rounded, 'فایل', const Color(0xFFFFC76B), () { Navigator.pop(context); _pickFile(); }),
          ]),
        ]),
      )),
    );
  }

  Widget _attachmentAction(IconData icon, String label, Color color, VoidCallback onTap) => Expanded(
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(17)),
          child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ])),
    ),
  );

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 96, maxWidth: 3000);
      if (picked == null || !mounted) return;
      final edited = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => CommunityImageEditor(file: File(picked.path))),
      );
      if (edited == null) return;
      await _uploadAndSend(edited, 'community-${DateTime.now().millisecondsSinceEpoch}.jpg', 'image/jpeg', 'image');
    } catch (_) { _toast('باز کردن تصویر انجام نشد.'); }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) { _toast('خواندن فایل انتخاب‌شده ممکن نشد.'); return; }
      final dot = file.name.lastIndexOf('.');
      final ext = dot >= 0 ? file.name.substring(dot).toLowerCase() : '';
      const mimeByExt = {
        '.pdf':'application/pdf','.zip':'application/zip','.txt':'text/plain','.csv':'text/csv',
        '.doc':'application/msword','.docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        '.xls':'application/vnd.ms-excel','.xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        '.ppt':'application/vnd.ms-powerpoint','.pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      };
      final mime = mimeByExt[ext];
      if (mime == null) { _toast('این نوع فایل پشتیبانی نمی‌شود. PDF، Word، Excel، PowerPoint، ZIP، TXT و CSV مجاز هستند.'); return; }
      await _uploadAndSend(bytes, file.name, mime, 'file');
    } catch (_) { _toast('انتخاب فایل انجام نشد.'); }
  }

  Future<void> _recordVoice() async {
    final file = await showDialog<File>(context: context, barrierDismissible: false,
      builder: (_) => const CommunityVoiceRecorder());
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _uploadAndSend(bytes, 'voice-${DateTime.now().millisecondsSinceEpoch}.m4a', 'audio/mp4', 'voice');
  }

  Widget _attachmentContent(Map<String, dynamic> message, AppColors c) {
    final path = message['attachment_path'] as String?;
    if (path == null) return const SizedBox.shrink();
    final url = _attachmentUrls[path];
    if (url == null) {
      _loadAttachmentUrl(message);
      return const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 24,height: 24,child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final mime = message['attachment_mime'] as String? ?? '';
    final name = message['attachment_name'] as String? ?? 'پیوست';
    if (message['message_type'] == 'voice' || message['message_type'] == 'audio') {
      return Padding(padding: const EdgeInsets.only(bottom: 7), child: CommunityVoiceMessage(url: url, mine: message['user_id'] == _userId));
    }
    if (mime.startsWith('image/')) {
      return Padding(padding: const EdgeInsets.only(bottom: 7), child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => Dialog(
            backgroundColor: Colors.black, insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
          )),
          child: Image.network(url, width: 240, fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(width: 220,height: 140,child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_,__,___) => const Icon(Icons.broken_image_outlined, color: Colors.white70)),
        ),
      ));
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(mime.startsWith('audio/') ? Icons.graphic_eq_rounded : Icons.insert_drive_file_rounded, color: c.secondary, size: 25),
          const SizedBox(width: 9),
          Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.ink, fontSize: 11, fontWeight: FontWeight.w700)),
            Text('${((message['attachment_size'] as num? ?? 0) / 1024).toStringAsFixed(0)} KB · برای دریافت لمس کن',
              style: TextStyle(color: c.muted, fontSize: 9)),
          ])),
        ]),
      ),
    );
  }

  Future<void> _react(Map<String, dynamic> message, String emoji) async {
    final id = message['id'] as String;
    try {
      final existing = await _client.from('community_message_reactions')
          .select('id').eq('message_id', id).eq('user_id', _userId!).eq('emoji', emoji).maybeSingle();
      if (existing != null) {
        await _client.from('community_message_reactions').delete()
            .eq('id', existing['id']).eq('user_id', _userId!);
      } else {
        await _client.from('community_message_reactions').insert({
          'message_id': id, 'user_id': _userId, 'emoji': emoji,
        });
      }
      if (mounted) setState(() {});
    } catch (_) {
      _toast('ثبت واکنش انجام نشد.');
    }
  }

  Future<Map<String, dynamic>?> _replyDetails(Map<String, dynamic> message) async {
    final id = message['reply_to'];
    if (id == null) return null;
    try {
      final row = await _client.from('community_messages').select('body,user_id')
          .eq('id', id).maybeSingle();
      if (row == null) return null;
      await _loadProfiles([row['user_id'] as String]);
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> _edit(Map<String, dynamic> message) async {
    final controller = TextEditingController(text: message['body'] as String? ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش پیام'),
        content: TextField(controller: controller, autofocus: true, maxLength: 5000, maxLines: 5, minLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ذخیره')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    try {
      await _client.from('community_messages').update({
        'body': value, 'edited_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', message['id']).eq('user_id', _userId!);
    } catch (_) { _toast('ویرایش پیام ناموفق بود.'); }
    controller.dispose();
  }

  Future<void> _delete(Map<String, dynamic> message) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('از حذف این پیام مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      if (_isAdmin) {
        await _client.from('community_messages').delete().eq('id', message['id']);
      } else {
        await _client.from('community_messages').update({
          'deleted_at': DateTime.now().toUtc().toIso8601String(), 'body': 'پیام حذف شد',
        }).eq('id', message['id']).eq('user_id', _userId!);
      }
    } catch (_) { _toast('حذف پیام ناموفق بود.'); }
  }

  Future<void> _report(Map<String, dynamic> message) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گزارش پیام'),
        content: TextField(controller: controller, autofocus: true, maxLength: 500, maxLines: 3, decoration: const InputDecoration(hintText: 'دلیل گزارش را بنویسید')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ثبت گزارش')),
        ],
      ),
    );
    if (reason == null || reason.length < 2) return;
    try {
      await _client.from('community_message_reports').insert({
        'message_id': message['id'], 'reporter_id': _userId, 'reason': reason.substring(0, reason.length > 500 ? 500 : reason.length),
      });
      _toast('گزارش شما ثبت شد.');
    } on PostgrestException catch (e) {
      _toast(e.code == '23505' ? 'این پیام را قبلاً گزارش کرده‌اید.' : 'ثبت گزارش انجام نشد.');
    } catch (_) { _toast('ثبت گزارش انجام نشد.'); }
    controller.dispose();
  }

  Future<void> _togglePin(Map<String, dynamic> message) async {
    if (!_isAdmin) return;
    final next = message['is_pinned'] != true;
    try {
      if (next) {
        await _client.from('community_messages').update({
          'is_pinned': false, 'pinned_at': null, 'pinned_by': null,
        }).eq('is_pinned', true);
      }
      await _client.from('community_messages').update(next
          ? {'is_pinned': true, 'pinned_at': DateTime.now().toUtc().toIso8601String(), 'pinned_by': _userId}
          : {'is_pinned': false, 'pinned_at': null, 'pinned_by': null})
          .eq('id', message['id']);
      await _loadPinned();
    } catch (_) { _toast('تغییر وضعیت سنجاق پیام انجام نشد.'); }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toast(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _time(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m'.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.ink,
          elevation: 0,
          titleSpacing: 0,
          title: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF123D68)]),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
              ),
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('گفت‌وگوی عمومی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(_loading ? 'در حال اتصال به انجمن…' : '$_onlineCount عضو آنلاین · انجمن زنده Alishams',
                style: TextStyle(fontSize: 10, color: c.muted, fontWeight: FontWeight.w400)),
            ])),
          ]),
          actions: [
            IconButton(tooltip: 'جست‌وجو', onPressed: () => setState(() => _searching = !_searching), icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded)),
            IconButton(tooltip: 'آخرین پیام‌ها', onPressed: _scrollToBottom, icon: const Icon(Icons.south_rounded)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _statePanel(c, _error!, Icons.lock_outline_rounded, true)
                : !_profileReady
                    ? _statePanel(c, 'برای استفاده از انجمن، پروفایل خود را تکمیل کنید.', Icons.person_outline_rounded, false)
                    : Column(children: [
                        if (_searching) Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                          child: TextField(controller: _search, decoration: InputDecoration(
                            hintText: 'جست‌وجو در پیام‌های دریافت‌شده…',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(onPressed: () => _search.clear(), icon: const Icon(Icons.close_rounded)),
                          )),
                        ),
                        if (_pinned != null) _pinnedBanner(c),
                        Expanded(child: _visibleMessages.isEmpty
                            ? Center(child: _statePanel(c, _query.isEmpty ? 'هنوز پیامی ارسال نشده؛ شروع‌کننده گفتگو باش.' : 'پیامی با این عبارت پیدا نشد.', Icons.forum_outlined, false))
                            : ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                                itemCount: _visibleMessages.length + (_loadingOlder ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_loadingOlder && index == 0) return const Padding(
                                    padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                                  final offset = _loadingOlder ? index - 1 : index;
                                  return _messageTile(c, _visibleMessages[offset]);
                                },
                              )),
                        if (_reply != null) _replyBanner(c),
                        _composer(c),
                      ]),
      ),
    );
  }

  Widget _statePanel(AppColors c, String message, IconData icon, bool retry) => Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 42, color: c.secondary),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.muted, height: 1.9)),
        if (retry) TextButton.icon(onPressed: () { setState(() { _error = null; _loading = true; }); _initialize(); }, icon: const Icon(Icons.refresh_rounded), label: const Text('تلاش دوباره')),
      ]),
    ));

  Widget _pinnedBanner(AppColors c) => InkWell(
    onTap: () {
      final index = _messages.indexWhere((m) => m['id'] == _pinned?['id']);
      if (index >= 0 && _scroll.hasClients) _scroll.animateTo(
        index * 100.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    },
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF263B58), Color(0xFF25204C)]),
        border: Border.all(color: const Color(0xFF9B83FF).withValues(alpha: .45)),
      ),
      child: Row(children: [
        const Icon(Icons.push_pin_rounded, color: Color(0xFFC5B2FF), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('پیام سنجاق‌شده', style: TextStyle(color: Color(0xFFC5B2FF), fontSize: 10, fontWeight: FontWeight.w800)),
          Text((_pinned?['body'] as String?)?.isNotEmpty == true ? _pinned!['body'] as String : 'یک پیوست در انجمن سنجاق شده است',
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ])),
        const Icon(Icons.chevron_left_rounded, color: Colors.white70),
      ]),
    ),
  );

  Widget _replyBanner(AppColors c) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: c.primary.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(Icons.reply_rounded, color: c.secondary, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text('پاسخ به ${_profiles[_reply?['user_id']]?['display_name'] ?? 'عضو'}: ${_reply?['body'] ?? 'پیوست'}',
        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.ink, fontSize: 11))),
      IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() => _reply = null), icon: const Icon(Icons.close_rounded, size: 18)),
    ]),
  );

  Widget _composer(AppColors c) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(tooltip: 'پیوست عکس یا فایل', onPressed: _sending ? null : _showAttachmentMenu, icon: Icon(Icons.add_circle_outline_rounded, color: c.secondary, size: 27)),
        Expanded(child: Container(
          decoration: BoxDecoration(color: c.surfaceContainer, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
          child: TextField(
            controller: _input, focusNode: _focus, minLines: 1, maxLines: 5, maxLength: 5000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'پیامت را برای اعضا بنویس…',
              border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            ),
            onSubmitted: (_) => _send(),
          ),
        )),
        const SizedBox(width: 9),
        IconButton(tooltip: 'ضبط پیام صوتی', onPressed: _sending ? null : _recordVoice, icon: Icon(Icons.mic_none_rounded, color: c.secondary, size: 25)),
        SizedBox(
          width: 48, height: 48,
          child: FilledButton(
            onPressed: _sending ? null : _send,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              backgroundColor: c.secondary,
              foregroundColor: c.onSecondary,
            ),
            child: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 20),
          ),
        ),
      ]),
    ),
  );

  Widget _messageTile(AppColors c, Map<String, dynamic> message) {
    final mine = message['user_id'] == _userId;
    final admin = message['user_id'] == _adminId;
    final profile = _profiles[message['user_id']] ?? {};
    final name = admin ? 'علی شمس' : (profile['display_name'] as String? ?? 'عضو');
    final avatarUrl = profile['avatar_url'] as String?;
    final pinned = message['is_pinned'] == true;
    final body = message['body'] as String? ?? '';
    return FutureBuilder<Map<String, dynamic>?>(
      future: _replyDetails(message),
      builder: (context, replySnapshot) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!mine) Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(radius: 17, backgroundColor: c.surfaceContainerHigh,
                backgroundImage: avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
                child: avatarUrl == null || avatarUrl.isEmpty ? Icon(Icons.person_rounded, color: c.muted, size: 17) : null),
            ),
            Expanded(child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (admin) const Icon(Icons.verified_rounded, color: Color(0xFFD9FF72), size: 13),
                    const SizedBox(width: 4),
                    Text(name, style: TextStyle(color: admin ? const Color(0xFFD9FF72) : c.secondary, fontSize: 10, fontWeight: FontWeight.w800)),
                    if (_plusUserIds.contains(message['user_id'])) ...[
                      const SizedBox(width: 5),
                      const Text('PLUS', style: TextStyle(color: Color(0xFFFFD76A), fontSize: 8, fontWeight: FontWeight.w900)),
                    ],
                  ]),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFF263A59) : c.surfaceContainer,
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(17), topLeft: const Radius.circular(17),
                      bottomRight: Radius.circular(mine ? 5 : 17), bottomLeft: Radius.circular(mine ? 17 : 5),
                    ),
                    border: Border.all(color: pinned ? const Color(0xFFD9FF72).withValues(alpha: .65) : c.line),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (replySnapshot.data != null) Container(
                      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .13), borderRadius: BorderRadius.circular(8),
                        border: const Border(right: BorderSide(color: Color(0xFFD9FF72), width: 2))),
                      child: Text('${_profiles[replySnapshot.data!['user_id']]?['display_name'] ?? 'عضو'}: ${replySnapshot.data!['body'] ?? 'پیوست'}',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 10)),
                    ),
                    if (message['attachment_path'] != null) _attachmentContent(message, c),
                    if (body.isNotEmpty) SelectableText(body, style: TextStyle(color: c.ink, height: 1.85, fontSize: 13)),
                    const SizedBox(height: 5),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (pinned) const Icon(Icons.push_pin_rounded, size: 11, color: Color(0xFFD9FF72)),
                      if (message['edited_at'] != null) Text('ویرایش‌شده · ', style: TextStyle(color: c.muted, fontSize: 9)),
                      Text(_time(message['created_at'] as String?), style: TextStyle(color: c.muted, fontSize: 9)),
                      if (mine) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, color: c.secondary, size: 12)],
                    ]),
                  ]),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _client.from('community_message_reactions').select('user_id,emoji').eq('message_id', message['id']).then((rows) => rows.map((r) => Map<String, dynamic>.from(r)).toList()),
                  builder: (context, snapshot) {
                    final rows = snapshot.data ?? [];
                    final grouped = <String, List<Map<String, dynamic>>>{};
                    for (final row in rows) { (grouped[row['emoji'] as String] ??= []).add(row); }
                    return Wrap(spacing: 5, children: grouped.entries.map((entry) => ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.key} ${entry.value.length}', style: const TextStyle(fontSize: 10)),
                      onPressed: () => _react(message, entry.key),
                    )).toList());
                  },
                ),
                Wrap(spacing: 4, children: [
                  _actionChip('پاسخ', Icons.reply_rounded, () => setState(() => _reply = message)),
                  _actionChip('❤️', Icons.favorite_border_rounded, () => _react(message, '❤️')),
                  if (mine && body.isNotEmpty) _actionChip('ویرایش', Icons.edit_outlined, () => _edit(message)),
                  if (mine || _isAdmin) _actionChip('حذف', Icons.delete_outline_rounded, () => _delete(message)),
                  if (_isAdmin) _actionChip(pinned ? 'برداشتن سنجاق' : 'سنجاق', Icons.push_pin_outlined, () => _togglePin(message)),
                  _actionChip('گزارش', Icons.flag_outlined, () => _report(message)),
                ]),
              ],
            )),
            if (mine) Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(radius: 17, backgroundColor: c.surfaceContainerHigh,
                backgroundImage: avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
                child: avatarUrl == null || avatarUrl.isEmpty ? Icon(Icons.person_rounded, color: c.muted, size: 17) : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) => ActionChip(
    visualDensity: VisualDensity.compact,
    avatar: Icon(icon, size: 13),
    label: Text(label, style: const TextStyle(fontSize: 9)),
    onPressed: onTap,
  );
}
