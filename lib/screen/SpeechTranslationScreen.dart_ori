import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:olimpique/configuration/parametres.dart';

class SpeechTranslationScreen extends StatefulWidget {
  const SpeechTranslationScreen({super.key});

  @override
  _SpeechTranslationScreenState createState() => _SpeechTranslationScreenState(); }

class _SpeechTranslationScreenState extends State<SpeechTranslationScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _spokenText = 'Presiona el botón y comienza a hablar';
  String _translatedText = '';

  // Recuperacion parametros backend
  String url = Parametres.direccionBackend;
  int puerto = Parametres.puerto;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) => setState(() {
        _spokenText = val.recognizedWords;
        _translateText(_spokenText);
      }));
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _translateText(String text) async {
    final response = await http.post(
      Uri.parse('$url:$puerto/translate'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      var translation = jsonDecode(utf8.decode(response.bodyBytes))['translation'];
      setState(() => _translatedText = translation);
      _speakText(_translatedText);
    } else {
      throw Exception('Error al traducir el texto');
    }
  }

  void _speakText(String text) async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traducción de Voz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Texto Reconocido: $_spokenText',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Texto Traducido: $_translatedText',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
