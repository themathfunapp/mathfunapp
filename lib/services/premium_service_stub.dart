// Stub file for web platform - no iOS/Android specific implementations

import 'package:in_app_purchase/in_app_purchase.dart';

// Stub function for iOS delegate setup (does nothing on web)
Future<void> setupIOSDelegate(InAppPurchase inAppPurchase) async {
  // No-op on web
}

// Stub function to check if running on Android
bool isAndroidPlatform() => false;

// Stub function to check if running on iOS
bool isIOSPlatform() => false;

// Stub for getting Android purchase details
dynamic getAndroidPurchaseDetails(PurchaseDetails details) => null;
