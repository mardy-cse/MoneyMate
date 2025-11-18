import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice Service for Speech-to-Text and Text-to-Speech
class VoiceService {
  // Singleton pattern
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';

  /// Initialize voice services
  Future<void> initialize() async {
    if (_isInitialized) return;

    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    // Configure TTS
    await _tts.setLanguage('en-US'); // English for numbers
    await _tts.setSpeechRate(0.5); // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );

      _isInitialized = available;
      print('Voice Service initialized: $_isInitialized');
    } else {
      print('Microphone permission denied');
      _isInitialized = false;
    }
  }

  /// Check if service is ready
  bool get isInitialized => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get last recognized text
  String get lastRecognizedText => _lastRecognizedText;

  /// Start listening for voice input
  Future<String> startListening({
    Duration timeout = const Duration(seconds: 30),
    Function(String)? onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Voice service not initialized');
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _lastRecognizedText = '';

    try {
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;

          if (result.hasConfidenceRating && result.confidence > 0) {
            print('Confidence: ${result.confidence}');
          }

          if (onPartialResult != null) {
            onPartialResult(_lastRecognizedText);
          }

          if (result.finalResult) {
            onResult?.call(_lastRecognizedText);
            _isListening = false;
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US', // English for better number recognition
        cancelOnError: true,
      );

      // Wait for final result or timeout
      await Future.delayed(timeout);

      if (_isListening) {
        await stopListening();
      }

      return _lastRecognizedText;
    } catch (e) {
      print('Speech recognition error: $e');
      _isListening = false;
      return '';
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
  }

  /// Speak text (Text-to-Speech)
  Future<void> speak(
    String text, {
    String? language,
    double? rate,
    double? volume,
    double? pitch,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Configure TTS settings
      if (language != null) {
        await _tts.setLanguage(language);
      }
      if (rate != null) {
        await _tts.setSpeechRate(rate);
      }
      if (volume != null) {
        await _tts.setVolume(volume);
      }
      if (pitch != null) {
        await _tts.setPitch(pitch);
      }

      // Speak the text
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Pause speaking
  Future<void> pauseSpeaking() async {
    await _tts.pause();
  }

  /// Check if currently speaking
  Future<bool> isSpeaking() async {
    // Note: isSpeaking is not available in all TTS engines
    return false;
  }

  /// Get available languages for TTS
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      print('Error getting languages: $e');
      return ['en-US'];
    }
  }

  /// Get available voices
  Future<List<Map>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      return List<Map>.from(voices);
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  /// Set voice by name
  Future<void> setVoice(Map voice) async {
    try {
      await _tts.setVoice({'name': voice['name'], 'locale': voice['locale']});
    } catch (e) {
      print('Error setting voice: $e');
    }
  }

  /// Speak financial data in natural way
  Future<void> speakFinancialData({
    required String context,
    required double amount,
    String? category,
    int? count,
  }) async {
    String message = '';

    switch (context.toLowerCase()) {
      case 'today':
        message = 'Today you spent ${_formatAmount(amount)}';
        if (count != null) {
          message += ' across $count transactions';
        }
        break;

      case 'yesterday':
        message = 'Yesterday you spent ${_formatAmount(amount)}';
        if (count != null) {
          message += ' in $count transactions';
        }
        break;

      case 'week':
        message = 'This week your total spending is ${_formatAmount(amount)}';
        if (count != null) {
          message += ' with $count transactions';
        }
        break;

      case 'month':
        message = 'This month you have spent ${_formatAmount(amount)}';
        if (count != null) {
          message += ' in $count transactions';
        }
        break;

      case 'category':
        if (category != null) {
          message = 'In $category category, you spent ${_formatAmount(amount)}';
          if (count != null) {
            message += ' across $count transactions';
          }
        }
        break;

      default:
        message = 'The amount is ${_formatAmount(amount)}';
    }

    await speak(message, rate: 0.45); // Slower for numbers
  }

  /// Format amount for speech
  String _formatAmount(double amount) {
    final taka = amount.toInt();
    final paisa = ((amount - taka) * 100).toInt();

    if (paisa > 0) {
      return '$taka taka and $paisa paisa';
    } else {
      return '$taka taka';
    }
  }

  /// Speak greeting with time-based message
  Future<void> speakGreeting() async {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good morning! How can I help you today?';
    } else if (hour < 17) {
      greeting = 'Good afternoon! What would you like to know?';
    } else {
      greeting = 'Good evening! Ready to check your expenses?';
    }

    await speak(greeting);
  }

  /// Parse voice command for financial queries
  Map<String, dynamic> parseVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Detect query type
    if (lowerCommand.contains('today') || lowerCommand.contains('todays')) {
      return {'type': 'expense', 'period': 'today'};
    } else if (lowerCommand.contains('yesterday')) {
      return {'type': 'expense', 'period': 'yesterday'};
    } else if (lowerCommand.contains('week') ||
        lowerCommand.contains('weekly')) {
      return {'type': 'expense', 'period': 'week'};
    } else if (lowerCommand.contains('month') ||
        lowerCommand.contains('monthly')) {
      return {'type': 'expense', 'period': 'month'};
    } else if (lowerCommand.contains('food') ||
        lowerCommand.contains('eating')) {
      return {'type': 'category', 'category': 'food'};
    } else if (lowerCommand.contains('transport') ||
        lowerCommand.contains('travel')) {
      return {'type': 'category', 'category': 'transport'};
    } else if (lowerCommand.contains('bill')) {
      return {'type': 'category', 'category': 'bills'};
    } else if (lowerCommand.contains('shopping') ||
        lowerCommand.contains('shop')) {
      return {'type': 'category', 'category': 'shopping'};
    } else if (lowerCommand.contains('budget') ||
        lowerCommand.contains('advice')) {
      return {'type': 'advice'};
    } else if (lowerCommand.contains('tip') || lowerCommand.contains('save')) {
      return {'type': 'tips'};
    } else if (lowerCommand.contains('help')) {
      return {'type': 'help'};
    }

    return {'type': 'unknown', 'text': command};
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _tts.stop();
    _isInitialized = false;
    _isListening = false;
  }
}
