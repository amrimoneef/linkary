// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linkary/core/theme/app_colors.dart';
import 'package:linkary/core/widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // الألوان الديناميكية
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subTextColor = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final glowColor = const Color(0xff4a90e2);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          // 🌌 خلفية الإشعاع والتوهج
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowColor.withValues(alpha: isDark ? 0.3 : 0.2),
                    glowColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // 🔙 زر الرجوع + العنوان
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                        onPressed: () => Get.back(),
                      ),
                      Text(
                        'حول التطبيق',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48), // لموازنة التوسيط
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 💎 أيقونة التطبيق الكبيرة
                  Hero(
                    tag: 'app_logo_hero',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 📝 اسم التطبيق والإصدار
                  Image.asset(
                    isDark ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => AppUpdateService.checkForUpdate(isManual: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: glowColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: glowColor.withValues(alpha: 0.3)),
                      ),
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final versionString = snapshot.hasData 
                              ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})' 
                              : '...';
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.refresh, color: glowColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'الإصدار $versionString  •  فحص التحديثات',
                                style: TextStyle(color: glowColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'لوحة التحكم الذكية والآمنة لإدارة مودم Sam4G\nبكل سهولة واحترافية.',
                    style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(icon: Iconsax.global, label: 'الموقع', onTap: () => _openLink('https://www.sam4g.com'),),
                      _buildQuickActionButton(icon: FontAwesomeIcons.whatsapp, label: 'واتساب', onTap: () => _openLink('https://api.whatsapp.com/send/?phone=967784111848&text&type=phone_number&app_absent=0')),
                      _buildQuickActionButton(icon: Iconsax.call, label: 'الرقم المجاني', onTap: () => _openLink('tel:8000848')),
                      _buildQuickActionButton(icon: Iconsax.sms, label: 'البريد الالكتروني', onTap: () => _openLink('mailto:support@sam4g.com')),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickActionButton(icon: FontAwesomeIcons.facebook, label: 'فيسبوك', onTap: () => _openLink('https://www.facebook.com/sam4g')),
                      _buildQuickActionButton(icon: FontAwesomeIcons.xTwitter, label: 'X', onTap: () => _openLink('https://www.x.com/SAM4GYE?s=03')),
                      _buildQuickActionButton(icon: FontAwesomeIcons.instagram, label: 'انستغرام', onTap: () => _openLink('https://www.instagram.com/sam4g.ye')),
                      _buildQuickActionButton(icon: FontAwesomeIcons.youtube, label: 'يوتيوب', onTap: () => _openLink('https://www.youtube.com/@sam4gyemen')),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 📋 بطاقة المعلومات (باستخدام GlassCard الخاص بك)
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: Text('حساباتنا الرسمية', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  // ),
                  // const SizedBox(height: 15),
                  // GlassCard(
                  //   child: Column(
                  //     children: [
                  //       _buildListTile(context, icon: Iconsax.cpu, title: 'الأجهزة المدعومة', subtitle: 'جميع أجهزة توجيه ASR/ZTE', isDark: isDark),
                  //       Divider(height: 25, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.2)),
                  //       _buildListTile(context, icon: Iconsax.code, title: 'المطور', subtitle: 'Harbi Developer', isDark: isDark),
                  //       Divider(height: 25, thickness: 0.5, color: Colors.grey.withValues(alpha: 0.2)),
                  //       _buildListTile(context, icon: Iconsax.document, title: 'سجل التغييرات', subtitle: 'النسخة الأولى (الميزات الأساسية)', isDark: isDark),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 50),

                  // 🛡️ الفوتر (حقوق النشر)
                  Icon(Iconsax.shield_tick, color: subTextColor.withValues(alpha: 0.5), size: 24),
                  const SizedBox(height: 10),
                  Text(
                    '© 2026 Sam4G. جميع الحقوق محفوظة.',
                    style: TextStyle(fontSize: 12, color: subTextColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () => _openLink('https://harbi.vip/'),
                    child: Column(
                      children: [
                        Text(
                          'طور بواسطة',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                        const SizedBox(height: 5),
                        Image.asset(
                          'assets/images/harbi-logo.png',
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Harbi.vip',
                          style: TextStyle(fontSize: 12, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة
  // ==========================================

  // زر الإجراءات السريعة الدائري
  Widget _buildQuickActionButton({required dynamic icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xb2538efa).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xb2538efa).withValues(alpha: 0.2)),
            ),
            child: icon is FaIconData 
                ? FaIcon(icon, color: const Color(0xff4a90e2), size: 24)
                : Icon(icon as IconData, color: const Color(0xff4a90e2), size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  // عنصر القائمة داخل البطاقة الزجاجية
  Widget _buildListTile(BuildContext context, {required dynamic icon, required String title, required String subtitle, required bool isDark}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: icon is FaIconData 
              ? FaIcon(icon, color: AppColors.primaryPurple, size: 22)
              : Icon(icon as IconData, color: AppColors.primaryPurple, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      CustomSnackbar.showError('خطأ', 'تعذر فتح الرابط');
    }
  }
}