import 'package:flutter/material.dart';
//import 'package:olimpique/screen/TranslationScreen.dart';
//import 'package:olimpique/screen/TraductorScreen1.dart';
import 'package:olimpique/screen/CallScreen.dart';
//import 'package:olimpique/configuration/parametres.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  //final String serveurJS = Parametres.serveurUrlJS;
  //final String sourceLang = "es-ES";
  //final String targetLang = "fr-FR";

  const MyApp({super.key});
  //final String direction ="es_to_en";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: CallScreen(serverUrl: serveurJS, sourceLang: sourceLang, targetLang: targetLang),
      home: CallScreen(),
    );
  }
}



