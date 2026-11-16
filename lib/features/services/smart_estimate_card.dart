import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import 'order_create_screen.dart';

class _EstimatePriceOption {
  final String label;
  final int min;
  final int max;
  final String unit;
  const _EstimatePriceOption(this.label, this.min, this.max, this.unit);

  factory _EstimatePriceOption.fromJson(Map<String, dynamic> json) {
    return _EstimatePriceOption(
      (json['label'] ?? '').toString(),
      (json['min'] as num?)?.toInt() ?? 0,
      (json['max'] as num?)?.toInt() ?? 0,
      (json['unit'] ?? '').toString(),
    );
  }
}

class _EstimateItem {
  final String service;
  final int min;
  final int max;
  final String unit;
  final bool quote;
  final List<_EstimatePriceOption> options;
  const _EstimateItem(
    this.service,
    this.min,
    this.max,
    this.unit, {
    this.quote = false,
    this.options = const [],
  });

  factory _EstimateItem.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map((option) => _EstimatePriceOption.fromJson(
                  Map<String, dynamic>.from(option),
                ))
            .toList(growable: false)
        : const <_EstimatePriceOption>[];

    return _EstimateItem(
      (json['service_name'] ?? '').toString(),
      (json['min_price'] as num?)?.toInt() ?? 0,
      (json['max_price'] as num?)?.toInt() ?? 0,
      (json['unit'] ?? '').toString(),
      quote: json['is_quote'] == true,
      options: options,
    );
  }
}

class _SelectedEstimate {
  final _EstimateItem item;
  int quantity;
  int optionIndex;
  _SelectedEstimate(this.item, {this.quantity = 1, this.optionIndex = 0});

  _EstimatePriceOption? get option =>
      item.options.isEmpty ? null : item.options[optionIndex];
  int get min => option?.min ?? item.min;
  int get max => option?.max ?? item.max;
  String get unit => option?.unit ?? item.unit;
}

class SmartEstimateCard extends StatefulWidget {
  final AppColors colors;
  const SmartEstimateCard({required this.colors});

  @override
  State<SmartEstimateCard> createState() => SmartEstimateCardState();
}

class SmartEstimateCardState extends State<SmartEstimateCard> {
  static const _fallbackItems = <_EstimateItem>[
    _EstimateItem('موشن‌گرافیک', 1750000, 25000000, 'پروژه'),
    _EstimateItem('طراحی وبسایت و قالب وبلاگ', 13795000, 150000000, 'پروژه'),
    _EstimateItem('طراحی قالب اختصاصی وبلاگ', 650000, 650000, 'قالب'),
    _EstimateItem('ریلز و محتوای ویدئویی', 2000000, 18000000, 'ویدئو'),
    _EstimateItem('تیزر تبلیغاتی', 695000, 7850000, 'تیزر'),
    _EstimateItem('امنیت شبکه‌های اجتماعی', 8000000, 8000000, 'ماه'),
    _EstimateItem('طراحی لوگو اختصاصی', 1550000, 22000000, 'لوگو'),
    _EstimateItem('نگارش مقاله وب‌سایت', 1250000, 7000000, 'مقاله'),
    _EstimateItem(
      'مشاوره کسب‌وکار آنلاین',
      2750000,
      2750000,
      'جلسه',
      options: [
        _EstimatePriceOption('جلسه‌ای', 2750000, 2750000, 'جلسه'),
        _EstimatePriceOption('پروژه‌ای', 7000000, 7000000, 'پروژه'),
      ],
    ),
    _EstimateItem(
      'خدمات SEO',
      36000000,
      36000000,
      'پروژه',
      options: [
        _EstimatePriceOption('پروژه‌ای', 36000000, 36000000, 'پروژه'),
        _EstimatePriceOption('ماهانه', 9000000, 9000000, 'ماه'),
      ],
    ),
    _EstimateItem('خدمات شبکه‌های اجتماعی', 0, 0, 'استعلام', quote: true),
    _EstimateItem('تبلیغات و معرفی', 0, 0, 'استعلام', quote: true),
  ];

