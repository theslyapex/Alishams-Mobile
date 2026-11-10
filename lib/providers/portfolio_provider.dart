import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../assets/app_assets.dart';
import '../models/portfolio_item.dart';

final portfolioItemsProvider = FutureProvider<List<PortfolioItem>>((ref) async {
  final client = Supabase.instance.client;

  // Public website projects listed on the live ALISHAMS portfolio page.
  const websites = <PortfolioItem>[
    PortfolioItem(id: 'website-iran-ma', title: 'ایران‌ما', description: 'وب‌سایت محتوایی درباره تاریخ ایران با تمرکز بر طراحی وب، هویت بصری و انتشار محتوای تاریخی.', categoryLabel: 'وب‌سایت محتوایی', imagePath: AppAssets.iranMaImage, kind: PortfolioKind.website, isAsset: true, targetUrl: 'https://infoiranma.ir/', caseStudyUrl: 'https://alishams.ir/case-studies/iran-ma.html'),
    PortfolioItem(id: 'website-apex', title: 'Apex Video Compressor', description: 'ابزار تحت وب برای ساده‌سازی فرایند فشرده‌سازی ویدئو و ارائه تجربه کاربری روشن.', categoryLabel: 'ابزار آنلاین', imagePath: AppAssets.apexImage, kind: PortfolioKind.website, isAsset: true, targetUrl: 'https://theslyapex.github.io/Apex-video-compressor/', caseStudyUrl: 'https://alishams.ir/case-studies/apex.html'),
    PortfolioItem(id: 'website-nova', title: 'Nova Image Lab', description: 'مجموعه ابزارهای تصویری با تمرکز بر پردازش محلی تصویر و دسترسی ساده.', categoryLabel: 'ابزار تصویری', imagePath: AppAssets.novaImage, kind: PortfolioKind.website, isAsset: true, targetUrl: 'https://theslyapex.github.io/Nova-image-lab/', caseStudyUrl: 'https://alishams.ir/case-studies/nova.html'),
    PortfolioItem(id: 'website-abzarino', title: 'ابزارینو', description: 'مجموعه ابزارهای کاربردی آنلاین با هدف دسترسی سریع و تجربه ساده برای کاربران.', categoryLabel: 'مجموعه ابزار', imagePath: AppAssets.abzarinoImage, kind: PortfolioKind.website, isAsset: true, targetUrl: 'https://theslyapex.github.io/Abzarino/', caseStudyUrl: 'https://alishams.ir/case-studies/abzarino.html'),
    PortfolioItem(id: 'website-shirazeh', title: 'SHIRAZEH · رزومه‌ساز', description: 'رزومه‌ساز آنلاین با تمرکز بر ارائه حرفه‌ای اطلاعات و انتخاب قالب.', categoryLabel: 'وب‌اپلیکیشن', imagePath: AppAssets.shirazehImage, kind: PortfolioKind.website, isAsset: true, targetUrl: 'https://theslyapex.github.io/SHIRAZEH/', caseStudyUrl: 'https://alishams.ir/case-studies/shirazeh.html'),
  ];

  final rows = await client.from('portfolio_items')
      .select('id,category,title,description,image_path,cover_path,created_at,view_count')
      .eq('published', true).order('created_at', ascending: false);
  final videoRows = await client.from('studio_videos')
      .select('id,slug,title,description,category,categories,video_url,poster_url,featured,published_at')
      .eq('is_published', true)
      .order('featured', ascending: false)
      .order('published_at', ascending: false);

  final galleryItems = <PortfolioItem>[];
  for (final raw in rows) {
    final row = Map<String, dynamic>.from(raw as Map);
    final category = (row['category'] ?? '').toString();
    final kind = category == 'logo' ? PortfolioKind.logo : PortfolioKind.adImage;
    final path = (row['cover_path'] ?? row['image_path'] ?? '').toString();
    if (path.isEmpty) continue;
    galleryItems.add(PortfolioItem(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? 'نمونه‌کار').toString(),
      description: (row['description'] ?? '').toString(),
      categoryLabel: kind == PortfolioKind.logo ? 'طراحی لوگو' : 'تصویر تبلیغاتی',
      imagePath: client.storage.from('portfolio-images').getPublicUrl(path),
      kind: kind,
      viewCount: (row['view_count'] as num?)?.toInt() ?? 0,
    ));
  }

  const labels = <String, String>{
    'motion-graphics': 'موشن‌گرافیک', 'reels': 'ریلز',
    'advertisement': 'تیزر تبلیغاتی', 'other': 'ویدئو',
  };
  final videos = <PortfolioItem>[];
  for (final raw in videoRows) {
    final row = Map<String, dynamic>.from(raw as Map);
    final poster = (row['poster_url'] ?? '').toString();
    final categories = (row['categories'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final fallback = (row['category'] ?? 'other').toString();
    final categoryLabel = (categories.isEmpty ? <String>[fallback] : categories)
        .map((e) => labels[e] ?? e).toSet().join(' · ');
    videos.add(PortfolioItem(
      id: (row['id'] ?? row['slug'] ?? '').toString(),
      title: (row['title'] ?? 'ویدئوی استودیو').toString(),
      description: (row['description'] ?? '').toString(),
      categoryLabel: categoryLabel.isEmpty ? 'ویدئو' : categoryLabel,
      imagePath: poster.isEmpty ? AppAssets.workspaceImage : poster,
      isAsset: poster.isEmpty,
      kind: PortfolioKind.video,
      targetUrl: (row['video_url'] ?? '').toString(),
    ));
  }

  return <PortfolioItem>[...websites, ...galleryItems, ...videos];
});