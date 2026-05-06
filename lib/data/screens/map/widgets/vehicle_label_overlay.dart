import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/map/widgets/vehicle_marker_label.dart';

class VehicleLabelOverlay extends StatefulWidget {
  final List<deviceItems> vehicles;
  final Map<int, LatLng> vehiclePositions;
  final CameraPosition? cameraPosition;
  final Size mapSize;
  final Function(deviceItems) onVehicleTap;
  final deviceItems? selectedVehicle;
  final VoidCallback? onMapTap;

  const VehicleLabelOverlay({
    Key? key,
    required this.vehicles,
    required this.vehiclePositions,
    this.cameraPosition,
    required this.mapSize,
    required this.onVehicleTap,
    this.selectedVehicle,
    this.onMapTap,
  }) : super(key: key);

  @override
  _VehicleLabelOverlayState createState() => _VehicleLabelOverlayState();
}

class _VehicleLabelOverlayState extends State<VehicleLabelOverlay> {
  @override
  Widget build(BuildContext context) {
    if (widget.cameraPosition == null || widget.mapSize.width == 0 || widget.mapSize.height == 0) {
      return SizedBox.shrink();
    }

    final labels = <Widget>[];

    for (final vehicle in widget.vehicles) {
      final position = widget.vehiclePositions[vehicle.id];
      if (position == null) continue;

      final screenPos = _latLngToScreen(position, widget.cameraPosition!, widget.mapSize);
      if (screenPos == null) continue;

      final isSelected = widget.selectedVehicle?.id == vehicle.id;

      // Label normal (sem expansão)
      // Centralizar o label: largura máxima do label é 200px, então offset de -100px
      labels.add(
        Positioned(
          left: screenPos.dx - 100, // Centralizar o label (largura máxima 200px / 2)
          top: screenPos.dy - 75, // Posicionar acima do marcador
          child: VehicleMarkerLabel(
            vehicle: vehicle,
            isSelected: isSelected,
            onTap: () => widget.onVehicleTap(vehicle),
          ),
        ),
      );
    }

    return Stack(children: labels);
  }

  // Converter coordenadas geográficas para coordenadas de tela
  Offset? _latLngToScreen(LatLng latLng, CameraPosition camera, Size mapSize) {
    try {
      // Cálculo aproximado baseado na projeção Mercator
      final zoom = camera.zoom;
      final scale = 256 * math.pow(2, zoom).toDouble();
      
      final latRad = latLng.latitude * math.pi / 180;
      final cameraLatRad = camera.target.latitude * math.pi / 180;
      
      final worldCoordinateX = (latLng.longitude + 180) / 360 * scale;
      final worldCoordinateY = (1 - math.log(math.tan(latRad) + 
          1 / math.cos(latRad)) / math.pi) / 2 * scale;
      
      final cameraWorldX = (camera.target.longitude + 180) / 360 * scale;
      final cameraWorldY = (1 - math.log(math.tan(cameraLatRad) + 
          1 / math.cos(cameraLatRad)) / math.pi) / 2 * scale;
      
      final screenX = (worldCoordinateX - cameraWorldX) + mapSize.width / 2;
      final screenY = (worldCoordinateY - cameraWorldY) + mapSize.height / 2;
      
      return Offset(screenX, screenY);
    } catch (e) {
      print('❌ Erro ao calcular posição de tela: $e');
      return null;
    }
  }
}