  List<_EstimateItem> _items = _fallbackItems;
  final Map<String, _SelectedEstimate> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadRemotePricing();
  }

  Future<void> _loadRemotePricing() async {
    try {
      final rows = await Supabase.instance.client
          .from('mobile_service_pricing')
          .select('service_name,min_price,max_price,unit,is_quote,options')
          .order('sort_order');

      final remoteItems = rows
          .map((row) => _EstimateItem.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .where((item) => item.service.isNotEmpty)
          .toList(growable: false);

      if (!mounted || remoteItems.isEmpty) return;

      setState(() {
        final previous = Map<String, _SelectedEstimate>.from(_selected);
        _items = remoteItems;
        _selected.clear();
        for (final item in remoteItems) {
          final old = previous[item.service];
          if (old != null) {
            final lastOption = item.options.isEmpty ? 0 : item.options.length - 1;
            _selected[item.service] = _SelectedEstimate(
              item,
              quantity: old.quantity,
              optionIndex: old.optionIndex.clamp(0, lastOption).toInt(),
            );
          }
        }
      });
    } catch (_) {
      // Keep the bundled prices available when the device is offline.
    }
  }

  String _money(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('٬');
      buffer.write(digits[i]);
    }
    return '${buffer.toString()} تومان';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    var minTotal = 0;
    var maxTotal = 0;
    var hasQuote = false;
    for (final selected in _selected.values) {
      if (selected.item.quote) {
        hasQuote = true;
      } else {
        minTotal += selected.min * selected.quantity;
        maxTotal += selected.max * selected.quantity;
      }
    }

    final estimate = _selected.isEmpty
        ? 'خدمتی انتخاب نشده'
        : hasQuote
            ? (minTotal > 0 ? '${_money(minTotal)} تا ${_money(maxTotal)} + استعلام' : 'نیازمند استعلام قیمت')
            : minTotal == maxTotal
                ? _money(minTotal)
                : '${_money(minTotal)} تا ${_money(maxTotal)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.secondary.withValues(alpha: .34)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [c.primary.withValues(alpha: .13), c.surface, c.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.secondary.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.calculate_outlined, color: c.secondary),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('برآورد هوشمند هزینه',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text('SMART PRICE ESTIMATOR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.secondary, letterSpacing: 1)),
              ],
            )),
          ]),
          const SizedBox(height: 9),
          Text('یک یا چند خدمت را انتخاب کن و تعداد موردنیاز را مشخص کن تا برآورد اولیه را ببینی.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
          const SizedBox(height: 16),
          Text('خدمات موردنیاز',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          ..._items.map((item) {
            final selected = _selected[item.service];
            final active = selected != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? c.secondary.withValues(alpha: .08) : c.background.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: active ? c.secondary.withValues(alpha: .42) : c.line),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 28,
                    height: 34,
                    child: Checkbox(
                      value: active,
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected[item.service] = _SelectedEstimate(item);
                        } else {
                          _selected.remove(item.service);
                        }
                      }),
                      activeColor: c.secondary,
                      side: BorderSide(color: c.muted.withValues(alpha: .7)),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(item.service,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700))),
                  if (item.quote)
                    Text('استعلام قیمت',
                        style: TextStyle(color: c.tertiary, fontSize: 10, fontWeight: FontWeight.w700))
                  else if (active) ...[
                    if (item.options.isNotEmpty)
                      DropdownButton<int>(
                        value: selected.optionIndex,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        iconSize: 16,
                        style: TextStyle(color: c.secondary, fontSize: 10, fontWeight: FontWeight.w700),
                        items: [
                          for (var i = 0; i < item.options.length; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(item.options[i].label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selected.optionIndex = value);
                          }
                        },
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => selected.quantity = (selected.quantity - 1).clamp(1, 100).toInt()),
                      icon: Icon(Icons.remove_circle_outline, color: c.muted, size: 19),
                    ),
                    Text('${selected.quantity}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => selected.quantity = (selected.quantity + 1).clamp(1, 100).toInt()),
                      icon: Icon(Icons.add_circle_outline, color: c.secondary, size: 19),
                    ),
                  ] else
                    Text(item.unit, style: TextStyle(color: c.muted, fontSize: 10)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.secondary.withValues(alpha: .25)),
            ),
            child: Column(children: [
              Text('برآورد اولیه هزینه',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.muted)),
              const SizedBox(height: 6),
              Text(estimate,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: c.secondary, fontWeight: FontWeight.w900, height: 1.6)),
              const SizedBox(height: 5),
              Text(
                _selected.isEmpty
                    ? 'برای شروع، حداقل یک خدمت را انتخاب کن.'
                    : 'مبلغ نهایی پس از بررسی جزئیات پروژه و توافق مشخص می‌شود.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.7),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          final quantities = <String, int>{
                            for (final entry in _selected.entries)
                              entry.key: entry.value.quantity,
                          };
                          final firstService = quantities.keys.first;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => OrderCreateScreen(
                              initialService: firstService,
                              initialServiceQuantities: quantities,
                            ),
                          ));
                        },
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('ادامه و ثبت سفارش'),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(
            'این مبلغ صرفاً برآورد راهنماست و پیش‌فاکتور یا تعهد قیمت محسوب نمی‌شود. خدمات استعلامی پس از دریافت جزئیات بررسی می‌شوند. تخفیف پلاس+ و هزینه‌های جانبی در این محاسبه لحاظ نشده‌اند.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, height: 1.8),
          ),
        ],
      ),
    );
  }
}
