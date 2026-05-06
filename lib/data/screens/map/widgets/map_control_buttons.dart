import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/data/screens/map/services/google_map_centering_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/data/screens/router/views/router_screen.dart';
import 'package:uconnect/utils/responsive_helper.dart';
import 'package:uconnect/utils/translation_helper.dart';

/// Botões de controle do mapa - arquivo leve
class MapControlButtons extends StatelessWidget {
  final GoogleMapCenteringService? centeringService;
  
  const MapControlButtons({Key? key, this.centeringService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final mapController = context.watch<MapController>();

    return Positioned(
      left: ResponsiveHelper.width(16),
      top: ResponsiveHelper.height(82), // Movido um pouco para cima
      child: Column(
        children: [
          _Button(
            icon: Icons.view_in_ar,
            onTap: () => mapController.toggle3DView(),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Vista 3D', '3D View'),
            isActive: mapController.is3DView,
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: Icons.my_location,
            onTap: () => _recenter(context, mapController),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Recentrar mapa', 'Recenter map'),
          ),
          ResponsiveHelper.verticalSpace(12),
          // Botão de rastro desativado mas com cor normal
          IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: 0.6,
              child: _Button(
                icon: Icons.timeline,
                onTap: () {},
                colorProvider: colorProvider,
                tooltip: TranslationHelper.translateSync(context, 'Mostrar rastro (desativado)', 'Show trail (disabled)'),
                isActive: false,
              ),
            ),
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: _getMapIcon(mapController.mapType),
            onTap: () => mapController.toggleMapType(),
            colorProvider: colorProvider,
            tooltip: _getMapTooltip(context, mapController.mapType),
            isActive: mapController.mapType != MapType.normal,
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: Icons.traffic,
            onTap: () => mapController.toggleTraffic(),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Tráfego', 'Traffic'),
            isActive: mapController.showTraffic,
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: Icons.place,
            onTap: () => _togglePOI(context, mapController),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Pontos de interesse', 'Points of interest'),
            isActive: mapController.showPOI,
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: Icons.fit_screen,
            onTap: () => _recenter(context, mapController),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Ajustar ao tamanho', 'Fit to size'),
            isActive: true,
          ),
          ResponsiveHelper.verticalSpace(12),
          _Button(
            icon: Icons.navigation,
            onTap: () => _calculateRoute(context, mapController),
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Calcular rota', 'Calculate route'),
          ),
        ],
      ),
    );
  }

  void _recenter(BuildContext context, MapController mapController) {
    if (centeringService != null) {
      final objectStore = context.read<ObjectStore>();
      final vehicles = mapController.getFilteredVehicles(objectStore.objects);
      if (vehicles.isNotEmpty) {
        centeringService!.centerOnVehiclesOnMapCreated(vehicles);
      }
    }
  }


  void _toggleTrail(BuildContext context, MapController mapController) {
    if (!mapController.showTrail && mapController.selectedVehicle == null) {
      _showToast(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver o rastro', 'Select a vehicle first to see the trail'));
      return;
    }
    mapController.toggleTrail();
  }

  void _togglePOI(BuildContext context, MapController mapController) {
    if (!mapController.showPOI && mapController.selectedVehicle == null) {
      _showToast(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver pontos de interesse', 'Select a vehicle first to see points of interest'));
      return;
    }
    mapController.togglePOI();
  }

  void _calculateRoute(BuildContext context, MapController mapController) {
    final vehicle = mapController.selectedVehicle;
    if (vehicle == null) {
      _showToast(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro', 'Select a vehicle first'));
      return;
    }
    if (vehicle.lat == null || vehicle.lng == null) {
      _showToast(TranslationHelper.translateSync(context, 'Posição do veículo não disponível', 'Vehicle position not available'));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RouterScreen(vehicle: vehicle)),
    );
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  IconData _getMapIcon(MapType type) {
    switch (type) {
      case MapType.satellite: return Icons.satellite_alt;
      case MapType.hybrid: return Icons.layers;
      case MapType.terrain: return Icons.terrain;
      default: return Icons.map;
    }
  }

  String _getMapTooltip(BuildContext context, MapType type) {
    switch (type) {
      case MapType.satellite: return TranslationHelper.translateSync(context, 'Mapa Satélite', 'Satellite Map');
      case MapType.hybrid: return TranslationHelper.translateSync(context, 'Mapa Híbrido', 'Hybrid Map');
      case MapType.terrain: return TranslationHelper.translateSync(context, 'Mapa Terreno', 'Terrain Map');
      default: return TranslationHelper.translateSync(context, 'Mapa Normal', 'Normal Map');
    }
  }
}

/// Botão individual leve
class _Button extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorProvider colorProvider;
  final String tooltip;
  final bool isActive;

  const _Button({
    required this.icon,
    required this.onTap,
    required this.colorProvider,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: ResponsiveHelper.width(36),
          height: ResponsiveHelper.height(36),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : colorProvider.primaryColor,
            shape: BoxShape.circle,
            border: isActive ? Border.all(color: colorProvider.primaryColor, width: ResponsiveHelper.width(2.5)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: ResponsiveHelper.radius(8),
                offset: Offset(0, ResponsiveHelper.height(2)),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? colorProvider.primaryColor : Colors.white,
            size: ResponsiveHelper.iconSize(18),
          ),
        ),
      ),
    );
  }
}

