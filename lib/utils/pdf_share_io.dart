import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Mobil / masaüstü: sistem paylaşım sayfası.
Future<void> sharePdfBytes(
  Uint8List bytes,
  String filename, {
  BuildContext? context,
  String dialogTitle = '',
  String dialogBody = '',
  String downloadLabel = '',
  String closeLabel = '',
}) =>
    Printing.sharePdf(bytes: bytes, filename: filename);
