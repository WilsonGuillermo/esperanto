import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:olimpique/services/peer_connection_service.dart';  // Importa el nuevo archivo
import 'package:olimpique/configuration/parametres.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  _CallScreenState createState() => _CallScreenState(); }

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  IO.Socket? _socket;
  bool _isCalling = false;
  String backend = Parametres.direccionBackend;
  int puertoRTC = Parametres.portwebRTC;


  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _connectToSocket();
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
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _connectToSocket() {
    _socket = IO.io('$backend:$puertoRTC', <String, dynamic>{
      'transports': ['websocket'],
    });

    _socket?.on('connect', (_) {
      print('Connected to signaling server');
    });

    _socket?.on('offer', (data) async {
      await _createPeerConnection();
      await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      var answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      _socket?.emit('answer', {
        'sdp': answer?.sdp,
        'type': answer?.type,
      });
    });

    _socket?.on('answer', (data) async {
      await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    });

    _socket?.on('candidate', (data) async {
      var candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      await _peerConnection?.addCandidate(candidate);
    });
  }

  Future<void> _createPeerConnection() async {
    _peerConnection = await newPeerConnection(
      _socket!,
      _remoteRenderer,
      _localRenderer,
          (RTCIceCandidate candidate) {
        _socket?.emit('candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
            },
    );
  }

  void _makeCall() async {
    await _createPeerConnection();
    var offer = await _peerConnection?.createOffer();
    await _peerConnection?.setLocalDescription(offer!);
    _socket?.emit('offer', {
      'sdp': offer?.sdp,
      'type': offer?.type,
    });
    setState(() {
      _isCalling = true;
    });
  }

  void _hangUp() {
    _peerConnection?.close();
    _peerConnection = null;
    _socket?.emit('hangup');
    setState(() {
      _isCalling = false;
    });
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
            child: RTCVideoView(_localRenderer, mirror: true),
          ),
          Expanded(
            child: RTCVideoView(_remoteRenderer),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: _makeCall,
                color: Colors.green,
                iconSize: 50,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.call_end),
                onPressed: _hangUp,
                color: Colors.red,
                iconSize: 50,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
