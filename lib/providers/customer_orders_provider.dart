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
  if (client.auth.currentUser?.id != userId) return const [];
  final response = await client.functions.invoke(
    'mobile-order-account',
    body: const {'action': 'list'},
  );
  final payload = response.data;
  if (response.status < 200 || response.status >= 300 ||
      payload is! Map || payload['ok'] != true) {
    final message = payload is Map ? payload['error']?.toString() : null;
    throw Exception(message?.isNotEmpty == true
        ? message
        : 'دریافت سفارش‌ها از سرویس امن انجام نشد.');
  }
  final orders = (payload['orders'] as List? ?? const [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList(growable: false);
  final eventRows = (payload['events'] as List? ?? const []);
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final row in eventRows) {
    final event = Map<String, dynamic>.from(row as Map);
    final orderId = (event['order_id'] ?? '').toString();
    grouped.putIfAbsent(orderId, () => []).add(event);
  }
  return orders.map((order) => CustomerOrder(
    data: order,
    events: List.unmodifiable(grouped[order['id'].toString()] ?? const []),
  )).toList(growable: false);
});
