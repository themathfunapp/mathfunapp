// ignore_for_file: avoid_web_libraries_in_flutter — bu dosya yalnızca web derlemesinde import edilir.

import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

bool _isAppleMobileWeb(html.Navigator nav) {
  final ua = nav.userAgent.toLowerCase();
  if (ua.contains('iphone') || ua.contains('ipad')) return true;
  // iPadOS 13+ bazen masaüstü Safari gibi davranır
  if (ua.contains('macintosh') && nav.maxTouchPoints != null && nav.maxTouchPoints! > 1) {
    return true;
  }
  return false;
}

/// Tarayıcılar async işten sonra programatik indirmeyi sıkça engeller; gerçek tıklamada tetiklenir.
void _triggerBrowserDownload(Uint8List bytes, String filename) {
  final safeName =
      filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim().isEmpty
          ? 'mathfun_report.pdf'
          : filename;

  final blob = html.Blob(<Object>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final nav = html.window.navigator;
  final body = html.document.body;

  void revokeSoon({required bool longDelay}) {
    Future<void>.delayed(
      Duration(seconds: longDelay ? 90 : 4),
      () => html.Url.revokeObjectUrl(url),
    );
  }

  // iOS Safari: <a download> blob URL ile genelde yok sayılır; yeni sekmede açılır, Paylaş > Dosyalara Kaydet.
  if (_isAppleMobileWeb(nav)) {
    html.window.open(url, '_blank');
    revokeSoon(longDelay: true);
    return;
  }

  if (body == null) {
    html.window.open(url, '_blank');
    revokeSoon(longDelay: true);
    return;
  }

  // display:none anchor bazı tarayıcılarda tıklamayı yutar; küçük görünür hit alanı kullan.
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', safeName)
    ..style.visibility = 'hidden'
    ..style.position = 'fixed'
    ..style.left = '0'
    ..style.top = '0'
    ..style.width = '1px'
    ..style.height = '1px'
    ..style.opacity = '0.01';

  body.append(anchor);
  anchor.click();
  anchor.remove();
  revokeSoon(longDelay: false);
}

/// Web: çocuk dostu, renkli indirme penceresi (ebeveyn paneli PDF akışı).
class _PlayfulPdfDownloadDialog extends StatefulWidget {
  const _PlayfulPdfDownloadDialog({
    required this.title,
    required this.body,
    required this.downloadLabel,
    required this.closeLabel,
    required this.onDownload,
    required this.onCancel,
  });

  final String title;
  final String body;
  final String downloadLabel;
  final String closeLabel;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  @override
  State<_PlayfulPdfDownloadDialog> createState() => _PlayfulPdfDownloadDialogState();
}

class _PlayfulPdfDownloadDialogState extends State<_PlayfulPdfDownloadDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _sparkle;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat(reverse: true);
    _sparkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  static const _purple = Color(0xFF6A4FBF);
  static const _coral = Color(0xFFFF6B6B);
  static const _sun = Color(0xFFFFD93D);
  static const _mint = Color(0xFF6BCB77);
  static const _sky = Color(0xFF4D96FF);

  @override
  Widget build(BuildContext context) {
    final pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_coral, _sun, _mint, _sky],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFE8F0), width: 2),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _sparkle,
                    builder: (context, child) {
                      final bob = 4 * math.sin(_sparkle.value * math.pi * 2);
                      return Transform.translate(
                        offset: Offset(0, bob),
                        child: child,
                      );
                    },
                    child: const Text(
                      '📄✨🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 38, height: 1.1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: _purple,
                      shadows: [
                        Shadow(
                          color: _sun.withValues(alpha: 0.85),
                          blurRadius: 0,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ScaleTransition(
                    scale: pulseScale,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onDownload,
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B35),
                                Color(0xFFFF8E53),
                                Color(0xFFFFC107),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.downloadLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: _purple,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: Text(
                      widget.closeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> sharePdfBytes(
  Uint8List bytes,
  String filename, {
  BuildContext? context,
  String dialogTitle = 'Save PDF',
  String dialogBody = 'Tap Download to save the file.',
  String downloadLabel = 'Download',
  String closeLabel = 'Cancel',
}) async {
  if (context != null && context.mounted) {
    final barrierLabel = MaterialLocalizations.of(context).modalBarrierDismissLabel;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: const Color(0xFF4A148C).withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _PlayfulPdfDownloadDialog(
          title: dialogTitle,
          body: dialogBody,
          downloadLabel: downloadLabel,
          closeLabel: closeLabel,
          onDownload: () {
            _triggerBrowserDownload(bytes, filename);
            Navigator.of(ctx).pop();
          },
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  } else {
    _triggerBrowserDownload(bytes, filename);
  }
}
