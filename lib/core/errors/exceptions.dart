import 'dart:typed_data';

class ServerException implements Exception {
  final String message;
  ServerException([this.message = "حدث خطأ في الخادم"]);
}

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = "انتهت الجلسة"]);
}

class CacheException implements Exception {}

class CaptchaRequiredException implements Exception {
  final String message;
  final String nonce;
  final String cookies;
  final String imageUrl;
  final Uint8List? imageBytes;

  CaptchaRequiredException({
    required this.nonce,
    required this.cookies,
    required this.imageUrl,
    this.imageBytes,
    this.message = "مطلوب رمز التحقق (كابتشا)",
  });
}
