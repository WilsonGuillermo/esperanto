import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:olimpique/configuration/parametres.dart';

Future<String> translatetext(String text, String direction) async {
  // Recuperacion parametros backend
  String url = Parametres.direccionBackend;
  int puerto = Parametres.puerto;

  final response = await http.post(
    Uri.parse('$url:$puerto/translate'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'text': text,
      'direction': direction,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['translated_text'];
  } else {
    throw Exception('Failed to translate text');
  }
}
