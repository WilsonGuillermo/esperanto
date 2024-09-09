import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as i_o; // IO

import 'package:olimpique/services/peer_connection_service.dart';
import 'package:olimpique/configuration/parametres.dart';
import 'package:olimpique/screen/TranslationNewScreen.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  _CallScreenState createState() => _CallScreenState(); }

class _CallScreenState extends State<CallScreen> {
  i_o.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String serveurJS = Parametres.serveurJS;
  int puertoRTC = Parametres.portwebRTC;
  TranslationScreen translationScreen = const TranslationScreen();

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _connectSocket();
  }

  void _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _connectSocket() {
    _socket = i_o.io('$serveurJS:$puertoRTC', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket?.connect();

    _socket?.on('connect', (_) {
      print('Connected to socket server');
    });

    _socket?.on('offer', (data) async {
      var offer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(offer);
      var answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      _socket?.emit('answer', answer?.toMap());
    });

    _socket?.on('answer', (data) async {
      var answer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(answer);
    });

    _socket?.on('candidate', (data) async {
      var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      await _peerConnection?.addCandidate(candidate);
    });

    _socket?.on('hangup', (_) async {
      await _peerConnection?.close();
      _peerConnection = null;
    });
  }

  Future<void> _makeCall() async {
    _peerConnection ??= await newPeerConnection(_socket!, _remoteRenderer, _localRenderer, (candidate) {
        _socket?.emit('candidate', candidate.toMap());
      });

    // Créer l'offre
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Emettre l'offre à l'autre peer
    _socket?.emit('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });

    print("Offre envoyée");
  }

  Future<void> _hangUp() async {
    if (_peerConnection != null) {
      await _peerConnection?.close();
      _peerConnection = null;
    }
    _socket?.emit('hangup');
    // Arreter STT
    translationScreen.stop  .stopListening();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
          Expanded(
            child: RTCVideoView(_localRenderer),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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






