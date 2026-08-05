# ==============================================================================
# Linkary ProGuard/R8 Rules
# ==============================================================================

# Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# freeRASP - Runtime App Self Protection
-keep class com.aheaditec.** { *; }
-dontwarn com.aheaditec.**

# AndroidX & Material
-keep class androidx.** { *; }
-keep class com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Linkary VPN Firewall Service (accessed via intent-filter)
-keep class com.sam4g.app_settings.LinkaryFirewallService { *; }
-keep class com.sam4g.app_settings.MainActivity { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Preserve annotations and source info for crash reports
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent R8 from stripping interface information
-keep,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Notification channels and builders
-keep class androidx.core.app.NotificationCompat** { *; }

# VPN Service
-keep class android.net.VpnService { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
