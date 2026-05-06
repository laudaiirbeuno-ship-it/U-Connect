import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/data/screens/router/views/router_screen.dart';
import 'package:uconnect/utils/translation_helper.dart';

class MapControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final mapController = context.watch<MapController>();

    return Positioned(
      left: 16,
      top: 85, // Ajustado um pouquinho para baixo
      child: Column(
        children: [
          _buildControlButton(
            context: context,
            icon: Icons.view_in_ar,
            onTap: () {
              print('🎯 Toggleando vista 3D'); // Debug
              mapController.toggle3DView();
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Vista 3D', '3D View'),
            isActive: mapController.is3DView,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.my_location,
            onTap: () {
              print('🎯 Recentralizando mapa'); // Debug
              // Recentrar mapa
              final objectStore = context.read<ObjectStore>();
              final vehicles = mapController.getFilteredVehicles(objectStore.objects);
              mapController.centerOnAllVehicles(vehicles);
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Recentrar mapa', 'Recenter map'),
            isActive: false,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.timeline,
            onTap: () {
              print('🛤️ Toggleando rastro'); // Debug
              
              // Verificar se há um veículo selecionado APENAS quando for ativar rastro
              // Se já estiver ativo, permitir desativar sem veículo selecionado
              if (!mapController.showTrail && mapController.selectedVehicle == null) {
                Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver o rastro', 'Select a vehicle first to see the trail'),
                  toastLength: Toast.LENGTH_LONG,
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                );
                return;
              }
              
              mapController.toggleTrail();
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Mostrar rastro', 'Show trail'),
            isActive: mapController.showTrail,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: _getMapTypeIcon(mapController.mapType),
            onTap: () {
              print('🗺️ Toggleando tipo de mapa'); // Debug
              mapController.toggleMapType();
            },
            colorProvider: colorProvider,
            tooltip: _getMapTypeTooltip(context, mapController.mapType),
            isActive: mapController.mapType != MapType.normal,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.traffic,
            onTap: () {
              print('🚦 Toggleando tráfego'); // Debug
              mapController.toggleTraffic();
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Tráfego', 'Traffic'),
            isActive: mapController.showTraffic,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.place,
            onTap: () {
              print('📍 Toggleando POIs'); // Debug
              
              // Verificar se há um veículo selecionado APENAS quando for ativar POI
              // Se já estiver ativo, permitir desativar sem veículo selecionado
              if (!mapController.showPOI && mapController.selectedVehicle == null) {
                Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver pontos de interesse', 'Select a vehicle first to see points of interest'),
                  toastLength: Toast.LENGTH_LONG,
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                );
                return;
              }
              
              mapController.togglePOI();
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Pontos de interesse', 'Points of interest'),
            isActive: mapController.showPOI,
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.fit_screen,
            onTap: () {
              // Resetar zoom e centralizar todos os veículos
              final objectStore = context.read<ObjectStore>();
              final vehicles = mapController.getFilteredVehicles(objectStore.objects);
              mapController.centerOnAllVehicles(vehicles);
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Ajustar ao tamanho', 'Fit to size'),
            isActive: true, // Sempre ativo
          ),
          SizedBox(height: 12),
          _buildControlButton(
            context: context,
            icon: Icons.navigation,
            onTap: () {
              _calculateRouteToVehicle(context, mapController);
            },
            colorProvider: colorProvider,
            tooltip: TranslationHelper.translateSync(context, 'Calcular rota', 'Calculate route'),
          ),
        ],
      ),
    );
  }

  // === NAVEGAR PARA ROTEIRIZADOR ===
  Future<void> _calculateRouteToVehicle(BuildContext context, MapController mapController) async {
    // Verificar se há um veículo selecionado
    if (mapController.selectedVehicle == null) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Selecione um veículo primeiro', 'Select a vehicle first'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
      );
      return;
    }

    final vehicle = mapController.selectedVehicle!;
    
    // Verificar se o veículo tem coordenadas válidas
    if (vehicle.lat == null || vehicle.lng == null) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Posição do veículo não disponível', 'Vehicle position not available'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Navegar para a página do roteirizador
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouterScreen(vehicle: vehicle),
      ),
    );
  }


  // Obter ícone baseado no tipo de mapa
  IconData _getMapTypeIcon(MapType mapType) {
    switch (mapType) {
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.hybrid:
        return Icons.layers;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.normal:
      default:
        return Icons.map;
    }
  }

  // Obter tooltip baseado no tipo de mapa
  String _getMapTypeTooltip(BuildContext context, MapType mapType) {
    switch (mapType) {
      case MapType.satellite:
        return TranslationHelper.translateSync(context, 'Mapa Satélite', 'Satellite Map');
      case MapType.hybrid:
        return TranslationHelper.translateSync(context, 'Mapa Híbrido', 'Hybrid Map');
      case MapType.terrain:
        return TranslationHelper.translateSync(context, 'Mapa Terreno', 'Terrain Map');
      case MapType.normal:
      default:
        return TranslationHelper.translateSync(context, 'Mapa Normal', 'Normal Map');
    }
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required ColorProvider colorProvider,
    required String tooltip,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        print('🔘 Botão clicado: $tooltip'); // Debug
        onTap();
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 42, // Diminuído de 48 para 42
          height: 42, // Diminuído de 48 para 42
          decoration: BoxDecoration(
            color: isActive ? Colors.white : colorProvider.primaryColor, // Branco quando ativo
            shape: BoxShape.circle, // Circular
            border: isActive ? Border.all(color: colorProvider.primaryColor, width: 2) : null, // Borda quando ativo
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? colorProvider.primaryColor : Colors.white, // Ícone da cor do tema quando ativo
            size: 20, // Diminuído de 22 para 20
          ),
        ),
      ),
    );
  }
}

