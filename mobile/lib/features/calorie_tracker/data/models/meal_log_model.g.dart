// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'meal_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientBreakdownModelAdapter
    extends TypeAdapter<IngredientBreakdownModel> {
  @override
  final int typeId = 0;

  @override
  IngredientBreakdownModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientBreakdownModel(
      ingredient: fields[0] as String,
      estimatedWeightGrams: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientBreakdownModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.ingredient)
      ..writeByte(1)
      ..write(obj.estimatedWeightGrams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientBreakdownModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealLogModelAdapter extends TypeAdapter<MealLogModel> {
  @override
  final int typeId = 1;

  @override
  MealLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealLogModel(
      id: fields[0] as String?,
      restaurantName: fields[1] as String,
      mealName: fields[2] as String,
      imageUrl: fields[3] as String?,
      calories: fields[4] as double,
      protein: fields[5] as double,
      carbs: fields[6] as double,
      fats: fields[7] as double,
      ingredientsBreakdown: (fields[8] as List)
          .cast<IngredientBreakdownModel>(),
      source: fields[9] as String,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MealLogModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.restaurantName)
      ..writeByte(2)
      ..write(obj.mealName)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.calories)
      ..writeByte(5)
      ..write(obj.protein)
      ..writeByte(6)
      ..write(obj.carbs)
      ..writeByte(7)
      ..write(obj.fats)
      ..writeByte(8)
      ..write(obj.ingredientsBreakdown)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
