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

    try {
      final banners = await remoteDataSource.getBanners();
      
      // Load old cache to fallback on images if network is slow
      final cachedString = prefs.getString(cacheKey);
      List<BannerModel> oldCache = [];
      if (cachedString != null && cachedString.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(cachedString);
          oldCache = jsonList.map((json) => BannerModel.fromJson(json as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      
      final List<BannerModel> bannersWithImages = [];
      for (var banner in banners) {
        String? base64Image;
        bool isImageDeleted = false;
        
        try {
          final response = await http.get(Uri.parse(banner.imageUrl)).timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            base64Image = base64Encode(response.bodyBytes);
          } else if (response.statusCode == 404 || response.statusCode == 403) {
            isImageDeleted = true; // Image deleted or forbidden on server
          }
        } catch (e) {
          if (kDebugMode) print('Failed to download image for base64: $e');
        }
        
        // Skip adding this banner if its image was explicitly deleted/not found
        if (isImageDeleted) continue;
        
        // Fallback to old cached image if download failed (e.g., timeout)
        if (base64Image == null) {
          final oldBanner = oldCache.firstWhereOrNull((b) => b.id == banner.id && b.imageUrl == banner.imageUrl);
          base64Image = oldBanner?.localImageBase64;
        }

        bannersWithImages.add(BannerModel(
          id: banner.id,
          imageUrl: banner.imageUrl,
          link: banner.link,
          expiresAt: banner.expiresAt,
          app: banner.app,
          localImageBase64: base64Image,
        ));
      }

      // Cache the result
      final List<Map<String, dynamic>> jsonList = bannersWithImages.map((b) => b.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      return bannersWithImages;
    } catch (e) {
      if (kDebugMode) print('Failed to fetch banners, trying cache. Error: $e');
      // Fallback to cache
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null && cachedString.isNotEmpty) {
        try {
          final List<dynamic> jsonList = jsonDecode(cachedString);
          return jsonList.map((json) => BannerModel.fromJson(json as Map<String, dynamic>)).toList();
        } catch (cacheError) {
          if (kDebugMode) print('Failed to parse cached banners: $cacheError');
        }
      }
      rethrow;
    }
  }
}
