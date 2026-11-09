import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountOverview {
  const AccountOverview({required this.points, required this.plusSummary});
  final int points;
  final String plusSummary;
}

final accountOverviewProvider = FutureProvider.family<AccountOverview, String>((ref, userId) async {
  final client = Supabase.instance.client;
  if (client.auth.currentUser?.id != userId) {
    return const AccountOverview(points: 0, plusSummary: 'برای مشاهده وضعیت عضویت وارد حساب شوید.');
  }

  final responses = await Future.wait([
    client.functions.invoke('mobile-club-api',
      headers: {'Origin': 'https://alishams.ir'}, body: {'action': 'status'}),
    client.functions.invoke('mobile-plus-api',
      headers: {'Origin': 'https://alishams.ir'}, body: {'action': 'status'}),
  ]);

  final clubResponse = responses[0];
  final plusResponse = responses[1];
  final clubData = clubResponse.data;
  final plusData = plusResponse.data;

  if (clubResponse.status < 200 || clubResponse.status >= 300 ||
      clubData is! Map || clubData['ok'] != true) {
    throw Exception(clubData is Map
      ? (clubData['error'] ?? 'دریافت امتیازهای باشگاه ممکن نشد.')
      : 'پاسخ نامعتبر باشگاه');
  }
  if (plusResponse.status < 200 || plusResponse.status >= 300 ||
      plusData is! Map || plusData['ok'] != true) {
    throw Exception(plusData is Map
      ? (plusData['error'] ?? 'دریافت وضعیت پلاس ممکن نشد.')
      : 'پاسخ نامعتبر پلاس');
  }

  final points = (clubData['balance'] as num?)?.toInt() ?? 0;
  final membership = plusData['membership'] is Map ? plusData['membership'] as Map : null;
  final active = membership?['is_active'] == true;
  var plusSummary = 'عضویت پلاس فعالی برای این حساب ثبت نشده است.';
  if (active) {
    final discount = (membership?['discount_percent'] as num?)?.toInt() ?? 0;
    final endsAt = DateTime.tryParse((membership?['ends_at'] ?? '').toString());
    final expiry = endsAt == null
      ? ''
      : ' • پایان اعتبار: ${endsAt.year}/${endsAt.month.toString().padLeft(2, '0')}/${endsAt.day.toString().padLeft(2, '0')}';
    plusSummary = 'عضویت پلاس فعال • تخفیف فعلی $discount٪$expiry';
  } else if (plusData['latest_manual_payment'] is Map &&
      (plusData['latest_manual_payment'] as Map)['payment_status'] == 'pending') {
    plusSummary = 'رسید پلاس ثبت شده و در انتظار بررسی مدیریت است.';
  } else {
    plusSummary = 'عضویت پلاس در حال حاضر فعال نیست.';
  }

  return AccountOverview(points: points, plusSummary: plusSummary);
});
