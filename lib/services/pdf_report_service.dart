import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../localization/parent_panel_l10n.dart';

/// Haftalık PDF rapor verisi
class PdfReportData {
  final String childName;
  final int totalScore;
  final int totalQuestions;
  final int correctAnswers;
  final int accuracy;
  final int earnedBadgesCount;
  final List<int> weeklyValues;
  final List<String> badgeNames;
  final List<String> recommendations;

  const PdfReportData({
    required this.childName,
    required this.totalScore,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.earnedBadgesCount,
    required this.weeklyValues,
    required this.badgeNames,
    required this.recommendations,
  });
}

/// PDF rapor oluşturma servisi
class PdfReportService {
  static const PdfColor _brandBlue = PdfColor.fromInt(0xFF3A6FF7);
  static const PdfColor _brandPurple = PdfColor.fromInt(0xFF6D45E6);
  static const PdfColor _softBg = PdfColor.fromInt(0xFFF5F7FF);
  static const PdfColor _good = PdfColor.fromInt(0xFF22A45D);
  static const PdfColor _mid = PdfColor.fromInt(0xFFF4A93E);
  static const PdfColor _warn = PdfColor.fromInt(0xFFE65555);

  static String _t(String languageCode, String key) =>
      ParentPanelL10n.of(languageCode, key);

  static Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      final raw = bytes.buffer.asUint8List();
      if (raw.isEmpty) return null;

      // Normalize image bytes via Flutter codec to avoid PDF viewer decode issues.
      final codec = await ui.instantiateImageCodec(raw);
      final frame = await codec.getNextFrame();
      final normalized = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      final data = normalized?.buffer.asUint8List();
      if (data != null && data.isNotEmpty) return pw.MemoryImage(data);
    } catch (_) {}
    return null;
  }

  /// PDF raporu oluştur ve bytes döndür
  static Future<Uint8List> generateReport(
    PdfReportData data, {
    String languageCode = 'tr',
  }) async {
    final lc = languageCode.trim().isEmpty ? 'tr' : languageCode.trim().toLowerCase();
    final days = List.generate(7, (d) => _t(lc, 'pp_weekday_$d'));

    // Türkçe karakter desteği için Roboto fontu kullan (ı, ğ, ş, İ, ü, ö, ç)
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );
    final pdf = pw.Document(
      title: 'MathFun ${_t(lc, 'pp_report_pdf_title')} - ${data.childName}',
      author: 'MathFun',
      theme: theme,
    );

    final now = DateTime.now();
    final dateText = '${now.day}.${now.month}.${now.year}';
    final logoImage = await _loadLogoImage();

    // Sayfa 1: Özet ve genel istatistikler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: _brandBlue,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 52,
                    height: 52,
                    margin: const pw.EdgeInsets.only(right: 12, top: 2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFE6ECFF)),
                    ),
                    padding: const pw.EdgeInsets.all(5),
                    child: logoImage != null
                        ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                        : pw.Center(
                            child: pw.Text(
                              'MM',
                              style: pw.TextStyle(
                                color: _brandBlue,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MathFun',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _t(lc, 'pp_report_pdf_title'),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(999),
                    ),
                    child: pw.Text(
                      dateText,
                      style: pw.TextStyle(
                        color: _brandBlue,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _softBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFDDE5FF)),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 64,
                    height: 64,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromInt(0xFFE1E8FF)),
                    ),
                    child: logoImage != null
                        ? pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          )
                        : pw.Text(
                            'MM',
                            style: pw.TextStyle(
                              color: _brandBlue,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _t(lc, 'pp_section_progress'),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${_t(lc, 'pp_lb_name')}: ${data.childName}',
                        style: const pw.TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              _t(lc, 'pp_section_detailed_stats'),
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _brandPurple),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _statBox(
                    _t(lc, 'pp_mini_points'),
                    '${data.totalScore}',
                    PdfColor.fromInt(0xFFEFF4FF),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _statBox(
                    _t(lc, 'pp_detail_total_questions'),
                    '${data.totalQuestions}',
                    PdfColor.fromInt(0xFFEFFFF7),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _statBox(
                    _t(lc, 'pp_detail_correct_answers'),
                    '${data.correctAnswers}',
                    PdfColor.fromInt(0xFFFFF4E8),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _statBox(
                    _t(lc, 'pp_detail_success_rate'),
                    '%${data.accuracy}',
                    PdfColor.fromInt(0xFFFFF0F3),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _statBox(
                    _t(lc, 'pp_badge_gallery_title'),
                    '${data.earnedBadgesCount}',
                    PdfColor.fromInt(0xFFF5F0FF),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFDF7EA),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFF7E1AC)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 14,
                    height: 14,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFE6A8),
                      borderRadius: pw.BorderRadius.circular(7),
                    ),
                    child: pw.Text(
                      'i',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xFF9A6A00),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(
                      _t(lc, 'pp_report_sunday_only'),
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Sayfa 2: Haftalık ilerleme + rozetler + öneriler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _t(lc, 'pp_weekly_progress_label'),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _brandPurple),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _softBg,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFDDE5FF)),
              ),
              child: pw.Column(
                children: [
                  pw.SizedBox(
                    height: 150,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final value = (i < data.weeklyValues.length) ? data.weeklyValues[i] : 0;
                        final height = (value / 100) * 110;
                        final barColor = value >= 80
                            ? _good
                            : (value >= 50 ? _mid : _warn);
                        return pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              width: 28,
                              height: height.clamp(6.0, 110.0),
                              decoration: pw.BoxDecoration(
                                color: barColor,
                                borderRadius: pw.BorderRadius.circular(5),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              '$value%',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(days[i], style: const pw.TextStyle(fontSize: 9)),
                          ],
                        );
                      }),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '100%  |  80%+ 🟢  |  50%+ 🟠  |  <50% 🔴',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              _t(lc, 'pp_badge_gallery_title'),
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _brandPurple),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFF7EA),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFF9E1A8)),
              ),
              child: data.badgeNames.isEmpty
                  ? pw.Text(
                      _t(lc, 'pp_badge_not_yet'),
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    )
                  : pw.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.badgeNames
                          .map(
                            (name) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.amber100,
                                borderRadius: pw.BorderRadius.circular(12),
                              ),
                              child: pw.Text(name, style: const pw.TextStyle(fontSize: 10)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              _t(lc, 'pp_report_suggestions'),
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _brandPurple),
            ),
            pw.SizedBox(height: 10),
            ...data.recommendations.map(
              (text) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1FFF3),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFCBEFD0)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      margin: const pw.EdgeInsets.only(top: 1),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFB6EBC0),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 11))),
                  ],
                ),
              ),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'MathFun',
                style: pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statBox(String label, String value, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
