import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';

/// Gerenciador de animação suave de marcadores
class MarkerAnimationManager {
  Completer<GoogleMapController>? _controller;
  final Map<MarkerId, Marker> _markers = {};
  final Map<int, LatLng> _previousPositions = {};
  
  /// Configurações de animação
  Duration _duration = Duration(milliseconds: 2000);
  Curve _curve = Curves.easeInOut;
  bool _useRotation = true;
  double? _rippleRadius;
  
  /// Definir controller do mapa
  void setController(Completer<GoogleMapController> controller) => _controller = controller;
  
  /// Obter controller do mapa
  Completer<GoogleMapController>? get controller => _controller;
  
  /// Definir duração da animação
  void setDuration(Duration duration) => _duration = duration;
  
  /// Definir curva de animação
  void setCurve(Curve curve) => _curve = curve;
  
  /// Habilitar/desabilitar rotação
  void setUseRotation(bool use) => _useRotation = use;
  
  /// Definir raio de ripple
  void setRippleRadius(double? radius) => _rippleRadius = radius;
  
  /// Obter marcadores
  Set<Marker> get markers => _markers.values.toSet();
  
  /// Adicionar/atualizar marcador com animação
  void updateMarker(
    int vehicleId,
    deviceItems vehicle,
    Marker marker,
  ) {
    final markerId = MarkerId('vehicle_$vehicleId');
    final newPosition = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
    
    if (newPosition == null) return;
    
    // Se é a primeira vez ou posição mudou significativamente
    final previousPosition = _previousPositions[vehicleId];
    if (previousPosition == null || 
        _calculateDistance(previousPosition, newPosition) > 0.0001) {
      
      // Atualizar marcador
      _markers[markerId] = marker;
      _previousPositions[vehicleId] = newPosition;
    }
  }
  
  /// Calcular distância entre duas posições (em graus)
  double _calculateDistance(LatLng pos1, LatLng pos2) {
    final latDiff = (pos1.latitude - pos2.latitude).abs();
    final lngDiff = (pos1.longitude - pos2.longitude).abs();
    return latDiff + lngDiff;
  }
  
  /// Limpar marcadores
  void clear() {
    _markers.clear();
    _previousPositions.clear();
  }
  
  /// Remover marcador específico
  void removeMarker(int vehicleId) {
    final markerId = MarkerId('vehicle_$vehicleId');
    _markers.remove(markerId);
    _previousPositions.remove(vehicleId);
  }
  
  /// Criar widget Animarker para envolver o GoogleMap
  Widget wrapWithAnimation(Widget googleMap) {
    if (_controller == null) return googleMap;
    
    return Animarker(
      duration: _duration,
      curve: _curve,
      useRotation: _useRotation,
      rippleRadius: _rippleRadius ?? 0.0,
      mapId: _controller!.future.then<int>((value) => value.mapId),
      markers: markers,
      child: googleMap,
    );
  }
  
  /// Verificar se há posição anterior para um veículo
  bool hasPreviousPosition(int vehicleId) => _previousPositions.containsKey(vehicleId);
  
  /// Obter posição anterior
  LatLng? getPreviousPosition(int vehicleId) => _previousPositions[vehicleId];
}

