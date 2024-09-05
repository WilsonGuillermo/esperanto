// Modificar el archivo `CallScreen` para usar el nuevo servicio

// En tu archivo `CallScreen`, importa el nuevo archivo y usa la función importada.


import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
//import 'package:permission_handler/permission_handler.dart';
import 'package:olimpique/services/peer_connection_service.dart';  // Importa el nuevo archivo
import 'package:olimpique/configuration/parametres.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RTCPeerConnection? _peerConnection;
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  IO.Socket? _socket;
  String backend = Parametres.direccionBackend;
  int puertoRTC = Parametres.portwebRTC;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _initializeSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _socket?.dispose();
    super.dispose();
  }

  void _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _initializeSocket() {
    _socket = IO.io('http://$backend:$puertoRTC', <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket?.on('connect', (_) {
      print('Connected to signaling server');
    });

    _socket?.on('offer', (data) async {
      await _createPeerConnection();
      _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      var answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      _socket?.emit('answer', {
        'sdp': answer?.sdp, // il peut y arriver que soit null
        'type': answer?.type, // il peut y arriver que soit null
      });
    });

    _socket?.on('answer', (data) {
      _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    });

    _socket?.on('candidate', (data) {
      _peerConnection?.addCandidate(RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await newPeerConnection(
      _socket!,
      _remoteRenderer,
      _localRenderer,
          (candidate) {
        _socket?.emit('candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Screen'),
      ),
      body: Stack(
        children: [
          RTCVideoView(_remoteRenderer),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 100,
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
        ],
      ),
    );
  }
}
