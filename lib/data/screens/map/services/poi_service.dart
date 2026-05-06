import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class POIService {
  static const String _apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  // Tipos de POI disponíveis
  static const Map<String, POIType> poiTypes = {
    'gas_station': POIType(
      type: 'gas_station',
      name: 'Postos de Gasolina',
      icon: Icons.local_gas_station,
      color: Colors.green,
      hue: BitmapDescriptor.hueGreen,
    ),
    'restaurant': POIType(
      type: 'restaurant',
      name: 'Restaurantes',
      icon: Icons.restaurant,
      color: Colors.red,
      hue: BitmapDescriptor.hueRed,
    ),
    'hospital': POIType(
      type: 'hospital',
      name: 'Hospitais',
      icon: Icons.local_hospital,
      color: Colors.pink,
      hue: BitmapDescriptor.hueRose,
    ),
    'bank': POIType(
      type: 'bank',
      name: 'Bancos',
      icon: Icons.account_balance,
      color: Colors.yellow,
      hue: BitmapDescriptor.hueYellow,
    ),
    'atm': POIType(
      type: 'atm',
      name: 'Caixas Eletrônicos',
      icon: Icons.atm,
      color: Colors.orange,
      hue: BitmapDescriptor.hueOrange,
    ),
    'pharmacy': POIType(
      type: 'pharmacy',
      name: 'Farmácias',
      icon: Icons.local_pharmacy,
      color: Colors.cyan,
      hue: BitmapDescriptor.hueCyan,
    ),
    'shopping_mall': POIType(
      type: 'shopping_mall',
      name: 'Shopping Centers',
      icon: Icons.shopping_bag,
      color: Colors.purple,
      hue: BitmapDescriptor.hueViolet,
    ),
    'lodging': POIType(
      type: 'lodging',
      name: 'Hotéis',
      icon: Icons.hotel,
      color: Colors.indigo,
      hue: BitmapDescriptor.hueBlue,
    ),
  };

  /// Buscar POIs próximos a uma localização
  static Future<List<POIMarker>> getNearbyPOIs({
    required LatLng center,
    required double radius,
    List<String>? types,
    int maxResults = 20,
  }) async {
    try {
      print('🔍 Buscando POIs próximos...');
      print('📍 Centro: ${center.latitude}, ${center.longitude}');
      print('📏 Raio: ${radius.toInt()}m');

      List<POIMarker> allPOIs = [];

      // Se tipos específicos não foram fornecidos, usar todos
      final typesToSearch = types ?? poiTypes.keys.toList();

      for (String type in typesToSearch) {
        final markers = await _searchPOIsByType(
          center: center,
          radius: radius,
          type: type,
          maxResults: maxResults ~/ typesToSearch.length,
        );
        allPOIs.addAll(markers);
      }

      print('✅ Total de POIs encontrados: ${allPOIs.length}');
      return allPOIs;

    } catch (e) {
      print('❌ Erro ao buscar POIs: $e');
      return [];
    }
  }

  /// Buscar POIs por tipo específico
  static Future<List<POIMarker>> _searchPOIsByType({
    required LatLng center,
    required double radius,
    required String type,
    int maxResults = 10,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl'
        '?location=${center.latitude},${center.longitude}'
        '&radius=${radius.toInt()}'
        '&type=$type'
        '&key=$_apiKey'
        '&language=pt-BR',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        print('⚠️ Erro HTTP ao buscar $type: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['status'] != 'OK') {
        print('⚠️ Erro da API ao buscar $type: ${data['status']}');
        return [];
      }

      final results = data['results'] as List? ?? [];
      final poiType = poiTypes[type];
      
      if (poiType == null) {
        print('⚠️ Tipo de POI desconhecido: $type');
        return [];
      }

      List<POIMarker> markers = [];

      for (var poi in results.take(maxResults)) {
        final geometry = poi['geometry']?['location'];
        if (geometry != null) {
          final lat = (geometry['lat'] as num).toDouble();
          final lng = (geometry['lng'] as num).toDouble();
          final name = poi['name'] as String? ?? 'POI';
          final placeId = poi['place_id'] as String? ?? '';
          final rating = poi['rating'] as double?;
          final vicinity = poi['vicinity'] as String?;
          final priceLevel = poi['price_level'] as int?;
          final isOpen = poi['opening_hours']?['open_now'] as bool?;

          final marker = POIMarker(
            id: 'poi_$placeId',
            position: LatLng(lat, lng),
            name: name,
            type: poiType,
            placeId: placeId,
            rating: rating,
            vicinity: vicinity,
            priceLevel: priceLevel,
            isOpen: isOpen,
          );

          markers.add(marker);
        }
      }

      print('📍 POIs do tipo "$type" encontrados: ${markers.length}');
      return markers;

    } catch (e) {
      print('❌ Erro ao buscar POIs do tipo "$type": $e');
      return [];
    }
  }

  /// Converter POIMarkers em Markers do Google Maps
  static Set<Marker> convertToGoogleMapMarkers(List<POIMarker> poiMarkers) {
    return poiMarkers.map((poi) {
      return Marker(
        markerId: MarkerId(poi.id),
        position: poi.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(poi.type.hue),
        infoWindow: InfoWindow(
          title: poi.name,
          snippet: _buildSnippet(poi),
        ),
        onTap: () {
          print('📍 POI clicado: ${poi.name}');
        },
      );
    }).toSet();
  }

  /// Construir snippet de informações do POI
  static String _buildSnippet(POIMarker poi) {
    List<String> info = [];
    
    info.add(poi.type.name);
    
    if (poi.rating != null) {
      info.add('⭐ ${poi.rating!.toStringAsFixed(1)}');
    }
    
    if (poi.isOpen != null) {
      info.add(poi.isOpen! ? '🟢 Aberto' : '🔴 Fechado');
    }
    
    if (poi.priceLevel != null) {
      final priceText = '\$' * (poi.priceLevel! + 1);
      info.add(priceText);
    }
    
    if (poi.vicinity != null) {
      info.add(poi.vicinity!);
    }

    return info.join(' • ');
  }

  /// Obter detalhes completos de um POI específico
  static Future<POIDetails?> getPOIDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,rating,formatted_phone_number,website,opening_hours,photos,reviews'
        '&key=$_apiKey'
        '&language=pt-BR',
      );

      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      
      if (data['status'] != 'OK') {
        return null;
      }

      final result = data['result'];
      
      return POIDetails(
        name: result['name'] as String? ?? '',
        rating: result['rating'] as double?,
        phoneNumber: result['formatted_phone_number'] as String?,
        website: result['website'] as String?,
        openingHours: (result['opening_hours']?['weekday_text'] as List?)
            ?.map((e) => e.toString()).toList(),
        reviews: (result['reviews'] as List?)
            ?.map((r) => POIReview(
              authorName: r['author_name'] as String? ?? '',
              rating: r['rating'] as int? ?? 0,
              text: r['text'] as String? ?? '',
              time: r['time'] as int? ?? 0,
            ))
            .toList(),
      );

    } catch (e) {
      print('❌ Erro ao obter detalhes do POI: $e');
      return null;
    }
  }

  /// Filtrar POIs por categoria
  static List<POIMarker> filterPOIsByCategory(
    List<POIMarker> pois, 
    List<String> categories,
  ) {
    if (categories.isEmpty) return pois;
    
    return pois.where((poi) => categories.contains(poi.type.type)).toList();
  }

  /// Calcular distância até POI mais próximo
  static double getDistanceToNearestPOI(
    LatLng userLocation, 
    List<POIMarker> pois,
  ) {
    if (pois.isEmpty) return double.infinity;
    
    double minDistance = double.infinity;
    
    for (var poi in pois) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        poi.position.latitude,
        poi.position.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance;
  }

  /// Calcular distância entre dois pontos (Haversine)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

/// Classe para definir tipos de POI
class POIType {
  final String type;
  final String name;
  final IconData icon;
  final Color color;
  final double hue;

  const POIType({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
    required this.hue,
  });
}

/// Classe para representar um marcador de POI
class POIMarker {
  final String id;
  final LatLng position;
  final String name;
  final POIType type;
  final String placeId;
  final double? rating;
  final String? vicinity;
  final int? priceLevel;
  final bool? isOpen;

  const POIMarker({
    required this.id,
    required this.position,
    required this.name,
    required this.type,
    required this.placeId,
    this.rating,
    this.vicinity,
    this.priceLevel,
    this.isOpen,
  });
}

/// Classe para detalhes completos de um POI
class POIDetails {
  final String name;
  final double? rating;
  final String? phoneNumber;
  final String? website;
  final List<String>? openingHours;
  final List<POIReview>? reviews;

  const POIDetails({
    required this.name,
    this.rating,
    this.phoneNumber,
    this.website,
    this.openingHours,
    this.reviews,
  });
}

/// Classe para reviews de POI
class POIReview {
  final String authorName;
  final int rating;
  final String text;
  final int time;

  const POIReview({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.time,
  });
}
