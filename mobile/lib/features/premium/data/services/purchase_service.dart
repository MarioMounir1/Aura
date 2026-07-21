// lib/features/premium/data/services/purchase_service.dart
// Aura — RevenueCat Integration Service Singleton

import 'dart:async';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // API Keys loaded via String.fromEnvironment (or falling back to dummy credentials)
  static const _googleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY', defaultValue: 'goog_mock_key_123456');
  static const _appleApiKey  = String.fromEnvironment('REVENUECAT_APPLE_KEY', defaultValue: 'appl_mock_key_123456');

  final _premiumStreamController = StreamController<bool>.broadcast();

  /// Stream to listen to real-time subscription status changes (isPremium)
  Stream<bool> get premiumStream => _premiumStreamController.stream;

  /// Initialize the SDK with the correct platform key and login user
  Future<void> init(String appUserId) async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      late PurchasesConfiguration configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(_googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_appleApiKey);
      } else {
        return; // Platform not supported by RevenueCat
      }

      await Purchases.configure(configuration);
      await Purchases.logIn(appUserId);

      // Listen for subscription updates in real-time
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        final isActive = customerInfo.entitlements.all['premium']?.isActive ?? false;
        _premiumStreamController.add(isActive);
      });

      // Emit initial entitlement state
      final currentInfo = await Purchases.getCustomerInfo();
      _premiumStreamController.add(currentInfo.entitlements.all['premium']?.isActive ?? false);
    } catch (e) {
      print('❌ [RevenueCat] Initialization error: $e');
    }
  }

  /// Check current entitlement status synchronously/on-demand
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      print('❌ [RevenueCat] check error: $e');
      return false;
    }
  }

  /// Fetch all available subscription packages/offerings
  Future<Offerings> fetchOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      print('❌ [RevenueCat] fetchOfferings error: $e');
      rethrow;
    }
  }

  /// Purchase a package and return the updated premium entitlement status
  Future<bool> purchaseSubPackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isNowPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      _premiumStreamController.add(isNowPremium);
      return isNowPremium;
    } catch (e) {
      print('❌ [RevenueCat] purchase error: $e');
      rethrow;
    }
  }

  /// Restore purchases (useful for Apple App Store/Google Play Store reviews)
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isNowPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      _premiumStreamController.add(isNowPremium);
      return isNowPremium;
    } catch (e) {
      print('❌ [RevenueCat] restore error: $e');
      rethrow;
    }
  }
}
