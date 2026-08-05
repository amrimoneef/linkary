import 'package:flutter/material.dart';

enum AppCategory {
  socialMedia,    // WhatsApp, Telegram, Facebook...
  streaming,      // YouTube, Netflix, Shahid...
  gaming,         // Games
  sharing,        // Sharing apps
  browsing,       // Browsers
  productivity,   // Mail, Docs
  vpn,            // VPN apps
  system,         // System services
  shopping,       // Amazon, Noon...
  education,      // Teams, Zoom...
  finance,        // Banking apps...
  other,          // Uncategorized
}

extension AppCategoryX on AppCategory {
  String get displayName {
    switch (this) {
      case AppCategory.socialMedia: return 'شبكات اجتماعية';
      case AppCategory.streaming: return 'وسائط متعددة';
      case AppCategory.gaming: return 'ألعاب';
      case AppCategory.sharing: return 'مشاركة';
      case AppCategory.browsing: return 'تصفح';
      case AppCategory.productivity: return 'إنتاجية';
      case AppCategory.vpn: return 'VPN';
      case AppCategory.system: return 'النظام';
      case AppCategory.shopping: return 'تسوق';
      case AppCategory.education: return 'تعليم';
      case AppCategory.finance: return 'مالية';
      case AppCategory.other: return 'أخرى';
    }
  }

  String get icon {
    switch (this) {
      case AppCategory.socialMedia: return '💬';
      case AppCategory.streaming: return '🎞';
      case AppCategory.gaming: return '🎮';
      case AppCategory.sharing: return '🔄';
      case AppCategory.browsing: return '🌐';
      case AppCategory.productivity: return '📊';
      case AppCategory.vpn: return '🔒';
      case AppCategory.system: return '🛠';
      case AppCategory.shopping: return '🛍️';
      case AppCategory.education: return '🎓';
      case AppCategory.finance: return '💰';
      case AppCategory.other: return '📱';
    }
  }

  Color get color {
    switch (this) {
      case AppCategory.socialMedia: return const Color(0xFF4A90E2); // Blue
      case AppCategory.streaming: return const Color(0xFFE94560);     // Red
      case AppCategory.gaming: return const Color(0xFF00FF87);        // Green
      case AppCategory.sharing: return const Color(0xFFF7D794);       // Yellow/Gold
      case AppCategory.browsing: return const Color(0xFF00D2FF);      // Cyan
      case AppCategory.productivity: return const Color(0xFF9B59B6);  // Purple
      case AppCategory.vpn: return const Color(0xFFE67E22);           // Orange
      case AppCategory.system: return const Color(0xFF95A5A6);         // Grey
      case AppCategory.shopping: return const Color(0xFFFF9FF3);       // Pink
      case AppCategory.education: return const Color(0xFF48DBFB);      // Light Blue
      case AppCategory.finance: return const Color(0xFF1DD1A1);        // Jade
      case AppCategory.other: return const Color(0xFF7F8C8D);          // Dark Grey
    }
  }
}
