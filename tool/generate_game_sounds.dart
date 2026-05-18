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

  // Çocuk dostu kısa efektler (44.1 kHz — web uyumlu)
  final childSfx = <String, Int16List Function()>{
    'button_tap': () => _sfxPop(pluckHz: 1046.5, vol: 0.14),
    'button_hover': () => _sfxPop(pluckHz: 1318.5, vol: 0.07, duration: 0.04),
    'page_flip': () => _sfxWhoosh(vol: 0.1),
    'correct_answer': () => _sfxCorrectDing(vol: 0.2),
    'wrong_answer': () => _sfxSoftWrong(vol: 0.15),
    'timeout': () => _sfxSoftWrong(vol: 0.12),
    'hint_reveal': () => _sfxNoteSequence([659.25, 784, 988], noteLen: 0.07, vol: 0.14),
    'level_up': () => _sfxNoteSequence([523.25, 659.25, 783.99, 1046.5], noteLen: 0.1, vol: 0.18),
    'achievement_unlock': () => _sfxNoteSequence([523.25, 659.25, 783.99, 1046.5, 1318.5], noteLen: 0.09, vol: 0.2),
    'streak_bonus': () => _sfxNoteSequence([784, 988, 1174.7], noteLen: 0.08, vol: 0.17),
    'combo_hit': () => _sfxNoteSequence([880, 1046.5], noteLen: 0.06, vol: 0.16),
    'coin_collect': () => _sfxNoteSequence([1318.5, 1568, 1760], noteLen: 0.05, vol: 0.15),
    'star_earn': () => _sfxNoteSequence([1046.5, 1318.5, 1568], noteLen: 0.07, vol: 0.17),
    'box_open': () => _sfxPop(pluckHz: 523.25, vol: 0.12, duration: 0.1),
    'spin_wheel': () => _sfxNoteSequence([440, 554.37, 659.25, 880], noteLen: 0.05, vol: 0.12),
    'character_happy': () => _sfxNoteSequence([523.25, 659.25, 783.99], noteLen: 0.08, vol: 0.16),
    'character_sad': () => _sfxNoteSequence([392, 349.23], noteLen: 0.14, vol: 0.12),
    'character_cheer': () => _sfxNoteSequence([659.25, 783.99, 987.77, 1174.7], noteLen: 0.07, vol: 0.18),
    'notification': () => _sfxPop(pluckHz: 880, vol: 0.12),
    'error_beep': () => _sfxSoftWrong(vol: 0.1),
    'success_chime': () => _sfxCorrectDing(vol: 0.18),
  };

  for (final e in childSfx.entries) {
    _writeWav(
      File('${dir.path}/sfx_${e.key}.wav'),
      e.value(),
      sampleRate: _sfxSampleRate,
    );
  }

  // Music mood loops (soft, distinct root) — eski drone tabanlı placeholder'lar
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

  // Uygulama geneli BGM: tanıdık çocuk melodisi, 44.1 kHz (web uyumlu)
  _writeWav(
    File('${dir.path}/music_kids_playful.wav'),
    _kidsPlayfulBgm(seconds: 8.0, vol: 0.14),
    sampleRate: _bgmSampleRate,
  );

  stdout.writeln(
    'Wrote ${ambients.length + childSfx.length + moods.length + 1} WAV files to ${dir.path}',
  );
}

const int _sampleRate = 22050;
/// Web + mobil için net efektler.
const int _sfxSampleRate = 44100;
/// Web tarayıcıları için BGM: standart 44.1 kHz PCM.
const int _bgmSampleRate = 44100;

/// Oyuncak xilofon / glocken vuruşu.
Int16List _pluck(double freq, double duration, {double vol = 0.18, int sr = _sfxSampleRate}) {
  final n = (duration * sr).round();
  final out = Int16List(n);
  final amp = 32767 * vol;
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final env = math.exp(-t * 7.5) * (1 - math.exp(-t * 180));
    final s = amp *
        env *
        (0.55 * math.sin(2 * math.pi * freq * t) +
            0.25 * math.sin(2 * math.pi * freq * 2.01 * t) +
            0.1 * math.sin(2 * math.pi * freq * 3.0 * t));
    out[i] = s.round().clamp(-32768, 32767);
  }
  return out;
}

