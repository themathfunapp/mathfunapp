import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  static const List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  /// PDF raporu oluştur ve bytes döndür
  static Future<Uint8List> generateReport(PdfReportData data) async {
    // Türkçe karakter desteği için Roboto fontu kullan (ı, ğ, ş, İ, ü, ö, ç)
    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );
    final pdf = pw.Document(
      title: 'MathFun Haftalık Rapor - ${data.childName}',
      author: 'Matematik Macerası',
      theme: theme,
    );

    // Sayfa 1: Profil ve genel istatistikler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Matematik Macerası - Haftalık Rapor',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Çocuk Profili', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('İsim: ${data.childName}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Genel İstatistikler', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _statBox('Toplam Puan', '${data.totalScore}'),
                _statBox('Çözülen Soru', '${data.totalQuestions}'),
                _statBox('Doğru Cevap', '${data.correctAnswers}'),
                _statBox('Başarı %', '%${data.accuracy}'),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _statBox('Kazanılan Rozet', '${data.earnedBadgesCount}'),
                pw.Spacer(),
              ],
            ),
          ],
        ),
      ),
    );

    // Sayfa 2: Haftalık grafik
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Haftalık İlerleme', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Container(
              height: 200,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final value = data.weeklyValues[i];
                  final height = (value / 100) * 150;
                  return pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 40,
                        height: height.clamp(4.0, 150.0),
                        decoration: pw.BoxDecoration(
                          color: value >= 70 ? PdfColors.green : PdfColors.orange,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('${value}%', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text(_days[i], style: const pw.TextStyle(fontSize: 10)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );

    // Sayfa 3: Rozetler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Kazanılan Rozetler', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            if (data.badgeNames.isEmpty)
              pw.Text('Henüz rozet kazanılmadı.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))
            else
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.badgeNames.map((name) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber100,
                    borderRadius: pw.BorderRadius.circular(16),
                  ),
                  child: pw.Text(name, style: const pw.TextStyle(fontSize: 11)),
                )).toList(),
              ),
          ],
        ),
      ),
    );

    // Sayfa 4: Öneriler
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Öneriler', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...data.recommendations.map((text) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: pw.TextStyle(fontSize: 12)),
                  pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 12))),
                ],
              ),
            )),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
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
