enum PortfolioKind { website, social, logo, adImage, video }

class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final String categoryLabel;
  final String imagePath;
  final bool isAsset;
  final PortfolioKind kind;
  final String? targetUrl;
  final String? caseStudyUrl;
  final int viewCount;

  const PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryLabel,
    required this.imagePath,
    required this.kind,
    this.isAsset = false,
    this.targetUrl,
    this.caseStudyUrl,
    this.viewCount = 0,
  });

  bool get hasExternalAction => (targetUrl ?? '').trim().isNotEmpty;
}