// lib/features/calorie_tracker/data/models/ai_usage_quota.dart

class AiUsageQuota {
  final int cameraUsage;
  final int galleryUsage;
  final int barcodeUsage;
  final int cameraLimit;
  final int galleryLimit;
  final int barcodeLimit;
  final bool isPremium;

  const AiUsageQuota({
    required this.cameraUsage,
    required this.galleryUsage,
    this.barcodeUsage = 0,
    required this.cameraLimit,
    required this.galleryLimit,
    this.barcodeLimit = 2,
    required this.isPremium,
  });

  factory AiUsageQuota.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    final limits = json['limits'] as Map<String, dynamic>? ?? {};
    return AiUsageQuota(
      cameraUsage: usage['camera'] as int? ?? 0,
      galleryUsage: usage['gallery'] as int? ?? 0,
      barcodeUsage: usage['barcode'] as int? ?? 0,
      cameraLimit: limits['camera'] as int? ?? 2,
      galleryLimit: limits['gallery'] as int? ?? 2,
      barcodeLimit: limits['barcode'] as int? ?? 2,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  bool get isCameraExceeded => cameraUsage >= cameraLimit;
  bool get isGalleryExceeded => galleryUsage >= galleryLimit;
  bool get isBarcodeExceeded => barcodeUsage >= barcodeLimit;
  
  int get remainingCamera => (cameraLimit - cameraUsage).clamp(0, 999);
  int get remainingGallery => (galleryLimit - galleryUsage).clamp(0, 999);
  int get remainingBarcode => (barcodeLimit - barcodeUsage).clamp(0, 999);
}
