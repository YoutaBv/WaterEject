import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const WaterEjectApp());
}

class WaterEjectApp extends StatelessWidget {
  const WaterEjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Eject',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35C9E8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF07131F),
        useMaterial3: true,
      ),
      home: const WaterEjectScreen(),
    );
  }
}

class WaterEjectScreen extends StatefulWidget {
  const WaterEjectScreen({super.key});

  @override
  State<WaterEjectScreen> createState() => _WaterEjectScreenState();
}

class _WaterEjectScreenState extends State<WaterEjectScreen> {
  static const _frequencyHz = 165.0;
  static const _runDuration = Duration(seconds: 30);

  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _tone = _generateTone();
  Timer? _stopTimer;
  double _volume = 0.6;
  bool _isPlaying = false;

  Future<void> _startTone() async {
    if (_isPlaying) return;

    try {
      await _player.setVolume(_volume);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(_tone, mimeType: 'audio/wav'));
      if (!mounted) return;

      setState(() => _isPlaying = true);
      _stopTimer = Timer(_runDuration, () {
        _stopTone();
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _stopTone() async {
    _stopTimer?.cancel();
    _stopTimer = null;

    try {
      await _player.stop();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _changeVolume(double volume) async {
    setState(() => _volume = volume);
    if (!_isPlaying) return;

    try {
      await _player.setVolume(volume);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('No se pudo reproducir el tono: $error')),
      );
  }

  Uint8List _generateTone() {
    const sampleRate = 44100;
    const durationSeconds = 4;
    const bitsPerSample = 16;
    const channels = 1;
    const bytesPerSample = bitsPerSample ~/ 8;
    const dataLength = sampleRate * durationSeconds * bytesPerSample;
    final wav = Uint8List(44 + dataLength);
    final header = ByteData.sublistView(wav);

    void writeAscii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        wav[offset + index] = value.codeUnitAt(index);
      }
    }

    writeAscii(0, 'RIFF');
    header
      ..setUint32(4, 36 + dataLength, Endian.little)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * channels * bytesPerSample, Endian.little)
      ..setUint16(32, channels * bytesPerSample, Endian.little)
      ..setUint16(34, bitsPerSample, Endian.little)
      ..setUint32(40, dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    writeAscii(36, 'data');

    const fundamentalAmplitude = 0.22;
    const secondHarmonicAmplitude = 0.055;
    const thirdHarmonicAmplitude = 0.025;
    const fadeSamples = sampleRate ~/ 20;
    for (var sampleIndex = 0;
        sampleIndex < sampleRate * durationSeconds;
        sampleIndex++) {
      final fadeIn = math.min(1.0, sampleIndex / fadeSamples);
      final remaining = sampleRate * durationSeconds - sampleIndex - 1;
      final fadeOut = math.min(1.0, remaining / fadeSamples);
      final envelope = math.min(fadeIn, fadeOut);
      final phase = 2 * math.pi * _frequencyHz * sampleIndex / sampleRate;
      final tone = math.sin(phase) * fundamentalAmplitude +
          math.sin(2 * phase) * secondHarmonicAmplitude +
          math.sin(3 * phase) * thirdHarmonicAmplitude;
      final sample = (tone * envelope * 32767).round();
      header.setInt16(44 + sampleIndex * bytesPerSample, sample, Endian.little);
    }

    return wav;
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Eject'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 72, color: accent),
                  const SizedBox(height: 20),
                  Text(
                    _isPlaying
                        ? 'Reproduciendo tono'
                        : 'Expulsa gotas superficiales',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_frequencyHz.toInt()} Hz · máximo 30 segundos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 184,
                    height: 184,
                    child: FilledButton(
                      onPressed: _isPlaying ? _stopTone : _startTone,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: _isPlaying
                            ? const Color(0xFFEF6C63)
                            : const Color(0xFF087FA3),
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 76,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.1,
                          max: 0.8,
                          divisions: 7,
                          label: '${(_volume * 100).round()}%',
                          onChanged: _changeVolume,
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Usa un volumen moderado. El tono puede ayudar a mover gotas '
                    'superficiales, pero no garantiza eliminar agua del interior '
                    'ni reparar daños. No lo uses con auriculares.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.5),
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
