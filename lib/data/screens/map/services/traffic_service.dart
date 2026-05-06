import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class TrafficService {
  static const String _apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
  static const String _directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obter informações de tráfego para uma rota específica
  static Future<TrafficInfo> getTrafficInfo({
    required LatLng origin,
    required LatLng destination,
    String travelMode = 'driving',
  }) async {
    try {
      print('🚦 Obtendo informações de tráfego...');
      print('🎯 Origem: ${origin.latitude}, ${origin.longitude}');
      print('🏁 Destino: ${destination.latitude}, ${destination.longitude}');

      // Fazer duas consultas: uma sem tráfego e outra com tráfego
      final withoutTrafficFuture = _getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
        departureTime: null, // Sem horário = sem tráfego
      );

      final withTrafficFuture = _getRouteInfo(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
        departureTime: DateTime.now(), // Com horário atual = com tráfego
      );

      final results = await Future.wait([withoutTrafficFuture, withTrafficFuture]);
      final withoutTraffic = results[0];
      final withTraffic = results[1];

      if (withoutTraffic == null || withTraffic == null) {
        return TrafficInfo.empty();
      }

      // Calcular impacto do tráfego
      final durationDiff = withTraffic.duration - withoutTraffic.duration;
      final delayPercentage = (durationDiff / withoutTraffic.duration) * 100;

      // Determinar nível de tráfego
      TrafficLevel level;
      Color color;
      String description;

      if (delayPercentage < 10) {
        level = TrafficLevel.light;
        color = Colors.green;
        description = 'Tráfego leve';
      } else if (delayPercentage < 25) {
        level = TrafficLevel.moderate;
        color = Colors.yellow;
        description = 'Tráfego moderado';
      } else if (delayPercentage < 50) {
        level = TrafficLevel.heavy;
        color = Colors.orange;
        description = 'Tráfego intenso';
      } else {
        level = TrafficLevel.severe;
        color = Colors.red;
        description = 'Tráfego muito intenso';
      }

      return TrafficInfo(
        level: level,
        color: color,
        description: description,
        durationWithoutTraffic: withoutTraffic.duration,
        durationWithTraffic: withTraffic.duration,
        delaySeconds: durationDiff,
        delayPercentage: delayPercentage,
        distanceMeters: withTraffic.distance,
        route: withTraffic,
      );

    } catch (e) {
      print('❌ Erro ao obter informações de tráfego: $e');
      return TrafficInfo.empty();
    }
  }

  /// Obter informações de rota (com ou sem tráfego)
  static Future<RouteInfo?> _getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    required String travelMode,
    DateTime? departureTime,
  }) async {
    try {
      final url = Uri.parse(
        '$_directionsUrl'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=$travelMode'
        '&language=pt-BR'
        '&key=$_apiKey'
        '${departureTime != null ? '&departure_time=${departureTime.millisecondsSinceEpoch ~/ 1000}' : ''}'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['routes'].isEmpty) {
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      // Extrair informações da rota
      final durationText = leg['duration']['text'] as String;
      final durationSeconds = leg['duration']['value'] as int;
      final distanceText = leg['distance']['text'] as String;
      final distanceMeters = leg['distance']['value'] as int;

      // Verificar se há informação de tráfego
      final durationInTraffic = leg['duration_in_traffic'];
      final trafficDurationSeconds = durationInTraffic?['value'] as int? ?? durationSeconds;
      final trafficDurationText = durationInTraffic?['text'] as String? ?? durationText;

      // Extrair polyline
      final polylinePoints = route['overview_polyline']['points'] as String;
      final coordinates = _decodePolyline(polylinePoints);

      return RouteInfo(
        durationText: departureTime != null ? trafficDurationText : durationText,
        duration: departureTime != null ? trafficDurationSeconds : durationSeconds,
        distanceText: distanceText,
        distance: distanceMeters,
        polylinePoints: polylinePoints,
        coordinates: coordinates,
        startAddress: leg['start_address'] as String,
        endAddress: leg['end_address'] as String,
        steps: _extractSteps(leg['steps']),
      );

    } catch (e) {
      print('❌ Erro ao obter informações da rota: $e');
      return null;
    }
  }

  /// Extrair passos da navegação
  static List<NavigationStep> _extractSteps(List steps) {
    return steps.map((step) {
      return NavigationStep(
        instruction: step['html_instructions'] as String? ?? '',
        distance: step['distance']['text'] as String? ?? '',
        duration: step['duration']['text'] as String? ?? '',
        startLocation: LatLng(
          (step['start_location']['lat'] as num).toDouble(),
          (step['start_location']['lng'] as num).toDouble(),
        ),
        endLocation: LatLng(
          (step['end_location']['lat'] as num).toDouble(),
          (step['end_location']['lng'] as num).toDouble(),
        ),
        maneuver: step['maneuver'] as String?,
      );
    }).toList();
  }

  /// Obter condições de tráfego em tempo real para múltiplos pontos
  static Future<List<TrafficCondition>> getRealTimeTrafficConditions(
    List<LatLng> locations,
  ) async {
    List<TrafficCondition> conditions = [];

    for (var location in locations) {
      try {
        // Para cada localização, fazer uma consulta pequena para determinar condições
        final nearbyLocation = LatLng(
          location.latitude + 0.001, // ~100m de diferença
          location.longitude + 0.001,
        );

        final trafficInfo = await getTrafficInfo(
          origin: location,
          destination: nearbyLocation,
        );

        conditions.add(TrafficCondition(
          location: location,
          level: trafficInfo.level,
          color: trafficInfo.color,
          description: trafficInfo.description,
          timestamp: DateTime.now(),
        ));

      } catch (e) {
        // Em caso de erro, adicionar condição neutra
        conditions.add(TrafficCondition(
          location: location,
          level: TrafficLevel.unknown,
          color: Colors.grey,
          description: 'Informação não disponível',
          timestamp: DateTime.now(),
        ));
      }
    }

    return conditions;
  }

  /// Obter rotas alternativas considerando tráfego
  static Future<List<AlternativeRoute>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
    int maxAlternatives = 3,
  }) async {
    try {
      final url = Uri.parse(
        '$_directionsUrl'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&alternatives=true'
        '&departure_time=${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
        '&language=pt-BR'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['routes'].isEmpty) {
        return [];
      }

      final routes = data['routes'] as List;
      List<AlternativeRoute> alternatives = [];

      for (int i = 0; i < routes.length && i < maxAlternatives; i++) {
        final route = routes[i];
        final leg = route['legs'][0];

        final durationInTraffic = leg['duration_in_traffic'];
        final duration = durationInTraffic?['value'] as int? ?? leg['duration']['value'] as int;
        final distance = leg['distance']['value'] as int;
        final polyline = route['overview_polyline']['points'] as String;

        alternatives.add(AlternativeRoute(
          index: i,
          name: i == 0 ? 'Rota principal' : 'Rota alternativa ${i}',
          duration: duration,
          distance: distance,
          polyline: polyline,
          coordinates: _decodePolyline(polyline),
          summary: route['summary'] as String? ?? '',
          warnings: (route['warnings'] as List?)?.map((w) => w.toString()).toList() ?? [],
        ));
      }

      return alternatives;

    } catch (e) {
      print('❌ Erro ao obter rotas alternativas: $e');
      return [];
    }
  }

  /// Decodificar polyline do Google Maps
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}

