import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountOverview {
  const AccountOverview({required this.points, required this.plusSummary});
  final int points;
  final String plusSummary;
}

final accountOverviewProvider = FutureProvider.family<AccountOverview, String>((ref, userId) async {
  final client = Supabase.instance.client;

  final ledger = await client
      .from('club_point_ledger')
      .select('points')
      .eq('user_id', userId);
  final points = (ledger as List)
      .fold<int>(0, (sum, row) => sum + ((row['points'] as num?)?.toInt() ?? 0));

  final membership = await client
      .from('plus_memberships')
      .select('status,ends_at,discount_percent,discount_use_count,created_at')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  var plusSummary = 'عضویت پلاس فعالی برای این حساب ثبت نشده است.';
  if (membership != null) {
    final status = (membership['status'] ?? '').toString().toLowerCase();
    final endsAt = DateTime.tryParse((membership['ends_at'] ?? '').toString());
    final isActive = status == 'active' && (endsAt == null || endsAt.isAfter(DateTime.now()));
    if (isActive) {
      final discount = (membership['discount_percent'] as num?)?.toInt() ?? 0;
      plusSummary = discount > 0
          ? 'عضویت پلاس فعال • تخفیف فعلی $discount٪'
          : 'عضویت پلاس فعال است.';
    } else {
      plusSummary = 'عضویت پلاس در حال حاضر فعال نیست.';
    }
  }

  return AccountOverview(points: points, plusSummary: plusSummary);
});
