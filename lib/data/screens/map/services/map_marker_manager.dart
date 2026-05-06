import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/map/services/custom_marker_service.dart';
import 'package:uconnect/data/screens/map/services/marker_config_service.dart';
import 'package:uconnect/data/screens/map/services/map_settings_service.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:uconnect/data/screens/map/services/marker_animation_manager.dart';
import 'package:uconnect/data/screens/map/services/google_map_centering_service.dart';

/// Gerenciador leve de marcadores personalizados com animação suave
class MapMarkerManager {
  Set<Marker> _markers = {};
  Map<int, VehicleMarkerConfig> _configs = {};
  MapSettings? _settings;
  MarkerAnimationManager? _animationManager;
  
  /// Inicializar com gerenciador de animação
  void initAnimation(Completer<GoogleMapController> controller) {
    _animationManager = MarkerAnimationManager();
    _animationManager!.setController(controller);
    _animationManager!.setDuration(Duration(milliseconds: 2000));
    _animationManager!.setCurve(Curves.easeInOut);
    _animationManager!.setUseRotation(true);
  }
  
  /// Verificar se animação está habilitada
  bool get isAnimationEnabled => _animationManager != null;
  
  /// Carregar configurações
  Future<void> loadConfigs() async {
    _configs = await MarkerConfigService.loadVehicleConfigs();
    _settings = await MapSettingsService.loadSettings();
  }
  
  /// Atualizar marcadores para os veículos com animação
  Future<Set<Marker>> updateMarkers(
    List<deviceItems> vehicles,
    MapController mapController,
    GoogleMapCenteringService? centeringService,
  ) async {
    if (_settings == null) await loadConfigs();
    
    final markerSize = _settings?.markerSize ?? MarkerSize.medium;
    
    final markers = await CustomMarkerService.createMarkersForVehicles(
      vehicles,
      _configs,
      mapController.selectedVehicle,
      (vehicle) {
        StaticVarMethod.imei = vehicle.deviceData?.imei?.toString() ?? '';
        mapController.setSelectedVehicle(vehicle);
        // Centralização nativa do Google Maps ao clicar no marcador
        final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
        if (position != null && centeringService != null) {
          centeringService.centerOnMarkerTap(position);
        }
      },
      markerSize: markerSize,
    );
    
    // Atualizar marcadores no gerenciador de animação
    if (_animationManager != null) {
      for (final vehicle in vehicles) {
        final marker = markers.firstWhere(
          (m) => m.markerId.value == 'vehicle_${vehicle.id}',
          orElse: () => markers.first,
        );
        _animationManager!.updateMarker(vehicle.id, vehicle, marker);
      }
    }
    
    _markers = _animationManager?.markers ?? markers;
    return _markers;
  }
  
  /// Obter marcadores atuais
  Set<Marker> get markers => _animationManager?.markers ?? _markers;
  
  /// Envolver GoogleMap com Animarker para animação suave
  Widget wrapWithAnimation(Widget googleMap) {
    if (_animationManager != null) {
      return _animationManager!.wrapWithAnimation(googleMap);
    }
    return googleMap;
  }
  
  /// Limpar cache
  static void clearCache() => CustomMarkerService.clearCache();
}

