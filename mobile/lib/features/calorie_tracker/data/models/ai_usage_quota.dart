// lib/features/calorie_tracker/data/models/ai_usage_quota.dart

class AiUsageQuota {
  final int cameraUsage;
  final int galleryUsage;
  final int cameraLimit;
  final int galleryLimit;
  final bool isPremium;

  const AiUsageQuota({
    required this.cameraUsage,
    required this.galleryUsage,
    required this.cameraLimit,
    required this.galleryLimit,
    required this.isPremium,
  });

  factory AiUsageQuota.fromJson(Map<String, dynamic> json) {
    return AiUsageQuota(
      cameraUsage: json['usage']['camera'] as int? ?? 0,
      galleryUsage: json['usage']['gallery'] as int? ?? 0,
      cameraLimit: json['limits']['camera'] as int? ?? 2,
      galleryLimit: json['limits']['gallery'] as int? ?? 2,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  bool get isCameraExceeded => cameraUsage >= cameraLimit;
  bool get isGalleryExceeded => galleryUsage >= galleryLimit;
  
  int get remainingCamera => (cameraLimit - cameraUsage).clamp(0, 999);
  int get remainingGallery => (galleryLimit - galleryUsage).clamp(0, 999);
}
