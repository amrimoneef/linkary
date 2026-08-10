import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/banners_controller.dart';
import '../../../../core/widgets/glass_card.dart';

class BannersCarouselWidget extends StatefulWidget {
  const BannersCarouselWidget({super.key});

  @override
  State<BannersCarouselWidget> createState() => _BannersCarouselWidgetState();
}

class _BannersCarouselWidgetState extends State<BannersCarouselWidget> {
  final BannersController controller = Get.find<BannersController>();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Listen to controller's index changes to animate the PageView
    ever(controller.currentIndex, (int index) {
      if (_pageController.hasClients) {
        // Only animate if it's not a user swipe (user swipes already update the page view)
        if (_pageController.page?.round() != index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 140,
          // Show empty space or you can add GlassCard if preferred
        );
      }

      if (controller.banners.isEmpty) {
        return const SizedBox.shrink(); // Hide entirely if no banners
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.banners.length,
                itemBuilder: (context, index) {
                  final banner = controller.banners[index];
                  return GestureDetector(
                    onTap: () => controller.openLink(banner.link),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: banner.localImageBase64 != null && banner.localImageBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(banner.localImageBase64!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => GlassCard(
                                  borderRadius: 20,
                                  child: const SizedBox.shrink(),
                                ),
                                errorWidget: (context, url, error) => GlassCard(
                                  borderRadius: 20,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                controller.banners.length,
                (index) => Obx(() {
                  bool isActive = controller.currentIndex.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 8,
                    width: isActive ? 15 : 8,
                    decoration: BoxDecoration(
                      color: isActive 
                        ? const Color(0xFF8BEDD7)
                        : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
