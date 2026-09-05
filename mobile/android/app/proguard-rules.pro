# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.**

# Play Core (deferred components referenced by Flutter engine)
-dontwarn com.google.android.play.core.**

# AndroidX WorkManager & Room (used by Google Mobile Ads SDK)
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.** { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.room.MultiInstanceInvalidationService { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Google Play Services & AdMob
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Purchases / RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**
