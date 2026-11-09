import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationUnreadCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  final response = await Supabase.instance.client.functions.invoke(
    'mobile-project-account',
    headers: const {'Origin': 'https://alishams.ir'},
    body: const {'action': 'notifications'},
  );
  final data = response.data;
  if (response.status < 200 ||
      response.status >= 300 ||
      data is! Map ||
      data['ok'] != true) {
    throw Exception(
      data is Map
          ? (data['error'] ?? 'دریافت اعلان‌ها انجام نشد.').toString()
          : 'پاسخ نامعتبر از سرویس اعلان‌ها',
    );
  }
  return (data['unread_count'] as num?)?.toInt() ?? 0;
});