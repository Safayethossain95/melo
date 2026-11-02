import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioOutputDevice {
  final int id;
  final String name;
  final String type; // 'bluetooth', 'speaker', 'wired', 'other'

  const AudioOutputDevice({
    required this.id,
    required this.name,
    required this.type,
  });

  bool get isBluetooth => type == 'bluetooth';
  bool get isSpeaker => type == 'speaker';
  bool get isWired => type == 'wired';

  IconData get icon {
    switch (type) {
      case 'bluetooth':
        return Icons.headphones_rounded;
      case 'speaker':
        return Icons.speaker_phone_rounded;
      case 'wired':
        return Icons.headset_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  factory AudioOutputDevice.fromMap(Map<dynamic, dynamic> map) {
    return AudioOutputDevice(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] as String?)?.trim() ?? 'Audio Output',
      type: (map['type'] as String?)?.trim() ?? 'other',
    );
  }

  static const AudioOutputDevice defaultSpeaker = AudioOutputDevice(
    id: 0,
    name: 'Phone Speaker',
    type: 'speaker',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioOutputDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}

class AudioOutputService extends ChangeNotifier {
  static final AudioOutputService _instance = AudioOutputService._internal();
  factory AudioOutputService() => _instance;
  AudioOutputService._internal();

  static const MethodChannel _channel = MethodChannel('com.melo.app/audio_output');

  final ValueNotifier<AudioOutputDevice> currentOutput =
      ValueNotifier<AudioOutputDevice>(AudioOutputDevice.defaultSpeaker);

  final ValueNotifier<List<AudioOutputDevice>> availableOutputs =
      ValueNotifier<List<AudioOutputDevice>>([AudioOutputDevice.defaultSpeaker]);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      currentOutput.value = const AudioOutputDevice(
        id: 0,
        name: 'Browser Audio Output',
        type: 'speaker',
      );
      availableOutputs.value = [currentOutput.value];
      return;
    }

    _channel.setMethodCallHandler(_handleMethodCall);

    await refreshOutputs();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onOutputsChanged') {
      try {
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          final curMap = data['current'] as Map<dynamic, dynamic>?;
          if (curMap != null) {
            currentOutput.value = AudioOutputDevice.fromMap(curMap);
          }

          final list = data['available'] as List<dynamic>?;
          if (list != null) {
            availableOutputs.value = list
                .whereType<Map<dynamic, dynamic>>()
                .map((m) => AudioOutputDevice.fromMap(m))
                .toList();
          }
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('Error handling onOutputsChanged: $e');
      }
    }
  }

  Future<void> refreshOutputs() async {
    if (kIsWeb) return;
    try {
      final cur = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentOutput');
      if (cur != null) {
        currentOutput.value = AudioOutputDevice.fromMap(cur);
      }

      final list = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getAudioOutputs');
      if (list != null) {
        availableOutputs.value = list.map((m) => AudioOutputDevice.fromMap(m)).toList();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error refreshing audio outputs: $e');
    }
  }

  Future<void> switchToSpeaker() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('switchToSpeaker');
      await refreshOutputs();
    } catch (e) {
      if (kDebugMode) print('Error switching to speaker: $e');
    }
  }

  Future<void> switchToDevice(AudioOutputDevice device) async {
    if (kIsWeb) return;
    try {
      if (device.isSpeaker) {
        await switchToSpeaker();
      } else {
        await _channel.invokeMethod('switchToDevice', {'id': device.id});
      }
      await refreshOutputs();
    } catch (e) {
      if (kDebugMode) print('Error switching to device: $e');
    }
  }

  Future<void> openOutputSettings() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('openOutputSettings');
    } catch (e) {
      if (kDebugMode) print('Error opening output settings: $e');
    }
  }
}