Int16List _sfxNoteSequence(
  List<double> freqs, {
  double noteLen = 0.09,
  double gap = 0.015,
  double vol = 0.16,
}) {
  final total = freqs.length * noteLen + (freqs.length - 1) * gap;
  final n = (total * _sfxSampleRate).round();
  final out = Int16List(n);
  for (var i = 0; i < freqs.length; i++) {
    final note = _pluck(freqs[i], noteLen, vol: vol);
    final start = ((i * (noteLen + gap)) * _sfxSampleRate).round();
    for (var j = 0; j < note.length && start + j < n; j++) {
      final mixed = out[start + j] + note[j];
      out[start + j] = mixed.clamp(-32768, 32767);
    }
  }
  return out;
}

Int16List _sfxCorrectDing({double vol = 0.2}) =>
    _sfxNoteSequence([523.25, 659.25, 783.99], noteLen: 0.09, vol: vol);

Int16List _sfxSoftWrong({double vol = 0.14}) =>
    _sfxNoteSequence([440, 392], noteLen: 0.11, gap: 0.02, vol: vol);

Int16List _sfxPop({required double pluckHz, double vol = 0.14, double duration = 0.06}) =>
    _pluck(pluckHz, duration, vol: vol);

Int16List _sfxWhoosh({double vol = 0.1}) {
  final n = (_sfxSampleRate * 0.12).round();
  final out = Int16List(n);
  final amp = 32767 * vol;
  for (var i = 0; i < n; i++) {
    final t = i / n;
    final env = math.sin(math.pi * t) * (1 - t);
    final noise = (math.Random(i).nextDouble() * 2 - 1);
    out[i] = (amp * env * noise * 0.35).round().clamp(-32768, 32767);
  }
  return out;
}

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

/// Neşeli çocuk oyun müziği — tanıdık “parlak yıldız” tarzı melodi (C majör).
Int16List _kidsPlayfulBgm({double seconds = 8.0, double vol = 0.14}) {
  // C C G G A A G | E E D D C  (çocukların tanıdığı, neşeli motif)
  const melody = [
    523.25, 523.25, 783.99, 783.99, 880.0, 880.0, 783.99,
    659.25, 659.25, 587.33, 587.33, 523.25,
  ];
  const bpm = 96.0;
  final beatSec = 60.0 / bpm;
  final noteDur = beatSec * 0.78;

  final n = (seconds * _bgmSampleRate).round();
  final out = Int16List(n);
  final amp = 32767 * vol;

  for (var i = 0; i < n; i++) {
    final t = i / _bgmSampleRate;
    final beatIndex = (t / beatSec).floor();
    final noteIndex = beatIndex % melody.length;
    final noteStart = beatIndex * beatSec;
    final localT = t - noteStart;

    var sample = 0.0;

    if (localT < noteDur) {
      final freq = melody[noteIndex];
      // Oyuncak piyano / glockenspiel — parlak, kısa, sevimli
      final env = math.exp(-localT * 4.8) * (1 - math.exp(-localT * 100));
      sample = amp *
          env *
          (0.5 * math.sin(2 * math.pi * freq * localT) +
              0.28 * math.sin(2 * math.pi * freq * 2.0 * localT) +
              0.12 * math.sin(2 * math.pi * freq * 3.0 * localT));
    }

    // Hafif ritim tıkı (oyuncak metronom)
    final phase = t % beatSec;
    if (phase < 0.025) {
      sample += amp * 0.1 * math.exp(-phase * 90);
    }

    out[i] = sample.round().clamp(-32768, 32767);
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

void _writeWav(File file, Int16List pcm, {int sampleRate = _sampleRate}) {
  final dataSize = pcm.length * 2;
  final buffer = BytesBuilder(copy: false);
  buffer.add(_ascii('RIFF'));
  buffer.add(_u32(36 + dataSize));
  buffer.add(_ascii('WAVE'));
  buffer.add(_ascii('fmt '));
  buffer.add(_u32(16)); // PCM chunk size
  buffer.add(_u16(1)); // audio format PCM
  buffer.add(_u16(1)); // mono
  buffer.add(_u32(sampleRate));
  buffer.add(_u32(sampleRate * 2)); // byte rate
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
