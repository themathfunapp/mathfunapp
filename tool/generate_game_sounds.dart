// Generates lightweight placeholder WAVs (sine / multi-tone) for MathFun.
// Run from repo root: dart run tool/generate_game_sounds.dart
//
// Replace these with professionally mastered assets later if desired.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // Ambient beds (~2.2s, loop-friendly)
  final ambients = <String, double>{
    'ambient_forest': 220,
    'ambient_river': 330,
    'ambient_castle': 145,
    'ambient_space': 180,
    'ambient_bakery': 275,
    'ambient_clockTower': 320,
    'ambient_underwater': 95,
    'ambient_mountain': 165,
  };
  for (final e in ambients.entries) {
    _writeWav(File('${dir.path}/${e.key}.wav'), _ambientSamples(e.value, seconds: 2.2));
  }

  // Short SFX (file base name -> generator)
  final sfx = <String, List<double>>{
    'button_tap': [880, 0.06],
    'button_hover': [660, 0.05],
    'page_flip': [400, 0.08],
    'correct_answer': [523, 0.12], // C5; two-tone in body
    'wrong_answer': [140, 0.18],
    'timeout': [200, 0.25],
    'hint_reveal': [740, 0.1],
    'level_up': [392, 0.35],
    'achievement_unlock': [587, 0.3],
    'streak_bonus': [659, 0.15],
    'combo_hit': [784, 0.12],
    'coin_collect': [988, 0.1],
    'star_earn': [1047, 0.14],
    'box_open': [311, 0.2],
    'spin_wheel': [440, 0.15],
    'character_happy': [659, 0.12],
    'character_sad': [196, 0.2],
    'character_cheer': [784, 0.18],
    'notification': [523, 0.12],
    'error_beep': [150, 0.15],
    'success_chime': [784, 0.2],
  };

  for (final e in sfx.entries) {
    final freq = e.value[0];
    final dur = e.value[1];
    Int16List samples;
    if (e.key == 'correct_answer') {
      samples = _twoTone(523, 659, dur, vol: 0.22);
    } else if (e.key == 'wrong_answer') {
      samples = _buzz(dur, vol: 0.2);
    } else if (e.key == 'level_up') {
      samples = _arpeggio(dur, vol: 0.2);
    } else {
      samples = _sineTone(freq, dur, vol: e.key.contains('character') ? 0.18 : 0.22);
    }
    _writeWav(File('${dir.path}/sfx_${e.key}.wav'), samples);
  }

  // Music mood loops (soft, distinct root)
  final moods = <String, double>{
    'music_calm_instrumental': 196,
    'music_intense_beat': 110,
    'music_mystery_thinking': 247,
    'music_celebration_fanfare': 349,
    'music_soft_encouragement': 175,
    'music_relaxed_ambient': 155,
  };
  for (final e in moods.entries) {
    _writeWav(File('${dir.path}/${e.key}.wav'), _ambientSamples(e.value, seconds: 3.0, vol: 0.12));
  }

  stdout.writeln('Wrote ${ambients.length + sfx.length + moods.length} WAV files to ${dir.path}');
}

const int _sampleRate = 22050;

Int16List _sineTone(double freqHz, double seconds, {double vol = 0.2}) {
  final n = (seconds * _sampleRate).round();
  final out = Int16List(n);
  final amp = (32767 * vol).clamp(1, 32767).toInt();
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final v = (amp * math.sin(2 * math.pi * freqHz * t)).round().clamp(-32768, 32767);
    out[i] = v;
  }
  return out;
}

Int16List _twoTone(double f1, double f2, double seconds, {double vol = 0.2}) {
  final n = (seconds * _sampleRate).round();
  final out = Int16List(n);
  final amp = (32767 * vol).clamp(1, 32767).toInt();
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final f = i < n ~/ 2 ? f1 : f2;
    final v = (amp * math.sin(2 * math.pi * f * t)).round().clamp(-32768, 32767);
    out[i] = v;
  }
  return out;
}

Int16List _buzz(double seconds, {double vol = 0.2}) {
  final n = (seconds * _sampleRate).round();
  final out = Int16List(n);
  final amp = (32767 * vol).clamp(1, 32767).toInt();
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final sq = (math.sin(2 * math.pi * 120 * t) >= 0) ? 1.0 : -1.0;
    final v = (amp * 0.7 * sq).round().clamp(-32768, 32767);
    out[i] = v;
  }
  return out;
}

Int16List _arpeggio(double seconds, {double vol = 0.2}) {
  final freqs = [392.0, 494.0, 587.0, 784.0];
  final n = (seconds * _sampleRate).round();
  final out = Int16List(n);
  final amp = (32767 * vol).clamp(1, 32767).toInt();
  final step = n ~/ freqs.length;
  for (var i = 0; i < n; i++) {
    final fi = (i ~/ (step == 0 ? 1 : step)).clamp(0, freqs.length - 1);
    final t = i / _sampleRate;
    final f = freqs[fi];
    final v = (amp * math.sin(2 * math.pi * f * t)).round().clamp(-32768, 32767);
    out[i] = v;
  }
  return out;
}

Int16List _ambientSamples(double rootHz, {required double seconds, double vol = 0.16}) {
  final n = (seconds * _sampleRate).round();
  final out = Int16List(n);
  final amp = (32767 * vol).clamp(1, 32767).toInt();
  for (var i = 0; i < n; i++) {
    final t = i / _sampleRate;
    final wobble = 1.0 + 0.04 * math.sin(2 * math.pi * 0.35 * t);
    final v = (amp *
            (0.55 * math.sin(2 * math.pi * rootHz * wobble * t) +
                0.25 * math.sin(2 * math.pi * rootHz * 1.5 * t) +
                0.12 * math.sin(2 * math.pi * rootHz * 2.01 * t)))
        .round()
        .clamp(-32768, 32767);
    out[i] = v;
  }
  return out;
}

void _writeWav(File file, Int16List pcm) {
  final dataSize = pcm.length * 2;
  final headerSize = 44;
  final buffer = BytesBuilder(copy: false);
  buffer.add(_ascii('RIFF'));
  buffer.add(_u32(36 + dataSize));
  buffer.add(_ascii('WAVE'));
  buffer.add(_ascii('fmt '));
  buffer.add(_u32(16)); // PCM chunk size
  buffer.add(_u16(1)); // audio format PCM
  buffer.add(_u16(1)); // mono
  buffer.add(_u32(_sampleRate));
  buffer.add(_u32(_sampleRate * 2)); // byte rate
  buffer.add(_u16(2)); // block align
  buffer.add(_u16(16)); // bits per sample
  buffer.add(_ascii('data'));
  buffer.add(_u32(dataSize));
  for (var i = 0; i < pcm.length; i++) {
    buffer.add(_i16(pcm[i]));
  }
  file.writeAsBytesSync(buffer.toBytes());
}

List<int> _ascii(String s) => s.codeUnits;

List<int> _u32(int v) => [(v & 0xff), (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];

List<int> _u16(int v) => [(v & 0xff), (v >> 8) & 0xff];

List<int> _i16(int v) {
  if (v < 0) v += 65536;
  return [(v & 0xff), (v >> 8) & 0xff];
}
