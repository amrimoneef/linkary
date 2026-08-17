import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/banner_entity.dart';
import '../../domain/repositories/banners_repository.dart';
import '../data_sources/banners_remote_data_source.dart';
import '../models/banner_model.dart';
import 'package:flutter/foundation.dart';

class BannersRepositoryImpl implements BannersRepository {
  final BannersRemoteDataSource remoteDataSource;

  BannersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BannerEntity>> getBanners() async {
    final prefs = Get.find<SharedPreferences>();
    const cacheKey = 'cached_banners_data';

    // 1. استرجاع الكاش القديم فوراً
    final cachedString = prefs.getString(cacheKey);
    List<BannerModel> oldCache = [];
    if (cachedString != null && cachedString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(cachedString);
        oldCache = jsonList.map((json) => BannerModel.fromJson(json as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    try {
      final banners = await remoteDataSource.getBanners().timeout(const Duration(seconds: 3));
      
      // 2. معالجة الصور بالتوازي (Parallel Execution) واستخدام الكاش المسبق للصور المخزنة
      final tasks = banners.map((banner) async {
        final oldBanner = oldCache.firstWhereOrNull((b) => b.id == banner.id && b.imageUrl == banner.imageUrl);
        
        // إذا كانت الصورة مخزنة مسبقاً في الكاش، نستخدمها فوراً دون أي اتصال بالإنترنت
        if (oldBanner?.localImageBase64 != null && oldBanner!.localImageBase64!.isNotEmpty) {
          return BannerModel(
            id: banner.id,
            imageUrl: banner.imageUrl,
            link: banner.link,
            expiresAt: banner.expiresAt,
            app: banner.app,
            localImageBase64: oldBanner.localImageBase64,
          );
        }

        // إذا كانت الصورة جديدة ولم تُخزن بعد، نحملها بمهلة سريعة
        String? base64Image;
        bool isImageDeleted = false;
        try {
          final response = await http.get(Uri.parse(banner.imageUrl)).timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            base64Image = base64Encode(response.bodyBytes);
          } else if (response.statusCode == 404 || response.statusCode == 403) {
            isImageDeleted = true;
          }
        } catch (e) {
          if (kDebugMode) print('Failed to download new banner image: $e');
        }

        if (isImageDeleted) return null;

        return BannerModel(
          id: banner.id,
          imageUrl: banner.imageUrl,
          link: banner.link,
          expiresAt: banner.expiresAt,
          app: banner.app,
          localImageBase64: base64Image,
        );
      });

      final results = await Future.wait(tasks);
      final List<BannerModel> validBanners = results.whereType<BannerModel>().toList();

      // 3. تحديث الكاش
      if (validBanners.isNotEmpty) {
        final List<Map<String, dynamic>> jsonList = validBanners.map((b) => b.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        return validBanners;
      } else if (oldCache.isNotEmpty) {
        return oldCache;
      }
      return validBanners;
    } catch (e) {
      if (kDebugMode) print('Failed to fetch banners from network, using cache: $e');
      if (oldCache.isNotEmpty) {
        return oldCache;
      }
      rethrow;
    }
  }
}
