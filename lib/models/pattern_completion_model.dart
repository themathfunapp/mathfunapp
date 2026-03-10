import 'dart:math' as math;

/// Desen Tamamlama - 10 seviye x 10 bölüm = 100 bölüm
/// Her hücre: 0=boş, 11-84=şekil*10+renk (şekil 1-8, renk 1-4)
class PatternModel {
  final int id;
  final int section; // 1-100
  final int rows;
  final int cols;
  final List<List<int>> matrix;
  final List<int> emptyIndices;
  final int shapeCount; // Bu bölümde kullanılan şekil sayısı (4, 5, 6, 7, 8)

  const PatternModel({
    required this.id,
    required this.section,
    required this.rows,
    required this.cols,
    required this.matrix,
    required this.emptyIndices,
    required this.shapeCount,
  });

  int get blockCount => rows * cols;
  int get emptyCount => emptyIndices.length;

  static int shapeFromVal(int val) => val >= 11 ? (val ~/ 10) : 0;
  static int colorFromVal(int val) => val >= 11 ? (val % 10) : 0;
}

/// 10 seviye x 10 bölüm = 100 bölüm
/// Seviye 1: 9 blok (3x3), 4 şekil
/// Seviye 2: 12 blok (3x4), 4 şekil
/// Seviye 3: 15 blok (3x5), 5 şekil
/// Seviye 4: 18 blok (3x6), 5 şekil
/// Seviye 5: 20 blok (4x5), 6 şekil
/// Seviye 6: 24 blok (4x6), 6 şekil
/// Seviye 7: 25 blok (5x5), 7 şekil
/// Seviye 8: 30 blok (5x6), 7 şekil
/// Seviye 9: 30 blok (6x5), 8 şekil
/// Seviye 10: 36 blok (6x6), 8 şekil
class PatternGenerator {
  static const List<(int rows, int cols, int shapes)> _levelConfig = [
    (3, 3, 4),   // L1: 9 blok, 4 şekil
    (3, 4, 4),   // L2: 12 blok, 4 şekil
    (3, 5, 5),   // L3: 15 blok, 5 şekil
    (3, 6, 5),   // L4: 18 blok, 5 şekil
    (4, 5, 6),   // L5: 20 blok, 6 şekil
    (4, 6, 6),   // L6: 24 blok, 6 şekil
    (5, 5, 7),   // L7: 25 blok, 7 şekil
    (5, 6, 7),   // L8: 30 blok, 7 şekil
    (6, 5, 8),   // L9: 30 blok, 8 şekil
    (6, 6, 8),   // L10: 36 blok, 8 şekil
  ];

  static List<PatternModel> generateAllPatterns() {
    final patterns = <PatternModel>[];
    int id = 1;
    final r = math.Random(42);

    for (int section = 1; section <= 100; section++) {
      final levelIndex = (section - 1) ~/ 10;
      final config = _levelConfig[levelIndex];
      final rows = config.$1;
      final cols = config.$2;
      final shapeCount = config.$3;
      final blockCount = rows * cols;

      // Bu bölüm için rastgele desen oluştur (şekil 1-shapeCount, renk 1-4)
      final matrix = <List<int>>[];
      for (int row = 0; row < rows; row++) {
        final rowData = <int>[];
        for (int col = 0; col < cols; col++) {
          final shape = 1 + r.nextInt(shapeCount);
          final color = 1 + r.nextInt(4);
          rowData.add(shape * 10 + color);
        }
        matrix.add(rowData);
      }

      final filled = _getFilledIndices(matrix, rows, cols);
      final ec = (2 + (section ~/ 20)).clamp(2, filled.length);
      filled.shuffle(r);
      patterns.add(PatternModel(
        id: id++,
        section: section,
        rows: rows,
        cols: cols,
        matrix: _copyMatrix(matrix),
        emptyIndices: filled.take(ec).toList(),
        shapeCount: shapeCount,
      ));
    }
    return patterns;
  }

  static List<int> _getFilledIndices(List<List<int>> m, int rows, int cols) {
    final list = <int>[];
    for (int i = 0; i < rows * cols; i++) {
      final val = m[i ~/ cols][i % cols];
      if (val >= 11 && val <= 84) list.add(i);
    }
    return list;
  }

  static List<List<int>> _copyMatrix(List<List<int>> m) =>
      m.map((r) => List<int>.from(r)).toList();
}
