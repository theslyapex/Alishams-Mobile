import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/portfolio_item.dart';
import '../../theme/app_colors.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final PortfolioItem item;
  const PortfolioDetailScreen({super.key, required this.item});

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _recordView();
  }

  Future<void> _recordView() async {
    if (widget.item.kind != PortfolioKind.logo &&
        widget.item.kind != PortfolioKind.adImage) return;
    try {
      await Supabase.instance.client.rpc(
        'record_portfolio_item_view',
        params: {'p_item_id': widget.item.id},
      );
    } catch (_) {
      // Analytics must not block opening a portfolio item.
    }
  }

  Future<void> _open(String? value) async {
    final raw = (value ?? '').trim();
    if (raw.isEmpty || _opening) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      _message('نشانی این پروژه معتبر نیست.');
      return;
    }
    setState(() => _opening = true);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _message('باز کردن پیوند انجام نشد.');
    } catch (_) {
      if (mounted) _message('در حال حاضر امکان باز کردن پیوند وجود ندارد.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Widget _image(AppColors c) {
    final item = widget.item;
    if (item.isAsset) {
      return Image.asset(item.imagePath, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _imageFallback(c));
    }
    return Image.network(
      item.imagePath,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => _imageFallback(c),
    );
  }

  Widget _imageFallback(AppColors c) => Container(
        color: c.surface,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: c.muted, size: 42),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final item = widget.item;
    final isVideo = item.kind == PortfolioKind.video;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(title: const Text('جزئیات نمونه‌کار')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  color: c.surface,
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _image(c),
                      if (isVideo)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .62),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white38),
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 38),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: c.line),
                  ),
                  child: Text(
                    item.categoryLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: c.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                      )),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.muted,
                          height: 2,
                        )),
              ],
              const SizedBox(height: 22),
              if (item.hasExternalAction)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _opening ? null : () => _open(item.targetUrl),
                    icon: Icon(isVideo
                        ? Icons.play_circle_outline_rounded
                        : Icons.open_in_new_rounded),
                    label: Text(_opening
                        ? 'در حال باز کردن…'
                        : isVideo
                            ? 'پخش ویدئو'
                            : item.kind == PortfolioKind.social
                                ? 'مشاهده صفحه'
                                : 'مشاهده پروژه زنده'),
                  ),
                ),
              if ((item.caseStudyUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _opening ? null : () => _open(item.caseStudyUrl),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('مطالعه جزئیات پروژه در وب‌سایت'),
                  ),
                ),
              ],
              if (!item.hasExternalAction && (item.caseStudyUrl ?? '').isEmpty)
                Text('این اثر در گالری نمونه‌کارهای استودیو ثبت شده است.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }
}