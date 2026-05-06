import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class RouteService {
  static const String _apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
  static const String _directionsUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Calcular rota entre dois pontos
  static Future<RouteResult> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    List<LatLng> waypoints = const [],
    bool optimizeWaypoints = false,
  }) async {
    try {
      print('🛣️ Calculando rota...');
      print('🎯 Origem: ${origin.latitude}, ${origin.longitude}');
      print('🏁 Destino: ${destination.latitude}, ${destination.longitude}');
      print('🚗 Modo: ${travelMode.name}');

      // Construir URL da API
      final waypointsParam = waypoints.isNotEmpty 
        ? '&waypoints=${optimizeWaypoints ? 'optimize:true|' : ''}${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}'
        : '';

      final avoid = <String>[];
      if (avoidTolls) avoid.add('tolls');
      if (avoidHighways) avoid.add('highways');
      if (avoidFerries) avoid.add('ferries');
      final avoidParam = avoid.isNotEmpty ? '&avoid=${avoid.join('|')}' : '';

      final url = Uri.parse(
        '$_directionsUrl'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=${_getTravelModeString(travelMode)}'
        '$waypointsParam'
        '$avoidParam'
        '&departure_time=${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
        '&traffic_model=best_guess'
        '&language=pt-BR'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        throw Exception('Erro da API: ${data['status']} - ${data['error_message'] ?? ''}');
      }

      if (data['routes'].isEmpty) {
        throw Exception('Nenhuma rota encontrada');
      }

      final route = data['routes'][0];
      final legs = route['legs'] as List;

      // Processar informações da rota
      int totalDistance = 0;
      int totalDuration = 0;
      int totalDurationInTraffic = 0;
      List<RouteStep> allSteps = [];
      List<String> allAddresses = [];

      for (var leg in legs) {
        totalDistance += leg['distance']['value'] as int;
        totalDuration += leg['duration']['value'] as int;
        totalDurationInTraffic += leg['duration_in_traffic']?['value'] as int? ?? leg['duration']['value'] as int;
        
        allAddresses.add(leg['start_address'] as String);
        if (leg == legs.last) {
          allAddresses.add(leg['end_address'] as String);
        }

        // Processar passos
        final steps = leg['steps'] as List;
        for (var step in steps) {
          allSteps.add(RouteStep(
            instruction: _cleanHtmlInstructions(step['html_instructions'] as String),
            distance: step['distance']['text'] as String,
            duration: step['duration']['text'] as String,
            distanceValue: step['distance']['value'] as int,
            durationValue: step['duration']['value'] as int,
            startLocation: LatLng(
              (step['start_location']['lat'] as num).toDouble(),
              (step['start_location']['lng'] as num).toDouble(),
            ),
            endLocation: LatLng(
              (step['end_location']['lat'] as num).toDouble(),
              (step['end_location']['lng'] as num).toDouble(),
            ),
            maneuver: step['maneuver'] as String?,
            polyline: step['polyline']['points'] as String,
            travelMode: _parseTravelMode(step['travel_mode'] as String?),
          ));
        }
      }

      // Decodificar polyline principal
      final mainPolyline = route['overview_polyline']['points'] as String;
      final coordinates = _decodePolyline(mainPolyline);

      // Calcular bounds
      final bounds = _calculateBounds(coordinates);

      // Extrair informações sobre pedágios e avisos
      final warnings = (route['warnings'] as List?)?.map((w) => w.toString()).toList() ?? [];
      final copyrights = route['copyrights'] as String? ?? '';

      return RouteResult(
        success: true,
        route: RouteData(
          coordinates: coordinates,
          polylinePoints: mainPolyline,
          distance: totalDistance,
          duration: totalDuration,
          durationInTraffic: totalDurationInTraffic,
          bounds: bounds,
          steps: allSteps,
          addresses: allAddresses,
          warnings: warnings,
          copyrights: copyrights,
          travelMode: travelMode,
        ),
        message: 'Rota calculada com sucesso',
      );

    } catch (e) {
      print('❌ Erro ao calcular rota: $e');
      return RouteResult(
        success: false,
        route: null,
        message: e.toString(),
      );
    }
  }

  /// Obter localização atual do usuário
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // Verificar permissões
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviços de localização desabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);

    } catch (e) {
      print('❌ Erro ao obter localização atual: $e');
      return null;
    }
  }

  /// Buscar endereço por coordenadas (geocoding reverso)
  static Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      final url = Uri.parse(
        '$_geocodingUrl'
        '?latlng=${location.latitude},${location.longitude}'
        '&language=pt-BR'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        return null;
      }

      return data['results'][0]['formatted_address'] as String;

    } catch (e) {
      print('❌ Erro ao obter endereço: $e');
      return null;
    }
  }

  /// Buscar coordenadas por endereço (geocoding)
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
        '$_geocodingUrl'
        '?address=${Uri.encodeComponent(address)}'
        '&language=pt-BR'
        '&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        return null;
      }

      final location = data['results'][0]['geometry']['location'];
      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );

    } catch (e) {
      print('❌ Erro ao obter coordenadas: $e');
      return null;
    }
  }

  /// Calcular distância entre dois pontos
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // metros
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calcular tempo estimado de viagem
  static Duration calculateEstimatedTime(double distanceMeters, TravelMode travelMode) {
    double averageSpeed; // km/h
    
    switch (travelMode) {
      case TravelMode.driving:
        averageSpeed = 50; // 50 km/h em área urbana
        break;
      case TravelMode.walking:
        averageSpeed = 5; // 5 km/h caminhando
        break;
      case TravelMode.bicycling:
        averageSpeed = 15; // 15 km/h de bicicleta
        break;
      case TravelMode.transit:
        averageSpeed = 25; // 25 km/h transporte público
        break;
    }

    final distanceKm = distanceMeters / 1000;
    final timeHours = distanceKm / averageSpeed;
    final timeMinutes = timeHours * 60;

    return Duration(minutes: timeMinutes.round());
  }

  /// Converter RouteData em Polyline para Google Maps
  static Polyline createPolylineFromRoute(RouteData route, {
    Color color = Colors.blue,
    double width = 5,
    String polylineId = 'route',
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: route.coordinates,
      color: color,
      width: width.toInt(),
      patterns: [],
    );
  }

  /// Criar marcadores para origem e destino
  static Set<Marker> createRouteMarkers(
    LatLng origin,
    LatLng destination, {
    String? originTitle,
    String? destinationTitle,
    VoidCallback? onOriginTap,
    VoidCallback? onDestinationTap,
  }) {
    return {
      Marker(
        markerId: const MarkerId('origin'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: originTitle ?? 'Origem',
          snippet: 'Ponto de partida',
        ),
        onTap: onOriginTap,
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: destinationTitle ?? 'Destino',
          snippet: 'Ponto de chegada',
        ),
        onTap: onDestinationTap,
      ),
    };
  }

  /// Funções auxiliares privadas

  static String _getTravelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'bicycling';
      case TravelMode.transit:
        return 'transit';
    }
  }

  static TravelMode _parseTravelMode(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'driving':
        return TravelMode.driving;
      case 'walking':
        return TravelMode.walking;
      case 'bicycling':
        return TravelMode.bicycling;
      case 'transit':
        return TravelMode.transit;
      default:
        return TravelMode.driving;
    }
  }

  static String _cleanHtmlInstructions(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

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

  static LatLngBounds _calculateBounds(List<LatLng> coordinates) {
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (var coord in coordinates) {
      minLat = math.min(minLat, coord.latitude);
      maxLat = math.max(maxLat, coord.latitude);
      minLng = math.min(minLng, coord.longitude);
      maxLng = math.max(maxLng, coord.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

/// Modos de viagem
enum TravelMode {
  driving,   // Dirigindo
  walking,   // Caminhando
  bicycling, // Bicicleta
  transit,   // Transporte público
}

/// Resultado do cálculo de rota
class RouteResult {
  final bool success;
  final RouteData? route;
  final String message;

  const RouteResult({
    required this.success,
    required this.route,
    required this.message,
  });
}

/// Dados completos de uma rota
class RouteData {
  final List<LatLng> coordinates;
  final String polylinePoints;
  final int distance; // metros
  final int duration; // segundos
  final int durationInTraffic; // segundos
  final LatLngBounds bounds;
  final List<RouteStep> steps;
  final List<String> addresses;
  final List<String> warnings;
  final String copyrights;
  final TravelMode travelMode;

  const RouteData({
    required this.coordinates,
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.durationInTraffic,
    required this.bounds,
    required this.steps,
    required this.addresses,
    required this.warnings,
    required this.copyrights,
    required this.travelMode,
  });

  String get distanceText {
    if (distance < 1000) {
      return '${distance}m';
    } else {
      final km = distance / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  String get durationText {
    final minutes = duration ~/ 60;
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  String get durationInTrafficText {
    final minutes = durationInTraffic ~/ 60;
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  Duration get trafficDelay {
    return Duration(seconds: durationInTraffic - duration);
  }

  bool get hasTrafficDelay {
    return durationInTraffic > duration;
  }
}

/// Passo individual de uma rota
class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final int distanceValue; // metros
  final int durationValue; // segundos
  final LatLng startLocation;
  final LatLng endLocation;
  final String? maneuver;
  final String polyline;
  final TravelMode travelMode;

  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.startLocation,
    required this.endLocation,
    this.maneuver,
    required this.polyline,
    required this.travelMode,
  });

  IconData get maneuverIcon {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
        return Icons.ramp_left;
      case 'ramp-right':
        return Icons.ramp_right;
      case 'merge':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'ferry':
        return Icons.directions_boat;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      default:
        return Icons.navigation;
    }
  }
}
