import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:olimpique/configuration/parametres.dart';

class TranslationScreen {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  late Function(String) _onTranslated;
  String url = Parametres.direccionBackend;
  int puerto = Parametres.puerto;

  void startListeningAndTranslating(Function(String) onTranslated) async {
    _onTranslated = onTranslated;
    bool available = await _speechToText.initialize();
    if (available) {
      _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String translatedText = await translateText(result.recognizedWords, 'es'); // Traduce al español como ejemplo
            _onTranslated(translatedText);
            await textToSpeech(translatedText, 'es-ES');
          }
        },
      );
      _isListening = true;
    }
  }

  void stopListening() {
    if (_isListening) {
      _speechToText.stop();
      _isListening = false;
    }
  }

  Future<String> translateText(String text, String targetLanguage) async {
    final response = await http.post(
      Uri.parse('$url:$puerto/translate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'text': text,
        'targetLanguage': targetLanguage,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['translatedText'];
    } else {
      throw Exception('Failed to translate text');
    }
  }

  Future<void> textToSpeech(String text, String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
  }

  void dispose() {
    stopListening();
  }
}

