import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerOrder {
  const CustomerOrder({required this.data, required this.events});
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> events;
  String get id => (data['id'] ?? '').toString();
  String get trackingCode => (data['tracking_code'] ?? '').toString();
  String get title => (data['title'] ?? 'سفارش').toString();
  String get service => (data['service'] ?? '').toString();
  String get status => (data['status'] ?? 'new').toString();
  String get publicMessage => (data['public_message'] ?? '').toString();
  num get quotedPrice => (data['quoted_price'] as num?) ?? 0;
  num get payableAmount => (data['payable_amount'] as num?) ?? 0;
  num get discountPercent => (data['discount_percent'] as num?) ?? 0;
  String get createdAt => (data['created_at'] ?? '').toString();
}

final customerOrdersProvider =
    FutureProvider.family<List<CustomerOrder>, String>((ref, userId) async {
  final client = Supabase.instance.client;
  final rows = await client
      .from('client_orders')
      .select('id,tracking_code,service,services,title,details,budget,status,quoted_price,eta_date,public_message,project_id,created_at,updated_at,discount_percent,discount_amount,payable_amount,offer_accepted_at,offer_terms_version,early_start_consent')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(100);
  final orders = (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList(growable: false);
  if (orders.isEmpty) return const [];
  final ids = orders.map((order) => order['id'].toString()).toList();
  final eventRows = await client
      .from('client_order_events')
      .select('id,order_id,status,public_message,created_at')
      .inFilter('order_id', ids)
      .order('created_at', ascending: false);
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in (eventRows as List)) {
    final event = Map<String, dynamic>.from(row as Map);
    final orderId = (event['order_id'] ?? '').toString();
    grouped.putIfAbsent(orderId, () => []).add(event);
  }
  return orders.map((order) => CustomerOrder(
    data: order,
    events: List.unmodifiable(grouped[order['id'].toString()] ?? const []),
  )).toList(growable: false);
});
