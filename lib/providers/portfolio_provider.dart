import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../assets/app_assets.dart';
import '../models/portfolio_item.dart';

final portfolioItemsProvider = FutureProvider<List<PortfolioItem>>((ref) async {
  final client = Supabase.instance.client;

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

  return <PortfolioItem>[...galleryItems, ...videos];
});