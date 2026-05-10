import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'pdf_share_io.dart'
    if (dart.library.html) 'pdf_share_web.dart' as impl;

/// Web: kullanıcı tıklamasıyla indirme (async sonrası tarayıcı engeli);
/// mobil: sistem paylaşımı.
Future<void> sharePdfBytes(
  Uint8List bytes,
  String filename, {
  BuildContext? context,
  String dialogTitle = 'Save PDF',
  String dialogBody = 'Tap Download to save the file.',
  String downloadLabel = 'Download',
  String closeLabel = 'Cancel',
}) =>
    impl.sharePdfBytes(
      bytes,
      filename,
      context: context,
      dialogTitle: dialogTitle,
      dialogBody: dialogBody,
      downloadLabel: downloadLabel,
      closeLabel: closeLabel,
    );
