import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  static final SpeechService instance = SpeechService._internal();
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;

  SpeechService._internal();

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      _isInitialized = true;
      return _isAvailable;
    } catch (e) {
      debugPrint('Speech initialization error (fallback active): $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String words) onResult,
    required Function(bool listening) onStatusChange,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isAvailable) {
      onStatusChange(false);
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 4),
        ),
      );
      onStatusChange(true);
    } catch (e) {
      debugPrint('Error starting speech listening: $e');
      onStatusChange(false);
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }
}
