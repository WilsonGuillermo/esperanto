#### 2. Implementación de la Traducción en Tiempo Real ```dart import 'package:http/http.dart' as http; import 'dart:convert';

Future<void> _translateAndSpeak(String text, String sourceLang, String targetLang) async {
  final response = await http.post(
    Uri.parse('http://your_backend_url/translate'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'text': text,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
    }),
  );

  if (response.statusCode == 200) {
    final translatedText = jsonDecode(response.body)['translatedText'];
    await _flutterTts.speak(translatedText);
  } else {
    throw Exception('Failed to translate text');
  }
}
