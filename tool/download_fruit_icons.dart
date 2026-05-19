// ignore_for_file: avoid_print
//
// Meyve Toplama — OpenMoji / Twemoji PNG ikonlarını indirir.
// Çalıştır: dart run tool/download_fruit_icons.dart
//
// Kaynaklar (CC BY-SA 4.0 / CC BY 4.0 — assets/sounds/SOUNDS_CREDITS.txt benzeri not):
// - https://openmoji.org (OpenMoji)
// - https://github.com/jdecked/twemoji (Twemoji)

import 'dart:io';

import '../lib/constants/fruit_icon_assets.dart';

const _openMojiBase =
    'https://cdn.jsdelivr.net/gh/hfg-gmuend/openmoji@15.1.0/color/72x72';
const _twemojiBase =
    'https://cdn.jsdelivr.net/gh/jdecked/twemoji@15.0.3/assets/72x72';

Future<void> main() async {
  final outDir = Directory('assets/fruit_icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  var ok = 0;
  var fail = 0;

  for (final entry in fruitIconHexById.entries) {
    final fruitId = entry.key;
    final hex = entry.value;
    final dest = File('${outDir.path}/$fruitId.png');

    final bytes = await _downloadIcon(hex);
    if (bytes == null) {
      print('FAIL $fruitId ($hex)');
      fail++;
      continue;
    }
    await dest.writeAsBytes(bytes);
    print('OK   $fruitId → ${dest.path}');
    ok++;
  }

  print('\nDone: $ok ok, $fail failed (${fruitIconHexById.length} total).');
  if (fail > 0) exitCode = 1;
}

Future<List<int>?> _downloadIcon(String hex) async {
  final openMojiUrl = '$_openMojiBase/$hex.png';
  var bytes = await _getBytes(openMojiUrl);
  if (bytes != null) return bytes;

  final twHex = hex.toLowerCase();
  final twUrl = '$_twemojiBase/$twHex.png';
  return _getBytes(twUrl);
}

Future<List<int>?> _getBytes(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) return null;
    return await response.fold<List<int>>(
      <int>[],
      (prev, chunk) => prev..addAll(chunk),
    );
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}
