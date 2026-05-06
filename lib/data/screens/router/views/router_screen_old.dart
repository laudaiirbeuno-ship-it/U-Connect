import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/main_bottom_nav.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';

class RouterScreen extends StatefulWidget {
  final deviceItems? vehicle;
  
  const RouterScreen({Key? key, this.vehicle}) : super(key: key);

  @override
  _RouterScreenState createState() => _RouterScreenState();
}

class _RouterScreenState extends State<RouterScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Position? _userPosition;
  
  // Controladores de entrada
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocus = FocusNode();
  
  // Estados da interface
  bool _isLoadingRoute = false;
  bool _showRouteDetails = false;
  
  // Dados da rota
  RouteDetails? _routeDetails;
  LatLng? _destinationCoords;
  bool _expandRouteCard = false;
  
  // Seleção de veículo
  deviceItems? _linkedVehicle;
  
  // Configurações de veículo
  VehicleType _selectedVehicleType = VehicleType.car;
  
  // Autocomplete de endereços
  List<PlacePrediction> _addressSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeRouter();
    
    // Listener para controlar sugestões
    _destinationFocus.addListener(() {
      if (!_destinationFocus.hasFocus) {
        // Delay para permitir tap nas sugestões
        Future.delayed(Duration(milliseconds: 150), () {
          if (mounted) _clearSuggestions();
        });
      }
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  // Limpar sugestões quando perder foco
  void _clearSuggestions() {
    setState(() {
      _showSuggestions = false;
      _addressSuggestions.clear();
    });
  }

  // Expandir/recolher card de rota
  void _toggleRouteExpansion(int index) {
    setState(() {
      if (_expandedRouteIndex == index) {
        _expandedRouteIndex = null;
        // Limpar mapa quando recolher
        _markers.clear();
        _polylines.clear();
      } else {
        _expandedRouteIndex = index;
        // Mostrar rota selecionada no mapa
        _showRouteOnMap(_routeHistory[index]);
      }
    });
  }

  // Mostrar rota específica no mapa
  void _showRouteOnMap(SavedRoute savedRoute) async {
    setState(() {
      _markers.clear();
      _polylines.clear();
    });

    try {
      final route = savedRoute.routeDetails;
      
      // Adicionar marcadores
      _markers.addAll({
        Marker(
          markerId: MarkerId('saved_origin'),
          position: savedRoute.originCoords,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '🚩 Origem',
            snippet: route.originAddress,
          ),
        ),
        Marker(
          markerId: MarkerId('saved_destination'),
          position: savedRoute.destinationCoords,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🎯 Destino',
            snippet: route.destinationAddress,
          ),
        ),
      });

      // Criar polyline da rota
      if (route.polylinePoints.isNotEmpty) {
        final routePolyline = Polyline(
          polylineId: PolylineId('saved_route'),
          points: route.polylinePoints,
          color: _getRouteColor(route.trafficLevel),
          width: 6,
          patterns: [],
        );
        _polylines.add(routePolyline);
      }

      // Centralizar mapa na rota
      if (_mapController != null && route.bounds != null) {
        await Future.delayed(Duration(milliseconds: 300));
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(route.bounds!, 100),
        );
      }

    } catch (e) {
      print('❌ Erro ao mostrar rota no mapa: $e');
    }
  }

  // Deletar rota do histórico
  void _deleteRoute(int index) {
    setState(() {
      _routeHistory.removeAt(index);
      if (_expandedRouteIndex == index) {
        _expandedRouteIndex = null;
        _markers.clear();
        _polylines.clear();
      } else if (_expandedRouteIndex != null && _expandedRouteIndex! > index) {
        _expandedRouteIndex = _expandedRouteIndex! - 1;
      }
    });

    Fluttertoast.showToast(
      msg: 'Rota removida do histórico',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _initializeRouter() async {
    await _getUserLocation();
    
    // Se foi passado um veículo específico, usar sua localização como destino
    if (widget.vehicle != null) {
      _destinationController.text = widget.vehicle!.address ?? 'Localização do veículo';
      if (widget.vehicle!.lat != null && widget.vehicle!.lng != null) {
        _destinationCoords = LatLng(
          widget.vehicle!.lat!.toDouble(), 
          widget.vehicle!.lng!.toDouble()
        );
        await _calculateRoute();
      }
    }
  }

  Future<void> _getUserLocation() async {
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

      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (_userPosition != null) {
        final userMarker = Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '📍 Sua localização',
            snippet: 'Ponto de partida',
          ),
        );

        setState(() {
          _markers.add(userMarker);
        });

        print('✅ Localização obtida: ${_userPosition!.latitude}, ${_userPosition!.longitude}');
      }
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      Fluttertoast.showToast(
        msg: 'Erro ao obter localização: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Buscar sugestões de endereços (autocomplete)
  Future<void> _searchAddressSuggestions(String query) async {
    if (query.length < 3) {
      setState(() {
        _addressSuggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    try {
      const apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
          'input=$encodedQuery&'
          'key=$apiKey&'
          'language=pt-BR&'
          'components=country:br&'
          'types=address';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          setState(() {
            _addressSuggestions = predictions
                .map((pred) => PlacePrediction.fromJson(pred))
                .toList();
            _showSuggestions = _addressSuggestions.isNotEmpty;
          });
        } else {
          setState(() {
            _addressSuggestions.clear();
            _showSuggestions = false;
          });
        }
      }
    } catch (e) {
      print('❌ Erro ao buscar sugestões: $e');
      setState(() {
        _addressSuggestions.clear();
        _showSuggestions = false;
      });
    }
  }

  // Selecionar endereço da lista de sugestões
  Future<void> _selectAddressSuggestion(PlacePrediction prediction) async {
    _destinationController.text = prediction.description;
    
    setState(() {
      _showSuggestions = false;
      _addressSuggestions.clear();
    });

    // Buscar coordenadas do local selecionado
    try {
      _destinationCoords = await _getCoordinatesFromPlaceId(prediction.placeId);
      
      if (_destinationCoords != null) {
        // Calcular rota automaticamente
        await _calculateRoute();
      }
    } catch (e) {
      print('❌ Erro ao obter coordenadas: $e');
      Fluttertoast.showToast(
        msg: 'Erro ao processar endereço selecionado',
        backgroundColor: Colors.red,
      );
    }

    _destinationFocus.unfocus();
  }

  // Obter coordenadas a partir do Place ID
  Future<LatLng?> _getCoordinatesFromPlaceId(String placeId) async {
    try {
      const apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?'
          'place_id=$placeId&'
          'fields=geometry&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao obter coordenadas do Place ID: $e');
      return null;
    }
  }

  Future<void> _searchDestination() async {
    final destination = _destinationController.text.trim();
    
    if (destination.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Digite um destino',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _showRouteDetails = false;
      _showSuggestions = false;
    });

    try {
      // Buscar coordenadas do destino usando Geocoding API
      _destinationCoords = await _getCoordinatesFromAddress(destination);
      
      if (_destinationCoords == null) {
        throw Exception('Destino não encontrado');
      }

      print('🎯 Destino encontrado: $_destinationCoords');

      // Calcular rota
      await _calculateRoute();

    } catch (e) {
      print('❌ Erro ao buscar destino: $e');
      Fluttertoast.showToast(
        msg: 'Destino não encontrado: $e',
        backgroundColor: Colors.red,
      );
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      const apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
      final encodedAddress = Uri.encodeComponent(address);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&language=pt-BR&region=BR';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro na geocodificação: $e');
      return null;
    }
  }

  Future<void> _calculateRoute() async {
    if (_userPosition == null) {
      Fluttertoast.showToast(
        msg: 'Obtendo sua localização...',
        backgroundColor: Colors.orange,
      );
      await _getUserLocation();
      return;
    }

    if (_destinationCoords == null) {
      Fluttertoast.showToast(
        msg: 'Destino não definido',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _showRouteDetails = false;
    });

    try {
      final origin = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final destination = _destinationCoords!;

      print('🛣️ Calculando rota detalhada...');
      print('📍 Origem: $origin');
      print('🎯 Destino: $destination');

      // Calcular rota usando Directions API
      final routeData = await _getDirectionsRoute(origin, destination);
      
      if (routeData == null) {
        throw Exception('Não foi possível calcular a rota');
      }

      // Análise avançada de pedágios
      final tollInfo = _detectTollsAdvanced(routeData);

      // Calcular tempos baseado no tipo de veículo selecionado
      final baseDuration = routeData['duration_seconds'] ?? 0;
      final carDuration = baseDuration;
      final truckDuration = (baseDuration * 1.25).round(); // 25% mais lento

      // Ajustar consumo baseado no tipo de veículo
      final vehicleConsumption = _selectedVehicleType == VehicleType.car 
          ? 12.0 // Carro: 12 km/L
          : 6.0; // Caminhão: 6 km/L

      // Calcular consumo de combustível baseado no tipo de veículo
      final fuelConsumption = _calculateFuelConsumption(routeData['distance_km'] ?? 0.0, vehicleConsumption);

      // Extrair dados de tráfego da API
      final trafficLevel = routeData['traffic_level'] as TrafficLevel? ?? TrafficLevel.unknown;
      final trafficDescription = routeData['traffic_description'] as String? ?? 'Não disponível';
      final delaySeconds = routeData['delay_seconds'] as int? ?? 0;

      print('📊 Dados processados da rota:');
      print('   🛣️ Resumo: ${routeData['summary']}');
      print('   ⚠️ Warnings: ${routeData['warnings']}');
      print('   🚗 Rotas alternativas: ${routeData['total_routes_found']}');
      print('   💰 Pedágios: ${tollInfo['has_tolls']} (R\$ ${tollInfo['estimated_cost']?.toStringAsFixed(2)})');
      print('   🚦 Tráfego: $trafficDescription ($delaySeconds s atraso)');

      // Criar detalhes completos da rota com MUITO mais informação
      _routeDetails = RouteDetails(
        // Dados básicos
        distanceText: routeData['distance_text'] ?? '',
        distanceKm: routeData['distance_km'] ?? 0.0,
        carDuration: carDuration,
        truckDuration: truckDuration,
        polylinePoints: routeData['polyline_points'] ?? [],
        bounds: routeData['bounds'],
        originAddress: 'Sua localização atual',
        destinationAddress: _destinationController.text,
        
        // Dados de tráfego expandidos
        trafficLevel: trafficLevel,
        trafficDescription: trafficDescription,
        delaySeconds: delaySeconds,
        durationInTrafficSeconds: routeData['duration_in_traffic_seconds'],
        durationInTrafficText: routeData['duration_in_traffic_text'],
        
        // Pedágios detalhados
        hasTolls: tollInfo['has_tolls'] as bool,
        estimatedTollCost: tollInfo['estimated_cost'] as double,
        tollCount: tollInfo['toll_count'] as int,
        tollRoads: List<String>.from(tollInfo['toll_roads']),
        
        // Combustível
        fuelConsumption: fuelConsumption,
        
        // Metadados da rota
        routeSummary: routeData['summary'] ?? 'Rota principal',
        warnings: List<String>.from(routeData['warnings'] ?? []),
        routeFeatures: routeData['route_features'] ?? {},
        
        // Rotas alternativas
        alternativeRoutes: List<Map<String, dynamic>>.from(routeData['alternative_routes'] ?? []),
        totalRoutesFound: routeData['total_routes_found'] ?? 1,
        
        // Horários otimizados
        optimizedDepartureTimes: List<Map<String, String>>.from(routeData['optimized_departure_times'] ?? []),
        
        // Características extras
        hasRestrictions: routeData['has_restrictions'] ?? false,
        detailedSteps: List<Map<String, dynamic>>.from(routeData['steps'] ?? []),
      );

      // Limpar marcadores anteriores
      _markers.clear();
      _polylines.clear();

      // Adicionar marcadores
      _markers.addAll({
        Marker(
          markerId: MarkerId('origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '🚩 Origem',
            snippet: 'Sua localização atual',
          ),
        ),
        Marker(
          markerId: MarkerId('destination'),
          position: destination,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🎯 Destino',
            snippet: _destinationController.text,
          ),
        ),
      });

      // Criar polyline da rota
      if (_routeDetails!.polylinePoints.isNotEmpty) {
        final routePolyline = Polyline(
          polylineId: PolylineId('main_route'),
          points: _routeDetails!.polylinePoints,
          color: _getRouteColor(_routeDetails!.trafficLevel),
          width: 6,
          patterns: [],
        );
        _polylines.add(routePolyline);
      }

      setState(() {
        _showRouteDetails = true;
        _isLoadingRoute = false;
      });

      // Centralizar mapa na rota
      if (_mapController != null && _routeDetails!.bounds != null) {
        await Future.delayed(Duration(milliseconds: 300));
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(_routeDetails!.bounds!, 100),
        );
      }

      Fluttertoast.showToast(
        msg: '✅ Rota calculada: ${_routeDetails!.distanceText}',
        backgroundColor: Colors.green,
      );

      // Esconder teclado
      _destinationFocus.unfocus();

    } catch (e) {
      print('❌ Erro ao calcular rota: $e');
      setState(() {
        _isLoadingRoute = false;
        _showRouteDetails = false;
      });
      Fluttertoast.showToast(
        msg: 'Erro ao calcular rota: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<Map<String, dynamic>?> _getDirectionsRoute(LatLng origin, LatLng destination) async {
    try {
      const apiKey = 'AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg';
      
      // URL expandida com muito mais parâmetros para extrair máximo de dados
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$apiKey&'
          'language=pt-BR&'
          'region=BR&'
          'departure_time=now&'
          'traffic_model=best_guess&'
          'alternatives=true&'           // Múltiplas rotas alternativas
          'avoid=&'                      // Permite especificar o que evitar
          'units=metric&'                // Unidades métricas
          'optimize_waypoints=true&'     // Otimizar pontos intermediários
          'provide_route_alternatives=true'; // Fornecer alternativas detalhadas

      print('🌐 Fazendo chamada completa da API: $url');
      final response = await http.get(Uri.parse(url));
      
      print('📡 Status da resposta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Status da API: ${data['status']}');
        print('📈 Quantidade de rotas encontradas: ${data['routes']?.length ?? 0}');

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          // Processar a melhor rota (primeira)
          final mainRoute = data['routes'][0];
          final mainLeg = mainRoute['legs'][0];
          
          print('🔍 Dados completos da rota principal:');
          print('   📏 Distância: ${mainLeg['distance']['text']} (${mainLeg['distance']['value']}m)');
          print('   ⏰ Duração: ${mainLeg['duration']['text']} (${mainLeg['duration']['value']}s)');
          
          // Verificar se há duração com tráfego
          String? durationInTrafficText;
          int? durationInTrafficSeconds;
          if (mainLeg['duration_in_traffic'] != null) {
            durationInTrafficText = mainLeg['duration_in_traffic']['text'];
            durationInTrafficSeconds = mainLeg['duration_in_traffic']['value'];
            print('   🚦 Duração no tráfego: $durationInTrafficText (${durationInTrafficSeconds}s)');
          }

          // Extrair warnings e alertas
          final warnings = List<String>.from(mainRoute['warnings'] ?? []);
          final copyrights = mainRoute['copyrights'] ?? '';
          final summary = mainRoute['summary'] ?? 'Rota principal';
          
          print('   ⚠️  Warnings: $warnings');
          print('   📋 Resumo: $summary');
          
          // Decodificar polyline
          final polylinePoints = _decodePolyline(mainRoute['overview_polyline']['points']);

          // Criar bounds
          final bounds = LatLngBounds(
            southwest: LatLng(
              mainRoute['bounds']['southwest']['lat'],
              mainRoute['bounds']['southwest']['lng'],
            ),
            northeast: LatLng(
              mainRoute['bounds']['northeast']['lat'],
              mainRoute['bounds']['northeast']['lng'],
            ),
          );

          // Processar rotas alternativas
          List<Map<String, dynamic>> alternativeRoutes = [];
          if (data['routes'].length > 1) {
            print('🔄 Processando ${data['routes'].length - 1} rotas alternativas...');
            
            for (int i = 1; i < data['routes'].length; i++) {
              final altRoute = data['routes'][i];
              final altLeg = altRoute['legs'][0];
              
              alternativeRoutes.add({
                'index': i,
                'summary': altRoute['summary'] ?? 'Rota alternativa $i',
                'distance_text': altLeg['distance']['text'],
                'distance_km': altLeg['distance']['value'] / 1000.0,
                'duration_text': altLeg['duration']['text'],
                'duration_seconds': altLeg['duration']['value'],
                'duration_in_traffic_text': altLeg['duration_in_traffic']?['text'],
                'duration_in_traffic_seconds': altLeg['duration_in_traffic']?['value'],
                'polyline_points': _decodePolyline(altRoute['overview_polyline']['points']),
                'warnings': List<String>.from(altRoute['warnings'] ?? []),
              });
              
              print('   🛣️  Rota $i: ${altLeg['distance']['text']} - ${altLeg['duration']['text']}');
            }
          }

          // Extrair passos detalhados com muito mais informação
          final detailedSteps = <Map<String, dynamic>>[];
          if (mainLeg['steps'] != null) {
            for (final step in mainLeg['steps']) {
              detailedSteps.add({
                'instruction': step['html_instructions'] ?? '',
                'plain_instruction': step['html_instructions']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                'distance_text': step['distance']?['text'] ?? '',
                'distance_meters': step['distance']?['value'] ?? 0,
                'duration_text': step['duration']?['text'] ?? '',
                'duration_seconds': step['duration']?['value'] ?? 0,
                'maneuver': step['maneuver'] ?? '',
                'start_location': step['start_location'],
                'end_location': step['end_location'],
                'travel_mode': step['travel_mode'] ?? 'DRIVING',
              });
            }
            print('   🗺️  Passos detalhados: ${detailedSteps.length} instruções');
          }

          // Analisar condições de tráfego
          TrafficLevel trafficLevel = TrafficLevel.unknown;
          String trafficDescription = 'Informações não disponíveis';
          int delaySeconds = 0;
          
          if (durationInTrafficSeconds != null && mainLeg['duration'] != null) {
            final normalDuration = mainLeg['duration']['value'] as int;
            delaySeconds = durationInTrafficSeconds - normalDuration;
            
            if (delaySeconds <= 300) { // Até 5 min de atraso
              trafficLevel = TrafficLevel.light;
              trafficDescription = 'Trânsito leve 🟢';
            } else if (delaySeconds <= 900) { // Até 15 min
              trafficLevel = TrafficLevel.moderate;
              trafficDescription = 'Trânsito moderado 🟡';
            } else if (delaySeconds <= 1800) { // Até 30 min
              trafficLevel = TrafficLevel.heavy;
              trafficDescription = 'Trânsito intenso 🟠';
            } else {
              trafficLevel = TrafficLevel.severe;
              trafficDescription = 'Trânsito muito intenso 🔴';
            }
            
            print('   🚦 Análise de tráfego: $trafficDescription (${delaySeconds}s de atraso)');
          }

          // Detectar características especiais da rota
          final routeFeatures = _analyzeRouteFeatures(mainRoute, detailedSteps);
          print('   🏷️  Características da rota: $routeFeatures');

          // Calcular horários otimizados (simulado)
          final optimizedTimes = _calculateOptimizedDepartureTimes(mainLeg['duration']['value']);

          return {
            // Dados básicos
            'distance_text': mainLeg['distance']['text'],
            'distance_km': mainLeg['distance']['value'] / 1000.0,
            'duration_seconds': mainLeg['duration']['value'],
            'duration_text': mainLeg['duration']['text'],
            'polyline_points': polylinePoints,
            'bounds': bounds,
            'steps': detailedSteps,
            
            // Dados de tráfego expandidos
            'duration_in_traffic_text': durationInTrafficText,
            'duration_in_traffic_seconds': durationInTrafficSeconds,
            'traffic_level': trafficLevel,
            'traffic_description': trafficDescription,
            'delay_seconds': delaySeconds,
            
            // Metadados da rota
            'summary': summary,
            'warnings': warnings,
            'copyrights': copyrights,
            'alternative_routes': alternativeRoutes,
            'route_features': routeFeatures,
            'optimized_departure_times': optimizedTimes,
            
            // Contadores úteis
            'total_routes_found': data['routes'].length,
            'has_tolls': warnings.any((w) => 
              w.toLowerCase().contains('toll') || 
              w.toLowerCase().contains('pedágio') ||
              w.toLowerCase().contains('taxa')),
            'has_restrictions': warnings.any((w) => 
              w.toLowerCase().contains('restrict') || 
              w.toLowerCase().contains('avoid')),
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Erro ao buscar direções: $e');
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  // Analisar características da rota
  Map<String, dynamic> _analyzeRouteFeatures(Map<String, dynamic> route, List<Map<String, dynamic>> steps) {
    final features = <String, dynamic>{
      'highways': <String>[],
      'cities': <String>[],
      'landmarks': <String>[],
      'road_types': <String, int>{},
      'estimated_tolls': 0,
      'fuel_stations': 0,
      'rest_areas': 0,
    };

    try {
      final summary = route['summary']?.toString().toLowerCase() ?? '';
      
      // Detectar rodovias principais
      final highwayPatterns = [
        RegExp(r'br-?\d+'), RegExp(r'sp-?\d+'), RegExp(r'mg-?\d+'),
        RegExp(r'rj-?\d+'), RegExp(r'rs-?\d+'), RegExp(r'pr-?\d+'),
        RegExp(r'sc-?\d+'), RegExp(r'go-?\d+'), RegExp(r'df-?\d+'),
      ];
      
      for (final pattern in highwayPatterns) {
        final matches = pattern.allMatches(summary);
        for (final match in matches) {
          final highway = match.group(0)?.toUpperCase() ?? '';
          if (!features['highways'].contains(highway)) {
            features['highways'].add(highway);
          }
        }
      }

      // Analisar passos para detectar tipos de via e pontos de interesse
      for (final step in steps) {
        final instruction = step['plain_instruction']?.toLowerCase() ?? '';
        
        // Tipos de via
        if (instruction.contains('rodovia') || instruction.contains('highway')) {
          features['road_types']['rodovia'] = (features['road_types']['rodovia'] ?? 0) + 1;
        }
        if (instruction.contains('avenida') || instruction.contains('avenue')) {
          features['road_types']['avenida'] = (features['road_types']['avenida'] ?? 0) + 1;
        }
        if (instruction.contains('rua') || instruction.contains('street')) {
          features['road_types']['rua'] = (features['road_types']['rua'] ?? 0) + 1;
        }
        
        // Estimar pedágios baseado em rodovias conhecidas
        if (instruction.contains('pedágio') || instruction.contains('praça')) {
          features['estimated_tolls']++;
        }
        
        // Detectar cidades/pontos importantes
        final cityPatterns = [
          'são paulo', 'rio de janeiro', 'belo horizonte', 'brasília',
          'salvador', 'fortaleza', 'recife', 'porto alegre', 'curitiba'
        ];
        
        for (final city in cityPatterns) {
        if (instruction.contains(city) && !(features['cities'] as List).contains(city)) {
          (features['cities'] as List).add(city);
          }
        }
      }

      // Estimar postos e áreas de descanso baseado na distância
      final distanceValue = route['legs']?[0]?['distance']?['value'];
      final distanceKm = distanceValue != null ? distanceValue / 1000.0 : 0.0;
      features['fuel_stations'] = (distanceKm / 50).round(); // A cada ~50km
      features['rest_areas'] = (distanceKm / 100).round(); // A cada ~100km

    } catch (e) {
      print('⚠️ Erro ao analisar características: $e');
    }

    return features;
  }

  // Calcular horários otimizados de partida
  List<Map<String, String>> _calculateOptimizedDepartureTimes(int baseDurationSeconds) {
    final now = DateTime.now();
    final times = <Map<String, String>>[];
    
    // Horários típicos de menor tráfego
    final optimalHours = [6, 10, 14, 20, 22]; // 6h, 10h, 14h, 20h, 22h
    
    for (final hour in optimalHours) {
      DateTime departureTime = DateTime(now.year, now.month, now.day, hour);
      
      // Se o horário já passou hoje, usar amanhã
      if (departureTime.isBefore(now)) {
        departureTime = departureTime.add(Duration(days: 1));
      }
      
      // final arrivalTime = departureTime.add(Duration(seconds: baseDurationSeconds)); // Removido pois não é usado
      
      // Estimar variação de tráfego baseada no horário
      double trafficMultiplier = 1.0;
      if (hour >= 7 && hour <= 9) trafficMultiplier = 1.4; // Rush matinal
      else if (hour >= 17 && hour <= 19) trafficMultiplier = 1.5; // Rush vespertino
      else if (hour >= 22 || hour <= 6) trafficMultiplier = 0.8; // Madrugada
      
      final estimatedDuration = (baseDurationSeconds * trafficMultiplier).round();
      final realArrivalTime = departureTime.add(Duration(seconds: estimatedDuration));
      
      String period = '';
      if (hour >= 6 && hour < 12) period = '🌅 Manhã';
      else if (hour >= 12 && hour < 18) period = '☀️ Tarde';
      else if (hour >= 18 && hour < 22) period = '🌆 Noite';
      else period = '🌙 Madrugada';
      
      String trafficStatus = '';
      if (trafficMultiplier <= 0.9) trafficStatus = '🟢 Ideal';
      else if (trafficMultiplier <= 1.1) trafficStatus = '🟡 Bom';
      else if (trafficMultiplier <= 1.3) trafficStatus = '🟠 Moderado';
      else trafficStatus = '🔴 Intenso';
      
      times.add({
        'departure': '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}',
        'arrival': '${realArrivalTime.hour.toString().padLeft(2, '0')}:${realArrivalTime.minute.toString().padLeft(2, '0')}',
        'duration': _formatDuration(estimatedDuration),
        'period': period,
        'traffic': trafficStatus,
        'day': departureTime.day == now.day ? 'Hoje' : 'Amanhã',
      });
    }
    
    return times;
  }

  // Detectar pedágios com mais detalhes
  Map<String, dynamic> _detectTollsAdvanced(Map<String, dynamic> routeData) {
    final tollInfo = {
      'has_tolls': false,
      'estimated_cost': 0.0,
      'toll_count': 0,
      'toll_roads': <String>[],
      'warnings': <String>[],
    };

    try {
      // Verificar warnings da API
      final warnings = List<String>.from(routeData['warnings'] ?? []);
      for (final warning in warnings) {
        final lowerWarning = warning.toLowerCase();
        if (lowerWarning.contains('toll') || lowerWarning.contains('pedágio')) {
          tollInfo['has_tolls'] = true;
          (tollInfo['warnings'] as List).add(warning);
        }
      }

      // Verificar nas características da rota
      final features = routeData['route_features'] as Map<String, dynamic>? ?? {};
      final estimatedTolls = features['estimated_tolls'] as int? ?? 0;
      
      if (estimatedTolls > 0) {
        tollInfo['has_tolls'] = true;
        tollInfo['toll_count'] = estimatedTolls;
        tollInfo['estimated_cost'] = estimatedTolls * 12.50; // Média R$ 12,50 por pedágio
      }

      // Verificar rodovias conhecidas por ter pedágios
      final highways = List<String>.from(features['highways'] ?? []);
      final tollRoads = ['BR-116', 'BR-381', 'BR-101', 'SP-348', 'SP-160'];
      
      for (final highway in highways) {
        if (tollRoads.any((toll) => highway.contains(toll.replaceAll('-', '')))) {
          tollInfo['has_tolls'] = true;
          (tollInfo['toll_roads'] as List).add(highway);
        }
      }

      // Se encontrou rodovias com pedágio mas não estimou custos, fazer estimativa baseada na distância
      if ((tollInfo['has_tolls'] as bool) && (tollInfo['estimated_cost'] as double) == 0.0) {
        final distanceKm = routeData['distance_km'] as double? ?? 0.0;
        final estimatedTollsByDistance = (distanceKm / 80).round(); // A cada ~80km uma praça
        tollInfo['toll_count'] = estimatedTollsByDistance;
        tollInfo['estimated_cost'] = estimatedTollsByDistance * 12.50;
      }

    } catch (e) {
      print('⚠️ Erro na análise avançada de pedágios: $e');
    }

    return tollInfo;
  }

  // Calcular consumo de combustível
  FuelConsumption _calculateFuelConsumption(double distanceKm, [double? customConsumption]) {
    final consumptionKmL = customConsumption ?? 
        (_selectedVehicleType == VehicleType.car ? 12.0 : 6.0);
    final litersNeeded = distanceKm / consumptionKmL;
    final estimatedCost = litersNeeded * 5.50; // R$ 5,50 por litro (estimativa)
    
    return FuelConsumption(
      distanceKm: distanceKm,
      consumptionKmL: consumptionKmL,
      litersNeeded: litersNeeded,
      estimatedCost: estimatedCost,
    );
  }

  // Construir card expansível da rota sobre o mapa
  Widget _buildExpandableRouteCard(ColorProvider colorProvider) {
    if (_routeDetails == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandRouteCard = !_expandRouteCard;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header do card - sempre visível
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone do tipo de veículo
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedVehicleType == VehicleType.car 
                          ? Icons.directions_car 
                          : Icons.local_shipping,
                      color: colorProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Informações principais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _routeDetails!.distanceText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorProvider.primaryColor,
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _routeDetails!.durationText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _routeDetails!.summary ?? 'Rota calculada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_linkedVehicle != null) ...[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.link, size: 12, color: Colors.blue[600]),
                              SizedBox(width: 4),
                              Text(
                                _linkedVehicle!.name ?? 'Veículo ${_linkedVehicle!.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Custo total e indicador de expansão
                  Column(
                    children: [
                      Text(
                        'R\$ ${_routeDetails!.fuelConsumption.estimatedCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Icon(
                        _expandRouteCard ? Icons.expand_less : Icons.expand_more,
                        color: colorProvider.primaryColor,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Detalhes expandidos
            if (_expandRouteCard) _buildRouteCardDetails(colorProvider),
          ],
        ),
      ),
    );
  }

  // Construir detalhes do card da rota
  Widget _buildRouteCardDetails(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          
          // Grid de informações
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildInfoItem(
                icon: Icons.local_gas_station,
                label: 'Combustível',
                value: '${_routeDetails!.fuelConsumption.litersNeeded.toStringAsFixed(1)}L',
                color: Colors.blue,
              ),
              _buildInfoItem(
                icon: _routeDetails!.hasTolls ? Icons.toll : Icons.money_off,
                label: 'Pedágios',
                value: _routeDetails!.hasTolls ? 'R\$ 12,00' : 'Livre',
                color: _routeDetails!.hasTolls ? Colors.red : Colors.green,
              ),
              _buildInfoItem(
                icon: Icons.speed,
                label: 'Velocidade Média',
                value: '${(_routeDetails!.distanceKm / (_routeDetails!.durationMinutes / 60)).toStringAsFixed(0)} km/h',
                color: Colors.orange,
              ),
              _buildInfoItem(
                icon: Icons.eco,
                label: 'Consumo',
                value: '${_routeDetails!.fuelConsumption.consumptionKmL.toStringAsFixed(1)} km/L',
                color: Colors.purple,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareRoute(),
                  icon: Icon(Icons.share, size: 16),
                  label: Text('Compartilhar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _saveToHistory(),
                  icon: Icon(Icons.save, size: 16),
                  label: Text('Salvar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para item de informação
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Salvar rota no histórico
  Future<void> _saveToHistory() async {
    if (_routeDetails == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('route_history') ?? [];
      
      final savedRoute = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'originAddress': _routeDetails!.originAddress,
        'destinationAddress': _routeDetails!.destinationAddress,
        'distanceText': _routeDetails!.distanceText,
        'durationText': _routeDetails!.durationText,
        'vehicleType': _selectedVehicleType == VehicleType.car ? 'car' : 'truck',
        'fuelCost': _routeDetails!.fuelConsumption.estimatedCost,
        'tollCost': _routeDetails!.hasTolls ? 12.0 : 0.0,
        'totalCost': _routeDetails!.fuelConsumption.estimatedCost + (_routeDetails!.hasTolls ? 12.0 : 0.0),
        'hasTolls': _routeDetails!.hasTolls,
        'trafficLevel': _routeDetails!.trafficLevel.toString(),
        'routeSummary': _routeDetails!.summary ?? 'Rota via rodovias principais',
        'calculatedAt': DateTime.now().toIso8601String(),
        'linkedVehicleId': _linkedVehicle?.id.toString(),
        'linkedVehicleName': _linkedVehicle?.name,
      };
      
      historyJson.insert(0, jsonEncode(savedRoute));
      
      // Manter apenas as últimas 50 rotas
      if (historyJson.length > 50) {
        historyJson.removeRange(50, historyJson.length);
      }
      
      await prefs.setStringList('route_history', historyJson);
      
      Fluttertoast.showToast(
        msg: 'Rota salva no histórico!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('❌ Erro ao salvar rota: $e');
      Fluttertoast.showToast(
        msg: 'Erro ao salvar rota',
        backgroundColor: Colors.red,
      );
    }
  }

  // Compartilhar rota
  Future<void> _shareRoute() async {
    // Implementar compartilhamento (WhatsApp, etc.)
    Fluttertoast.showToast(
      msg: 'Funcionalidade em desenvolvimento',
      backgroundColor: Colors.orange,
    );
  }

  // Loading indicator
  Widget _buildLoadingIndicator(ColorProvider colorProvider) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: colorProvider.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Calculando melhor rota...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Obter cor da rota baseada no tráfego
  Color _getRouteColor(TrafficLevel level) {
    switch (level) {
      case TrafficLevel.light:
        return Colors.green;
      case TrafficLevel.moderate:
        return Colors.yellow.shade700;
      case TrafficLevel.heavy:
        return Colors.orange;
      case TrafficLevel.severe:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Formatar duração em texto legível
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  // Compartilhar rota no WhatsApp
  Future<void> _shareRouteOnWhatsApp() async {
    if (_routeDetails == null) {
      Fluttertoast.showToast(
        msg: 'Calcule uma rota primeiro',
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final route = _routeDetails!;
      
      // Montar mensagem SUPER detalhada
      final message = '''
🗺️ *ROTA COMPLETA CALCULADA* 🗺️

📍 *Origem:* ${route.originAddress}
🎯 *Destino:* ${route.destinationAddress}
🛣️ *Via:* ${route.routeSummary}

═══════════════════════════
📊 *INFORMAÇÕES PRINCIPAIS*
═══════════════════════════

📏 *Distância:* ${route.distanceText}
⏰ *Tempo Carro:* ${route.durationInTrafficText ?? _formatDuration(route.carDuration)}${route.hasTrafficDelay ? ' (+${route.delayText} por tráfego)' : ''}
🚛 *Tempo Caminhão:* ${_formatDuration(route.truckDuration)}

🚦 *Condições de Tráfego:*
${route.trafficDescription}
${route.hasTrafficDelay ? '⏱️ Atraso estimado: ${route.delayText}' : '✅ Sem atrasos significativos'}

💰 *Pedágios e Custos:*
${route.hasTolls ? '⚠️ POSSUI PEDÁGIOS' : '✅ ROTA SEM PEDÁGIOS'}
${route.hasTolls ? '• ${route.tollCount} praças estimadas' : ''}
${route.hasTolls ? '• Custo estimado: R\$ ${route.estimatedTollCost.toStringAsFixed(2)}' : ''}
${route.tollRoads.isNotEmpty ? '• Rodovias com pedágio: ${route.tollRoads.join(', ')}' : ''}

⛽ *Combustível:*
• Consumo estimado: ${route.fuelConsumption.litersNeeded.toStringAsFixed(1)}L
• Custo combustível: R\$ ${route.fuelConsumption.estimatedCost.toStringAsFixed(2)}
• Base cálculo: ${route.fuelConsumption.consumptionKmL}km/L
• *CUSTO TOTAL VIAGEM:* R\$ ${(route.fuelConsumption.estimatedCost + route.estimatedTollCost).toStringAsFixed(2)}

${route.highways.isNotEmpty ? '''
🛣️ *Rodovias Principais:*
${route.highways.map((h) => '• $h').join('\n')}
''' : ''}

${route.hasAlternatives ? '''
═══════════════════════════
🔄 *ROTAS ALTERNATIVAS* (${route.alternativeRoutes.length})
═══════════════════════════
${route.alternativeRoutes.map((alt) => '🛣️ ${alt['summary']}: ${alt['distance_text']} - ${alt['duration_text']}').take(2).join('\n')}
${route.alternativeRoutes.length > 2 ? '... e mais ${route.alternativeRoutes.length - 2} opções' : ''}
''' : ''}

${route.optimizedDepartureTimes.isNotEmpty ? '''
═══════════════════════════
⏰ *HORÁRIOS RECOMENDADOS*
═══════════════════════════
${route.optimizedDepartureTimes.take(3).map((time) => '${time['period']} (${time['day']}): ${time['departure']} → ${time['arrival']} (${time['duration']}) ${time['traffic']}').join('\n')}
''' : ''}

${route.warnings.isNotEmpty ? '''
⚠️ *AVISOS IMPORTANTES:*
${route.warnings.map((w) => '• $w').join('\n')}
''' : ''}

🏢 *Serviços na Rota:*
• ⛽ Postos estimados: ~${route.routeFeatures['fuel_stations'] ?? 0}
• 🛣️ Áreas de descanso: ~${route.routeFeatures['rest_areas'] ?? 0}

═══════════════════════════
🔗 *NAVEGAÇÃO*
═══════════════════════════
*Abrir no Google Maps:*
https://www.google.com/maps/dir/${_userPosition!.latitude},${_userPosition!.longitude}/${_destinationCoords!.latitude},${_destinationCoords!.longitude}

_Relatório completo gerado pelo U-Connect 📱_
_Dados atualizados com tráfego em tempo real_
      '''.trim();

      // Codificar mensagem para URL
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/?text=$encodedMessage';

      // Abrir WhatsApp
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Copiar para clipboard como fallback
        await Clipboard.setData(ClipboardData(text: message));
        Fluttertoast.showToast(
          msg: 'Rota copiada para área de transferência',
          backgroundColor: Colors.green,
        );
      }

    } catch (e) {
      print('❌ Erro ao compartilhar rota: $e');
      Fluttertoast.showToast(
        msg: 'Erro ao compartilhar: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Método removido pois já é tratado em RouteDetails.trafficDescription

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, _) {
        return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: StandardHeader(
              title: 'Roteirizador',
              icon: Icons.navigation,
            ),
            bottomNavigationBar: const MainBottomNav(currentIndex: -1),
            body: Column(
              children: [
                // Campo de busca do destino com autocomplete
                Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Campo de entrada do destino
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.search, color: colorProvider.primaryColor),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _destinationController,
                                    focusNode: _destinationFocus,
                                    decoration: InputDecoration(
                                      hintText: 'Para onde você quer ir?',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey[500]),
                                    ),
                                    textInputAction: TextInputAction.search,
                                    onChanged: _searchAddressSuggestions,
                                    onSubmitted: (_) => _searchDestination(),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _isLoadingRoute ? null : _searchDestination,
                                  icon: _isLoadingRoute 
                                    ? SizedBox(
                                        width: 16, 
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Icon(Icons.directions, size: 18),
                                  label: Text('Ir', style: TextStyle(fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorProvider.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: Size(60, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Lista de sugestões de endereços
                            if (_showSuggestions && _addressSuggestions.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _addressSuggestions.length > 5 ? 5 : _addressSuggestions.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                                  itemBuilder: (context, index) {
                                    final suggestion = _addressSuggestions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(Icons.place, color: Colors.grey[600], size: 20),
                                      title: Text(
                                        suggestion.description,
                                        style: TextStyle(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () => _selectAddressSuggestion(suggestion),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Selecionadores de veículo e tipo
                      Container(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            // Selecionador de veículo
                            Expanded(
                              flex: 2,
                              child: Consumer<ObjectStore>(
                                builder: (context, objectStore, _) {
                                  return DropdownButtonFormField<deviceItems>(
                                    decoration: InputDecoration(
                                      labelText: 'Vincular veículo',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      labelStyle: TextStyle(fontSize: 12),
                                    ),
                                    value: _linkedVehicle,
                                    items: [
                                      DropdownMenuItem<deviceItems>(
                                        value: null,
                                        child: Text('Nenhum', style: TextStyle(fontSize: 12)),
                                      ),
                                      ...objectStore.objects.map((vehicle) {
                                        return DropdownMenuItem<deviceItems>(
                                          value: vehicle,
                                          child: Text(
                                            vehicle.name ?? 'Veículo ${vehicle.id}',
                                            style: TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (vehicle) {
                                      setState(() {
                                        _linkedVehicle = vehicle;
                                      });
                                    },
                                    isExpanded: true,
                                  );
                                },
                              ),
                            ),
                            
                            SizedBox(width: 12),
                            
                            // Seletor de tipo simplificado
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedVehicleType = VehicleType.car;
                                        });
                                        if (_routeDetails != null) {
                                          _calculateRoute();
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: _selectedVehicleType == VehicleType.car 
                                              ? colorProvider.primaryColor 
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _selectedVehicleType == VehicleType.car 
                                                ? colorProvider.primaryColor 
                                                : Colors.grey[400]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.directions_car, 
                                              size: 14,
                                              color: _selectedVehicleType == VehicleType.car 
                                                  ? Colors.white 
                                                  : Colors.grey[600],
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Carro',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: _selectedVehicleType == VehicleType.car 
                                                    ? Colors.white 
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedVehicleType = VehicleType.truck;
                                        });
                                        if (_routeDetails != null) {
                                          _calculateRoute();
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: _selectedVehicleType == VehicleType.truck 
                                              ? colorProvider.primaryColor 
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _selectedVehicleType == VehicleType.truck 
                                                ? colorProvider.primaryColor 
                                                : Colors.grey[400]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.local_shipping, 
                                              size: 14,
                                              color: _selectedVehicleType == VehicleType.truck 
                                                  ? Colors.white 
                                                  : Colors.grey[600],
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Truck',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: _selectedVehicleType == VehicleType.truck 
                                                    ? Colors.white 
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mapa principal
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: _userPosition != null
                              ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                              : const LatLng(-23.5489, -46.6388),
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapType: MapType.normal,
                        trafficEnabled: true,
                      ),
                      
                      // Card expansível da rota
                      if (_showRouteDetails && _routeDetails != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: _buildExpandableRouteCard(colorProvider),
                        ),
                      
                      // Loading indicator
                      if (_isLoadingRoute) _buildLoadingIndicator(colorProvider),
                    ],
                  ),
                ),
                
                // Botões de ação na parte inferior
                if (_showRouteDetails)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareRouteOnWhatsApp,
                            icon: Icon(Icons.share, size: 18),
                            label: Text('Compartilhar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_routeDetails != null && _routeDetails!.bounds != null) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngBounds(_routeDetails!.bounds!, 100),
                                );
                              }
                            },
                            icon: Icon(Icons.center_focus_strong, size: 18),
                            label: Text('Centralizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: colorProvider.primaryColor,
                              side: BorderSide(color: colorProvider.primaryColor),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        );
      },
    );
  }

  // Estado vazio com mapa
  Widget _buildEmptyStateWithMap(ColorProvider colorProvider) {
    return Stack(
      children: [
        // Mapa de fundo
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : const LatLng(-23.5489, -46.6388),
            zoom: 14.0,
          ),
          markers: _markers,
          polylines: _polylines,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          trafficEnabled: true,
        ),
        
        // Mensagem de estado vazio
        Center(
          child: Container(
            margin: EdgeInsets.all(32),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation,
                  size: 64,
                  color: colorProvider.primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Calcule sua primeira rota',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorProvider.primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Digite um destino acima para começar a\ncriar seu histórico de rotas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Loading indicator
        if (_isLoadingRoute) _buildLoadingIndicator(colorProvider),
      ],
    );
  }

  // Lista de rotas com mapa
  Widget _buildRouteHistoryWithMap(ColorProvider colorProvider) {
    return Column(
      children: [
        // Mapa (metade superior)
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _userPosition != null
                        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                        : const LatLng(-23.5489, -46.6388),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  trafficEnabled: true,
                ),
                
                // Detalhes da rota atual
                if (_showRouteDetails && _routeDetails != null && _expandedRouteIndex == null)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: _buildCompactRouteCard(colorProvider),
                  ),
                
                // Loading indicator
                if (_isLoadingRoute) _buildLoadingIndicator(colorProvider),
              ],
            ),
          ),
        ),
        
        // Lista de rotas (metade inferior)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[50],
            child: Column(
              children: [
                // Header da lista
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: colorProvider.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Histórico de Rotas (${_routeHistory.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                      Spacer(),
                      if (_routeHistory.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _routeHistory.clear();
                              _expandedRouteIndex = null;
                              _markers.clear();
                              _polylines.clear();
                            });
                            Fluttertoast.showToast(
                              msg: 'Histórico limpo',
                              backgroundColor: Colors.green,
                            );
                          },
                          icon: Icon(Icons.clear_all, size: 16, color: Colors.red[600]),
                          label: Text(
                            'Limpar',
                            style: TextStyle(fontSize: 12, color: Colors.red[600]),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Lista de rotas
                Expanded(
                  child: _routeHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.route, size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Nenhuma rota calculada ainda',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _routeHistory.length,
                          itemBuilder: (context, index) {
                            return _buildRouteHistoryCard(
                              colorProvider,
                              _routeHistory[index],
                              index,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Card compacto da rota atual
  Widget _buildCompactRouteCard(ColorProvider colorProvider) {
    final route = _routeDetails!;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.navigation, color: colorProvider.primaryColor, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.distanceText} • ${_formatDuration(_selectedVehicleType == VehicleType.car ? route.carDuration : route.truckDuration)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorProvider.primaryColor,
                  ),
                ),
                Text(
                  route.destinationAddress,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 16,
          ),
        ],
      ),
    );
  }

  // Card do histórico de rotas
  Widget _buildRouteHistoryCard(ColorProvider colorProvider, SavedRoute savedRoute, int index) {
    final route = savedRoute.routeDetails;
    final isExpanded = _expandedRouteIndex == index;
    final vehicleDuration = savedRoute.vehicleType == VehicleType.car 
        ? route.carDuration 
        : route.truckDuration;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do card (sempre visível)
          InkWell(
            onTap: () => _toggleRouteExpansion(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ícone do tipo de veículo
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      savedRoute.vehicleType == VehicleType.car 
                          ? Icons.directions_car 
                          : Icons.local_shipping,
                      color: colorProvider.primaryColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Informações da rota
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              route.distanceText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorProvider.primaryColor,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatDuration(vehicleDuration),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          route.destinationAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 10, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              _formatDateTime(savedRoute.calculatedAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Ações
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _shareRouteFromHistory(savedRoute),
                        icon: Icon(Icons.share, size: 18, color: Colors.blue[600]),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        onPressed: () => _deleteRoute(index),
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[600]),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colorProvider.primaryColor,
                        size: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Detalhes expandidos
          if (isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: _buildExpandedRouteDetails(colorProvider, route, savedRoute.vehicleType),
            ),
        ],
      ),
    );
  }

  // Detalhes expandidos da rota
  Widget _buildExpandedRouteDetails(ColorProvider colorProvider, RouteDetails route, VehicleType vehicleType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        
        // Grid de informações
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildDetailItem(
              icon: Icons.directions_car,
              label: 'Carro',
              value: _formatDuration(route.carDuration),
              color: Colors.green,
            ),
            _buildDetailItem(
              icon: Icons.local_shipping,
              label: 'Caminhão',
              value: _formatDuration(route.truckDuration),
              color: Colors.orange,
            ),
            _buildDetailItem(
              icon: route.hasTolls ? Icons.toll : Icons.money_off,
              label: 'Pedágios',
              value: route.hasTolls ? 'R\$ ${route.estimatedTollCost.toStringAsFixed(0)}' : 'Livre',
              color: route.hasTolls ? Colors.red : Colors.green,
            ),
            _buildDetailItem(
              icon: Icons.local_gas_station,
              label: 'Combustível',
              value: 'R\$ ${route.fuelConsumption.estimatedCost.toStringAsFixed(2)}',
              color: Colors.blue,
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Botões de ação
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareRouteFromHistory(SavedRoute(
                  id: '',
                  routeDetails: route,
                  originCoords: LatLng(0, 0),
                  destinationCoords: LatLng(0, 0),
                  vehicleType: vehicleType,
                  calculatedAt: DateTime.now(),
                )),
                icon: Icon(Icons.share, size: 16),
                label: Text('Compartilhar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (route.bounds != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(route.bounds!, 50),
                    );
                  }
                },
                icon: Icon(Icons.center_focus_strong, size: 16),
                label: Text('Ver no Mapa', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Formatar data e hora
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }

  // Compartilhar rota do histórico
  Future<void> _shareRouteFromHistory(SavedRoute savedRoute) async {
    // Usar o mesmo método de compartilhar, mas com dados da rota salva
    final tempRouteDetails = _routeDetails;
    final tempDestinationCoords = _destinationCoords;
    
    _routeDetails = savedRoute.routeDetails;
    _destinationCoords = savedRoute.destinationCoords;
    
    await _shareRouteOnWhatsApp();
    
    // Restaurar dados originais
    _routeDetails = tempRouteDetails;
    _destinationCoords = tempDestinationCoords;
  }

  // Método _buildRouteDetailsCard removido - usando novos métodos de histórico

  // Método _buildExpandableSection removido - não usado mais

  // Métodos removidos - não usados na nova implementação de histórico

  Widget _buildLoadingIndicator(ColorProvider colorProvider) {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colorProvider.primaryColor),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Calculando rota detalhada...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de cores de tráfego removidos - não usados mais
}

// Classes de dados expandidas para organizar as informações
class RouteDetails {
  // Dados básicos
  final String distanceText;
  final double distanceKm;
  final int carDuration;
  final int truckDuration;
  final List<LatLng> polylinePoints;
  final LatLngBounds? bounds;
  final String originAddress;
  final String destinationAddress;
  
  // Dados de tráfego expandidos
  final TrafficLevel trafficLevel;
  final String trafficDescription;
  final int delaySeconds;
  final int? durationInTrafficSeconds;
  final String? durationInTrafficText;
  
  // Pedágios detalhados
  final bool hasTolls;
  final double estimatedTollCost;
  final int tollCount;
  final List<String> tollRoads;
  
  // Combustível
  FuelConsumption fuelConsumption;
  
  // Metadados da rota
  final String routeSummary;
  final List<String> warnings;
  final Map<String, dynamic> routeFeatures;
  
  // Rotas alternativas
  final List<Map<String, dynamic>> alternativeRoutes;
  final int totalRoutesFound;
  
  // Horários otimizados
  final List<Map<String, String>> optimizedDepartureTimes;
  
  // Características extras
  final bool hasRestrictions;
  final List<Map<String, dynamic>> detailedSteps;

  RouteDetails({
    // Dados básicos
    required this.distanceText,
    required this.distanceKm,
    required this.carDuration,
    required this.truckDuration,
    required this.polylinePoints,
    required this.bounds,
    required this.originAddress,
    required this.destinationAddress,
    
    // Dados de tráfego
    required this.trafficLevel,
    required this.trafficDescription,
    required this.delaySeconds,
    this.durationInTrafficSeconds,
    this.durationInTrafficText,
    
    // Pedágios
    required this.hasTolls,
    required this.estimatedTollCost,
    required this.tollCount,
    required this.tollRoads,
    
    // Combustível
    required this.fuelConsumption,
    
    // Metadados
    required this.routeSummary,
    required this.warnings,
    required this.routeFeatures,
    
    // Alternativas
    required this.alternativeRoutes,
    required this.totalRoutesFound,
    
    // Horários
    required this.optimizedDepartureTimes,
    
    // Extras
    required this.hasRestrictions,
    required this.detailedSteps,
  });
  
  // Getters convenientes
  bool get hasTrafficDelay => delaySeconds > 0;
  String get delayText => _formatDurationFromSeconds(delaySeconds);
  bool get hasAlternatives => alternativeRoutes.isNotEmpty;
  int get highwayCount => (routeFeatures['highways'] as List?)?.length ?? 0;
  List<String> get highways => List<String>.from(routeFeatures['highways'] ?? []);
  
  static String _formatDurationFromSeconds(int seconds) {
    if (seconds <= 0) return '0min';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

class FuelConsumption {
  final double distanceKm;
  final double consumptionKmL;
  final double litersNeeded;
  final double estimatedCost;

  FuelConsumption({
    required this.distanceKm,
    required this.consumptionKmL,
    required this.litersNeeded,
    required this.estimatedCost,
  });
}

enum VehicleType { car, truck }

enum TrafficLevel { unknown, light, moderate, heavy, severe }

// Classe para sugestões de endereço do autocomplete
class PlacePrediction {
  final String placeId;
  final String description;
  final List<String> types;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.types,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

// Classe para armazenar rotas calculadas no histórico
class SavedRoute {
  final String id;
  final RouteDetails routeDetails;
  final LatLng originCoords;
  final LatLng destinationCoords;
  final VehicleType vehicleType;
  final DateTime calculatedAt;

  SavedRoute({
    required this.id,
    required this.routeDetails,
    required this.originCoords,
    required this.destinationCoords,
    required this.vehicleType,
    required this.calculatedAt,
  });
}