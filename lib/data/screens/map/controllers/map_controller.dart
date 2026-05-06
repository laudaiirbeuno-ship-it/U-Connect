import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/screens/map/services/map_services.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:uconnect/data/model/device_latest_response.dart';

class MapController extends ChangeNotifier {
  GoogleMapController? _mapController;
  Set<Circle> _circles = {}; // Círculos de âncora
  Set<Polyline> _polylines = {}; // Polylines para trilhas e rotas
  Map<String, AnchorInfo> _activeAnchors = {}; // deviceId -> AnchorInfo
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  deviceItems? _selectedVehicle;
  bool _isLoading = false;
  bool _showVehicleCard = false;
  bool _showTrail = false;
  bool _showGeofences = false;
  bool _showPOI = false;
  bool _showTraffic = false;
  bool _is3DView = false;
  MapType _mapType = MapType.normal;
  double _currentZoom = 14.0;
  double _currentTilt = 0.0;
  LatLngBounds? _bounds;


  GoogleMapController? get mapController => _mapController;
  Set<Circle> get circles => _circles;
  Set<Polyline> get polylines => _polylines; // Polylines para trilhas e rotas
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  deviceItems? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  bool get showVehicleCard => _showVehicleCard;
  bool get showTrail => _showTrail;
  bool get showGeofences => _showGeofences;
  bool get showPOI => _showPOI;
  bool get showTraffic => _showTraffic;
  bool get is3DView => _is3DView;
  MapType get mapType => _mapType;
  double get currentZoom => _currentZoom;
  double get currentTilt => _currentTilt;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSelectedVehicle(deviceItems? vehicle) {
    _selectedVehicle = vehicle;
    _showVehicleCard = vehicle != null;
    
    // Atualizar trilha se estiver ativa e houver veículo selecionado
    if (_showTrail && vehicle != null) {
      _loadVehicleTrail(vehicle.id);
    } else if (!_showTrail || vehicle == null) {
      // Remover trilha quando não houver veículo ou trilha estiver desativada
      _polylines.removeWhere((polyline) => polyline.polylineId.value.startsWith('trail_'));
    }
    
    if (vehicle != null && vehicle.lat != null && vehicle.lng != null) {
      // Centralizar no veículo com zoom mais próximo, mantendo inclinação 3D se ativa
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng) ?? LatLng(0.0, 0.0),
            zoom: 16.0, // Zoom mais próximo para ver o endereço exato
            tilt: _currentTilt, // Manter inclinação 3D
            bearing: 0.0,
          ),
        ),
      );
    }
    notifyListeners();
  }

  void closeVehicleCard() {
    _showVehicleCard = false;
    _selectedVehicle = null;
    notifyListeners();
  }

  void toggleTrail() {
    _showTrail = !_showTrail;
    if (!_showTrail) {
      // Remover trilha quando desativar
      _polylines.removeWhere((polyline) => polyline.polylineId.value.startsWith('trail_'));
    } else if (_selectedVehicle != null) {
      // Carregar trilha quando ativar e houver veículo selecionado
      _loadVehicleTrail(_selectedVehicle!.id);
    }
    notifyListeners();
  }

  // Carregar rastro do veículo usando get_devices_latest (campo tail)
  Future<void> _loadVehicleTrail(int deviceId) async {
    try {
      print('🛤️ Carregando rastro para veículo ID: $deviceId');
      
      // Remover trilha anterior
      _polylines.removeWhere((polyline) => polyline.polylineId.value.startsWith('trail_'));
      
      // Buscar dados atualizados usando get_devices_latest
      final latestData = await gpsapis.getDevicesLatest();
      
      if (latestData != null && latestData.items.isNotEmpty) {
        // Encontrar o veículo específico
        DeviceLatestItem? vehicle;
        try {
          vehicle = latestData.items.firstWhere(
            (v) => v.id == deviceId,
          );
        } catch (e) {
          print('⚠️ Veículo ID $deviceId não encontrado, usando primeiro veículo disponível');
          vehicle = latestData.items.first;
        }
        
        // Obter o rastro (tail) do veículo
        final tail = vehicle.parsedTail;
        
        if (tail.isNotEmpty) {
            print('✅ Rastro encontrado com ${tail.length} pontos');
            
            // Converter coordenadas do tail para LatLng
            List<LatLng> trailPoints = tail.map((coord) {
              return LatLng(coord.lat, coord.lng);
            }).toList();
            
            // Obter cor do rastro do device_data
            final tailColor = vehicle.deviceData.tailColor;
            Color polylineColor;
            try {
              String hex = tailColor.replaceAll('#', '');
              polylineColor = Color(int.parse('FF$hex', radix: 16));
            } catch (e) {
              polylineColor = Colors.blue; // Cor padrão se falhar
            }
            
            if (trailPoints.length > 1) {
              final polyline = Polyline(
                polylineId: PolylineId('trail_$deviceId'),
                points: trailPoints,
                color: polylineColor,
                width: 4,
                patterns: [],
              );
              
              _polylines = Set<Polyline>.from(_polylines)..add(polyline);
              print('✅ Rastro adicionado ao mapa com ${trailPoints.length} pontos');
              notifyListeners();
          } else {
            print('⚠️ Rastro tem menos de 2 pontos, não é possível desenhar');
          }
        } else {
          print('⚠️ Rastro vazio para o veículo ID: $deviceId, tentando histórico');
          // Tentar método alternativo usando histórico se tail estiver vazio
          await _loadVehicleTrailFromHistory(deviceId.toString());
        }
      } else {
        print('⚠️ Nenhum dado retornado da API get_devices_latest, tentando histórico');
        // Tentar método alternativo usando histórico
        await _loadVehicleTrailFromHistory(deviceId.toString());
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar rastro: $e');
      print('❌ Stack trace: $stackTrace');
      // Tentar método alternativo usando histórico em caso de erro
      await _loadVehicleTrailFromHistory(deviceId.toString());
    }
  }

  // Método alternativo: carregar trilha usando histórico (fallback)
  Future<void> _loadVehicleTrailFromHistory(String deviceId) async {
    try {
      print('🛤️ Tentando carregar rastro do histórico (método alternativo)');
      
      // Buscar histórico das últimas 24 horas
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      
      final fromDate = yesterday.toIso8601String().split('T')[0];
      final fromTime = '00:00';
      final toDate = now.toIso8601String().split('T')[0];
      final toTime = '23:59';
      
      final history = await gpsapis.getHistorynew(
        deviceId,
        fromDate,
        fromTime,
        toDate,
        toTime,
      );

      if (history != null && history.items != null && history.items!.isNotEmpty) {
        List<LatLng> trailPoints = [];
        
        for (var item in history.items!) {
          try {
            // Os items são dynamic, então acessamos como Map
            if (item is Map) {
              final lat = item['lat'];
              final lng = item['lng'];
              
              if (lat != null && lng != null) {
                final position = CoordinateUtils.toLatLng(lat, lng);
                if (position != null && position.latitude != 0 && position.longitude != 0) {
                  trailPoints.add(position);
                }
              }
            }
          } catch (e) {
            // Ignorar itens inválidos
            continue;
          }
        }

        if (trailPoints.length > 1) {
          final polyline = Polyline(
            polylineId: PolylineId('trail_$deviceId'),
            points: trailPoints,
            color: Colors.blue,
            width: 3,
            patterns: [],
          );
          
          _polylines = Set<Polyline>.from(_polylines)..add(polyline);
          print('✅ Rastro carregado do histórico com ${trailPoints.length} pontos');
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar trilha do histórico: $e');
    }
  }

  // Adicionar polyline de rota usando RouteService
  void addRoutePolyline(List<LatLng> routePoints) {
    // Remover rota anterior
    _polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');
    
    if (routePoints.isNotEmpty) {
      // Criar RouteData temporário para usar o serviço
      final routeData = RouteData(
        coordinates: routePoints,
        polylinePoints: '',
        distance: 0,
        duration: 0,
        durationInTraffic: 0,
        bounds: LatLngBounds(southwest: routePoints.first, northeast: routePoints.last),
        steps: [],
        addresses: [],
        warnings: [],
        copyrights: '',
        travelMode: TravelMode.driving,
      );

      // Usar o RouteService para criar a polyline
      final polyline = RouteService.createPolylineFromRoute(
        routeData,
        color: Colors.green,
        width: 5,
        polylineId: 'route',
      );
      
      _polylines = Set<Polyline>.from(_polylines)..add(polyline);
      notifyListeners();
    }
  }

  // Adicionar rota completa usando RouteService
  Future<void> addCompleteRoute(LatLng origin, LatLng destination) async {
    try {
      print('🛣️ Calculando rota completa usando RouteService...');

      final result = await RouteService.calculateRoute(
        origin: origin,
        destination: destination,
        travelMode: TravelMode.driving,
      );

      if (result.success && result.route != null) {
        // Remover rota anterior
        _polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');

        // Adicionar nova rota
        final polyline = RouteService.createPolylineFromRoute(
          result.route!,
          color: Colors.blue,
          width: 6,
          polylineId: 'route',
        );

        _polylines = Set<Polyline>.from(_polylines)..add(polyline);

        // Centralizar mapa na rota
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(result.route!.bounds, 100.0),
          );
        }

        print('✅ Rota completa adicionada: ${result.route!.distanceText} - ${result.route!.durationText}');
      } else {
        print('❌ Falha ao calcular rota: ${result.message}');
      }

    } catch (e) {
      print('❌ Erro ao adicionar rota completa: $e');
    }
    
    notifyListeners();
  }

  // Remover polyline de rota
  void clearRoutePolyline() {
    _polylines.removeWhere((polyline) => polyline.polylineId.value == 'route');
    notifyListeners();
  }

  void toggleGeofences() {
    _showGeofences = !_showGeofences;
    notifyListeners();
  }

  void togglePOI() {
    // Se está ativando POI, verificar se há veículo selecionado
    if (!_showPOI) {
      if (_selectedVehicle == null || _selectedVehicle!.lat == null || _selectedVehicle!.lng == null) {
        print('⚠️ Nenhum veículo selecionado para buscar POIs');
        // Não ativar POI se não houver veículo selecionado
        return;
      }
      // Carregar POIs ao redor do veículo selecionado
      _loadNearbyPOIs();
    }
    
    _showPOI = !_showPOI;
    notifyListeners();
  }

  // Carregar pontos de interesse ao redor do veículo selecionado
  Future<void> _loadNearbyPOIs() async {
    try {
      if (_mapController == null || _selectedVehicle == null) {
        print('❌ MapController ou veículo selecionado não disponível');
        return;
      }

      if (_selectedVehicle!.lat == null || _selectedVehicle!.lng == null) {
        print('❌ Coordenadas do veículo selecionado não disponíveis');
        return;
      }

      print('📍 Carregando POIs ao redor do veículo selecionado: ${_selectedVehicle!.name}');

      // Usar posição do veículo selecionado como centro
      final vehiclePosition = CoordinateUtils.toLatLng(_selectedVehicle!.lat, _selectedVehicle!.lng);
      if (vehiclePosition == null) return;

      print('🎯 Posição do veículo: ${vehiclePosition.latitude}, ${vehiclePosition.longitude}');

      // Definir raio fixo de 2km ao redor do veículo
      const double radius = 2000.0; // 2km

      print('📏 Raio de busca: ${radius.toInt()}m');

      // Buscar POIs usando o serviço
      final poiMarkers = await POIService.getNearbyPOIs(
        center: vehiclePosition,
        radius: radius,
        maxResults: 30, // Aumentado para mais resultados
      );

      print('✅ ${poiMarkers.length} POIs carregados ao redor do veículo ${_selectedVehicle!.name}');

    } catch (e) {
      print('❌ Erro ao carregar POIs: $e');
    }
    notifyListeners();
  }

  void toggleTraffic() {
    _showTraffic = !_showTraffic;
    if (_showTraffic) {
      _loadTrafficInfo();
    }
    notifyListeners();
  }

  // Carregar informações de tráfego usando TrafficService
  Future<void> _loadTrafficInfo() async {
    try {
      if (_mapController == null) return;

      print('🚦 Carregando informações de tráfego usando TrafficService...');

      // Obter região visível do mapa
      final visibleRegion = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
        (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
      );

      // Criar alguns pontos de teste na região visível para verificar tráfego
      final testPoints = [
        center,
        LatLng(center.latitude + 0.01, center.longitude),
        LatLng(center.latitude, center.longitude + 0.01),
        LatLng(center.latitude - 0.01, center.longitude),
        LatLng(center.latitude, center.longitude - 0.01),
      ];

      // Obter condições de tráfego em tempo real
      final trafficConditions = await TrafficService.getRealTimeTrafficConditions(testPoints);

      print('✅ Informações de tráfego carregadas para ${trafficConditions.length} pontos');

      // Exibir informações de tráfego no console (pode ser usado para UI futura)
      for (var condition in trafficConditions) {
        print('📍 ${condition.location.latitude}, ${condition.location.longitude}: ${condition.description}');
      }

    } catch (e) {
      print('❌ Erro ao carregar informações de tráfego: $e');
    }
  }

  void toggleMapType() {
    // Ciclar entre os tipos: normal -> satellite -> hybrid -> terrain -> normal
    switch (_mapType) {
      case MapType.normal:
        _mapType = MapType.satellite;
        break;
      case MapType.satellite:
        _mapType = MapType.hybrid;
        break;
      case MapType.hybrid:
        _mapType = MapType.terrain;
        break;
      case MapType.terrain:
        _mapType = MapType.normal;
        break;
      default:
        _mapType = MapType.normal;
    }
    notifyListeners();
  }

  void toggle3DView() {
    _is3DView = !_is3DView;
    _currentTilt = _is3DView ? 60.0 : 0.0; // 60 graus de inclinação para 3D
    
    print('🎯 Vista 3D ${_is3DView ? "ATIVADA" : "DESATIVADA"} - Tilt: $_currentTilt°');
    
    if (_mapController != null) {
      // Obter posição atual da câmera antes de aplicar tilt
      _mapController!.getVisibleRegion().then((visibleRegion) {
        // Usar o centro da região visível atual
        final center = LatLng(
          (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
          (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
        );
        
        // Aplicar tilt mantendo a posição atual e zoom
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: center,
              zoom: _currentZoom,
              tilt: _currentTilt,
              bearing: 0.0,
            ),
          ),
        );
      }).catchError((error) {
        // Se falhar, usar posição padrão ou do veículo selecionado
        final target = _selectedVehicle != null 
          ? (CoordinateUtils.toLatLng(_selectedVehicle!.lat, _selectedVehicle!.lng) ?? LatLng(-23.5505, -46.6333))
          : LatLng(-23.5505, -46.6333);
        
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: target,
              zoom: _currentZoom,
              tilt: _currentTilt,
              bearing: 0.0,
            ),
          ),
        );
      });
    }
    
    // IMPORTANTE: Notificar listeners para garantir que os marcadores sejam re-renderizados
    notifyListeners();
  }

  void setZoom(double zoom) {
    _currentZoom = zoom;
    notifyListeners();
  }

  // Atualizar zoom sem notificar listeners (evita rebuilds desnecessários)
  void setZoomSilently(double zoom) {
    _currentZoom = zoom;
    // Não chamar notifyListeners() para evitar rebuilds constantes
  }

  // Atualizar tilt sem notificar listeners
  void setTiltSilently(double tilt) {
    _currentTilt = tilt;
    _is3DView = tilt > 30.0; // Considerar 3D se tilt > 30°
    // Não chamar notifyListeners() para evitar rebuilds constantes
  }

  void zoomIn() {
    if (_mapController != null && _currentZoom < 20) {
      _currentZoom += 1;
      // Usar zoomTo que mantém automaticamente a inclinação atual
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_mapController != null && _currentZoom > 3) {
      _currentZoom -= 1;
      // Usar zoomTo que mantém automaticamente a inclinação atual
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
      notifyListeners();
    }
  }

  void centerOnAllVehicles(List<deviceItems> vehicles) {
    if (vehicles.isEmpty) return;

    final validVehicles = vehicles.where((v) => 
      v.lat != null && v.lng != null && 
      v.lat != 0 && v.lng != 0
    ).toList();

    if (validVehicles.isEmpty) return;

    if (validVehicles.length == 1) {
      final vehicle = validVehicles.first;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng) ?? LatLng(0.0, 0.0),
            zoom: 14.0,
            tilt: _currentTilt, // Manter inclinação 3D
            bearing: 0.0,
          ),
        ),
      );
    } else {
      // Calcular bounds para múltiplos veículos
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (var vehicle in validVehicles) {
        final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
        if (position != null) {
          if (position.latitude < minLat) minLat = position.latitude;
          if (position.latitude > maxLat) maxLat = position.latitude;
          if (position.longitude < minLng) minLng = position.longitude;
          if (position.longitude > maxLng) maxLng = position.longitude;
        }
      }

      _bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_bounds!, 100.0),
      );
    }
  }



  List<deviceItems> getFilteredVehicles(List<deviceItems> allVehicles) {
    List<deviceItems> filtered = allVehicles;

    // Aplicar filtro de status (usando filtros traduzidos)
    switch (_selectedFilter) {
      case 'Todos':
      case 'All': // Compatibilidade com código antigo
        // Não filtrar, mostrar todos
        break;
      case 'Online':
        filtered = filtered.where((v) => 
          v.online != null && v.online!.toLowerCase().contains('online')
        ).toList();
        break;
      case 'Offline':
        filtered = filtered.where((v) => 
          v.online == null || !v.online!.toLowerCase().contains('online')
        ).toList();
        break;
      case 'Em movimento':
      case 'Moving': // Compatibilidade com código antigo
        filtered = filtered.where((v) => 
          v.speed != null && v.speed! > 0
        ).toList();
        break;
      case 'Parado':
      case 'Stopped': // Compatibilidade com código antigo
        filtered = filtered.where((v) => 
          v.speed == null || v.speed == 0
        ).toList();
        break;
      case 'Bloqueado':
      case 'Blocked': // Compatibilidade com código antigo
        // Filtrar veículos bloqueados se a propriedade existir
        filtered = filtered.where((v) => 
          v.alarm != null && v.alarm != 0
        ).toList();
        break;
    }

    // Aplicar busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((v) {
        final query = _searchQuery.toLowerCase();
        return (v.name?.toLowerCase().contains(query) ?? false) ||
               (v.plateNumber?.toLowerCase().contains(query) ?? false) ||
               (v.driver?.toLowerCase().contains(query) ?? false) ||
               (v.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> updateVehiclePosition(String deviceId) async {
    // Atualizar posição do veículo via API
    // Implementar se necessário
    notifyListeners();
  }

  Future<void> blockVehicle(String deviceId) async {
    // Bloquear veículo via API
    // Implementar se necessário
    notifyListeners();
  }

  Future<void> unblockVehicle(String deviceId) async {
    // Desbloquear veículo via API
    // Implementar se necessário
    notifyListeners();
  }

  // Métodos para gerenciar âncoras
  // IMPORTANTE: A âncora é FIXA e NÃO acompanha o veículo
  // As coordenadas (center) devem ser as coordenadas originais da geofence, não a posição atual do veículo
  void addAnchorCircle(String deviceId, LatLng center, double radius, String geofenceId, {String? vehicleName, String? vehicleAddress, Color? circleColor}) {
    final circleId = CircleId('anchor_$deviceId');
    
    // Remover círculo existente se houver
    _circles.removeWhere((circle) => circle.circleId.value == 'anchor_$deviceId');
    
    // Usar cor fornecida ou cor padrão laranja
    final Color fenceColor = circleColor ?? Colors.orange;
    
    // IMPORTANTE: O círculo usa coordenadas FIXAS (center) - não muda quando o veículo se move
    final circle = Circle(
      circleId: circleId,
      center: center, // Coordenadas FIXAS da geofence - NÃO acompanha o veículo
      radius: radius, // Raio FIXO da geofence
      fillColor: fenceColor.withOpacity(0.3),
      strokeColor: fenceColor,
      strokeWidth: 3, // int conforme esperado pelo Circle
    );
    
    // Criar novo Set para garantir que o Flutter detecte a mudança
    _circles = Set<Circle>.from(_circles)..add(circle);
    
    // Armazenar informações da âncora com coordenadas FIXAS
    _activeAnchors[deviceId] = AnchorInfo(
      deviceId: deviceId,
      center: center, // Coordenadas FIXAS - nunca mudam
      radius: radius, // Raio FIXO - nunca muda
      geofenceId: geofenceId,
    );
    
    print('🔵 Âncora criada para veículo $deviceId em coordenadas FIXAS: ${center.latitude}, ${center.longitude} (raio: $radius m)');
    
    notifyListeners();
  }
  
  // REMOVIDO: Método para criar marcador de label de âncora - não há mais marcadores de âncora
  // void _createAnchorLabelMarker(String deviceId, LatLng center, double radius, String geofenceId, String? vehicleName, String? vehicleAddress) {
  //   ...
  // }

  void removeAnchorCircle(String deviceId) {
    // Criar novo Set para garantir que o Flutter detecte a mudança
    _circles = Set<Circle>.from(_circles)
      ..removeWhere((circle) => circle.circleId.value == 'anchor_$deviceId');
    
    // REMOVIDO: Remoção de marcador de label - não há mais marcadores de âncora
    // final anchorInfo = _activeAnchors[deviceId];
    // if (anchorInfo != null) {
    //   _anchorMarkers = Set<Marker>.from(_anchorMarkers)
    //     ..removeWhere((marker) => 
    //       marker.markerId.value == 'anchor_label_$deviceId' || 
    //       marker.markerId.value == 'anchor_geofence_label_${anchorInfo.geofenceId}'
    //     );
    // }
    
    _activeAnchors.remove(deviceId);
    notifyListeners();
  }

  AnchorInfo? getAnchorInfo(String deviceId) {
    return _activeAnchors[deviceId];
  }

  bool hasActiveAnchor(String deviceId) {
    return _activeAnchors.containsKey(deviceId);
  }

  // Verificar se veículo saiu da área da âncora
  bool checkVehicleOutsideAnchor(deviceItems vehicle) {
    final anchor = _activeAnchors[vehicle.id.toString()];
    if (anchor == null) return false;
    
    if (vehicle.lat == null || vehicle.lng == null) return false;
    
    final distance = _calculateDistance(
      anchor.center.latitude,
      anchor.center.longitude,
      CoordinateUtils.toDouble(vehicle.lat) ?? 0.0,
      CoordinateUtils.toDouble(vehicle.lng) ?? 0.0,
    );
    
    return distance > anchor.radius;
  }

  // Calcular distância entre dois pontos (Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // === CARREGAR GEOFENCES EXISTENTES (IDÊNTICO AO CÓDIGO FORNECIDO) ===
  Future<void> loadExistingGeofences(List<deviceItems> devicesList) async {
    try {
      print('🔵 Carregando geofences existentes...');

      var geofences = await gpsapis.getGeoFences();

      // Limpar círculos de geofences antes de recarregar (para evitar duplicatas)
      _circles.removeWhere(
          (circle) => circle.circleId.value.startsWith('anchor_geofence_'));

      // REMOVIDO: Remoção de marcadores de âncora - não há mais marcadores
      // _anchorMarkers.removeWhere((marker) => 
      //   marker.markerId.value.startsWith('anchor_geofence_label_')
      // );

      if (geofences != null && geofences.isNotEmpty) {
        print('📊 Geofences encontradas: ${geofences.length}');

        for (var geofence in geofences) {
          // Verificar se é uma geofence de âncora (nome contém "Ancora" ou "âncora")
          if (geofence.name != null &&
              geofence.name!.toString().toLowerCase().contains('ancora') &&
              geofence.center != null &&
              geofence.radius != null &&
              geofence.type == 'circle') {
            print('🔵 Geofence de âncora encontrada: ${geofence.name}');

            // Extrair raio da geofence (pode ser String, int ou double)
            double radius = 50.0; // Padrão em double
            if (geofence.radius is double) {
              radius = geofence.radius as double;
            } else if (geofence.radius is int) {
              radius = (geofence.radius as int).toDouble();
            } else if (geofence.radius is num) {
              radius = (geofence.radius as num).toDouble();
            } else if (geofence.radius is String) {
              radius = double.tryParse(geofence.radius as String) ?? 50.0;
            }

            // Extrair coordenadas do center da geofence
            double? lat;
            double? lng;

            if (geofence.center is Map) {
              // Center é um objeto com lat e lng
              var centerMap = geofence.center as Map;
              lat = CoordinateUtils.toDouble(centerMap['lat']);
              lng = CoordinateUtils.toDouble(centerMap['lng']);
            } else if (geofence.center is String) {
              // Center é uma string JSON
              try {
                var centerJson = json.decode(geofence.center as String);
                lat = CoordinateUtils.toDouble(centerJson['lat']);
                lng = CoordinateUtils.toDouble(centerJson['lng']);
              } catch (e) {
                print('❌ Erro ao parsear center JSON: $e');
              }
            }

            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              print('   📍 Coordenadas da geofence: $lat, $lng');
              print('   📏 Raio: ${radius.toStringAsFixed(0)} metros');

              // Definir cor da geofence, se disponível
              Color fenceColor;
              try {
                final dynamic colorField = geofence.polygon_color;
                final String colorStr = (colorField?.toString() ?? '#FFA500');
                fenceColor = _parseColorFromString(colorStr);
              } catch (_) {
                fenceColor = Colors.orange;
              }

              // IMPORTANTE: Criar círculo com coordenadas FIXAS da geofence
              // O círculo NÃO acompanha o veículo - usa sempre as coordenadas originais da geofence
              final anchorCenter = LatLng(lat, lng); // Coordenadas FIXAS da geofence
              
              Circle anchorCircle = Circle(
                circleId: CircleId('anchor_geofence_${geofence.id}'),
                center: anchorCenter, // Coordenadas FIXAS - nunca mudam
                radius: radius, // Raio FIXO - nunca muda
                fillColor: fenceColor.withOpacity(0.3),
                strokeColor: fenceColor,
                strokeWidth: 3, // int conforme esperado pelo Circle
              );

              // Remover círculo existente se houver
              _circles.removeWhere((circle) =>
                  circle.circleId.value == 'anchor_geofence_${geofence.id}');
              // Adicionar novo círculo
              _circles = Set<Circle>.from(_circles)..add(anchorCircle);

              // Verificar se o dispositivo tem âncora ativa
              // IMPORTANTE: Só manter círculo se o dispositivo tiver alert_id ativo
              bool hasActiveAnchor = false;
              try {
                devicesList.firstWhere(
                  (d) =>
                      d.deviceData?.alert_id != null &&
                      d.deviceData!.alert_id != "0" &&
                      geofence.name!
                          .toString()
                          .toLowerCase()
                          .contains((d.name ?? '').toLowerCase()),
                );
                hasActiveAnchor = true;
              } catch (_) {
                hasActiveAnchor = false;
              }

              // Se não encontrar dispositivo com âncora ativa, remover o círculo
              deviceItems? relatedDevice;
              if (!hasActiveAnchor) {
                print(
                    '   ⚠️ Geofence encontrada mas dispositivo não tem âncora ativa - removendo círculo');
                _circles.removeWhere((circle) =>
                    circle.circleId.value == 'anchor_geofence_${geofence.id}');
                continue;
              } else {
                // Encontrar o dispositivo relacionado para registrar a âncora
                try {
                  relatedDevice = devicesList.firstWhere(
                    (d) =>
                        d.deviceData?.alert_id != null &&
                        d.deviceData!.alert_id != "0" &&
                        geofence.name!
                            .toString()
                            .toLowerCase()
                            .contains((d.name ?? '').toLowerCase()),
                  );
                  
                  // IMPORTANTE: Registrar âncora no _activeAnchors para monitoramento
                  // Usar coordenadas FIXAS da geofence, não a posição atual do veículo
                  _activeAnchors[relatedDevice.id.toString()] = AnchorInfo(
                    deviceId: relatedDevice.id.toString(),
                    center: anchorCenter, // Coordenadas FIXAS da geofence
                    radius: radius, // Raio FIXO da geofence
                    geofenceId: geofence.id.toString(),
                  );
                  
                  print('   ✅ Âncora registrada para monitoramento: veículo ${relatedDevice.id} em coordenadas FIXAS ${anchorCenter.latitude}, ${anchorCenter.longitude}');
                } catch (e) {
                  print('   ⚠️ Erro ao encontrar dispositivo relacionado: $e');
                }
              }

              // REMOVIDO: Criação de marcador de âncora - mantendo apenas o círculo
              // final String deviceAddress =
              //     relatedDevice?.address ?? 'Endereço não disponível';
              // final String createdAt = DateTime.now().toLocal().toString();
              // final String title = 'Âncora: ${geofence.name ?? 'Geofence'}';
              // final String snippet =
              //     'Raio: ${radius} m\n$deviceAddress\nCriado: $createdAt';
              // 
              // final String geoLabelKey = 'anchor_geofence_label_${geofence.id}';
              // final MarkerId geoLabelId = MarkerId(geoLabelKey);
              // 
              // final marker = Marker(
              //   markerId: geoLabelId,
              //   position: LatLng(lat, lng),
              //   icon: BitmapDescriptor.defaultMarkerWithHue(
              //       BitmapDescriptor.hueOrange),
              //   infoWindow: InfoWindow(title: title, snippet: snippet),
              //   anchor: const Offset(0.5, 0.5),
              // );
              // 
              // _anchorMarkers = Set<Marker>.from(_anchorMarkers)..add(marker);
              // 
              // if (_mapController != null) {
              //   Future.delayed(const Duration(milliseconds: 200), () {
              //     _mapController?.showMarkerInfoWindow(geoLabelId);
              //   });
              // }

              print(
                  '✅ Círculo de âncora criado a partir da geofence: ${geofence.name}');
            } else {
              print('⚠️ Coordenadas inválidas na geofence: ${geofence.name}');
            }
          }
        }

        print(
            '📊 Total de círculos de âncora no mapa: ${_circles.length}');
      } else {
        print('📊 Nenhuma geofence encontrada');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar geofences: $e');
    }
  }

  // Função auxiliar para converter cor hex em Color (IDÊNTICO AO CÓDIGO FORNECIDO)
  Color _parseColorFromString(String colorString) {
    try {
      // Remove # se presente
      String hex = colorString.replaceAll('#', '');

      // Se for formato de 6 dígitos (RGB)
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }

      // Se for formato de 8 dígitos (ARGB)
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }

      // Fallback para laranja
      return Colors.orange;
    } catch (e) {
      print('❌ Erro ao converter cor: $colorString - $e');
      return Colors.orange;
    }
  }

  // Método auxiliar para calcular rota usando RouteService
  Future<RouteResult?> calculateRouteToVehicle(deviceItems vehicle) async {
    try {
      // Obter localização atual
      final currentLocation = await RouteService.getCurrentLocation();
      if (currentLocation == null) {
        return null;
      }

      if (vehicle.lat == null || vehicle.lng == null) {
        return null;
      }

      final destination = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
      if (destination == null) return null;

      // Calcular rota
      final result = await RouteService.calculateRoute(
        origin: currentLocation,
        destination: destination,
        travelMode: TravelMode.driving,
      );

      return result;
    } catch (e) {
      print('❌ Erro ao calcular rota para veículo: $e');
      return null;
    }
  }

  // Método para obter informações de tráfego para uma rota específica
  Future<TrafficInfo?> getTrafficInfoForRoute(LatLng origin, LatLng destination) async {
    try {
      return await TrafficService.getTrafficInfo(
        origin: origin,
        destination: destination,
        travelMode: 'driving',
      );
    } catch (e) {
      print('❌ Erro ao obter informações de tráfego: $e');
      return null;
    }
  }

  // Método para buscar POIs específicos por tipo
  Future<void> loadPOIsByType(List<String> types) async {
    try {
      if (_mapController == null) return;

      // Obter centro do mapa atual
      final visibleRegion = await _mapController!.getVisibleRegion();
      final center = LatLng(
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
        (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
      );

      // Calcular raio
      final distance = _calculateDistance(
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
      );
      final radius = (distance / 2).clamp(500.0, 50000.0);

      // Buscar POIs específicos
      final poiMarkers = await POIService.getNearbyPOIs(
        center: center,
        radius: radius,
        types: types,
        maxResults: 30,
      );

      print('✅ ${poiMarkers.length} POIs carregados');

      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar POIs por tipo: $e');
    }
  }


  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Classe para armazenar informações da âncora
class AnchorInfo {
  final String deviceId;
  final LatLng center;
  final double radius;
  final String geofenceId;

  AnchorInfo({
    required this.deviceId,
    required this.center,
    required this.radius,
    required this.geofenceId,
  });
}

