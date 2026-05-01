import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

/// Google Identity Services resmi düğmesi (FedCM / hesap seçici).
Widget buildWebGoogleSignInButton({
  String? locale,
  double? minWidth,
}) {
  return SizedBox(
    height: 52,
    width: double.infinity,
    child: Center(
      child: renderButton(
        configuration: GSIButtonConfiguration(
          type: GSIButtonType.standard,
          theme: GSIButtonTheme.filledBlue,
          size: GSIButtonSize.large,
          text: GSIButtonText.continueWith,
          shape: GSIButtonShape.rectangular,
          minimumWidth: minWidth ?? 320,
          locale: locale,
        ),
      ),
    ),
  );
}
