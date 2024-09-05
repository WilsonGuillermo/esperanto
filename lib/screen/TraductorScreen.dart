// Actualización del Frontend (Flutter)
// Vamos a actualizar el método `_translateText` para enviar `sourceLang` y `targetLang` en el cuerpo de la solicitud HTTP.

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'package:olimpique/configuration/parametres.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  _TranslationScreenState createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  String _translatedText = '';
  String _sourceLang = 'es'; // Default source language
  String _targetLang = 'en'; // Default target language
  String url = Parametres.direccionBackend;
  int puerto = Parametres.puerto;
  final String _selectedSourceLanguage = 'es';
  final String _selectedTargetLanguage = 'en';
  bool _isTranslating = false; // Variable pour eviter des appels repetitives

  @override
  void initState() {
  super.initState();
  _initializeSpeech();
  }

  void _initializeSpeech() async {
    print('Initializing speech recognition');
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await _requestPermissions();

    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );

    if (!available) {
      print('Speech recognition not available');
    }
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Microphone permission granted');
    } else {
      print('Microphone permission denied');
      return;
    }
  }

  void _startListening() async {
    print('Starting to listen');
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      print('Speech recognition available');
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          print('onResult triggered');
          setState(() {
            _text = val.recognizedWords;
            print('Recognized words: $_text');

            if (val.finalResult && !_isTranslating) {
              _isTranslating = true;
              _translateText(_text);
            }
          });
        },
      );
    } else {
      print('Speech recognition not available');
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _stopListening() {
    print('Stopping listening');
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _translateText(String text) async {
    print('Translating text: $text');

    try {
      final response = await http.post(
        Uri.parse('$url:$puerto/translate'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'text': text,
          'sourceLang': _sourceLang,
          'targetLang': _targetLang,
        }),
      );

      print("le text va pasar por aqui................ ");
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        print("le text reçu est: ");
        print(response.body);

        if (jsonResponse['translatedText'] !=  null) {
          setState(() {
            print("------------10");

            print("___________________________1");
            _translatedText = jsonResponse['translatedText'];
            print("___________________________2");
          });
          print("___________________________3");
          print('Translated text: $_translatedText');
          print("___________________________4");
          _speak(_translatedText);
          print("___________________________5");
        } else {
          throw Exception('Failed to translate text');
        }
      } else {
        print('Failed to translate text');
        print("___________________________6");
        throw Exception('Failed to translate text');
      }
    } catch (error) {
      // Manejar errores de connexion u otros
      print('requete enviada 3 con error');
      print('Error: $error');
    } finally {
      _isTranslating = false;
    }

  }

  Future<void> _speak(String text) async {
    print('Speaking text: $text');
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation App'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _text,
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _translatedText,
                style: const TextStyle(fontSize: 24.0),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _sourceLang = 'es';
                      _targetLang = 'en';
                    });
                  },
                  child: const Text('Translate ES => EN'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _sourceLang = 'en';
                    _targetLang = 'es';
                  });
                },
                child: const Text('Translate EN => ES'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
