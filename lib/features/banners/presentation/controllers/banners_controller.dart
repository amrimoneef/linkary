import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/usecases/get_banners_usecase.dart';
import '../../infrastructure/models/banner_model.dart';

class BannersController extends GetxController {
  final GetBannersUseCase getBannersUseCase;

  BannersController({required this.getBannersUseCase});

  var banners = <BannerEntity>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var currentIndex = 0.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // 🚀 عرض البانرات المخزنة فوراً في 0 ثانية (Cache-First)
    _loadCachedBanners();
    // 🔄 تحديث البانرات من الخادم في الخلفية
    fetchBanners();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// تحميل البانرات من الكاش المحلي فوراً دون انتظار أي استجابة من الشبكة
  void _loadCachedBanners() {
    try {
      if (Get.isRegistered<SharedPreferences>()) {
        final prefs = Get.find<SharedPreferences>();
        final cachedString = prefs.getString('cached_banners_data');
        if (cachedString != null && cachedString.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(cachedString);
          final cached = jsonList.map((json) => BannerModel.fromJson(json as Map<String, dynamic>)).toList();
          final now = DateTime.now();
          
          final validCached = cached.where((banner) {
            if (banner.expiresAt != null && banner.expiresAt!.isNotEmpty) {
              final expiryDate = DateTime.tryParse(banner.expiresAt!);
              if (expiryDate != null && now.isAfter(expiryDate)) {
                return false;
              }
            }
            return true;
          }).toList();

          if (validCached.isNotEmpty) {
            banners.value = validCached;
            isLoading.value = false;
            _startAutoSlide();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("⚠️ Error loading cached banners: $e");
    }
  }

  Future<void> fetchBanners() async {
    if (banners.isEmpty) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await getBannersUseCase.execute();
      
      final now = DateTime.now();
      final validBanners = result.where((banner) {
        if (banner.expiresAt != null && banner.expiresAt!.isNotEmpty) {
          final expiryDate = DateTime.tryParse(banner.expiresAt!);
          if (expiryDate != null && now.isAfter(expiryDate)) {
            return false; // Filter out expired banners
          }
        }
        return true;
      }).toList();
      
      if (validBanners.isNotEmpty) {
        banners.value = validBanners;
        _startAutoSlide();
        _precacheBanners(validBanners);
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) print("❌ Error fetching banners: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _precacheBanners(List<BannerEntity> fetchedBanners) async {
    for (var banner in fetchedBanners) {
      try {
        if (banner.imageUrl.isNotEmpty) {
          final provider = CachedNetworkImageProvider(banner.imageUrl);
          provider.resolve(const ImageConfiguration());
        }
      } catch (e) {
        if (kDebugMode) print("❌ Error precaching banner: $e");
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (banners.length <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (banners.isNotEmpty) {
        currentIndex.value = (currentIndex.value + 1) % banners.length;
      }
    });
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    // Reset timer on manual swipe to avoid instant automatic swipe right after manual
    _startAutoSlide();
  }

  Future<void> openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) print('Could not launch $url');
    }
  }
}
