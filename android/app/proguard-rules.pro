# ==============================================================================
# Linkary ProGuard / R8 Optimized Rules
# ==============================================================================

# 1. Main Application & Native Services
-keep class com.sam4g.app_settings.MainActivity { *; }
-keep class com.sam4g.app_settings.LinkaryFirewallService { *; }

# 2. freeRASP - Runtime App Self Protection
-keep class com.aheaditec.** { *; }
-dontwarn com.aheaditec.**

# 3. Crash Reporting & Stack Trace Attributes
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 4. Warnings Suppression for Optional Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# 5. Remove Debug Logging in Release Builds (Performance Boost)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
