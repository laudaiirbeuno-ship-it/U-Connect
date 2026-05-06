/// Exportação centralizada dos serviços de mapa
/// 
/// Este arquivo facilita a importação de todos os serviços relacionados ao mapa
/// em um único local, mantendo o código limpo e organizado.

// Imports necessários
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'poi_service.dart';
import 'traffic_service.dart';
import 'route_service.dart';

// Serviços principais
export 'poi_service.dart';
export 'traffic_service.dart';
export 'route_service.dart';

/// Classe utilitária para coordenar os serviços de mapa
class MapServices {
  
  /// Informações sobre os serviços disponíveis
  static const Map<String, String> availableServices = {
    'POI': 'Pontos de Interesse usando Google Places API',
    'Traffic': 'Informações de tráfego em tempo real',
    'Route': 'Cálculo de rotas e navegação',
  };

  /// Verificar se todos os serviços estão funcionais
  static Future<Map<String, bool>> checkServicesHealth() async {
    Map<String, bool> status = {};
    
    try {
      // Testar POIService
      final testLocation = LatLng(-23.5505, -46.6333); // São Paulo
      final pois = await POIService.getNearbyPOIs(
        center: testLocation,
        radius: 1000,
        maxResults: 1,
      );
      status['POI'] = pois.isNotEmpty;
    } catch (e) {
      status['POI'] = false;
    }

    try {
      // Testar TrafficService
      final origin = LatLng(-23.5505, -46.6333);
      final destination = LatLng(-23.5606, -46.6394);
      final traffic = await TrafficService.getTrafficInfo(
        origin: origin,
        destination: destination,
      );
      status['Traffic'] = traffic.level != TrafficLevel.unknown;
    } catch (e) {
      status['Traffic'] = false;
    }

    try {
      // Testar RouteService
      final origin = LatLng(-23.5505, -46.6333);
      final destination = LatLng(-23.5606, -46.6394);
      final route = await RouteService.calculateRoute(
        origin: origin,
        destination: destination,
      );
      status['Route'] = route.success;
    } catch (e) {
      status['Route'] = false;
    }

    return status;
  }

  /// Obter estatísticas dos serviços
  static Map<String, String> getServicesInfo() {
    return {
      'POI Types': POIService.poiTypes.length.toString(),
      'Traffic Levels': TrafficLevel.values.length.toString(),
      'Travel Modes': TravelMode.values.length.toString(),
      'API Key': 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg'.replaceRange(20, -10, '***'),
    };
  }
}

// Classes e tipos importantes já exportados pelos serviços individuais
