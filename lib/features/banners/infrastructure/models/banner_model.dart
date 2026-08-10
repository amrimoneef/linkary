import '../../domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  BannerModel({
    required super.id,
    required super.imageUrl,
    super.link,
    super.expiresAt,
    super.app,
    super.localImageBase64,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['image_url'] as String;
    if (rawUrl.startsWith('/')) {
      rawUrl = 'https://sam4g.com$rawUrl';
    }

    return BannerModel(
      id: json['id'] as int,
      imageUrl: rawUrl,
      link: json['link'] as String?,
      expiresAt: json['expires_at'] as String?,
      app: json['app'] as String?,
      localImageBase64: json['local_image_base64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'link': link,
      'expires_at': expiresAt,
      'app': app,
      'local_image_base64': localImageBase64,
    };
  }
}
