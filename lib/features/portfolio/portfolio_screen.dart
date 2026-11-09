import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/portfolio_item.dart';
import '../../providers/portfolio_provider.dart';
import '../../theme/app_colors.dart';
import 'portfolio_detail_screen.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  String _filter = 'all';

  static const _filters = <(String, String)>[
    ('all', 'همه آثار'),
    ('website', 'وب‌سایت‌ها'),
    ('logo', 'لوگوها'),
    ('ad', 'تصاویر تبلیغاتی'),
    ('video', 'ویدئوها'),
    ('social', 'شبکه اجتماعی'),
  ];

  List<PortfolioItem> _filtered(List<PortfolioItem> items) {
    switch (_filter) {
      case 'website':
        return items.where((e) => e.kind == PortfolioKind.website).toList();
      case 'logo':
        return items.where((e) => e.kind == PortfolioKind.logo).toList();
      case 'ad':
        return items.where((e) => e.kind == PortfolioKind.adImage).toList();
      case 'video':
        return items.where((e) => e.kind == PortfolioKind.video).toList();
      case 'social':
        return items.where((e) => e.kind == PortfolioKind.social).toList();
      default:
        return items;
    }
  }

  void _openItem(PortfolioItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PortfolioDetailScreen(item: item)),
    );
  }

  Widget _projectImage(PortfolioItem item, AppColors c) {
    if (item.isAsset) {
      return Image.asset(item.imagePath, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imageFallback(c));
    }
    return Image.network(
      item.imagePath,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              color: c.surface,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
      errorBuilder: (_, __, ___) => _imageFallback(c),
    );
  }

  Widget _imageFallback(AppColors c) => Container(
        color: c.surface,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: c.muted, size: 32),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final result = ref.watch(portfolioItemsProvider);
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: const Text('نمونه‌کارهای استودیو'),
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی آثار',
              onPressed: () => ref.invalidate(portfolioItemsProvider),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, color: c.muted, size: 42),
                  const SizedBox(height: 12),
                  const Text('دریافت نمونه‌کارها از سایت انجام نشد.', textAlign: TextAlign.center),
                  const SizedBox(height: 7),
                  Text('اتصال اینترنت را بررسی کن و دوباره تلاش کن.\n$error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8)),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(portfolioItemsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تلاش دوباره'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            final visible = _filtered(items);
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(portfolioItemsProvider),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('از ایده تا اجرای واقعی',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text(
                            'آثار منتشرشده در وب‌سایت، گالری لوگو، تصاویر تبلیغاتی و ویدئوهای استودیو به‌صورت زنده همگام می‌شوند.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted, height: 1.8),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _filters.map((filter) {
                                final selected = _filter == filter.$1;
                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 8),
                                  child: ChoiceChip(
                                    label: Text(filter.$2),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _filter = filter.$1),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('${visible.length} نمونه‌کار',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.secondary)),
                        ],
                      ),
                    ),
                  ),
                  if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text('در این دسته هنوز اثری ثبت نشده است.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted)),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.crossAxisExtent < 340 ? 1 : 2;
                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: columns == 1 ? 1.35 : .76,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _PortfolioCard(
                                item: visible[index],
                                colors: c,
                                image: _projectImage(visible[index], c),
                                onTap: () => _openItem(visible[index]),
                              ),
                              childCount: visible.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioItem item;
  final AppColors colors;
  final Widget image;
  final VoidCallback onTap;

  const _PortfolioCard({
    required this.item,
    required this.colors,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: .55)],
                      ),
                    ),
                  ),
                  if (item.kind == PortfolioKind.video)
                    const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 42)),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .65), borderRadius: BorderRadius.circular(30)),
                      child: Text(item.categoryLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text('مشاهده جزئیات',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.secondary, fontWeight: FontWeight.w700)),
                        ),
                        Icon(Icons.arrow_back_rounded, size: 15, color: colors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}