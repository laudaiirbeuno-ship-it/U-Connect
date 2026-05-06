import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';

class HeatmapWidget extends StatefulWidget {
  @override
  _HeatmapWidgetState createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  GoogleMapController? _mapController;
  Set<Circle> _heatmapCircles = {};
  Map<LatLng, int> _eventCounts = {};

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    // Processar eventos para criar mapa de calor quando os dados mudarem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processEvents(controller);
    });
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.whatshot, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'Mapa de Calor de Eventos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(-23.5505, -46.6333), // São Paulo
                  zoom: 10,
                ),
                mapType: MapType.normal,
                circles: _heatmapCircles,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _updateCamera();
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem('Baixa', Colors.green, colorProvider),
              SizedBox(width: 16),
              _buildLegendItem('Média', Colors.orange, colorProvider),
              SizedBox(width: 16),
              _buildLegendItem('Alta', Colors.red, colorProvider),
            ],
          ),
        ],
      ),
    );
  }
  
  void _processEvents(FleetOverviewController controller) {
    if (!mounted) return;
    
    final oldCount = _eventCounts.length;
    _eventCounts.clear();
    _heatmapCircles.clear();
    
    // Processar alertas recentes e críticos
    final allEvents = [...controller.recentAlerts, ...controller.criticalAlerts];
    
    for (var event in allEvents) {
      if (event.latitude != null && event.longitude != null) {
        try {
          final lat = double.tryParse(event.latitude.toString()) ?? 0.0;
          final lng = double.tryParse(event.longitude.toString()) ?? 0.0;
          
          if (lat != 0.0 && lng != 0.0) {
            // Arredondar coordenadas para agrupar eventos próximos
            final roundedLat = (lat * 100).round() / 100;
            final roundedLng = (lng * 100).round() / 100;
            final roundedLocation = LatLng(roundedLat, roundedLng);
            
            _eventCounts[roundedLocation] = (_eventCounts[roundedLocation] ?? 0) + 1;
          }
        } catch (e) {
          print('Erro ao processar coordenadas do evento: $e');
        }
      }
    }
    
    // Criar círculos de calor baseado na contagem
    if (_eventCounts.isEmpty) {
      // Se não houver eventos, atualizar UI mesmo assim
      if (mounted && oldCount != _eventCounts.length) {
        setState(() {});
      }
      return;
    }
    
    final maxCount = _eventCounts.values.reduce((a, b) => a > b ? a : b);
    
    _eventCounts.forEach((location, count) {
      final intensity = count / maxCount;
      Color circleColor;
      double radius;
      
      if (intensity < 0.33) {
        circleColor = Colors.green.withOpacity(0.3);
        radius = 200;
      } else if (intensity < 0.66) {
        circleColor = Colors.orange.withOpacity(0.4);
        radius = 300;
      } else {
        circleColor = Colors.red.withOpacity(0.5);
        radius = 400;
      }
      
      _heatmapCircles.add(Circle(
        circleId: CircleId('heat_${location.latitude}_${location.longitude}'),
        center: location,
        radius: radius,
        fillColor: circleColor,
        strokeColor: circleColor.withOpacity(0.8),
        strokeWidth: 2,
      ));
    });
    
    // Atualizar UI
    if (mounted) {
      setState(() {});
    }
    
    // Atualizar câmera após processar eventos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCamera();
    });
  }
  
  void _updateCamera() {
    if (_mapController == null || _eventCounts.isEmpty) return;
    
    final locations = _eventCounts.keys.toList();
    if (locations.isEmpty) return;
    
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;
    
    for (var loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, ColorProvider colorProvider) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

