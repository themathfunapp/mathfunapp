// IO file for mobile platforms (iOS/Android)

import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

// Setup iOS delegate
Future<void> setupIOSDelegate(InAppPurchase inAppPurchase) async {
  if (Platform.isIOS) {
    final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
        inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    await iosPlatformAddition.setDelegate(_IOSPaymentQueueDelegate());
  }
}

// Check if running on Android
bool isAndroidPlatform() => Platform.isAndroid;

// Check if running on iOS
bool isIOSPlatform() => Platform.isIOS;

// Get Android purchase details
dynamic getAndroidPurchaseDetails(PurchaseDetails details) {
  if (Platform.isAndroid && details is GooglePlayPurchaseDetails) {
    return details;
  }
  return null;
}

// iOS Payment Queue Delegate
class _IOSPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
