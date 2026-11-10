import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'order_create_screen.dart';

class _EstimateItem {
  final String service;
  final int min;
  final int max;
  final String unit;
  final bool quote;
  const _EstimateItem(this.service, this.min, this.max, this.unit, {this.quote = false});
}

class _SelectedEstimate {
  final _EstimateItem item;
  int quantity;
  _SelectedEstimate(this.item, {this.quantity = 1});
}

class SmartEstimateCard extends StatefulWidget {
  final AppColors colors;
  const SmartEstimateCard({required this.colors});

  @override
  State<SmartEstimateCard> createState() => SmartEstimateCardState();
}

class SmartEstimateCardState extends State<SmartEstimateCard> {
  static const _items = <_EstimateItem>[
    _EstimateItem('موشن‌گرافیک', 480000, 899000, 'پروژه'),
    _EstimateItem('طراحی وبسایت و قالب وبلاگ', 5000000, 100000000, 'پروژه'),
    _EstimateItem('ریلز و محتوای ویدئویی', 855000, 3000000, 'ویدئو'),
    _EstimateItem('تیزر تبلیغاتی', 695000, 7850000, 'تیزر'),
    _EstimateItem('امنیت شبکه‌های اجتماعی', 8000000, 8000000, 'ماه'),
    _EstimateItem('طراحی لوگو اختصاصی', 475000, 3000000, 'لوگو'),
    _EstimateItem('نگارش مقاله وب‌سایت', 389000, 675000, 'مقاله'),
    _EstimateItem('مشاوره کسب‌وکار آنلاین', 750000, 750000, 'جلسه'),
    _EstimateItem('خدمات SEO', 1000000, 5000000, 'واحد'),
    _EstimateItem('خدمات شبکه‌های اجتماعی', 0, 0, 'استعلام', quote: true),
    _EstimateItem('تبلیغات و معرفی', 0, 0, 'استعلام', quote: true),
  ];

  final Map<String, _SelectedEstimate> _selected = {};

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
        minTotal += selected.item.min * selected.quantity;
        maxTotal += selected.item.max * selected.quantity;
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => selected.quantity = (selected.quantity - 1).clamp(1, 100)),
                      icon: Icon(Icons.remove_circle_outline, color: c.muted, size: 19),
                    ),
                    Text('${selected.quantity}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => setState(() => selected.quantity = (selected.quantity + 1).clamp(1, 100)),
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
                          final firstService = _selected.keys.first;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => OrderCreateScreen(initialService: firstService),
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
