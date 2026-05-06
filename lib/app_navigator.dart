import 'package:flutter/material.dart';

/// [MaterialApp] kök [Navigator] anahtarı.
///
/// `MaterialApp.builder` ile Navigator'ın üstüne yerleşen widget'lar (ör. davet host)
/// `Navigator.of(context)` ile bu Navigator'a erişemez; push/pop için bu anahtar kullanılmalıdır.
final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'appRootNavigator',
);
