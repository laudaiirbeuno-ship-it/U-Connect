import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/screens/map/services/map_settings_service.dart';

class MarkerAnimationService {
  /// Aplicar animação ao atualizar posição do marcador
  static Future<void> animateMarkerUpdate(
    GoogleMapController? mapController,
    MarkerId markerId,
    LatLng newPosition,
    AnimationType animationType,
  ) async {
    if (mapController == null || animationType == AnimationType.none) {
      return;
    }

    switch (animationType) {
      case AnimationType.slide:
        await _slideAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.bounce:
        await _bounceAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.fade:
        await _fadeAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.rotate:
        await _rotateAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.pulse:
        await _pulseAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.elastic:
        await _elasticAnimation(mapController, markerId, newPosition);
        break;
      case AnimationType.none:
        break;
    }
  }

  /// Animação de deslizar suavemente
  static Future<void> _slideAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // A animação de slide é feita automaticamente pelo Google Maps
    // quando atualizamos a posição do marcador
    await mapController.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  /// Animação de rebote
  static Future<void> _bounceAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // Mover ligeiramente além da posição e voltar
    final overshoot = LatLng(
      newPosition.latitude + 0.0001,
      newPosition.longitude + 0.0001,
    );
    
    await mapController.animateCamera(
      CameraUpdate.newLatLng(overshoot),
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    await mapController.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  /// Animação de fade (fade in/out)
  static Future<void> _fadeAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // Para fade, precisaríamos controlar a opacidade do marcador
    // Por enquanto, apenas movemos suavemente
    await mapController.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  /// Animação de rotação
  static Future<void> _rotateAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // Rotação é aplicada automaticamente pelo curso do veículo
    await mapController.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  /// Animação de pulsação
  static Future<void> _pulseAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // Zoom in e out para efeito de pulso
    await mapController.animateCamera(
      CameraUpdate.zoomIn(),
    );
    
    await Future.delayed(Duration(milliseconds: 150));
    
    await mapController.animateCamera(
      CameraUpdate.newLatLngZoom(newPosition, 14.0),
    );
  }

  /// Animação elástica
  static Future<void> _elasticAnimation(
    GoogleMapController mapController,
    MarkerId markerId,
    LatLng newPosition,
  ) async {
    // Movimento elástico com overshoot e retorno
    final overshoot1 = LatLng(
      newPosition.latitude + 0.0002,
      newPosition.longitude + 0.0002,
    );
    
    await mapController.animateCamera(
      CameraUpdate.newLatLng(overshoot1),
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    final overshoot2 = LatLng(
      newPosition.latitude - 0.0001,
      newPosition.longitude - 0.0001,
    );
    
    await mapController.animateCamera(
      CameraUpdate.newLatLng(overshoot2),
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    await mapController.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }
}
