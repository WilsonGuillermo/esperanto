import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:olimpique/configuration/parametres.dart';

Future<RTCPeerConnection> newPeerConnection(
  IO.Socket socket,
  RTCVideoRenderer remoteRenderer,
  RTCVideoRenderer localRenderer,
  void Function(RTCIceCandidate candidate) onIceCandidate ) async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:${Parametres.direccionStun}:${Parametres.puertoStun}'},
        {
          'urls': 'turn:${Parametres.direccionConturn}:${Parametres.puertoConturn}',
          'username': Parametres.usernameConturn,
          'credential': Parametres.mdpConturn,
        },
      ],
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    final RTCPeerConnection peerConnection = await createPeerConnection(configuration, offerSdpConstraints);

    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      onIceCandidate(candidate);
    };

    peerConnection.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
    };

    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    localRenderer.srcObject = localStream;
    peerConnection.addStream(localStream);

    return peerConnection;
}
