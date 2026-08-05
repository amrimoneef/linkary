import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/saved_locations_controller.dart';
import '../../domain/entities/signal_rank.dart';

class SavedLocationsPage extends StatelessWidget {
  const SavedLocationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SavedLocationsController>();

    return Scaffold(
      backgroundColor: const Color(0xFF070B19), // Deep dark tech background
      appBar: AppBar(
        title: const Text('المواقع المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 100)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeaderInfo(),
                
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    }
                    if (controller.locations.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), // padding bottom for FAB
                      itemCount: controller.locations.length,
                      itemBuilder: (context, index) {
                        final loc = controller.locations[index];
                        return _buildLocationCard(context, loc, controller);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final count = controller.locations.length;
        if (count >= 10) return const SizedBox.shrink(); // Hide if maxed out
        
        return Container(
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Get.back(), // Return to radar to scan
            icon: const Icon(Iconsax.radar_2, color: Colors.white),
            label: const Text(
              'مسح موقع جديد',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.info_circle, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختر المكان الأفضل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('قارن بين المواقع المحفوظة (الأعلى نسبة هو الأفضل).', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
            child: const Icon(Iconsax.radar5, size: 60, color: Colors.blueAccent),
          ),
          const SizedBox(height: 20),
          const Text('لم تقم بحفظ أي موقع بعد!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'استخدم الرادار وابحث عن أفضل\nمكان لشبكة المودم ثم قم بحفظه هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, dynamic loc, SavedLocationsController controller) {
    final rankColor = _getRankColor(loc.rank);
    final rankText = _getRankText(loc.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title, Date and Delete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.location5, color: rankColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('dd MMM yyyy', 'ar').format(loc.timestamp)} • ${DateFormat('hh:mm a', 'ar').format(loc.timestamp)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                      onPressed: () => _showDeleteConfirm(context, controller, loc.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                if (loc.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    loc.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Bottom Row: Score and Bar
                Row(
                  children: [
                    // Score Circle
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loc.score / 100,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                          ),
                          Text(
                            '${loc.score.toInt()}%',
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Rank Text & Mini Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rankText,
                              style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getRankHint(loc.rank),
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(SignalRank rank) {
    switch (rank) {
      case SignalRank.deadZone:
        return Colors.redAccent;
      case SignalRank.critical:
        return Colors.orangeAccent;
      case SignalRank.stable:
        return Colors.blueAccent;
      case SignalRank.legendary:
        return Colors.greenAccent;
    }
  }

  String _getRankText(SignalRank rank) {
    switch (rank) {
      case SignalRank.deadZone: return 'ضعيف جداً';
      case SignalRank.critical: return 'مقبول';
      case SignalRank.stable: return 'جيد جداً';
      case SignalRank.legendary: return 'ممتاز (أسطوري)';
    }
  }

  String _getRankHint(SignalRank rank) {
    switch (rank) {
      case SignalRank.deadZone: return 'التغطية هنا سيئة جداً، ابحث عن مكان آخر.';
      case SignalRank.critical: return 'تغطية مقبولة ولكن يمكن إيجاد مكان أفضل.';
      case SignalRank.stable: return 'مكان مناسب ويوفر سرعات استقرار عالية.';
      case SignalRank.legendary: return 'هذا هو المكان الذهبي! ثبّت المودم هنا.';
    }
  }

  void _showDeleteConfirm(BuildContext context, SavedLocationsController controller, String id) {
    Get.defaultDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: 'تأكيد الحذف',
      titleStyle: const TextStyle(color: Colors.white),
      middleText: 'هل أنت متأكد أنك تريد حذف هذا الموقع؟',
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: 'نعم، احذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      cancelTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteLocation(id);
        Get.back();
      },
    );
  }
}
