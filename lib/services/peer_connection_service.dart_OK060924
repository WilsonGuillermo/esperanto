import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as i_o; // IO
import 'package:olimpique/configuration/parametres.dart';

Future<RTCPeerConnection> newPeerConnection(
  i_o.Socket socket,
  RTCVideoRenderer remoteRenderer,
  RTCVideoRenderer localRenderer,
  Function(RTCIceCandidate) onIceCandidate) async {
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

    print("socket en peer------------------------------- $socket");
    print("_remoteRenderer en peer------------------------------- $remoteRenderer");
    print("_localRenderer en peer------------------------------- $localRenderer");

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    RTCPeerConnection peerConnection = await createPeerConnection(configuration, offerSdpConstraints);

    peerConnection.onIceCandidate = (candidate) {
      onIceCandidate(candidate);
    };

    peerConnection.onAddStream = (stream) {
      remoteRenderer.srcObject = stream;
    };

    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    });

    localRenderer.srcObject = localStream;
    peerConnection.addStream(localStream);

    return peerConnection;
}
