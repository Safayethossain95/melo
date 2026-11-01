// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 1. Cyber Teal (Synthwave - Arpeggio)
  generateWav(
    path: 'assets/audio/cyber_teal.wav',
    durationSeconds: 16,
    generator: (t) {
      final chord = [220.0, 277.18, 329.63, 440.0, 554.37]; // A major
      final noteIndex = ((t * 4).floor()) % chord.length;
      final freq = chord[noteIndex];
      final osc1 = sin(2 * pi * freq * t);
      final osc2 = sin(2 * pi * (freq * 0.5) * t) * 0.5; // sub bass
      final env = (1.0 - ((t * 4) % 1.0) * 0.6);
      return (osc1 * 0.5 + osc2) * env * 0.3;
    },
  );

  // 2. Lo-Fi Rain (Chill Lo-Fi - Warm Rhodes)
  generateWav(
    path: 'assets/audio/lofi_rain.wav',
    durationSeconds: 18,
    generator: (t) {
      final chords = [
        [261.63, 329.63, 392.0, 493.88], // Cmaj7
        [220.0, 261.63, 329.63, 392.0],  // Am7
        [174.61, 220.0, 261.63, 329.63], // Fmaj7
        [196.0, 246.94, 293.66, 349.23], // G7
      ];
      final chordIndex = ((t / 3.0).floor()) % chords.length;
      final notes = chords[chordIndex];
      double sample = 0;
      for (final n in notes) {
        sample += sin(2 * pi * n * t) * 0.2;
      }
      // Lo-fi vinyl warmth
      final crackle = (Random().nextDouble() - 0.5) * 0.02;
      return (sample + crackle) * 0.4;
    },
  );

  // 3. Deep Ocean (Ambient Focus - Ethereal drone)
  generateWav(
    path: 'assets/audio/deep_ocean.wav',
    durationSeconds: 20,
    generator: (t) {
      final f1 = 110.0 + sin(t * 0.5) * 1.5;
      final f2 = 164.81 + cos(t * 0.3) * 2.0;
      final f3 = 220.0 + sin(t * 0.2) * 1.0;
      final wave = sin(2 * pi * f1 * t) * 0.4 +
          sin(2 * pi * f2 * t) * 0.3 +
          sin(2 * pi * f3 * t) * 0.2;
      final lfo = (sin(t * 1.2) + 1.0) * 0.5;
      return wave * (0.2 + lfo * 0.15);
    },
  );

  // 4. Midnight Drive (Pulsing bass & lead)
  generateWav(
    path: 'assets/audio/midnight_drive.wav',
    durationSeconds: 15,
    generator: (t) {
      final bassFreq = 65.41; // C2
      final bass = (sin(2 * pi * bassFreq * t) > 0 ? 0.3 : -0.3) * 0.4;
      final leadFreq = [523.25, 587.33, 659.25, 783.99][((t * 2).floor()) % 4];
      final lead = sin(2 * pi * leadFreq * t) * 0.2;
      return (bass + lead) * 0.5;
    },
  );

  // 5. Morning Coffee (Acoustic chill progression)
  generateWav(
    path: 'assets/audio/morning_coffee.wav',
    durationSeconds: 16,
    generator: (t) {
      final scale = [196.0, 246.94, 293.66, 329.63, 392.0]; // G Major pentatonic
      final n1 = scale[((t * 3).floor()) % scale.length];
      final n2 = scale[((t * 1.5).floor()) % scale.length] * 0.5;
      final pluck = exp(-3.0 * ((t * 3) % 1.0));
      return (sin(2 * pi * n1 * t) + sin(2 * pi * n2 * t) * 0.5) * pluck * 0.4;
    },
  );

  print('Successfully generated 5 sample audio tracks in assets/audio!');
}

void generateWav({
  required String path,
  required int durationSeconds,
  required double Function(double t) generator,
}) {
  const sampleRate = 44100;
  final numSamples = durationSeconds * sampleRate;
  const numChannels = 2; // Stereo
  const bitsPerSample = 16;
  const byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = numSamples * blockAlign;
  final chunkSize = 36 + dataSize;

  final bytes = BytesBuilder();

  // RIFF header
  bytes.add('RIFF'.codeUnits);
  bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, chunkSize, Endian.little));
  bytes.add('WAVE'.codeUnits);

  // fmt sub-chunk
  bytes.add('fmt '.codeUnits);
  bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, 16, Endian.little)); // Subchunk1Size (16 for PCM)
  bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, 1, Endian.little));  // AudioFormat (1 for PCM)
  bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, numChannels, Endian.little));
  bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, sampleRate, Endian.little));
  bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, byteRate, Endian.little));
  bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, blockAlign, Endian.little));
  bytes.add(Uint8List(2)..buffer.asByteData().setUint16(0, bitsPerSample, Endian.little));

  // data sub-chunk
  bytes.add('data'.codeUnits);
  bytes.add(Uint8List(4)..buffer.asByteData().setUint32(0, dataSize, Endian.little));

  final sampleData = ByteData(dataSize);
  int offset = 0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final val = generator(t).clamp(-1.0, 1.0);
    final intSample = (val * 32767).toInt();
    // Left channel
    sampleData.setInt16(offset, intSample, Endian.little);
    offset += 2;
    // Right channel (slightly detuned / wide)
    sampleData.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  bytes.add(sampleData.buffer.asUint8List());

  File(path).writeAsBytesSync(bytes.toBytes());
  print('Generated: $path (${File(path).lengthSync()} bytes)');
}
