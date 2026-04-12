import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mathfun/localization/app_localizations.dart';

/// Mağaza yayını: derlemede geçirin, ör.
/// `--dart-define=PRIVACY_POLICY_URL=https://siteniz.com/gizlilik`
/// `--dart-define=TERMS_OF_USE_URL=https://siteniz.com/kosullar`
const String kPrivacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: '',
);

const String kTermsOfUseUrl = String.fromEnvironment(
  'TERMS_OF_USE_URL',
  defaultValue: '',
);

bool _isUsableHttpUrl(String s) {
  final u = Uri.tryParse(s.trim());
  if (u == null || !u.hasScheme) return false;
  if (u.host.isEmpty) return false;
  return u.scheme == 'https' || u.scheme == 'http';
}

bool get hasConfiguredPrivacyPolicyUrl => _isUsableHttpUrl(kPrivacyPolicyUrl);
bool get hasConfiguredTermsOfUseUrl => _isUsableHttpUrl(kTermsOfUseUrl);

Future<bool> launchConfiguredUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched;
  } catch (_) {
    return false;
  }
}

/// Gizlilik / şartlar: URL tanımlıysa tarayıcı; değilse uygulama içi özet metin.
class LegalUrls {
  LegalUrls._();

  static Future<void> openPrivacyPolicy(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    if (hasConfiguredPrivacyPolicyUrl) {
      final ok = await launchConfiguredUrl(kPrivacyPolicyUrl);
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.get('legal_link_open_failed'))),
        );
      }
      return;
    }
    if (!context.mounted) return;
    _showTextDialog(
      context,
      title: loc.privacyPolicy,
      body: loc.privacyContent,
      closeLabel: loc.close,
    );
  }

  static Future<void> openTermsOfUse(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    if (hasConfiguredTermsOfUseUrl) {
      final ok = await launchConfiguredUrl(kTermsOfUseUrl);
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.get('legal_link_open_failed'))),
        );
      }
      return;
    }
    if (!context.mounted) return;
    _showTextDialog(
      context,
      title: loc.termsOfUse,
      body: loc.termsContent,
      closeLabel: loc.close,
    );
  }

  static Future<void> launchPrivacyInBrowserFromDialog(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    if (!hasConfiguredPrivacyPolicyUrl) return;
    final ok = await launchConfiguredUrl(kPrivacyPolicyUrl);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.get('legal_link_open_failed'))),
      );
    }
  }

  static Future<void> launchTermsInBrowserFromDialog(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    if (!hasConfiguredTermsOfUseUrl) return;
    final ok = await launchConfiguredUrl(kTermsOfUseUrl);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.get('legal_link_open_failed'))),
      );
    }
  }

  static void _showTextDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String closeLabel,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}
