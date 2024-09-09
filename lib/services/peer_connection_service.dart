import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as i_o; // IO
import 'package:olimpique/configuration/parametres.dart';

Future<RTCPeerConnection> newPeerConnection(
  i_o.Socket socket,
  RTCVideoRenderer remoteRenderer,
  RTCVideoRenderer localRenderer,
  Function(RTCIceCandidate) onIceCandidate) async {

    // Configuration des serveurs ICE
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

    // Creation de la RTCPeerConnetion
    RTCPeerConnection peerConnection = await createPeerConnection(configuration, offerSdpConstraints);

    // Envoyer le ICE à l'autre peer
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      if ( candidate != null ) {
        //onIceCandidate(candidate); modification 070924
        // Emettre le candidate ICE utilisant la socket
        socket?.emit('candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // Traiter le stream de la video ou audio entrant
    peerConnection?.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
    };

    peerConnection.onTrack = ( RTCTrackEvent event ) {
      if ( event.track.kind == 'video' ) {
        remoteRenderer.srcObject = event.streams[0]; // On montre la video remote
      }
    };

    // Obtenir le stream de la camera-microphone local sans constraint
    //MediaStream localStream = await navigator.mediaDevices.getUserMedia({
    //  'audio': true,
    //  'video': true,
    //});

    // Obtenir le stream de la camera-microphone local, camera Frontal ou derriere
    MediaStream localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    });

    // Ajouter le stream local à la connexion
    localRenderer.srcObject = localStream; // on montre la video local
    peerConnection?.addStream(localStream);

    return peerConnection;
}
