import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';

/// Serviço para centralização usando funcionalidades nativas do Google Maps
class GoogleMapCenteringService {
  GoogleMapController? _mapController;
  
  /// Definir o controller do mapa
  void setMapController(GoogleMapController? controller) {
    _mapController = controller;
  }
  
  /// Centralizar automaticamente quando o mapa é criado (funcionalidade nativa)
  Future<void> centerOnVehiclesOnMapCreated(List<deviceItems> vehicles) async {
    if (_mapController == null || vehicles.isEmpty) return;
    
    final validVehicles = vehicles.where((v) => 
      CoordinateUtils.isValidCoordinate(v.lat, v.lng)
    ).toList();
    
    if (validVehicles.isEmpty) return;
    
    if (validVehicles.length == 1) {
      // Centralizar em um único veículo
      final vehicle = validVehicles.first;
      final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
      if (position != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15.0),
        );
      }
    } else {
      // Centralizar em múltiplos veículos usando bounds
      await _centerOnMultipleVehicles(validVehicles);
    }
  }
  
  /// Centralizar ao clicar no marcador (funcionalidade nativa)
  Future<void> centerOnMarkerTap(LatLng position) async {
    if (_mapController == null) return;
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16.0),
    );
  }
  
  /// Centralizar em múltiplos veículos usando bounds nativo
  Future<void> _centerOnMultipleVehicles(List<deviceItems> vehicles) async {
    if (_mapController == null || vehicles.isEmpty) return;
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (var vehicle in vehicles) {
      final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
      if (position != null) {
        if (position.latitude < minLat) minLat = position.latitude;
        if (position.latitude > maxLat) maxLat = position.latitude;
        if (position.longitude < minLng) minLng = position.longitude;
        if (position.longitude > maxLng) maxLng = position.longitude;
      }
    }
    
    if (minLat == double.infinity) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    // Padding baseado no número de veículos
    final padding = vehicles.length <= 3 ? 100.0 : 150.0;
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }
  
  /// Centralizar em um veículo específico
  Future<void> centerOnVehicle(deviceItems vehicle) async {
    if (_mapController == null) return;
    
    final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
    if (position != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16.0),
      );
    }
  }
  
  /// Centralizar em uma posição específica
  Future<void> centerOnPosition(LatLng position, {double zoom = 15.0}) async {
    if (_mapController == null) return;
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom),
    );
  }
}



































