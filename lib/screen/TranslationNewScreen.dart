// Actualización del Frontend (Flutter)
// Vamos a actualizar el método `translateText` para enviar `sourceLang` y `targetLang` en el cuerpo de la solicitud HTTP.

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
  TranslationScreenState createState() => TranslationScreenState();
}

class TranslationScreenState extends State<TranslationScreen> {
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  String _translatedText = '';
  String _sourceLang = 'es'; // Default source language
  String _targetLang = 'en'; // Default target language
  String url = Parametres.direccionBackend;
  int puerto = Parametres.puerto;

  @override
  void initState() {
  super.initState();
  initializeSpeech();
  }

  void initializeSpeech() async {
    print('Initializing speech recognition');
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await requestPermissions();

    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );

    if (!available) {
      print('Speech recognition not available');
    }
  }

  Future<void> requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print('Microphone permission granted');
    } else {
      print('Microphone permission denied');
      return;
    }
  }

  void startListening() async {
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
            if (val.hasConfidenceRating && val.confidence > 0) {
              translateText(_text, _sourceLang, _targetLang);
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: _sourceLang == 'es' ? 'es_ES' : 'en_US', // Adjust localeId based on source language
        onSoundLevelChange: (level) => print('Sound level: $level'),
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      print('Speech recognition not available');
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void stopListening() {
    print('Stopping listening');
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> translateText(String text, String sourceLang, String targetLang) async {
    String direction;

    print('Translating text: $text');
    print('Translating text source: $sourceLang');
    print('Translating text source: $targetLang');

    if ( sourceLang == "en" ) {
      direction = "en_to_es";
    } else {
      direction = "es_to_en";
    }

    print("la direction est");
    print(direction);

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
      //_showErrorDialog(context, 'Demarrer le Backend, por favor.');
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
              const Text('Translate from:'),
              DropdownButton<String>(
                value: _sourceLang,
                items: <String>['es', 'en'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) {
                setState(() {
                    _sourceLang = newValue!;
                  });
                },
              ),
              const Text(' to '),
              DropdownButton<String>(
                value: _targetLang,
                items: <String>['en', 'es'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _targetLang = newValue!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? stopListening : startListening,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
