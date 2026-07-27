// lib/features/calorie_tracker/data/models/barcode_product.dart
// Aura — Barcode Product Data Model
//
// Maps the JSON payload from:
//   POST /api/v1/meals/scan-barcode
//
// Response shape:
// {
//   "success": true,
//   "source": "open_food_facts" | "cache",
//   "data": {
//     "barcode": "3017620422003",
//     "productName": "Nutella",
//     "per100g": {
//       "calories": 539,
//       "protein": 6.3,
//       "carbs": 57.5,
//       "fats": 30.9
//     }
//   }
// }

class BarcodeProduct {
  final String barcode;
  final String productName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final String dataSource;

  const BarcodeProduct({
    required this.barcode,
    required this.productName,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    this.dataSource = 'open_food_facts',
  });

  factory BarcodeProduct.fromJson(Map<String, dynamic> json) {
    final per100g = json['per100g'] as Map<String, dynamic>? ?? {};
    return BarcodeProduct(
      barcode: json['barcode'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Unknown Product',
      caloriesPer100g: (per100g['calories'] as num?)?.toDouble() ?? 0.0,
      proteinPer100g: (per100g['protein'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (per100g['carbs'] as num?)?.toDouble() ?? 0.0,
      fatsPer100g: (per100g['fats'] as num?)?.toDouble() ?? 0.0,
      dataSource: (json['dataSource'] as String?) ?? 'open_food_facts',
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'productName': productName,
        'dataSource': dataSource,
        'per100g': {
          'calories': caloriesPer100g,
          'protein': proteinPer100g,
          'carbs': carbsPer100g,
          'fats': fatsPer100g,
        },
      };

  /// Calculate macros for a given serving size in grams.
  BarcodeServing forServing(double grams) {
    final factor = grams / 100.0;
    return BarcodeServing(
      product: this,
      servingGrams: grams,
      calories: (caloriesPer100g * factor).roundToDouble(),
      protein: (proteinPer100g * factor * 10).round() / 10,
      carbs: (carbsPer100g * factor * 10).round() / 10,
      fats: (fatsPer100g * factor * 10).round() / 10,
    );
  }
}

/// Calculated macros for a user-specified serving size.
class BarcodeServing {
  final BarcodeProduct product;
  final double servingGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  const BarcodeServing({
    required this.product,
    required this.servingGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

// ── Typed Exceptions ──────────────────────────────────────────

class BarcodeNotFoundException implements Exception {
  final String message;
  const BarcodeNotFoundException([this.message = 'Product not found in barcode database.']);

  @override
  String toString() => 'BarcodeNotFoundException: $message';
}

class BarcodeNetworkException implements Exception {
  final String message;
  final bool isTimeout;

  const BarcodeNetworkException(this.message, {this.isTimeout = false});

  @override
  String toString() => 'BarcodeNetworkException: $message';
}