/// Níveis de tráfego
enum TrafficLevel {
  light,     // Leve
  moderate,  // Moderado  
  heavy,     // Intenso
  severe,    // Muito intenso
  unknown,   // Desconhecido
}

/// Informações completas de tráfego
class TrafficInfo {
  final TrafficLevel level;
  final Color color;
  final String description;
  final int durationWithoutTraffic; // segundos
  final int durationWithTraffic;    // segundos
  final int delaySeconds;           // atraso em segundos
  final double delayPercentage;     // atraso em porcentagem
  final int distanceMeters;
  final RouteInfo? route;

  const TrafficInfo({
    required this.level,
    required this.color,
    required this.description,
    required this.durationWithoutTraffic,
    required this.durationWithTraffic,
    required this.delaySeconds,
    required this.delayPercentage,
    required this.distanceMeters,
    this.route,
  });

  factory TrafficInfo.empty() {
    return const TrafficInfo(
      level: TrafficLevel.unknown,
      color: Colors.grey,
      description: 'Informação não disponível',
      durationWithoutTraffic: 0,
      durationWithTraffic: 0,
      delaySeconds: 0,
      delayPercentage: 0,
      distanceMeters: 0,
      route: null,
    );
  }

  String get delayText {
    if (delaySeconds < 60) {
      return '${delaySeconds}s de atraso';
    } else {
      final minutes = delaySeconds ~/ 60;
      return '${minutes}min de atraso';
    }
  }
}

/// Informações de uma rota
class RouteInfo {
  final String durationText;
  final int duration; // segundos
  final String distanceText;
  final int distance; // metros
  final String polylinePoints;
  final List<LatLng> coordinates;
  final String startAddress;
  final String endAddress;
  final List<NavigationStep> steps;

  const RouteInfo({
    required this.durationText,
    required this.duration,
    required this.distanceText,
    required this.distance,
    required this.polylinePoints,
    required this.coordinates,
    required this.startAddress,
    required this.endAddress,
    required this.steps,
  });
}

/// Passo de navegação
class NavigationStep {
  final String instruction;
  final String distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String? maneuver;

  const NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
  });
}

/// Condição de tráfego em um ponto específico
class TrafficCondition {
  final LatLng location;
  final TrafficLevel level;
  final Color color;
  final String description;
  final DateTime timestamp;

  const TrafficCondition({
    required this.location,
    required this.level,
    required this.color,
    required this.description,
    required this.timestamp,
  });
}

/// Rota alternativa
class AlternativeRoute {
  final int index;
  final String name;
  final int duration; // segundos
  final int distance; // metros
  final String polyline;
  final List<LatLng> coordinates;
  final String summary;
  final List<String> warnings;

  const AlternativeRoute({
    required this.index,
    required this.name,
    required this.duration,
    required this.distance,
    required this.polyline,
    required this.coordinates,
    required this.summary,
    required this.warnings,
  });

  String get durationText {
    final minutes = duration ~/ 60;
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  String get distanceText {
    if (distance < 1000) {
      return '${distance}m';
    } else {
      final km = distance / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
}
