# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# AndroidX WorkManager & Room (used by Google Mobile Ads SDK)
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    *;
}
-keep class androidx.room.MultiInstanceInvalidationService { *; }
-dontwarn androidx.work.impl.**

# Google Play Services & AdMob
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Purchases / RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
