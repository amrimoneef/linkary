import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/usecases/get_banners_usecase.dart';

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
    fetchBanners();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchBanners() async {
    if (banners.isEmpty) {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await getBannersUseCase.execute();
      banners.value = result;
      if (banners.isNotEmpty) {
        _startAutoSlide();
        _precacheBanners(result);
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
        final provider = CachedNetworkImageProvider(banner.imageUrl);
        provider.resolve(const ImageConfiguration());
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
