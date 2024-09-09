import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:olimpique/services/peer_connection_service.dart';
import 'package:olimpique/configuration/parametres.dart';

class CallScreen extends StatefulWidget {
  @override
  _CallScreenState createState() => _CallScreenState(); }

class _CallScreenState extends State<CallScreen> {
  IO.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String _sourceLang = 'es';
  String _targetLang = 'en';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _spokenText = '';
  final String _serverUrlJS = Parametres.serverUrlJS;

  bool _isCallActive = false; //Deshabilitar el botón "Llamar" mientras la llamada está en curso
  String accumulatedText = '';


  @override
  void initState() {
    super.initState();
    initRenderers();
    _connectSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _socket?.disconnect();
    super.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _connectSocket() {
    _socket = IO.io(_serverUrlJS, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.on('connect', (_) {
      print("-------------------------------");
      print('Connected to socket server');
      print("-------------------------------");
    });

    _socket!.on('offer', (data) async {
      try {
        print("-------------------------------");
        print('Received offer: $data');
        print("-------------------------------");

        // Creation de l'offer avec les donnés reçues
        RTCSessionDescription offer = RTCSessionDescription(
            data['sdp'], data['type']);

        // Etablir la description remote ( pour savoir que propose l'autre peer )
        await _peerConnection?.setRemoteDescription(offer);

        // Si la peerConnection a été créée, creation de la réponse (answer )
        if (_peerConnection != null) {
          // La réponse permet d'accepter la reception de la video et de l'audio
          RTCSessionDescription answer = await _peerConnection!.createAnswer(
              {
                'mandatory': {
                  'OfferToReceiveAudio': true, // on est sur de recevoir l'audio
                  'OfferToReceiveVideo': true, // on est sur de recevoir la video
                },
                'optional': [],
              }
          );

          // Etablir la description Local
          await _peerConnection?.setLocalDescription(answer);

          // Envoyer la reponse de retour au serveur
          _socket?.emit('answer', {
            'sdp': answer.sdp,
            'type': answer.type,
          });
          print("-------------------------------");
          print('Sent answer: $answer');
          print("-------------------------------");
        } else {
          print("-------------------------------");
          print("Error: PeerConnection no esta inicializada");
          print("-------------------------------");
        }
      } catch (e) {
        print("Error pendant la création de l'offerta (offer): $e");
      }
    });

    _socket!.on('answer', (data) async {
      try {
        // Seuelement si la peerConnection existe
        if (_peerConnection != null) {
          print("-------------------------------");
          print('Received answer: $data');
          print("-------------------------------");

          // On créé la réponse à partir des données reçues
          RTCSessionDescription answer = RTCSessionDescription(
              data['sdp'], data['type']);

          // On établie la description remote
          await _peerConnection?.setRemoteDescription(answer);
        } else {
          print("Error: La peerConnection est null à la reception de l'answer");
        }
      } catch (e) {
        print("Error pendant la manipulation de la réponse (answer): $e");
      }
    });

    _socket!.on('candidate', (data) async {
      // Vérification si la peerConnection existe
      try {
        if (_peerConnection != null) {
          print("-------------------------------");
          print('Received candidate: $data');
          print("-------------------------------");

          // Avec les données recçues, nous creons le candidate
          RTCIceCandidate candidate = RTCIceCandidate(
              data['candidate'], data['sdpMid'], data['sdpMLineIndex']);

          // Ajoutants le candidate à la peerConnection
          await _peerConnection?.addCandidate(candidate);
          print("Candidate ICE ajouté");
        } else {
          print("PeerConnection n'est pas initializée pour receptionner des candidats.");
        }
      } catch (e) {
        print("Error pendant l'ajout du candidate: $e");
      }
    });

    _socket!.on('translated_text', (data) {
      print("-------------------------------");
      print('Received translated text: $data');
      print("-------------------------------");
      _speakTranslatedText(data);
      //_onTranslatedTextReceived(data); // on envoi l'audio à la fin
    });

    _socket!.on('hangup', (_) {
      print('Received hangup');
      _hangUp();
    });

    _socket!.connect();
  }

  Future<void> _makeCall() async {
    // On va s'assurer que PeerConnection n'est pas déjà initialisé
    print("socket------------------------------- $_socket");
    print("_remoteRenderer------------------------------- $_remoteRenderer");
    print("_localRenderer------------------------------- $_localRenderer");
    print("candidate-------------------------------");
    //if (_peerConnection != null) {
    //  print("-------------------------------");
    //  print("PeerConnection est déja initialisé");
    //  print("-------------------------------");
    //  return;
    //}

    _peerConnection ??= await newPeerConnection(
        _socket!,
        _remoteRenderer,
        _localRenderer,
            (candidate)
            {
              _socket?.emit('candidate', candidate.toMap());
            }
    );

    if (_peerConnection == null) {
      print("-------------------------------");
      print("Error : PeerConnection n'a pa été initialisé");
      print("-------------------------------");
      return;
    }

    if (_isCallActive) return;

    setState(() {
      _isCallActive = true;
    });

    ////////////////////////////////////////
    // Flux Local
    // On s'asure que le flux local est bien ajouté
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    _peerConnection?.addStream(_localStream!); // On ajoute le Stream local à la peerConnection
    _localRenderer.srcObject = _localStream;
    /////////////////////////////////////////

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection?.setLocalDescription(offer);
    _socket?.emit('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
      'sourceLang': _sourceLang,
      'targetLang': _targetLang,
    });
    print("-------------------------------");
    print('Sent offer: $offer');
    print("-------------------------------");

    // Iniciar STT
    _startListening();
  }

  Future<void> _hangUp() async {
    if (!_isCallActive) return;

    if (_peerConnection != null) {
      await _peerConnection?.close();
      _peerConnection = null;
    }

    if (_localStream != null) {
      _localStream?.dispose();
      _localStream = null;
    }

    setState(() {
      _remoteRenderer.srcObject = null;
      _isCallActive = false;
    });

    _socket?.emit('hangup', {});
    print('Call ended');

    // Detener STT
    _stopListening();
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _spokenText = val.recognizedWords;
          // Enviar texto reconocido al backend para traducir
          _socket?.emit('translate_text', {
            'text': _spokenText,
            'sourceLang': _sourceLang,
            'targetLang': _targetLang
            //'direction': direction
          });
        }),
        localeId: _sourceLang, // Especificamos el idioma de reconocimiento
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _onTranslatedTextReceived(Map<String, dynamic> data) {
    // Obtener el texto traducido y el indicador de finalización
    String translatedText = data['translatedText'];
    bool isFinal = data['isFinal'];

    // Acumular el texto
    accumulatedText += translatedText;

    // Si es la última parte de la frase, convertir a audio y reproducir
    if (isFinal) {
      _playAudio(accumulatedText);
      accumulatedText = '';  // Resetear el buffer
    }
  }

  void _playAudio(String text) async {
    // Lógica para convertir texto a voz y reproducir el audio
    await _flutterTts.speak(text);
  }

  void _speakTranslatedText(String text) async {
    print('Received text after audio: $text');
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Center Screen'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _sourceLang,
                items: <String>['es', 'en', 'fr'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _sourceLang = newValue!;
                  });
                },
              ),
              DropdownButton<String>(
                value: _targetLang,
                items: <String>['es', 'en', 'fr'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _targetLang = newValue!;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: _makeCall,
              ),
              IconButton(
                icon: const Icon(Icons.call_end),
                onPressed: _hangUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}