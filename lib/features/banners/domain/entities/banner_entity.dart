class BannerEntity {
  final int id;
  final String imageUrl;
  final String? link;
  final String? expiresAt;
  final String? app;

  BannerEntity({
    required this.id,
    required this.imageUrl,
    this.link,
    this.expiresAt,
    this.app,
  });
}
