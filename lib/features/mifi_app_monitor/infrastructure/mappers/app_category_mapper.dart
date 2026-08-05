import '../../domain/entities/app_category.dart';

class AppCategoryMapper {
  /// Known apps map for quick lookup
  static const Map<String, AppCategory> _knownApps = {
    // Social Media
    'com.whatsapp': AppCategory.socialMedia,
    'com.facebook.katana': AppCategory.socialMedia,
    'com.facebook.orca': AppCategory.socialMedia, // Messenger
    'com.instagram.android': AppCategory.socialMedia,
    'com.twitter.android': AppCategory.socialMedia,
    'org.telegram.messenger': AppCategory.socialMedia,
    'com.snapchat.android': AppCategory.socialMedia,
    'com.tiktok': AppCategory.socialMedia,
    
    // Streaming
    'com.google.android.youtube': AppCategory.streaming,
    'com.netflix.mediaclient': AppCategory.streaming,
    'com.shahid.stream': AppCategory.streaming,
    'com.spotify.music': AppCategory.streaming,
    
    // Browsers
    'com.android.chrome': AppCategory.browsing,
    'com.brave.browser': AppCategory.browsing,
    'org.mozilla.firefox': AppCategory.browsing,
    'com.opera.browser': AppCategory.browsing,
    
    // Productivity
    'com.google.android.gm': AppCategory.productivity,
    'com.microsoft.office.outlook': AppCategory.productivity,
    'com.google.android.apps.docs': AppCategory.productivity,
  };

  /// Categorizes an app by its package name.
  /// Falls back to package name prefix guessing if not in known list.
  static AppCategory categorize(String packageName) {
    // 1. Precise lookup
    if (_knownApps.containsKey(packageName)) {
      return _knownApps[packageName]!;
    }
    
    // 2. Prefix/Keyword guessing
    final lower = packageName.toLowerCase();
    
    if (lower.startsWith('com.android.') || 
        lower.startsWith('com.google.android.') && !lower.contains('youtube')) {
      return AppCategory.system;
    }
    if (lower.contains('game') || lower.contains('play')) {
      return AppCategory.gaming;
    }
    if (lower.contains('browser') || lower.contains('chrome')) {
      return AppCategory.browsing;
    }
    if (lower.contains('vpn') || lower.contains('proxy')) {
      return AppCategory.vpn;
    }
    if (lower.contains('chat') || lower.contains('messaging') || lower.contains('whatsapp') || lower.contains('telegram') || lower.contains('facebook')) {
      return AppCategory.socialMedia;
    }
    if (lower.contains('streaming') || lower.contains('video') || lower.contains('music') || lower.contains('netflix') || lower.contains('youtube') || lower.contains('spotify') || lower.contains('player') || lower.contains('shahid')) {
      return AppCategory.streaming;
    }
    if (lower.contains('productivity') || lower.contains('office') || lower.contains('docs') || lower.contains('mail')) {
      return AppCategory.productivity;
    }
    if (lower.contains('share') || lower.contains('zapya') || lower.contains('xender') || lower.contains('clone') || lower.contains('transfer')) {
      return AppCategory.sharing;
    }
    if (lower.contains('amazon') || lower.contains('noon') || lower.contains('shop') || lower.contains('market') || lower.contains('cart') || lower.contains('aliexpress')) {
      return AppCategory.shopping;
    }
    if (lower.contains('teams') || lower.contains('zoom') || lower.contains('classroom') || lower.contains('education') || lower.contains('school') || lower.contains('learn')) {
      return AppCategory.education;
    }
    if (lower.contains('bank') || lower.contains('pay') || lower.contains('wallet') || lower.contains('finance') || lower.contains('cash') || lower.contains('money')) {
      return AppCategory.finance;
    }
    
    return AppCategory.other;
  }
}
