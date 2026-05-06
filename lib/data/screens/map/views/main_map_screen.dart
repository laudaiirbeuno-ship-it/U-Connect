import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng, CameraPosition;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/GeofenceModel.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/config/static.dart';
// Removido: serviços de voz e notificações locais não serão usados no mapa
import 'package:uconnect/storage/user_repository.dart';
// Removido: imports de arquivos que não existem
// import 'package:uconnect/utils/notification_manager.dart';
// import 'package:uconnect/data/model/PushNotification.dart';
// import 'package:uconnect/providers/theme_provider.dart';
// import 'package:uconnect/utils/LocalNotificationService.dart';
// import 'package:uconnect/utils/vehicle_event_service.dart';
// import 'package:uconnect/utils/map_3d_controller.dart';
// import 'package:uconnect/utils/poi_controller.dart';
// import 'package:uconnect/utils/performance_config.dart';
// import 'package:uconnect/data/screens/listscreen.dart';
// import 'package:uconnect/data/screens/dashboard.dart';
// import 'package:uconnect/data/screens/reports/consumo_odometro_page.dart';
// import 'package:uconnect/widgets/hamburger_menu.dart';
// import 'package:uconnect/utils/anchor_service.dart';
// import 'package:uconnect/utils/anchor_modals.dart';
// import 'package:uconnect/ui/reusable/global_widget.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/map_filters.dart';
import '../widgets/vehicle_label_overlay.dart';
import '../widgets/create_anchor_modal.dart';
import '../controllers/map_controller.dart';
import '../services/poi_service.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/utils/command_logic.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

// === CLASSE PRINCIPAL DO MAPA GPSWOX ===
class MainMapScreen extends StatefulWidget {
  const MainMapScreen({Key? key}) : super(key: key);

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen>
    with TickerProviderStateMixin {
  // === CONTROLADOR DO MAPA ===
  gmaps.GoogleMapController? _mapController;

  // === SISTEMA DE DESLIZAMENTO DOS MARCADORES ===
  Map<String, gmaps.LatLng> _previousPositions = {};
  Map<String, gmaps.LatLng> _currentPositions = {};
  Map<String, AnimationController> _slideControllers = {};
  Map<String, Animation<gmaps.LatLng>> _slideAnimations = {};

  // === CONFIGURAÇÕES DE DESLIZAMENTO ===
  static const Duration slideDuration = Duration(milliseconds: 1500);
  static const Curve slideCurve = Curves.easeInOut;
  static const double minDistanceToSlide = 10.0; // metros

  // === POSIÇÃO INICIAL (CENTRO DO BRASIL) ===
  gmaps.LatLng _initialPosition = const gmaps.LatLng(-14.2350, -51.9253);
  double _currentZoom = 3.0; // Zoom ainda menor para visão mais ampla
  double _tiltAngle = 0.0;

  // === ESTADO DO MAPA ===
  bool _showMapLoading = true;
  bool _isMapReady = false;

  // === LISTA DE DISPOSITIVOS ===
  List<deviceItems> _devicesList = [];
  
  // === LISTA DE GEOFENCES ATIVAS ===
  List<Geofence> _activeGeofences = []; // Cache de geofences ativas

  // === MARCADORES E ELEMENTOS DO MAPA ===
  Map<String, gmaps.Marker> _deviceMarkers = {};
  Set<gmaps.Circle> _anchorCircles = {};
  Set<gmaps.Polyline> _trailPolylines = {};
  Set<gmaps.Polyline> _routePolylines = {};
  
  // === ÂNCORAS FIXAS (não acompanham movimento do veículo) ===
  Map<String, gmaps.LatLng> _anchorFixedPositions = {}; // deviceId -> posição fixa
  Map<String, AnimationController> _anchorPulseControllers = {}; // deviceId -> controller de animação
  Map<String, String> _circleIdToDeviceId = {}; // circleId -> deviceId (para mapear círculos de geofence)
  
  // === ANIMAÇÃO DE MARCADORES ===
  Map<String, AnimationController> _markerPulseControllers = {}; // deviceId -> controller de animação de marcador
  Map<String, double> _markerBaseScales = {}; // deviceId -> escala base do marcador

  // === NAVEGAÇÃO ATÉ O VEÍCULO ===
  bool _showRoute = false;
  List<gmaps.LatLng> _routeCoordinates = [];
  gmaps.Polyline? _navigationRoute;
  String? _routeDistance;
  String? _routeDuration;

  // === CONTROLLER DE POIs ===
  // Removido: POIController não existe
  // final POIController _poiController = POIController();

  // Cache de rotas (evita recalcular a mesma rota)
  Map<String, Map<String, dynamic>> _routeCache = {};
  static const Duration _routeCacheDuration =
      Duration(hours: 1); // Cache válido por 1 hora

  // === CONFIGURAÇÕES DO MAPA ===
  gmaps.MapType _currentMapType = gmaps.MapType.normal;
  bool _trafficEnabled = false;
  bool _showTrail = true;

  // === TIMERS ===
  Timer? _updateTimer;
  Timer? _trailTimer;

  // Throttle para animação de marcadores (evita setState a cada frame)
  DateTime? _lastMarkerUpdate;
  static const Duration _markerUpdateThrottle = Duration(milliseconds: 100);

  // === VARIÁVEIS ADICIONAIS DO MAPA ORIGINAL ===
  // Removido: labels antigos - agora usando VehicleLabelOverlay
  bool _showTitle = false;
  bool _justSelectedVehicle = false;
  List<gmaps.LatLng> _latlng = [];

  // === COMANDOS ===
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];

  // === SERVIÇO DE ÂNCORA ===
  // Removido: AnchorService não existe
  // final AnchorService _anchorService = AnchorService();

  // === REMOVIDO: MARCADORES SOS ===

  // === DETALHES DO VEÍCULO ===
  bool isshowvehicledetail = false;
  // Removido: cache de endereços não utilizado

  // === CAMPO DE BUSCA ===
  TextEditingController _searchController = TextEditingController();

  // === POSIÇÕES DOS VEÍCULOS PARA LABELS ===
  Map<int, LatLng> _vehiclePositions = {};
  CameraPosition? _currentCameraPosition;
  
  // === LISTENER DE CONFIGURAÇÕES ===
  AppSettingsProvider? _settingsProvider;
  double? _lastMarkerSize;
  bool? _lastMarkerAnimation;

  // === CONTROLE DE CENTRALIZAÇÃO ===
  bool _isFirstLoad = true;

  // === POSIÇÃO ATUAL DA CÂMERA ===
  gmaps.LatLng? _currentCameraTarget;
  // Escala do ícone do veículo no mapa (1.0 = padrão)
  double _markerScale = 1.0;
  // === ZOOM SLIDER ===
  double _zoomSlider = 3.0; // vinculado ao _currentZoom

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trailTimer?.cancel();
    _cleanupSlideResources();
    // Limpar controllers de animação das âncoras
    for (var controller in _anchorPulseControllers.values) {
      controller.dispose();
    }
    _anchorPulseControllers.clear();
    
    // Limpar controllers de animação de marcadores
    for (var controller in _markerPulseControllers.values) {
      controller.dispose();
    }
    _markerPulseControllers.clear();
    _markerBaseScales.clear();
    
    super.dispose();
  }

  // === SISTEMA DE DESLIZAMENTO DOS MARCADORES ===

  // Limpar recursos de deslizamento
  void _cleanupSlideResources() {
    for (var controller in _slideControllers.values) {
      controller.dispose();
    }
    _slideControllers.clear();
    _slideAnimations.clear();
  }

  // Calcular distância entre duas posições
  double _calculateDistance(gmaps.LatLng pos1, gmaps.LatLng pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  // Deslizar marcador para nova posição
  void _slideMarkerToNewPosition(String deviceId, gmaps.LatLng newPosition) {
    gmaps.LatLng currentPosition = _currentPositions[deviceId] ?? newPosition;

    // Verificar se há mudança significativa de posição
    double distance = _calculateDistance(currentPosition, newPosition);
    if (distance < minDistanceToSlide) return;

    // Criar animação de deslizamento
    _createSlideAnimation(deviceId, currentPosition, newPosition);
  }

  // Criar animação de deslizamento
  void _createSlideAnimation(
      String deviceId, gmaps.LatLng from, gmaps.LatLng to) {
    // Cancelar animação anterior se existir
    _slideControllers[deviceId]?.dispose();

    // Criar novo controller
    _slideControllers[deviceId] = AnimationController(
      duration: slideDuration,
      vsync: this,
    );

    // Criar animação de posição
    _slideAnimations[deviceId] = Tween<gmaps.LatLng>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: _slideControllers[deviceId]!,
      curve: slideCurve,
    ));

    // Listener para atualizar posição durante animação
    _slideAnimations[deviceId]!.addListener(() {
      _updateMarkerPositionDuringSlide(deviceId);
    });

    // Iniciar animação
    _slideControllers[deviceId]!.forward();
  }

  // Atualizar posição do marcador durante o deslizamento
  // Otimizado: usa throttle para reduzir setState durante animação
  void _updateMarkerPositionDuringSlide(String deviceId) {
    if (!_slideAnimations.containsKey(deviceId) || !mounted) return;

    gmaps.LatLng animatedPosition = _slideAnimations[deviceId]!.value;

    // Atualizar posição atual
    _currentPositions[deviceId] = animatedPosition;

    // Atualizar apenas o marcador específico
    if (_deviceMarkers.containsKey(deviceId)) {
      gmaps.Marker existingMarker = _deviceMarkers[deviceId]!;
      _deviceMarkers[deviceId] = gmaps.Marker(
        markerId: existingMarker.markerId,
        position: animatedPosition,
        onTap: existingMarker.onTap,
        anchor: existingMarker.anchor,
        icon: existingMarker.icon,
        rotation: existingMarker.rotation,
      );
    }

    // Throttle: setState apenas a cada 100ms ou quando animação completa
    final now = DateTime.now();
    final shouldUpdate = _lastMarkerUpdate == null ||
        now.difference(_lastMarkerUpdate!) >= _markerUpdateThrottle ||
        _slideControllers[deviceId]?.status == AnimationStatus.completed;

    if (shouldUpdate && mounted) {
      _lastMarkerUpdate = now;
      setState(() {
        // Forçar rebuild do mapa com novas posições dos marcadores
      });

      // Limpar throttle quando animação completa
      if (_slideControllers[deviceId]?.status == AnimationStatus.completed) {
        _lastMarkerUpdate = null;
      }
    }
  }

  // Salvar posições anteriores
  void _savePreviousPositions() {
    for (var device in _devicesList) {
      String deviceId = device.id.toString();
      _previousPositions[deviceId] =
          _currentPositions[deviceId] ?? gmaps.LatLng(device.lat!, device.lng!);
    }
  }

  // Aplicar deslizamento para novos dados
  void _applySlidingToNewData() {
    for (var device in _devicesList) {
      String deviceId = device.id.toString();
      gmaps.LatLng newPosition = gmaps.LatLng(device.lat!, device.lng!);

      // Verificar se há mudança de posição
      if (_previousPositions.containsKey(deviceId)) {
        gmaps.LatLng previousPosition = _previousPositions[deviceId]!;
        double distance = _calculateDistance(previousPosition, newPosition);

        if (distance > minDistanceToSlide) {
          _slideMarkerToNewPosition(deviceId, newPosition);
        } else {
          // Atualizar posição sem deslizamento
          _currentPositions[deviceId] = newPosition;
        }
      } else {
        // Primeira vez - posicionar diretamente
        _currentPositions[deviceId] = newPosition;
      }
    }
  }

  // === INICIALIZAÇÃO DO MAPA ===
  void _initializeMap() {
    // Removido: POI controller não existe
    // _poiController.setOnPOITapCallback(_showPOIDetails);
    print('🗺️ Inicializando mapa GPSWox...');
    _checkUserAuthentication();
    _loadDevicesFromAPI().then((_) {
      // Garantir que os veículos apareçam após carregamento
      if (_devicesList.isNotEmpty) {
        print('🚗 Dispositivos carregados, criando marcadores...');
        _showAllVehiclesWithoutFilters();
      }
    });
    _startAutoUpdateTimer();
  }

  // === VERIFICAÇÃO DE AUTENTICAÇÃO ===
  void _checkUserAuthentication() {
    print('🔐 Verificando autenticação...');
    print('🔑 User API Hash: ${StaticVarMethod.user_api_hash}');
    print('🌐 Base URL: ${StaticVarMethod.baseurlall}');

    if (StaticVarMethod.user_api_hash == null ||
        StaticVarMethod.user_api_hash!.isEmpty) {
      print('❌ Usuário não autenticado');
      _showAuthenticationError();
    } else {
      print('✅ Usuário autenticado com sucesso');
    }
  }

  // === CARREGAMENTO DE DISPOSITIVOS (100% DOCUMENTAÇÃO GPSWOX) ===
  Future<void> _loadDevicesFromAPI() async {
    try {
      print('🔵 Carregando dispositivos da API GPSWox...');

      // URL correta usando UserRepository
      String baseUrl = UserRepository.getServerURL();
      String apiUrl =
          "$baseUrl/api/get_devices?lang=br&user_api_hash=${StaticVarMethod.user_api_hash}";
      print('🌐 URL da API: $apiUrl');

      // Chamada HTTP seguindo documentação
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        print('📊 Resposta da API: ${jsonData.toString()}');

        List<deviceItems> devices = [];

        // Processamento seguindo estrutura da documentação GPSWox
        if (jsonData is List) {
          for (var deviceGroup in jsonData) {
            if (deviceGroup['items'] != null && deviceGroup['items'] is List) {
              for (var deviceData in deviceGroup['items']) {
                try {
                  var device = deviceItems.fromJson(deviceData);
                  devices.add(device);
                  print(
                      '✅ Dispositivo carregado: ${device.name} (ID: ${device.id})');
                } catch (e) {
                  print('❌ Erro ao processar dispositivo: $e');
                }
              }
            }
          }
        }

        print('📊 Total de dispositivos processados: ${devices.length}');

        if (devices.isNotEmpty) {
          // Salvar posições anteriores antes de atualizar
          _savePreviousPositions();

          setState(() {
            _devicesList = devices;
          });

          print('✅ ${devices.length} dispositivos carregados com sucesso');

          // Aplicar deslizamento para novos dados
          _applySlidingToNewData();

          // Carregar geofences existentes após carregar dispositivos
          await _loadExistingGeofences();
          
          // Verificar violações de âncora e acionar imobilização se necessário
          await _checkAnchorViolations();

          // Criar marcadores apenas na primeira carga
          if (_isFirstLoad) {
            _showAllVehiclesWithoutFilters();
          } else {
            // Atualizar apenas posições nas atualizações subsequentes
            _updateMarkersPositions();
          }

          // Removido: seleção automática do primeiro veículo
          // O painel só deve aparecer quando o usuário clicar no ícone do veículo
          // if (devices.isNotEmpty) {
          //   _selectFirstVehicleAutomatically();
          // }

          print(
              '📊 Lista de dispositivos atualizada: ${devices.length} dispositivos');
        } else {
          print('⚠️ Nenhum dispositivo encontrado');
        }
      } else {
        print('❌ Erro na API: ${response.statusCode}');
        print('📄 Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao carregar dispositivos: $e');
    }
  }

  // === VERIFICAR VIOLAÇÕES DE ÂNCORA E ACIONAR IMOBILIZAÇÃO ===
  Future<void> _checkAnchorViolations() async {
    try {
      // Buscar todas as geofences ativas
      final geofences = await gpsapis.getGeoFences(lang: 'br');
      if (geofences == null || geofences.isEmpty) return;

      for (var device in _devicesList) {
        if (device.lat == null || device.lng == null) continue;
        
        final lat = device.lat is double ? device.lat as double : (device.lat as num).toDouble();
        final lng = device.lng is double ? device.lng as double : (device.lng as num).toDouble();
        final speed = device.speed is double ? device.speed as double : (device.speed as num?)?.toDouble() ?? 0.0;

        // Verificar se o ponto está em violação de geofence
        final violationCheck = await gpsapis.checkPointInGeofences(
          lat: lat,
          lng: lng,
          speed: speed,
          device_id: device.id,
          lang: 'br',
        );

        if (violationCheck != null && violationCheck['status'] == 1) {
          final zones = violationCheck['zones'] as List?;
          if (zones != null && zones.isNotEmpty) {
            for (var zone in zones) {
              final zoneData = zone as Map<String, dynamic>;
              final inside = zoneData['inside'] as bool? ?? true;
              final blocked = zoneData['blocked'] as bool? ?? false;
              final speedViolation = zoneData['speed_violation'] as bool? ?? false;
              final event = zoneData['event'] as String?;
              final geofenceId = zoneData['geofence_id'] as int?;

              if (geofenceId == null) continue;

              // Buscar a geofence correspondente
              final geofence = geofences.firstWhere(
                (g) => g.id == geofenceId,
                orElse: () => Geofence(),
              );

              bool shouldBlock = false;
              String? blockReason;

              // CASO 1: AO SAIR DA CERCA (sempre bloqueia, independente de movement_allowed)
              if (!inside && (event == 'exit' || event == 'exit_and_speed')) {
                shouldBlock = true;
                blockReason = TranslationHelper.translateSync(context, 'Saiu da cerca', 'Left the geofence');
              }
              // CASO 2: AO PASSAR DO LIMITE DE VELOCIDADE (sempre bloqueia, independente de movement_allowed)
              else if (speedViolation && (event == 'speed' || event == 'exit_and_speed' || event == 'speed_violation')) {
                shouldBlock = true;
                blockReason = TranslationHelper.translateSync(context, 'Excedeu limite de velocidade', 'Exceeded speed limit');
              }
              // CASO 3: AO DETECTAR MOVIMENTAÇÃO DENTRO DA CERCA (apenas se movement_allowed = true)
              // Verifica se está dentro da cerca E se movement_allowed está ativo
              else if (inside && geofence.movement_allowed == true) {
                // Verificar velocidade do veículo para detectar movimento
                final currentSpeed = device.speed is double ? device.speed as double : (device.speed as num?)?.toDouble() ?? 0.0;
                // Se há evento de movimento OU se a velocidade é maior que 0 dentro da cerca
                if (event == 'movement' || event == 'enter' || currentSpeed > 0) {
                  shouldBlock = true;
                  blockReason = TranslationHelper.translateSync(context, 'Movimentação detectada dentro da cerca', 'Movement detected inside geofence');
                }
              }

              // Acionar imobilização se necessário
              if (shouldBlock && blocked) {
                print('🚨 BLOQUEIO NECESSÁRIO: ${device.name}');
                print('   📍 Geofence: ${geofence.name}');
                print('   🚨 Motivo: $blockReason');
                print('   📊 Evento: $event');
                print('   ⚠️ Violação de velocidade: $speedViolation');
                print('   📍 Dentro da cerca: $inside');
                print('   🔓 Movement allowed: ${geofence.movement_allowed}');
                
                await _triggerImmobilization(device, geofence, event, speedViolation);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao verificar violações de âncora: $e');
    }
  }

  // === ACIONAR IMOBILIZAÇÃO DO VEÍCULO ===
  Future<void> _triggerImmobilization(
    deviceItems device,
    Geofence geofence,
    String? event,
    bool speedViolation,
  ) async {
    try {
      print('🚨 ACIONANDO IMOBILIZAÇÃO IMEDIATA: ${device.name} (ID: ${device.id})');
      print('   📍 Geofence: ${geofence.name}');
      print('   🚨 Evento: $event');
      print('   ⚠️ Violação de velocidade: $speedViolation');

      // Usar a mesma lógica do modal de bloqueio - BLOQUEIO IMEDIATO
      // Definir o deviceId para o sistema de comandos
      StaticVarMethod.deviceId = device.id.toString();
      StaticVarMethod.deviceName = device.name ?? 'Veículo';

      // IMPORTANTE: Não esperar getCommands() para tornar o bloqueio imediato
      // O sendCommand do command_logic.dart já lida com comandos padrão se necessário
      // Enviar comando de parar motor (lock) IMEDIATAMENTE usando sendCommand do command_logic.dart
      // Isso usa EXATAMENTE a mesma lógica do modal de bloqueio
      // O deviceId já foi definido em StaticVarMethod.deviceId acima
      sendCommand('lock');
      
      print('✅ Comando de imobilização (parar motor) enviado IMEDIATAMENTE!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🚨 ${TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')} ${device.name} ${TranslationHelper.translateSync(context, 'imobilizado por violação de âncora', 'immobilized due to anchor violation')}!',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao acionar imobilização: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.translateSync(context, 'Erro ao imobilizar veículo', 'Error immobilizing vehicle')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === CARREGAR GEOFENCES EXISTENTES ===
  Future<void> _loadExistingGeofences() async {
    try {
      print('🔵 Carregando geofences existentes...');

      var geofences = await gpsapis.getGeoFences(lang: 'br');

      // REMOVER TODAS AS ÂNCORAS ATIVAS DO MAPA
      setState(() {
        // Remover todos os círculos de âncora
        _anchorCircles.clear();
        
        // Remover todos os rótulos de âncora
        final keysToRemove = _deviceMarkers.keys
            .where((key) => key.startsWith('anchor_') || key.startsWith('anchor_geofence_'))
            .toList();
        for (var key in keysToRemove) {
          _deviceMarkers.remove(key);
        }
        
        // Limpar controllers de animação
        for (var controller in _anchorPulseControllers.values) {
          controller.dispose();
        }
        _anchorPulseControllers.clear();
        _anchorFixedPositions.clear();
        _circleIdToDeviceId.clear();
      });
      
      print('🗑️ Todas as âncoras ativas foram removidas do mapa');

      // Atualizar cache de geofences ativas
      _activeGeofences = geofences?.where((g) => g.isAnchor && g.isActive).toList() ?? [];
      
      if (geofences != null && geofences.isNotEmpty) {
        print('📊 Geofences encontradas: ${geofences.length}');

        for (var geofence in geofences) {
          // Verificar se é uma geofence de âncora usando helper
          // IMPORTANTE: device_id pode ser null na API, mas ainda assim é uma âncora válida
          if (geofence.isAnchor &&
              geofence.center != null &&
              geofence.radius != null &&
              geofence.type == 'circle') {
            print('🔵 Geofence de âncora encontrada: ${geofence.name}');
            print('   📍 device_id: ${geofence.device_id} (pode ser null)');

            // Extrair raio da geofence
            final radius = geofence.radius!.toInt();

            // Usar coordenadas do center (já parseado pelo modelo)
            final center = geofence.center!;
            final lat = center.lat;
            final lng = center.lng;

            if (lat != 0 && lng != 0) {
              print('   📍 Coordenadas da geofence: $lat, $lng');
              print('   📏 Raio: $radius metros');

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
              // A âncora NUNCA se move - usa sempre as coordenadas originais da geofence
              final anchorCenter = gmaps.LatLng(lat, lng); // Coordenadas FIXAS da geofence
              
              // Armazenar posição fixa da âncora (não acompanha movimento do veículo)
              // Se device_id for null, usar o ID da geofence como chave
              final positionKey = geofence.device_id != null 
                  ? geofence.device_id.toString() 
                  : 'geofence_${geofence.id}';
              _anchorFixedPositions[positionKey] = anchorCenter;
              print('   📍 Posição fixa armazenada com chave: $positionKey');
              
              // Criar círculo principal da âncora com coordenadas FIXAS
              final circleId = 'anchor_geofence_${geofence.id}';
              gmaps.Circle anchorCircle = gmaps.Circle(
                circleId: gmaps.CircleId(circleId),
                center: anchorCenter, // Coordenadas FIXAS - nunca mudam
                radius: radius.toDouble(), // Raio FIXO - nunca muda
                fillColor: fenceColor.withOpacity(0.3),
                strokeColor: fenceColor,
                strokeWidth: 3,
              );
              
              // Mapear circleId para deviceId (ou geofence_id se device_id for null)
              final mappingKey = geofence.device_id != null 
                  ? geofence.device_id.toString() 
                  : 'geofence_${geofence.id}';
              _circleIdToDeviceId[circleId] = mappingKey;
              print('   🔗 Mapeamento circleId->deviceId: $circleId -> $mappingKey');
              
              // Criar círculos de onda animados (3 ondas) com coordenadas FIXAS
              List<gmaps.Circle> waveCircles = [];
              for (int i = 0; i < 3; i++) {
                final waveId = 'anchor_wave_geofence_${geofence.id}_$i';
                waveCircles.add(
                  gmaps.Circle(
                    circleId: gmaps.CircleId(waveId),
                    center: anchorCenter, // Coordenadas FIXAS
                    radius: radius.toDouble(),
                    fillColor: Colors.transparent,
                    strokeColor: fenceColor.withOpacity(0.0), // Será animado
                    strokeWidth: 2,
                  ),
                );
                // Mapear waveId para deviceId também (ou geofence_id se device_id for null)
                _circleIdToDeviceId[waveId] = mappingKey;
              }
              
              // Adicionar círculos ao set
                setState(() {
                _anchorCircles.add(anchorCircle);
                _anchorCircles.addAll(waveCircles);
                _anchorCircles = Set<gmaps.Circle>.from(_anchorCircles);
              });
              
              // Iniciar animação de onda usando a chave de mapeamento
              if (!_anchorPulseControllers.containsKey(mappingKey)) {
                  final pulseController = AnimationController(
                    vsync: this,
                    duration: const Duration(milliseconds: 2000),
                  )..repeat();
                _anchorPulseControllers[mappingKey] = pulseController;
                }
              _startWaveAnimation(mappingKey, radius.toDouble(), fenceColor);

              // Labels de âncora removidos - apenas círculo e marcador de veículo são exibidos

              print('✅ Círculo de âncora criado a partir da geofence: ${geofence.name}');
              print('   📍 Coordenadas FIXAS: $lat, $lng (nunca se movimentam)');
            } else {
              print('⚠️ Coordenadas inválidas na geofence: ${geofence.name}');
            }
          }
        }

        print(
            '📊 Total de círculos de âncora no mapa: ${_anchorCircles.length}');
      } else {
        print('📊 Nenhuma geofence encontrada');
      }
    } catch (e) {
      print('❌ Erro ao carregar geofences: $e');
    }
  }

  // === MOSTRAR TODOS OS VEÍCULOS SEM FILTROS E CENTRALIZAR ===
  Future<void> _showAllVehiclesWithoutFilters() async {
    if (_devicesList.isEmpty) {
      print('⚠️ Nenhum dispositivo para mostrar');
      return;
    }

    print(
        '🎨 Criando marcadores para todos os ${_devicesList.length} dispositivos...');
    await _createDeviceMarkers();

    // Centralizar mapa em todos os veículos após criar marcadores
    // Mas apenas se não houver um veículo selecionado recentemente
    if (_mapController != null && _deviceMarkers.isNotEmpty && !_justSelectedVehicle) {
      Timer(const Duration(milliseconds: 500), () {
        if (!_justSelectedVehicle) {
        _centerMapOnAllVehicles();
        }
      });
    }

    setState(() {
      _isFirstLoad = false;
    });
  }

  // === CENTRALIZAR MAPA EM TODOS OS VEÍCULOS ===
  Future<void> _centerMapOnAllVehicles() async {
    if (_mapController == null || _deviceMarkers.isEmpty) {
      print('⚠️ Não é possível centralizar: mapa não pronto ou sem marcadores');
      return;
    }

    try {
      // Coletar todas as posições dos marcadores
      List<gmaps.LatLng> positions = [];
      for (var marker in _deviceMarkers.values) {
        positions.add(marker.position);
      }

      if (positions.isEmpty) {
        print('⚠️ Nenhuma posição válida encontrada');
        return;
      }

      // Calcular bounds para incluir todos os veículos
      double minLat = positions[0].latitude;
      double maxLat = positions[0].latitude;
      double minLng = positions[0].longitude;
      double maxLng = positions[0].longitude;

      for (var pos in positions) {
        minLat = minLat < pos.latitude ? minLat : pos.latitude;
        maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
        minLng = minLng < pos.longitude ? minLng : pos.longitude;
        maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
      }

      // Se há apenas um veículo, centralizar nele
      if (positions.length == 1) {
        await _mapController!.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(positions[0], 18.0),
        );
      } else {
        // Se há múltiplos veículos, criar bounds e ajustar zoom
        gmaps.LatLngBounds bounds = gmaps.LatLngBounds(
          southwest: gmaps.LatLng(minLat, minLng),
          northeast: gmaps.LatLng(maxLat, maxLng),
        );

        await _mapController!.animateCamera(
          gmaps.CameraUpdate.newLatLngBounds(
              bounds, 100.0), // Padding de 100 pixels
        );
      }

      print('✅ Mapa centralizado em ${positions.length} veículo(s)');
    } catch (e) {
      print('❌ Erro ao centralizar mapa em todos os veículos: $e');
    }
  }

  // === CRIAÇÃO DE MARCADORES COM DESLIZAMENTO ===
  Future<void> _createDeviceMarkers() async {
    print(
        '🎨 Iniciando criação de marcadores para ${_devicesList.length} dispositivos...');
    _deviceMarkers.clear();
    _latlng.clear();

    int validDevices = 0;
    int invalidDevices = 0;
    List<Future<void>> markerFutures = [];

    // Obter tamanho do marcador do provider uma vez
    final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
    final baseScale = settingsProvider.markerSize;
    final shouldAnimate = settingsProvider.markerAnimation;

    for (int i = 0; i < _devicesList.length; i++) {
      var device = _devicesList[i];

      if (device.lat != null && device.lng != null && device.lat != 0) {
        validDevices++;
        String other = device.deviceData?.traccar?.other?.toString() ?? "";
        String ignition = "false";
        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }

        var color;
        // Define a cor do label com base no status
        if (device.speed!.toInt() > 0) {
          color = Colors.green;
        } else if (device.online!.contains('engine')) {
          color = Colors.yellow;
        } else if (device.online!.contains('online')) {
          color = Colors.green;
        } else if (device.online!.contains('ack')) {
          color = Colors.red;
        } else if (device.online!.contains('offline')) {
          color = Colors.blue;
        } else {
          color = Colors.grey;
        }

        // Ícone de ignição
        String ignitionIcon = '🔴'; // desligado
        if (ignition.contains("true") && device.speed! > 0) {
          ignitionIcon = '🟢'; // em movimento
        } else if (ignition.contains("true")) {
          ignitionIcon = '🟢'; // ligado
        }

        // Rótulo final com nome + chave + velocidade
        String speedLabel =
            '${device.speed!.toDouble().toStringAsFixed(0)} km/h';
        String label = '${device.name} $ignitionIcon $speedLabel';

        // Converter para double caso venha como int
        double lat = device.lat is double
            ? device.lat as double
            : (device.lat as num).toDouble();
        double lng = device.lng is double
            ? device.lng as double
            : (device.lng as num).toDouble();

        // Usar posição atual (com deslizamento) ou posição original
        String deviceId = device.id.toString();
        gmaps.LatLng currentPosition =
            _currentPositions[deviceId] ?? gmaps.LatLng(lat, lng);

        gmaps.LatLng position =
            gmaps.LatLng(currentPosition.latitude, currentPosition.longitude);
        _latlng.add(position);

        String baseUrl = "https://web.unnicatelemetria.com.br/";
        String? deviceIconPath = device.icon?.path;
        String deviceIconFullPath = baseUrl + (deviceIconPath ?? '');

        final bool isSelectedMarker = (device.deviceData?.imei?.toString() ?? '') == StaticVarMethod.imei;
        final selectedScale = isSelectedMarker ? _markerScale * baseScale : baseScale;

        // Criar marcador de forma assíncrona e adicionar à lista de futures
        Future<void> markerFuture = _createImageLabel(
          iconpath: deviceIconFullPath,
          label: label,
          course: device.course.toDouble(),
          color: color,
          showtitle: _showTitle,
          scale: selectedScale,
        ).then((gmaps.BitmapDescriptor customIcon) {
          if (!mounted) return;
          
          _deviceMarkers[deviceId] = gmaps.Marker(
            markerId: gmaps.MarkerId(deviceId),
            position: position,
            onTap: () {
              // Executar de forma assíncrona para não travar a UI
              Future.microtask(() async {
                try {
                  if (!mounted) return;

                  // Definir IMEI primeiro (rápido)
                  StaticVarMethod.imei =
                      device.deviceData?.imei?.toString() ?? "";

                  // SEMPRE mostrar painel, mesmo que já tenha centralizado
                  if (mounted) {
                    // Definir veículo selecionado no MapController
                    final mapController = Provider.of<MapController>(context, listen: false);
                    mapController.setSelectedVehicle(device);
                    
                    setState(() {
                      isshowvehicledetail = true; // SEMPRE mostrar o card
                    });
                  }

                  // Centralizar mapa de forma assíncrona (não bloqueia UI)
                  _centerMapOnVehicle(device);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${TranslationHelper.translateSync(context, 'Erro ao abrir detalhes do veículo', 'Error opening vehicle details')}: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              });
            },
            anchor: const Offset(0.5, 0.5),
            icon: customIcon,
          );

          // Armazenar escala base para animação
          _markerBaseScales[deviceId] = selectedScale;
          
          // Se animação estiver ativa, iniciar animação pulsante
          if (shouldAnimate && !_markerPulseControllers.containsKey(deviceId)) {
            _startMarkerAnimation(deviceId, device);
          } else if (!shouldAnimate && _markerPulseControllers.containsKey(deviceId)) {
            _stopMarkerAnimation(deviceId);
          }

          // Atualizar UI progressivamente para mostrar marcadores conforme são criados
          if (mounted) {
            setState(() {});
          }
        }).catchError((e) {
          print('❌ Erro ao criar marcador para ${device.name}: $e');
        });

        markerFutures.add(markerFuture);
      } else {
        invalidDevices++;
      }
    }

    // Aguardar todos os marcadores serem criados antes de finalizar
    try {
      await Future.wait(markerFutures);
    } catch (e) {
      print('⚠️ Alguns marcadores falharam ao carregar: $e');
    }

    // Atualizar UI final
    if (mounted) {
    setState(() {
      _isFirstLoad = false; // Marcar que já foi carregado pela primeira vez
    });
    }

    print('📊 Resumo da criação de marcadores:');
    print('   ✅ Dispositivos válidos: $validDevices');
    print('   ❌ Dispositivos inválidos: $invalidDevices');
    print('   🎯 Marcadores criados: ${_deviceMarkers.length}');
    print('   📍 Posições adicionadas: ${_latlng.length}');
  }

  // === CARREGAMENTO DE COMANDOS ===
  Future<void> getCommands() async {
    print('📡 Buscando comandos do deviceId: ${StaticVarMethod.deviceId}');

    try {
      final response =
          await gpsapis.getSavedCommands(StaticVarMethod.deviceId.toString());

      if (response != null && response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is List && body.isNotEmpty) {
          print('🔁 COMANDOS ENCONTRADOS: ${body.length}');

          _commands.clear();
          _commandsValue.clear();

          for (var element in body) {
            if (element is Map) {
              print('🎯 COMANDO: ${element["title"]} | TYPE: ${element["type"]}');
              _commands.add(element["title"]);
              _commandsValue.add(element["type"]);
            }
          }
          setState(() {});
        } else {
          print('⚠️ Lista de comandos vazia da API, usando comandos padrão');
          _loadDefaultCommands();
        }
      } else {
        print('⚠️ Lista de comandos vazia da API, usando comandos padrão');
        _loadDefaultCommands();
      }
    } catch (e) {
      print('❌ Erro ao buscar comandos: $e');
      _loadDefaultCommands();
    }
  }

  // === COMANDOS PADRÃO ===
  void _loadDefaultCommands() {
    print('🔄 Carregando comandos padrão...');

    _commands.clear();
    _commandsValue.clear();

    // Comandos padrão - apenas motor
    _commands.addAll([
      'Ligar Motor',
      'Desligar Motor',
      'Desbloquear Motor',
    ]);

    _commandsValue.addAll([
      'power_on',
      'lock',
      'unlock',
    ]);

    print('✅ ${_commands.length} comandos padrão carregados');
    setState(() {});
  }

  // === ENVIO DE COMANDOS ===
  void sendCommand(String type, {String? data}) async {
    print('📤 ENVIANDO COMANDO: $type');
    print('📤 DEVICE_ID: ${StaticVarMethod.deviceId}');

    Map<String, String> requestBody;

    if (type == 'custom') {
      requestBody = {
        'id': "",
        'device_id': StaticVarMethod.deviceId,
        'type': 'custom',
        'data': data ?? ''
      };
    } else {
      requestBody = {
        'id': "",
        'device_id': StaticVarMethod.deviceId,
        'type': type,
      };
    }

    print('📤 REQUEST BODY: $requestBody');
    final res = await gpsapis.sendCommands(requestBody);

    if (res.statusCode == 200) {
      print('✅ Comando enviado com sucesso!');

      // Criar notificação local baseada no tipo de comando
      await _createCommandNotification(type);

      // === REMOVIDO: Fluxo SOS ===

      // Fluxo quando for desbloqueio: notificar servidor
      if (type.toLowerCase() == 'unlock') {
        await _notifyServerUnlock();
      }

      // Notificações para dashboard: registrar bloqueio/desbloqueio
      final lower = type.toLowerCase();

      // Obter informações do veículo selecionado para eventos de bloqueio/desbloqueio
      deviceItems? selectedVehicle;
      try {
        selectedVehicle = _devicesList.firstWhere(
          (device) =>
              device.deviceData?.imei?.toString() == StaticVarMethod.imei ||
              device.id.toString() == StaticVarMethod.deviceId,
        );
      } catch (e) {
        print(
            '⚠️ Veículo selecionado não encontrado para evento de bloqueio/desbloqueio');
      }

      // Removido: notificações e eventos não disponíveis
      // if (lower == 'lock' || lower.contains('desligar_motor')) {
      //   ...
      // }
      // if (lower == 'unlock' || lower.contains('ligar_motor')) {
      //   ...
      // }
    } else {
      print('❌ Falha ao enviar comando!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao enviar comando', 'Error sending command')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === REMOVIDO: _notifyServerSOS ===

  // Notifica o servidor criando um registro (Task) para desbloqueio
  Future<void> _notifyServerUnlock() async {
    try {
      final String deviceId = StaticVarMethod.deviceId;
      final String deviceName = StaticVarMethod.deviceName;

      deviceItems? device;
      try {
        device = _devicesList.firstWhere(
          (d) => d.id.toString() == deviceId,
        );
      } catch (_) {
        device = _devicesList.isNotEmpty ? _devicesList.first : null;
      }

      final String pickupAddress = device?.address ?? TranslationHelper.translateSync(context, 'Endereço não disponível', 'Address not available');
      final String pickupLat = (device?.lat ?? 0).toString();
      final String pickupLng = (device?.lng ?? 0).toString();

      StaticVarMethod.deviceId = deviceId;

      final res = await gpsapis.AddTask(
        'DESBLOQUEIO - $deviceName',
        'Desbloqueio solicitado em ${DateTime.now().toIso8601String()}',
        pickupAddress,
        pickupLat,
        pickupLng,
      );

      if (res.statusCode == 200) {
        print('✅ Servidor notificado (Task DESBLOQUEIO criada)');
      } else {
        print(
            '⚠️ Falha ao notificar servidor (DESBLOQUEIO): ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao notificar servidor (DESBLOQUEIO): $e');
    }
  }

  // === CRIAR NOTIFICAÇÃO PARA COMANDO ===
  Future<void> _createCommandNotification(String commandType) async {
    try {
      String deviceName = StaticVarMethod.deviceName;
      String notificationTitle = '';
      String notificationMessage = '';

      // Determinar tipo de notificação baseado no comando
      switch (commandType.toLowerCase()) {
        case 'unlock':
        case 'desbloquear':
          notificationTitle = TranslationHelper.translateSync(context, '🔓 Veículo Desbloqueado', '🔓 Vehicle Unlocked');
          notificationMessage = TranslationHelper.translateSync(context, 'Veículo $deviceName foi desbloqueado com sucesso', 'Vehicle $deviceName was successfully unlocked');
          break;
        case 'power_on':
        case 'ligar_motor':
          notificationTitle = TranslationHelper.translateSync(context, '🚗 Motor Ligado', '🚗 Engine On');
          notificationMessage = TranslationHelper.translateSync(context, 'Motor do veículo $deviceName foi ligado', 'Engine of vehicle $deviceName was turned on');
          break;
        case 'lock':
        case 'desligar_motor':
          notificationTitle = TranslationHelper.translateSync(context, '🔒 Motor Bloqueado', '🔒 Engine Locked');
          notificationMessage = TranslationHelper.translateSync(context, 'Motor do veículo $deviceName foi bloqueado', 'Engine of vehicle $deviceName was locked');
          break;
        case 'alarm_on':
        case 'ativar_alarme':
          notificationTitle = TranslationHelper.translateSync(context, '🚨 Alarme Ativado', '🚨 Alarm Activated');
          notificationMessage = TranslationHelper.translateSync(context, 'Alarme do veículo $deviceName foi ativado', 'Alarm of vehicle $deviceName was activated');
          break;
        case 'alarm_off':
        case 'desativar_alarme':
          notificationTitle = TranslationHelper.translateSync(context, '🔇 Alarme Desativado', '🔇 Alarm Deactivated');
          notificationMessage = TranslationHelper.translateSync(context, 'Alarme do veículo $deviceName foi desativado', 'Alarm of vehicle $deviceName was deactivated');
          break;
        case 'anchor_on':
        case 'ativar_ancora':
          notificationTitle = TranslationHelper.translateSync(context, '🔒 Antifurto Ativado', '🔒 Antitheft Activated');
          notificationMessage = '${TranslationHelper.translateSync(context, 'Antifurto do veículo', 'Antitheft of vehicle')} $deviceName ${TranslationHelper.translateSync(context, 'foi ativado', 'was activated')}';
          break;
        case 'anchor_off':
        case 'desativar_ancora':
          notificationTitle = TranslationHelper.translateSync(context, '🔓 Antifurto Desativado', '🔓 Antitheft Deactivated');
          notificationMessage = '${TranslationHelper.translateSync(context, 'Antifurto do veículo', 'Antitheft of vehicle')} $deviceName ${TranslationHelper.translateSync(context, 'foi desativado', 'was deactivated')}';
          break;
        case 'sos':
        case 'ativar_sos':
          notificationTitle = TranslationHelper.translateSync(context, '🚨 SOS Ativado', '🚨 SOS Activated');
          notificationMessage = TranslationHelper.translateSync(context, 'SOS do veículo $deviceName foi ativado', 'SOS of vehicle $deviceName was activated');
          break;
        default:
          notificationTitle = TranslationHelper.translateSync(context, '📱 Comando Executado', '📱 Command Executed');
          notificationMessage = TranslationHelper.translateSync(context, 'Comando executado no veículo $deviceName', 'Command executed on vehicle $deviceName');
      }

      // Removido: NotificationManager não existe
      // await NotificationManager.addNotification(...);

      // Mostrar SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notificationMessage),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Notificações locais e sons desativados no mapa

      print(
          '📱 Notificação de comando criada: $notificationTitle - $notificationMessage');
    } catch (e) {
      print('❌ Erro ao criar notificação de comando: $e');
    }
  }

  // === REMOVIDO: MODAL DE SOS (PÂNICO) ===
  // Todas as funções SOS foram removidas:
  // - _triggerSOS
  // - _showSOSDialog
  // - _notifyServerSOS
  // - _notifyServerSOSResolved
  // - _sendSOSWithFallback
  // - _addSOSMarker
  // - _removeSOSMarker

  // Removido: envio de push notification (não utilizado)

  // === OBTER ARQUIVO DE SOM PARA EVENTO ===
  // Removido: mapeamento de arquivos de som por evento (não utilizado)

  // === REPRODUZIR SOM DO COMANDO ===
  // Removido: reprodução de som de comando no mapa

  // === CRIAÇÃO DE MARCADORES PERSONALIZADOS ===
  Future<gmaps.BitmapDescriptor> _createImageLabel({
    String iconpath = '',
    String label = 'label',
    double course = 0,
    Color color = Colors.red,
    bool showtitle = true,
    double scale = 1.0,
  }) async {
    return getMarkerIcon(iconpath, label, color, course, showtitle, scale);
  }

  // === CARREGAMENTO DE IMAGENS ===
  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // === TIMER DE ATUALIZAÇÃO AUTOMÁTICA ===
  void _startAutoUpdateTimer() {
    // Usar intervalo fixo (PerformanceConfig não existe)
    const updateInterval = 10; // 10 segundos
    _updateTimer = Timer.periodic(Duration(seconds: updateInterval), (timer) {
      if (_isMapReady && mounted && !_justSelectedVehicle) {
        // Não atualizar se um veículo foi selecionado recentemente
        _loadDevicesFromAPI().then((_) {
          if (mounted && !_justSelectedVehicle) {
            // Atualizar apenas posições dos marcadores existentes
            _updateMarkersPositions();
            // Verificar violações de âncora a cada atualização
            _checkAnchorViolations();
            // Log reduzido para melhorar performance
            // print('🔄 Dados atualizados automaticamente');
          }
        }).catchError((e) {
          // Erro silencioso
        });
      }
    });
    
    // Timer adicional para verificar violações mais frequentemente (a cada 5 segundos)
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_isMapReady && mounted && !_justSelectedVehicle) {
        _checkAnchorViolations();
      }
    });

    // Removido: verificação de âncora (AnchorService não existe)
    // Timer separado para verificar eventos de saída da âncora
    // const anchorCheckInterval = updateInterval * 2;
    // Timer.periodic(Duration(seconds: anchorCheckInterval), (timer) {
    //   ...
    // });
  }

  // === VERIFICAÇÃO DE ÂNCORA ===
  // Agora usa o AnchorService - verificação feita nos timers

  // === ATUALIZAR APENAS POSIÇÕES DOS MARCADORES ===
  Future<void> _updateMarkersPositions() async {
    if (_deviceMarkers.isEmpty || _devicesList.isEmpty) {
      // Se não há marcadores, criar todos
      if (_isFirstLoad) {
        _showAllVehiclesWithoutFilters();
      }
      return;
    }

    // Atualizar apenas posições e propriedades, sem recriar marcadores
    for (var device in _devicesList) {
      if (device.lat != null && device.lng != null && device.lat != 0) {
        String deviceId = device.id.toString();

        // Verificar se o marcador já existe
        if (_deviceMarkers.containsKey(deviceId)) {
          // Usar posição atual (com deslizamento) ou posição original
          gmaps.LatLng currentPosition = _currentPositions[deviceId] ??
              gmaps.LatLng(device.lat!, device.lng!);

          // Recriar marcador com nova posição (marcadores são imutáveis)
          gmaps.Marker existingMarker = _deviceMarkers[deviceId]!;
          _deviceMarkers[deviceId] = gmaps.Marker(
            markerId: existingMarker.markerId,
            position: currentPosition,
            onTap: existingMarker.onTap,
            anchor: existingMarker.anchor,
            icon: existingMarker.icon,
            rotation: existingMarker.rotation,
          );
        } else {
          // Se não existe, criar novo marcador (mas não limpar todos)
          await _createSingleMarker(device);
        }
      }
    }

    // Remover marcadores de veículos que não existem mais
    _deviceMarkers.removeWhere((key, marker) {
      // Preservar marcadores de rótulo de âncora
      // Labels de âncora removidos
      return !_devicesList.any((device) => device.id.toString() == key);
    });

    setState(() {});
  }

  // === CRIAR UM ÚNICO MARCADOR ===
  Future<void> _createSingleMarker(deviceItems device) async {
    try {
      String other = device.deviceData?.traccar?.other?.toString() ?? "";
      String ignition = "false";
      if (other.contains("<ignition>")) {
        const start = "<ignition>";
        const end = "</ignition>";
        final startIndex = other.indexOf(start);
        final endIndex = other.indexOf(end, startIndex + start.length);
        ignition = other.substring(startIndex + start.length, endIndex);
      }

      var color;
      // Define a cor do label com base no status
      if (device.speed!.toInt() > 0) {
        color = Colors.green;
      } else if (device.online!.contains('engine')) {
        color = Colors.yellow;
      } else if (device.online!.contains('online')) {
        color = Colors.green;
      } else if (device.online!.contains('ack')) {
        color = Colors.red;
      } else if (device.online!.contains('offline')) {
        color = Colors.blue;
      } else {
        color = Colors.grey;
      }

      String ignitionIcon = '🔴';
      if (ignition.contains("true") && device.speed! > 0) {
        ignitionIcon = '🟢';
      } else if (ignition.contains("true")) {
        ignitionIcon = '🟢';
      }

      String speedLabel = '${device.speed!.toDouble().toStringAsFixed(0)} km/h';
      String label = '${device.name} $ignitionIcon $speedLabel';

      // Converter para double caso venha como int
      double lat = device.lat is double
          ? device.lat as double
          : (device.lat as num).toDouble();
      double lng = device.lng is double
          ? device.lng as double
          : (device.lng as num).toDouble();

      String deviceId = device.id.toString();
      gmaps.LatLng currentPosition =
          _currentPositions[deviceId] ?? gmaps.LatLng(lat, lng);

      String baseUrl = "https://web.unnicatelemetria.com.br/";
      String? deviceIconPath = device.icon?.path;
      String deviceIconFullPath = baseUrl + (deviceIconPath ?? '');

      // Aplicar escala apenas no veículo selecionado (por IMEI)
      final bool isSelectedMarker =
          (device.deviceData?.imei?.toString() ?? '') == StaticVarMethod.imei;

      // Obter tamanho do marcador do provider
      final settingsProvider = Provider.of<AppSettingsProvider>(context, listen: false);
      final baseScale = settingsProvider.markerSize;
      final selectedScale = isSelectedMarker ? _markerScale * baseScale : baseScale;

      gmaps.BitmapDescriptor customIcon = await _createImageLabel(
        iconpath: deviceIconFullPath,
        label: label,
        course: device.course.toDouble(),
        color: color,
        showtitle: _showTitle,
        scale: selectedScale,
      );

      _deviceMarkers[deviceId] = gmaps.Marker(
        markerId: gmaps.MarkerId(deviceId),
        position: currentPosition,
        onTap: () {
          // Executar de forma assíncrona para não travar a UI
          Future.microtask(() async {
            try {
              if (!mounted) return;

              StaticVarMethod.imei = device.deviceData?.imei?.toString() ?? "";

              // SEMPRE mostrar painel, mesmo que já tenha centralizado
              if (mounted) {
                // Definir veículo selecionado no MapController
                final mapController = Provider.of<MapController>(context, listen: false);
                mapController.setSelectedVehicle(device);
                
                setState(() {
                  isshowvehicledetail = true; // SEMPRE mostrar o card
                });
              }

              // Centralizar mapa de forma assíncrona (não bloqueia UI)
              _centerMapOnVehicle(device);
            } catch (e) {
              // Erro silencioso
            }
          });
        },
        anchor: const Offset(0.5, 0.5),
        icon: customIcon,
      );

      // Armazenar escala base para animação
      _markerBaseScales[deviceId] = selectedScale;

      // Verificar se deve aplicar animação
      final shouldAnimate = settingsProvider.markerAnimation;

      // Se animação estiver ativa, iniciar animação pulsante
      if (shouldAnimate && !_markerPulseControllers.containsKey(deviceId)) {
        _startMarkerAnimation(deviceId, device);
      } else if (!shouldAnimate && _markerPulseControllers.containsKey(deviceId)) {
        _stopMarkerAnimation(deviceId);
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  // === CALLBACKS DO MAPA ===
  void _onMapCreated(gmaps.GoogleMapController controller) {
    try {
      _mapController = controller;
      // Inicializar posição da câmera
      _currentCameraTarget = _initialPosition;
      // Sincronizar slider com zoom atual
      _zoomSlider = _currentZoom;
      if (mounted) {
        setState(() {
          _showMapLoading = false;
          _isMapReady = true;
        });
      }

      // Garantir que os veículos apareçam após o mapa estar pronto
      if (_devicesList.isNotEmpty && mounted) {
        // Adicionar delay para evitar conflitos
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            try {
              _showAllVehiclesWithoutFilters();
            } catch (e) {
              // Erro silencioso
            }
          }
        });
      }
    } catch (e) {
      // Erro silencioso - apenas garantir estado correto
      if (mounted) {
        try {
          setState(() {
            _showMapLoading = false;
            _isMapReady = false;
          });
        } catch (_) {
          // Erro ao fazer setState
        }
      }
    }
  }

  void _onCameraMove(gmaps.CameraPosition position) {
    try {
      // Atualizar variáveis sem setState para melhor performance
      // Este método é chamado muitas vezes durante o movimento da câmera
      _currentZoom = position.zoom;
      _tiltAngle = position.tilt;
      _currentCameraTarget = position.target;

      // Atualizar slider apenas se a diferença for significativa (>0.5)
      if ((_zoomSlider - position.zoom).abs() > 0.5 && mounted) {
        _zoomSlider = position.zoom;
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  void _onCameraIdle() {
    try {
      // Reseta o flag após o idle, mas com delay para garantir que a centralização seja mantida
      if (_justSelectedVehicle && mounted) {
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
        setState(() {
          _justSelectedVehicle = false;
            });
          }
        });
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  // Removido: função não utilizada

  // === MÉTODOS DE UTILIDADE ===

  // Funções de zoom
  void _zoomIn() {
    if (_mapController != null && _currentCameraTarget != null) {
      final newZoom = (_currentZoom + 1).clamp(3.0, 20.0);
      setState(() {
        _currentZoom = newZoom;
        _zoomSlider = newZoom;
      });
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: _currentCameraTarget!,
            zoom: newZoom,
            tilt: _tiltAngle,
          ),
        ),
      );
    }
  }

  void _zoomOut() {
    if (_mapController != null && _currentCameraTarget != null) {
      final newZoom = (_currentZoom - 1).clamp(3.0, 20.0);
      setState(() {
        _currentZoom = newZoom;
        _zoomSlider = newZoom;
      });
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: _currentCameraTarget!,
            zoom: newZoom,
            tilt: _tiltAngle,
          ),
        ),
      );
    }
  }

  // === MÉTODOS DE CONTROLE ===

  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case gmaps.MapType.normal:
          _currentMapType = gmaps.MapType.satellite;
          break;
        case gmaps.MapType.satellite:
          _currentMapType = gmaps.MapType.hybrid;
          break;
        case gmaps.MapType.hybrid:
          _currentMapType = gmaps.MapType.normal;
          break;
        default:
          _currentMapType = gmaps.MapType.normal;
      }
    });
  }

  // Método para obter o ícone correto baseado no tipo de mapa
  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case gmaps.MapType.normal:
        return Icons.map;
      case gmaps.MapType.satellite:
        return Icons.satellite;
      case gmaps.MapType.hybrid:
        return Icons.layers;
      default:
        return Icons.map;
    }
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
  }

  void _toggleTrail() {
    final mapController = Provider.of<MapController>(context, listen: false);
    
    // Verificar se há um veículo selecionado
    if (!mapController.showTrail && mapController.selectedVehicle == null) {
      // Tentar usar o veículo selecionado via IMEI
      if (StaticVarMethod.imei.isNotEmpty) {
        try {
          final selectedDevice = _devicesList.firstWhere(
            (device) => device.deviceData?.imei?.toString() == StaticVarMethod.imei,
          );
          mapController.setSelectedVehicle(selectedDevice);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver o rastro', 'Select a vehicle first to see the trail')),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro para ver o rastro', 'Select a vehicle first to see the trail')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    // Usar o MapController para gerenciar o rastro
    mapController.toggleTrail();
    
    // Atualizar estado local
    setState(() {
      _showTrail = mapController.showTrail;
      // Atualizar polylines do mapa com as do controller
      _trailPolylines = mapController.polylines.where((p) => p.polylineId.value.startsWith('trail_')).toSet();
    });
    
    // Se o rastro foi ativado e há veículo selecionado, garantir que a trilha seja carregada
    if (_showTrail && mapController.selectedVehicle != null) {
      // O MapController já carrega a trilha automaticamente quando toggleTrail é chamado
      // Mas vamos garantir que as polylines sejam atualizadas
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
      _trailPolylines = mapController.polylines.where((p) => p.polylineId.value.startsWith('trail_')).toSet();
    });
        }
      });
    }
  }

  // === NAVEGAÇÃO ATÉ O VEÍCULO ===

  /// Obtém a localização atual do usuário
  Future<Position?> _getCurrentUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Serviços de localização estão desabilitados', 'Location services are disabled')),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Permissão de localização negada', 'Location permission denied')),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Permissão de localização negada permanentemente. Ative nas configurações.', 'Location permission permanently denied. Enable in settings.')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao obter localização', 'Error getting location')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  /// Calcula a rota da localização atual até o veículo usando Google Directions API
  Future<void> _calculateRouteToVehicle(deviceItems vehicle) async {
    if (vehicle.lat == null || vehicle.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Posição do veículo não disponível', 'Vehicle position not available')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text(TranslationHelper.translateSync(context, 'Calculando rota...', 'Calculating route...')),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Obter localização atual do usuário
      Position? userPosition = await _getCurrentUserLocation();
      if (userPosition == null) {
        return;
      }

      final originLat = userPosition.latitude;
      final originLng = userPosition.longitude;
      final destLat = (vehicle.lat as num).toDouble();
      final destLng = (vehicle.lng as num).toDouble();

      // Verificar cache de rota (economiza API calls)
      final routeCacheKey =
          '${originLat.toStringAsFixed(4)}_${originLng.toStringAsFixed(4)}_${destLat.toStringAsFixed(4)}_${destLng.toStringAsFixed(4)}';

      if (_routeCache.containsKey(routeCacheKey)) {
        try {
          final cachedRoute = _routeCache[routeCacheKey]!;
          final cacheTime = cachedRoute['timestamp'] as DateTime?;

          if (cacheTime != null &&
              DateTime.now().difference(cacheTime) < _routeCacheDuration) {
            print('📦 Usando rota do cache (economizando API call)');

            final cachedDistance = cachedRoute['distance'] as String?;
            final cachedDuration = cachedRoute['duration'] as String?;
            final cachedCoords = cachedRoute['coordinates'];

            if (cachedDistance != null &&
                cachedDuration != null &&
                cachedCoords != null) {
              // Converter coordenadas do cache corretamente
              List<gmaps.LatLng> coordsList = [];
              if (cachedCoords is List) {
                for (var coord in cachedCoords) {
                  if (coord is Map) {
                    coordsList.add(gmaps.LatLng(
                      (coord['latitude'] as num?)?.toDouble() ??
                          (coord['lat'] as num?)?.toDouble() ??
                          0.0,
                      (coord['longitude'] as num?)?.toDouble() ??
                          (coord['lng'] as num?)?.toDouble() ??
                          0.0,
                    ));
                  } else if (coord is gmaps.LatLng) {
                    coordsList.add(coord);
                  }
                }
              }

              if (coordsList.isNotEmpty) {
                _routeDistance = cachedDistance;
                _routeDuration = cachedDuration;
                _routeCoordinates = coordsList;

                final routePolylineId = gmaps.PolylineId('navigation_route');
                _navigationRoute = gmaps.Polyline(
                  polylineId: routePolylineId,
                  color: Colors.blue,
                  width: 5,
                  points: _routeCoordinates,
                  patterns: [
                    gmaps.PatternItem.dash(20),
                    gmaps.PatternItem.gap(10)
                  ],
                  geodesic: true,
                );

                setState(() {
                  _routePolylines.clear();
                  _routePolylines.add(_navigationRoute!);
                  _showRoute = true;
                });

                if (_mapController != null && _routeCoordinates.isNotEmpty) {
                  try {
                    final bounds = _boundsFromLatLngList(_routeCoordinates);
                    await _mapController!.animateCamera(
                      gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
                    );
                  } catch (e) {
                    print('⚠️ Erro ao ajustar câmera: $e');
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${TranslationHelper.translateSync(context, 'Rota (cache)', 'Route (cached)')}: $_routeDistance - $_routeDuration',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: TranslationHelper.translateSync(context, 'Abrir no Maps', 'Open in Maps'),
                        textColor: Colors.white,
                        onPressed: () => _openNavigationInMaps(
                            originLat, originLng, destLat, destLng),
                      ),
                    ),
                  );
                }
                return;
              }
            }
          }
        } catch (e) {
          print('⚠️ Erro ao usar cache de rota: $e');
          // Se houver erro no cache, continuar para buscar nova rota
          _routeCache.remove(routeCacheKey);
        }
      }

      // Construir URL da Directions API
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=driving'
        '&language=pt-BR'
        '&key=AIzaSyAF5K1-6hqTKD6l8dA1_9Avxt06KGOM-Zg', // Google Maps API Key
      );

      print(
          '🗺️ Calculando rota: ($originLat, $originLng) -> ($destLat, $destLng)');

      // Fazer requisição
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        throw Exception(
            'Erro da API: ${data['status']} - ${data['error_message'] ?? ''}');
      }

      if (data['routes'] == null || data['routes'].isEmpty) {
        throw Exception('Nenhuma rota encontrada');
      }

      final route = data['routes'][0];

      if (route['legs'] == null || (route['legs'] as List).isEmpty) {
        throw Exception('Rota sem informações de percurso');
      }

      final leg = route['legs'][0];

      // Extrair distância e duração com verificações de segurança
      if (leg['distance'] == null || leg['distance']['text'] == null) {
        throw Exception('Distância não disponível na resposta da API');
      }
      if (leg['duration'] == null || leg['duration']['text'] == null) {
        throw Exception('Duração não disponível na resposta da API');
      }

      _routeDistance = leg['distance']['text'] as String;
      _routeDuration = leg['duration']['text'] as String;

      // Extrair coordenadas da rota
      if (route['overview_polyline'] == null ||
          route['overview_polyline']['points'] == null) {
        throw Exception('Coordenadas da rota não disponíveis');
      }

      final polyline = route['overview_polyline']['points'] as String;
      if (polyline.isEmpty) {
        throw Exception('Polyline vazio');
      }

      _routeCoordinates = _decodePolyline(polyline);

      if (_routeCoordinates.isEmpty) {
        throw Exception('Falha ao decodificar coordenadas da rota');
      }

      // Criar polilinha da rota
      final routePolylineId = gmaps.PolylineId('navigation_route');
      _navigationRoute = gmaps.Polyline(
        polylineId: routePolylineId,
        color: Colors.blue,
        width: 5,
        points: _routeCoordinates,
        patterns: [gmaps.PatternItem.dash(20), gmaps.PatternItem.gap(10)],
        geodesic: true,
      );

      // Adicionar rota ao conjunto de polylines
      setState(() {
        _routePolylines.clear();
        _routePolylines.add(_navigationRoute!);
        _showRoute = true;
      });

      // Salvar no cache para próximas buscas (converter para formato serializável)
      try {
        _routeCache[routeCacheKey] = {
          'distance': _routeDistance!,
          'duration': _routeDuration!,
          'coordinates': _routeCoordinates
              .map((coord) => {
                    'latitude': coord.latitude,
                    'longitude': coord.longitude,
                  })
              .toList(),
          'timestamp': DateTime.now(),
        };
      } catch (e) {
        print('⚠️ Erro ao salvar rota no cache: $e');
      }

      // Ajustar câmera para mostrar toda a rota
      if (_mapController != null && _routeCoordinates.isNotEmpty) {
        final bounds = _boundsFromLatLngList(_routeCoordinates);
        await _mapController!.animateCamera(
          gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }

      // Mostrar informações da rota
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rota calculada: $_routeDistance - $_routeDuration',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: TranslationHelper.translateSync(context, 'Abrir no Maps', 'Open in Maps'),
              textColor: Colors.white,
              onPressed: () =>
                  _openNavigationInMaps(originLat, originLng, destLat, destLng),
            ),
          ),
        );
      }

      print(
          '✅ Rota calculada com sucesso e armazenada no cache: $_routeDistance - $_routeDuration');
    } catch (e, stackTrace) {
      print('❌ Erro ao calcular rota: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.translateSync(context, 'Erro ao calcular rota', 'Error calculating route')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Decodifica uma string polyline do Google Maps em uma lista de coordenadas
  List<gmaps.LatLng> _decodePolyline(String encoded) {
    List<gmaps.LatLng> poly = [];
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

      poly.add(gmaps.LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  /// Calcula os bounds de uma lista de coordenadas
  gmaps.LatLngBounds _boundsFromLatLngList(List<gmaps.LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat ?? 0, minLng ?? 0),
      northeast: gmaps.LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  /// Abre a navegação no app Google Maps
  Future<void> _openNavigationInMaps(double originLat, double originLng,
      double destLat, double destLng) async {
    try {
      // URL para abrir no Google Maps app com navegação
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Não foi possível abrir o Google Maps', 'Could not open Google Maps')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao abrir navegação: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao abrir navegação', 'Error opening navigation')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Remove a rota de navegação do mapa
  void _clearNavigationRoute() {
    setState(() {
      _showRoute = false;
      _routeCoordinates.clear();
      _navigationRoute = null;
      _routeDistance = null;
      _routeDuration = null;
      _routePolylines.clear();
    });
  }

  // Removido: funções de Street View não utilizadas

  /// Constrói um botão com cor sólida usando a cor primária do usuário
  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required Widget icon,
    bool isActive = false,
    String? tooltip,
    ColorProvider? colorProvider,
  }) {
    // Usar ColorProvider se disponível, senão usar Theme
    final primaryColor = colorProvider?.primaryColor ?? Theme.of(context).colorScheme.primary;

    // Quando ativo: fundo branco, bordas e ícones na cor do tema
    // Quando inativo: fundo na cor do tema, ícone branco
    Widget finalIcon = icon;
    Color iconColor;
    Color backgroundColor;
    Color borderColor;
    
    if (isActive) {
      // Ativo: fundo branco, bordas e ícones na cor do tema
      backgroundColor = Colors.white;
      borderColor = primaryColor;
      iconColor = primaryColor;
      
      // Sempre substituir a cor do ícone pela cor do tema quando ativo
      if (icon is Icon) {
        finalIcon = Icon(
          icon.icon,
          color: iconColor, // Sempre usar cor do tema quando ativo
          size: icon.size ?? 20,
        );
      }
    } else {
      // Inativo: fundo na cor do tema, ícone branco
      backgroundColor = primaryColor.withOpacity(0.9);
      borderColor = primaryColor;
      iconColor = Colors.white;
      
      if (icon is Icon && icon.color == null) {
        finalIcon = Icon(
          icon.icon,
          color: iconColor,
          size: icon.size ?? 20,
        );
      }
    }

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Prevenir propagação do evento para o mapa
          onPressed();
        },
        child: Container(
          width: 48, // Diminuído um pouco
          height: 48, // Diminuído um pouco
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: isActive ? 2.5 : 0, // Borda mais visível quando ativo
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Prevenir propagação do evento para o mapa
                onPressed();
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: primaryColor.withOpacity(0.3),
              highlightColor: primaryColor.withOpacity(0.2),
              child: Container(
                alignment: Alignment.center,
                child: finalIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === CONTROLLER 3D ===
  // Removido: Map3DController não existe
  // final Map3DController _map3DController = Map3DController();
  Future<void> _toggle3DView() async {
    // Implementação simples de toggle 3D
    if (_mapController == null) return;

    // Usar a posição atual da câmera ou a posição inicial
    final target = _currentCameraTarget ?? _initialPosition;
    
    setState(() {
      _tiltAngle = _tiltAngle == 0.0 ? 45.0 : 0.0;
      // Diminuir zoom ao ativar 3D
      if (_tiltAngle > 0) {
        _currentZoom = (_currentZoom - 2).clamp(3.0, 20.0);
        _zoomSlider = _currentZoom;
      }
    });
    
    await _mapController!.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: target,
          zoom: _currentZoom,
          tilt: _tiltAngle,
        ),
      ),
    );
  }

  void _goToMyLocation() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLng(_initialPosition),
      );
    }
  }

  void _locateAllDevices() {
    // Função desabilitada - não centralizar todos os veículos
    print('ℹ️ Centralização de todos os veículos desabilitada');
  }

  // === TOGGLE PONTOS DE INTERESSE ===
  bool _showPOIs = false;
  Set<gmaps.Marker> _poiMarkers = {};
  
  Future<void> _togglePOIs() async {
    if (!_showPOIs) {
      // Ativando POIs - buscar pontos de interesse
      if (_currentCameraTarget == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Centralize o mapa primeiro para buscar pontos de interesse', 'Center the map first to search for points of interest')),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text(TranslationHelper.translateSync(context, 'Buscando pontos de interesse...', 'Searching for points of interest...')),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Buscar POIs ao redor da posição atual da câmera
        final center = gmaps.LatLng(_currentCameraTarget!.latitude, _currentCameraTarget!.longitude);
        final poiMarkers = await POIService.getNearbyPOIs(
          center: center,
          radius: 2000.0, // 2km
          maxResults: 30,
        );

        // Converter para marcadores do Google Maps
        final googleMapMarkers = poiMarkers.map((poi) {
          return gmaps.Marker(
            markerId: gmaps.MarkerId(poi.id),
            position: gmaps.LatLng(poi.position.latitude, poi.position.longitude),
            icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(poi.type.hue),
            infoWindow: gmaps.InfoWindow(
              title: poi.name,
              snippet: '${poi.type.name}${poi.rating != null ? ' • ⭐ ${poi.rating!.toStringAsFixed(1)}' : ''}${poi.isOpen != null ? (poi.isOpen! ? ' • 🟢 Aberto' : ' • 🔴 Fechado') : ''}',
            ),
            onTap: () {
              _showPOIDetails(poi.placeId);
            },
          );
        }).toSet();

        setState(() {
          _showPOIs = true;
          _poiMarkers = googleMapMarkers;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${poiMarkers.length} ${TranslationHelper.translateSync(context, 'pontos de interesse encontrados', 'points of interest found')}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('❌ Erro ao buscar POIs: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${TranslationHelper.translateSync(context, 'Erro ao buscar pontos de interesse', 'Error searching for points of interest')}: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Desativando POIs - remover marcadores
      setState(() {
        _showPOIs = false;
        _poiMarkers.clear();
      });
    }
  }

  void _removePOIMarkers() {
    setState(() {
      _poiMarkers.clear();
    });
  }

  // === BUSCAR PONTOS DE INTERESSE PRÓXIMOS ===
  Future<void> _fetchNearbyPlaces() async {
    // Implementação vazia - POI controller não existe
  }

  // === MOSTRAR DETALHES DO POI ===
  Future<void> _showPOIDetails(String placeId) async {
    print('📍 POI details: $placeId');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Buscar detalhes do POI usando POIService
      final poiDetails = await POIService.getPOIDetails(placeId);
      if (context.mounted) Navigator.pop(context);
      
      if (poiDetails == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Não foi possível carregar detalhes do ponto de interesse', 'Could not load point of interest details')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final name = poiDetails.name;
      final phone = poiDetails.phoneNumber ?? TranslationHelper.translateSync(context, 'Telefone não disponível', 'Phone not available');
      final rating = poiDetails.rating;
      final website = poiDetails.website;
      final reviews = poiDetails.reviews;
      final openingHours = poiDetails.openingHours;

      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 16),
                      if (rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (reviews != null && reviews.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${reviews.length} ${TranslationHelper.translateSync(context, 'avaliações', 'reviews')})',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (openingHours != null && openingHours.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationHelper.translateSync(context, 'Horários:', 'Hours:'),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ...(openingHours.map((text) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(text,
                                      style: TextStyle(
                                          color: Colors.grey[700])),
                                ))),
                          ],
                        ),
                      const SizedBox(height: 16),
                      if (phone != TranslationHelper.translateSync(context, 'Telefone não disponível', 'Phone not available'))
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                phone,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.call),
                              onPressed: () async {
                                try {
                                  final uri = Uri.parse('tel:$phone');
                                  await launchUrl(uri);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('${TranslationHelper.translateSync(context, 'Erro ao fazer ligação', 'Error making call')}: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (website != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final uri = Uri.parse(website);
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('${TranslationHelper.translateSync(context, 'Erro ao abrir site', 'Error opening website')}: $e')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.language),
                                label: Text(TranslationHelper.translateSync(context, 'Site', 'Website')),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (reviews != null && reviews.isNotEmpty) ...[
                        const Divider(),
                        Text(
                          TranslationHelper.translateSync(context, 'Avaliações', 'Reviews'),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...reviews.take(3).map((review) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        review.authorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          Text(review.rating.toString()),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (review.text.isNotEmpty)
                                    Text(
                                      review.text,
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14),
                                    ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      print('❌ Erro ao mostrar detalhes do POI: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${TranslationHelper.translateSync(context, 'Erro ao carregar detalhes', 'Error loading details')}: $e')),
      );
    }
  }

  // === ABRIR STREET VIEW ===
  // Removido: função não utilizada

  void _showAuthenticationError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(TranslationHelper.translateSync(context, 'Erro de Autenticação', 'Authentication Error')),
          content:
              Text(TranslationHelper.translateSync(context, 'Usuário não autenticado. Faça login para continuar.', 'User not authenticated. Please login to continue.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(TranslationHelper.translateSync(context, 'OK', 'OK')),
            ),
          ],
        );
      },
    );
  }

  // === SELECIONAR PRIMEIRO VEÍCULO AUTOMATICAMENTE ===
  // Removido: função não utilizada (seleção automática desabilitada - usuário deve clicar no veículo)

  // === FILTRO DE VEÍCULOS ===
  void _filterVehicles(String query) async {
    if (query.isEmpty) {
      // Se a busca estiver vazia, mostrar todos os veículos
      _createDeviceMarkers();
      return;
    }

    List<deviceItems> filteredDevices = _devicesList.where((device) {
      String name = device.name?.toLowerCase() ?? '';
      String plate = _extractPlateNumber(device).toLowerCase();
      String searchQuery = query.toLowerCase();

      return name.contains(searchQuery) || plate.contains(searchQuery);
    }).toList();

    // Atualizar marcadores com veículos filtrados
    _deviceMarkers.clear();
    for (int i = 0; i < filteredDevices.length; i++) {
      deviceItems device = filteredDevices[i];
      if (device.lat != null && device.lng != null) {
        final bool isSelectedMarker =
            (device.deviceData?.imei?.toString() ?? '') == StaticVarMethod.imei;

        gmaps.BitmapDescriptor customIcon = await getMarkerIcon(
            '',
            device.name ?? 'Veículo',
            device.online == true ? Colors.green : Colors.red,
            0,
            true,
            isSelectedMarker ? _markerScale : 1.0);

        gmaps.Marker marker = gmaps.Marker(
          markerId: gmaps.MarkerId(device.id.toString()),
          position: gmaps.LatLng(device.lat!, device.lng!),
          onTap: () {
            try {
              StaticVarMethod.imei = device.deviceData?.imei?.toString() ?? "";
              if (mounted) {
                setState(() {
                  isshowvehicledetail = true;
                });
                // Centralizar mapa no veículo clicado
                _centerMapOnVehicle(device);
              }
            } catch (e) {
              // Erro silencioso - apenas log interno
            }
          },
          anchor: const Offset(0.5, 0.5),
          icon: customIcon,
        );

        _deviceMarkers[device.id.toString()] = marker;
      }
    }

    setState(() {});
  }

  // === MÉTODOS AUXILIARES PARA O PAINEL DE DETALHES ===

  String _extractPlateNumber(deviceItems device) {
    // Primeiro tenta usar o plateNumber direto da API
    if (device.deviceData?.plateNumber != null &&
        device.deviceData!.plateNumber!.isNotEmpty) {
      return device.deviceData!.plateNumber!;
    }

    // Se não tiver, tenta extrair da string 'other' usando regex
    if (device.deviceData?.traccar?.other != null) {
      RegExp plateRegex =
          RegExp(r'[A-Z]{3}[0-9]{4}|[A-Z]{3}[0-9][A-Z][0-9]{2}');
      Match? match =
          plateRegex.firstMatch(device.deviceData!.traccar!.other!.toString());
      if (match != null) {
        return match.group(0)!;
      }
    }

    // Fallback: usa partes do nome
    if (device.name != null && device.name!.isNotEmpty) {
      List<String> nameParts = device.name!.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0]} ${nameParts[1]}';
      }
      return device.name!;
    }

    return TranslationHelper.translateSync(context, 'N/A', 'N/A');
  }

  // Removido: função não utilizada

  String _formatDateTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return TranslationHelper.translateSync(context, 'N/A', 'N/A');
    }

    try {
      DateTime dateTime;

      // Tenta diferentes formatos de data
      if (timeString.contains('T')) {
        dateTime = DateTime.parse(timeString);
      } else if (timeString.contains('-')) {
        dateTime = DateTime.parse(timeString);
      } else {
        // Assume timestamp em milissegundos
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timeString));
      }

      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}:'
          '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  // Removido: funções não utilizadas

  // Removido: função não utilizada

  // === FUNÇÃO PARA CENTRALIZAR MAPA EM VEÍCULO ESPECÍFICO ===
  Future<void> _centerMapOnVehicle(deviceItems device) async {
    if (!mounted) return;

    if (_mapController == null || device.lat == null || device.lng == null) {
      return;
    }

    try {
      // Converter para double caso venha como int
      double lat = device.lat is double
          ? device.lat as double
          : (device.lat as num).toDouble();
      double lng = device.lng is double
          ? device.lng as double
          : (device.lng as num).toDouble();

      // Validar coordenadas
      if (lat.isNaN || lng.isNaN || lat == 0.0 && lng == 0.0) {
        return;
      }

      // Atualizar zoom e slider sem setState bloqueante - zoom mais próximo
      _currentZoom = 18.0;
      _zoomSlider = 18.0;

      // Aguardar um frame antes de mover a câmera para evitar conflitos
      await Future.delayed(const Duration(milliseconds: 50));

      if (!mounted || _mapController == null) return;

      await _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(lat, lng),
          18.0, // Zoom mais próximo (18) ao selecionar veículo
        ),
      );
    } catch (e) {
      // Erro silencioso - não fazer nada
    }
  }

  // === FUNÇÃO PARA CONSTRUIR IMAGEM DO VEÍCULO (MESMA LÓGICA DA LISTA) ===
  Widget _buildVehicleImageForPanel(deviceItems device) {
    try {
      // Tentar obter a imagem da API
      String? imageUrl = device.image;
      String baseUrl = UserRepository.getServerURL() + "/";

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Construir URL completa da imagem
        String fullImageUrl =
            imageUrl.startsWith('http') ? imageUrl : "$baseUrl$imageUrl";

        // Se há URL da imagem, usar NetworkImage
        return Image.network(
          fullImageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback para ícone padrão se a imagem falhar
            return Image.network(
              "$baseUrl/images/device_icons/rotating/1.png",
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Último fallback para ícone se tudo falhar
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.directions_car,
                    size: 35,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            // Mostrar ícone simples enquanto carrega
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        );
      } else {
        // Se não há imagem, usar ícone padrão da API
        return Image.network(
          "$baseUrl/images/device_icons/rotating/1.png",
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback para ícone se tudo falhar
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.directions_car,
                size: 35,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('❌ Erro ao carregar imagem do veículo: $e');
      // Fallback final em caso de erro
      return Container(
        width: 80,
        height: 80,
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          Icons.directions_car,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  // === FUNÇÕES PARA EXTRAIR DADOS DOS SENSORES DA API ORIGINAL ===

  // Extrair status da ignição diretamente da API
  String _getIgnitionFromAPI(deviceItems device) {
    // Verifica primeiro nos sensores
    if (device.sensors != null && device.sensors!.isNotEmpty) {
      for (var sensor in device.sensors!) {
        if (sensor.type == 'acc' ||
            sensor.name?.toLowerCase().contains('ignition') == true) {
          return sensor.val == true ? 'Ligada' : 'Desligada';
        }
      }
    }

    // Verifica no campo 'other' do traccar
    if (device.deviceData?.traccar?.other != null) {
      String other = device.deviceData!.traccar!.other!.toString();
      if (other.contains('<ignition>')) {
        const start = '<ignition>';
        const end = '</ignition>';
        final startIndex = other.indexOf(start);
        final endIndex = other.indexOf(end, startIndex + start.length);
        if (startIndex != -1 && endIndex != -1) {
          String ignitionValue =
              other.substring(startIndex + start.length, endIndex);
          return ignitionValue.toLowerCase() == 'true' ? TranslationHelper.translateSync(context, 'Ligada', 'On') : TranslationHelper.translateSync(context, 'Desligada', 'Off');
        }
      }
    }

    // Fallback: baseado na velocidade e status online
    if (device.speed != null && device.speed! > 0) {
      return TranslationHelper.translateSync(context, 'Ligada', 'On');
    }

      return TranslationHelper.translateSync(context, 'Desligada', 'Off');
  }

  // Extrair status de movimento diretamente da API
  String _getMovementFromAPI(deviceItems device) {
    // Verifica primeiro nos sensores
    if (device.sensors != null && device.sensors!.isNotEmpty) {
      for (var sensor in device.sensors!) {
        if (sensor.type == 'motion' ||
            sensor.name?.toLowerCase().contains('movement') == true) {
          return sensor.val == true ? TranslationHelper.translateSync(context, 'Em Movimento', 'Moving') : TranslationHelper.translateSync(context, 'Parado', 'Stopped');
        }
      }
    }

    // Baseado na velocidade
    if (device.speed != null && device.speed! > 0) {
      return TranslationHelper.translateSync(context, 'Em Movimento', 'Moving');
    }

    // Baseado no status online
    if (device.online != null) {
      if (device.online!.contains('online') &&
          device.speed != null &&
          device.speed! > 0) {
        return TranslationHelper.translateSync(context, 'Em Movimento', 'Moving');
      } else if (device.online!.contains('online')) {
        return TranslationHelper.translateSync(context, 'Parado', 'Stopped');
      }
    }

    return TranslationHelper.translateSync(context, 'Parado', 'Stopped');
  }

  // Extrair distância total diretamente da API
  String _getDistanceFromAPI(deviceItems device) {
    if (device.totalDistance != null) {
      double distance = device.totalDistance!.toDouble();
      if (distance >= 1000) {
        return '${(distance / 1000).toStringAsFixed(1)} km';
      } else {
        return '${distance.toStringAsFixed(0)} m';
      }
    }
    return '0 km';
  }

  // Extrair última posição diretamente da API
  String _getLastPositionFromAPI(deviceItems device) {
    if (device.time != null && device.time!.isNotEmpty) {
      return _formatDateTime(device.time);
    }

    if (device.deviceData?.traccar?.time != null) {
      return _formatDateTime(device.deviceData!.traccar!.time);
    }

    return TranslationHelper.translateSync(context, 'N/A', 'N/A');
  }

  // Extrair endereço diretamente da API
  String _getAddressFromAPI(deviceItems device) {
    if (device.address != null &&
        device.address!.isNotEmpty &&
        device.address != '-') {
      return device.address!;
    }

    if (device.deviceData?.traccar?.address != null &&
        device.deviceData!.traccar!.address!.isNotEmpty &&
        device.deviceData!.traccar!.address != '-') {
      return device.deviceData!.traccar!.address!;
    }

    return TranslationHelper.translateSync(context, 'Endereço não disponível', 'Address not available');
  }

  // Removido: função não utilizada

  // Removido: funções não utilizadas

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    Color buttonColor = isActive ? Colors.green : color;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(isActive ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: buttonColor, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: buttonColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  // === MÉTODOS DE AÇÃO DOS BOTÕES ===

  void _toggleLock(deviceItems device) async {
    try {
      // Definir o deviceId para o sistema de comandos
      StaticVarMethod.deviceId = device.id.toString();
      StaticVarMethod.deviceName = device.name ?? 'Veículo';

      // Buscar comandos salvos para o dispositivo
      await getCommands();

      // Mostrar dialog com comandos disponíveis usando commandDialog do command_logic.dart
      commandDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao executar bloqueio', 'Error executing lock')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleAnchor(deviceItems device) async {
    // Verificar se já tem âncora ativa (verificação assíncrona para incluir API)
    final bool isAnchored = await _isVehicleAnchoredAsync(device);

    // Sempre mostrar o modal de criação/gerenciamento de âncora
    // O modal mostrará o botão de desativar se já existir uma âncora
    showDialog(
      context: context,
      builder: (context) {
        return CreateAnchorModal(
          device: device,
          hasActiveAnchor: isAnchored,
          onCreate: (name, radius, color, speedLimit, movementAllowed, {autoBlock, alertIgnition, alertSpeed}) {
            _activateAnchor(
              device,
              radius,
              name,
              color,
              speedLimit,
              movementAllowed,
              autoBlock: autoBlock,
              alertIgnition: alertIgnition,
              alertSpeed: alertSpeed,
            );
          },
          onDeactivate: () {
            _deactivateAnchor(device);
          },
        );
      },
    );
  }

  // Método _buildColorOption removido - agora está no CreateAnchorModal

  // === MÉTODOS DE VERIFICAÇÃO DE ESTADO ===
  // Implementação simplificada (AnchorService não existe)

  bool _isVehicleBlocked(deviceItems device) {
    // Verificar se o veículo está bloqueado baseado no alarm
    return device.alarm != null && device.alarm != 0;
  }

  bool _isVehicleAnchored(deviceItems device) {
    final deviceIdStr = device.id.toString();
    
    print('🔍 [_isVehicleAnchored] Verificando âncora para veículo ${device.name} (ID: ${device.id})');
    print('   📊 Total de círculos no mapa: ${_anchorCircles.length}');
    print('   📊 Total de posições fixas: ${_anchorFixedPositions.length}');
    print('   📊 Total de geofences ativas: ${_activeGeofences.length}');
    
    // Verificar se há um círculo de âncora para este dispositivo no mapa
    // Verificar tanto círculos criados diretamente quanto de geofences
    final hasCircle = _anchorCircles.any((circle) {
      final circleId = circle.circleId.value;
      
      // Círculo criado diretamente: anchor_${device.id}
      if (circleId == 'anchor_$deviceIdStr') {
        print('   ✅ Círculo encontrado: $circleId (criado diretamente)');
        return true;
      }
      
      // Círculo de geofence: verificar se o mapeamento indica que é deste device
      if (circleId.startsWith('anchor_geofence_')) {
        final mappedDeviceId = _circleIdToDeviceId[circleId];
        if (mappedDeviceId == deviceIdStr) {
          print('   ✅ Círculo encontrado: $circleId (geofence mapeada para device $mappedDeviceId)');
          return true;
        }
      }
      
      // Verificar círculos de onda também
      if (circleId.startsWith('anchor_wave_$deviceIdStr')) {
        print('   ✅ Círculo de onda encontrado: $circleId');
        return true;
      }
      
      return false;
    });
    
    if (hasCircle) {
      print('✅ [_isVehicleAnchored] Veículo ${device.name} (ID: ${device.id}) tem círculo no mapa');
      return true;
    }
    
    // Se não encontrou no mapa, verificar se há posição fixa armazenada
    // (indica que a âncora foi criada mas ainda não foi renderizada)
    if (_anchorFixedPositions.containsKey(deviceIdStr)) {
      print('✅ [_isVehicleAnchored] Veículo ${device.name} (ID: ${device.id}) tem posição fixa armazenada');
      return true;
    }
    
    // Verificar também por geofence_id se device_id for null
    for (var entry in _anchorFixedPositions.entries) {
      if (entry.key.startsWith('geofence_')) {
        // Verificar se há geofence ativa que corresponde a este veículo
        final hasMatchingGeofence = _activeGeofences.any((geofence) {
          if (geofence.id.toString() == entry.key.replaceAll('geofence_', '')) {
            // Verificar se corresponde ao veículo por nome ou coordenadas
            final geofenceName = geofence.name?.toLowerCase() ?? '';
            final deviceName = device.name?.toLowerCase() ?? '';
            
            if (geofenceName.contains(deviceName) || 
                geofenceName.contains('antifurto') ||
                geofenceName.contains('ancora')) {
              return true;
            }
            
            // Verificar por coordenadas próximas
            if (geofence.center != null && device.lat != null && device.lng != null) {
              final geofenceLat = geofence.center!.lat;
              final geofenceLng = geofence.center!.lng;
              final deviceLat = device.lat is double ? device.lat as double : (device.lat as num).toDouble();
              final deviceLng = device.lng is double ? device.lng as double : (device.lng as num).toDouble();
              
              final latDiff = (geofenceLat - deviceLat).abs();
              final lngDiff = (geofenceLng - deviceLng).abs();
              
              if (latDiff < 0.0001 && lngDiff < 0.0001) {
                return true;
              }
            }
          }
          return false;
        });
        
        if (hasMatchingGeofence) {
          print('✅ [_isVehicleAnchored] Veículo ${device.name} (ID: ${device.id}) tem geofence correspondente por posição fixa');
          return true;
        }
      }
    }
    
    // Verificar no cache de geofences ativas
    final hasActiveGeofence = _activeGeofences.any((geofence) {
      // Verificar por device_id
      if (geofence.device_id == device.id) {
        return geofence.isAnchor && geofence.isActive && geofence.type == 'circle';
      }
      
      // Se device_id é null, verificar por nome ou coordenadas
      if (geofence.device_id == null) {
        final geofenceName = geofence.name?.toLowerCase() ?? '';
        final deviceName = device.name?.toLowerCase() ?? '';
        
        if (geofenceName.contains(deviceName) || 
            geofenceName.contains('antifurto') ||
            geofenceName.contains('ancora')) {
          return geofence.isAnchor && geofence.isActive && geofence.type == 'circle';
        }
        
        // Verificar por coordenadas próximas
        if (geofence.center != null && device.lat != null && device.lng != null) {
          final geofenceLat = geofence.center!.lat;
          final geofenceLng = geofence.center!.lng;
          final deviceLat = device.lat is double ? device.lat as double : (device.lat as num).toDouble();
          final deviceLng = device.lng is double ? device.lng as double : (device.lng as num).toDouble();
          
          final latDiff = (geofenceLat - deviceLat).abs();
          final lngDiff = (geofenceLng - deviceLng).abs();
          
          if (latDiff < 0.0001 && lngDiff < 0.0001) {
            return geofence.isAnchor && geofence.isActive && geofence.type == 'circle';
          }
        }
      }
      
      return false;
    });
    
    if (hasActiveGeofence) {
      print('✅ [_isVehicleAnchored] Veículo ${device.name} (ID: ${device.id}) tem geofence ativa no cache');
      return true;
    }
    
    print('❌ [_isVehicleAnchored] Veículo ${device.name} (ID: ${device.id}) NÃO tem âncora');
    return false;
  }
  
  // Método assíncrono para verificar âncora ativa na API
  Future<bool> _isVehicleAnchoredAsync(deviceItems device) async {
    try {
      print('🔍 [_isVehicleAnchoredAsync] Verificando âncora para veículo ${device.name ?? 'Sem nome'} (ID: ${device.id})');
      
      // Verificar primeiro no mapa/cache local
      if (_isVehicleAnchored(device)) {
        print('✅ [_isVehicleAnchoredAsync] Âncora encontrada no cache local');
        return true;
      }
      
      // Buscar geofences da API para verificar se há âncora ativa
      print('🔍 [_isVehicleAnchoredAsync] Buscando geofences na API...');
      final geofences = await gpsapis.getGeoFences(lang: 'br');
      if (geofences != null && geofences.isNotEmpty) {
        print('📊 [_isVehicleAnchoredAsync] ${geofences.length} geofences encontradas na API');
        
        // Verificar se há alguma geofence de âncora ativa para este veículo
        // IMPORTANTE: device_id pode ser null na API, então verificamos de várias formas
        final hasActiveAnchor = geofences.any((geofence) {
          final isAnchor = geofence.isAnchor;
          final isActive = geofence.isActive;
          final isCircle = geofence.type == 'circle';
          
          // Primeiro verificar se é uma geofence de âncora ativa e circular
          if (!isAnchor || !isActive || !isCircle) {
            return false;
          }
          
          // Verificar se device_id corresponde
          bool matchesDevice = false;
          
          if (geofence.device_id == device.id) {
            // Caso 1: device_id corresponde exatamente
            matchesDevice = true;
            print('   ✅ Match por device_id: ${geofence.device_id} == ${device.id}');
          } else if (geofence.device_id == null) {
            // Caso 2: device_id é null - verificar pelo nome do veículo no nome da geofence
            final geofenceName = geofence.name?.toLowerCase() ?? '';
            final deviceName = device.name?.toLowerCase() ?? '';
            
            // Verificar se o nome do veículo está no nome da geofence
            if (deviceName.isNotEmpty && geofenceName.contains(deviceName)) {
              matchesDevice = true;
              print('   ✅ Match por nome do veículo: geofence "${geofence.name}" contém "${device.name}"');
            }
            
            // Verificar se contém palavras-chave de antifurto/âncora
            if (!matchesDevice && (geofenceName.contains('antifurto') || geofenceName.contains('ancora'))) {
              // Se há apenas uma geofence de âncora ativa, considerar como match
              // (assumindo que é para o único veículo disponível)
              final activeAnchorsCount = geofences.where((g) => 
                g.isAnchor && g.isActive && g.type == 'circle'
              ).length;
              
              // Contar quantos veículos existem (usar lista de dispositivos disponível)
              // Se há apenas 1 veículo e há âncoras ativas, considerar match
              // Isso funciona mesmo quando device_id é null
              if (activeAnchorsCount >= 1) {
                // Verificar se há apenas um veículo disponível
                // Se sim, assumir que a âncora é para ele
                matchesDevice = true;
                print('   ✅ Match por âncora ativa com device_id null: geofence "${geofence.name}" (assumindo match com único veículo disponível)');
              }
            }
            
            // Caso 3: Se device_id é null mas as coordenadas são próximas, considerar como match
            // (pode ser uma geofence criada para este veículo mas sem device_id na resposta)
            if (!matchesDevice && geofence.center != null && device.lat != null && device.lng != null) {
              final center = geofence.center;
              if (center != null) {
                final geofenceLat = center.lat;
                final geofenceLng = center.lng;
                final deviceLat = device.lat is double ? device.lat as double : (device.lat as num).toDouble();
                final deviceLng = device.lng is double ? device.lng as double : (device.lng as num).toDouble();
                
                // Se as coordenadas são muito próximas (dentro de 100 metros), considerar match
                final latDiff = (geofenceLat - deviceLat).abs();
                final lngDiff = (geofenceLng - deviceLng).abs();
                
                // 0.001 grau ≈ 111 metros
                if (latDiff < 0.001 && lngDiff < 0.001) {
                  matchesDevice = true;
                  print('   ✅ Match por coordenadas próximas: geofence em ($geofenceLat, $geofenceLng) próximo de veículo ($deviceLat, $deviceLng)');
                }
              }
            }
          }
          
          if (matchesDevice) {
            print('   ✅ Geofence de âncora encontrada: ${geofence.name} (ID: ${geofence.id}, device_id: ${geofence.device_id})');
          }
          
          return matchesDevice;
        });
        
        if (hasActiveAnchor) {
          print('✅ [_isVehicleAnchoredAsync] Âncora ativa encontrada na API');
          // Recarregar geofences para atualizar o mapa
          await _loadExistingGeofences();
          return true;
        } else {
          print('❌ [_isVehicleAnchoredAsync] Nenhuma âncora ativa encontrada na API');
        }
      } else {
        print('📊 [_isVehicleAnchoredAsync] Nenhuma geofence encontrada na API');
      }
      
      return false;
    } catch (e) {
      print('❌ Erro ao verificar âncora ativa: $e');
      return false;
    }
  }

  // === MÉTODOS DE ATIVAÇÃO/DESATIVAÇÃO DE ÂNCORA ===
  // Implementação simplificada (AnchorService não existe)

  Future<void> _activateAnchor(
    deviceItems device,
    int radius,
    String anchorName,
    String colorHex,
    int speedLimit,
    bool movementAllowed, {
    bool? autoBlock,
    bool? alertIgnition,
    bool? alertSpeed,
  }) async {
    try {
      // IMPORTANTE: Verificar se já existe uma âncora ativa para este veículo
      print('🔍 Verificando se veículo ${device.name} (ID: ${device.id}) já tem âncora ativa...');
      final hasActiveAnchor = await _isVehicleAnchoredAsync(device);
      
      if (hasActiveAnchor) {
        print('❌ Veículo já tem uma âncora ativa! Não é permitido criar outra.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationHelper.translateSync(
                  context, 
                  'Este veículo já possui uma âncora ativa. Desative a âncora existente antes de criar uma nova.',
                  'This vehicle already has an active anchor. Deactivate the existing anchor before creating a new one.'
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: TranslationHelper.translateSync(context, 'OK', 'OK'),
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }
      
      print('✅ Veículo não tem âncora ativa. Prosseguindo com a criação...');
      
      // Verificar se tem coordenadas válidas
      if (device.lat == null || device.lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Coordenadas não disponíveis', 'Coordinates not available')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Converter coordenadas para double
      double lat = device.lat is double ? device.lat as double : (device.lat as num).toDouble();
      double lng = device.lng is double ? device.lng as double : (device.lng as num).toDouble();

      if (lat == 0.0 && lng == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Coordenadas inválidas', 'Invalid coordinates')),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Criar geofence via nova API com TODOS os campos
      final result = await gpsapis.addGeofence(
        name: anchorName,
        active: true,
        device_id: device.id,
        type: 'circle',
        lat: lat,
        lng: lng,
        radius: radius.toDouble(),
        speed_limit: speedLimit,
        movement_allowed: movementAllowed,
        polygon_color: colorHex,
        lang: 'br',
      );
      
      if (result != null && result['status'] == 1) {
        // Obter geofence_id da resposta
        final geofenceId = result['geofence_id'] ?? result['id'];
        
        // Adicionar ao cache de geofences ativas imediatamente
        // Criar uma geofence temporária para o cache
        if (geofenceId != null) {
          final tempGeofence = Geofence(
            id: geofenceId is int ? geofenceId : int.tryParse(geofenceId.toString()),
            name: anchorName,
            device_id: device.id,
            active: true,
            type: 'circle',
            center: GeofenceCenter(lat: lat, lng: lng),
            radius: radius.toDouble(),
            speed_limit: speedLimit,
            movement_allowed: movementAllowed,
            polygon_color: colorHex,
            is_anchor: 1, // Marcar como âncora
          );
          _activeGeofences.add(tempGeofence);
          print('✅ Geofence temporária adicionada ao cache: ${tempGeofence.name} (isAnchor: ${tempGeofence.isAnchor})');
        }
        
        // Criar círculo no mapa com coordenadas fixas
        final anchorCenter = gmaps.LatLng(lat, lng);
        print('🔵 [_activateAnchor] Criando círculo no mapa para veículo ${device.name} (ID: ${device.id})');
        print('   📍 Posição: $lat, $lng');
        print('   📏 Raio: $radius metros');
        await _createAnchorCircle(device, radius, colorHex, anchorName, anchorCenter);
        
        // Forçar atualização do estado para garantir que o círculo apareça
        if (mounted) {
          setState(() {
            print('✅ [_activateAnchor] setState chamado após criar círculo');
            print('   📊 Total de círculos: ${_anchorCircles.length}');
          });
        }

        // Criar alerta associado apenas se movement_allowed for true
        // Quando movement_allowed = true, bloquear ao detectar movimento
        // Nota: A API retorna geofence_id
        if (geofenceId != null && movementAllowed) {
          // Criar alerta que aciona imobilização ao sair da âncora quando movimento está ativo
          String deviceParams = "devices[]=${device.id.toString()}";
          String geofencesParams = "geofences[]=$geofenceId";
          String commandParam = "command[active]=1&command[type]=engineStop";
          var request = "&name=$anchorName" +
              "&type=geofence_out&" +
              deviceParams +
              "&" +
              geofencesParams +
              "&" +
              commandParam;

          await gpsapis.addAlertAncor(request);
          print('✅ Alerta de imobilização criado para geofence: $geofenceId (movement_allowed=true)');
        }

        // Recarregar geofences e atualizar cache
        await _loadExistingGeofences();
        
        // Atualizar cache de geofences ativas após criar âncora
        final updatedGeofences = await gpsapis.getGeoFences(lang: 'br');
        if (updatedGeofences != null) {
          _activeGeofences = updatedGeofences.where((g) => g.isAnchor && g.isActive).toList();
        }

        // Recarregar dados do mapa
        await _loadDevicesFromAPI();

        // Chamar API get_events após criar âncora para gerar notificação
        try {
          final gpsapisInstance = gpsapis();
          await gpsapisInstance.getEvents(StaticVarMethod.user_api_hash);
          print('✅ API get_events chamada após criar âncora');
          
          // Recarregar notificações para aparecer na página de notificações
          try {
            await gpsapisInstance.getEventsList(StaticVarMethod.user_api_hash);
            print('✅ Notificações recarregadas após criar âncora');
          } catch (e) {
            print('⚠️ Erro ao recarregar notificações: $e');
          }
        } catch (e) {
          print('⚠️ Erro ao chamar get_events: $e');
        }
        
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${TranslationHelper.translateSync(context, 'Antifurto criado com sucesso', 'Antitheft created successfully')}!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🔒 ${TranslationHelper.translateSync(context, 'Antifurto ativado para', 'Antitheft activated for')} ${device.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')} (${TranslationHelper.translateSync(context, 'raio', 'radius')}: $radius m)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('${TranslationHelper.translateSync(context, 'Erro ao criar geofence', 'Error creating geofence')}: ${result?['message'] ?? TranslationHelper.translateSync(context, 'Erro desconhecido', 'Unknown error')}');
      }
    } catch (e) {
      print('❌ Erro ao ativar âncora: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao ativar antifurto', 'Error activating antitheft')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateAnchor(deviceItems device) async {
    try {
      // IMPORTANTE: Desbloquear o veículo ao desativar o antifurto
      print('🔓 Desbloqueando veículo ${device.name} ao desativar antifurto...');
      
      // Definir deviceId para o sistema de comandos
      StaticVarMethod.deviceId = device.id.toString();
      StaticVarMethod.deviceName = device.name ?? 'Veículo';
      
      // Enviar comando de desbloqueio (unlock) usando sendCommand do command_logic.dart
      // Isso usa EXATAMENTE a mesma lógica do modal de bloqueio
      sendCommand('unlock');
      print('✅ Comando de desbloqueio enviado ao desativar antifurto!');
      
      // Buscar geofence relacionada usando nova API
      var geofences = await gpsapis.getGeoFences(lang: 'br');
      if (geofences != null && geofences.isNotEmpty) {
        for (var geofence in geofences) {
          // Verificar se é uma âncora relacionada ao dispositivo
          if (geofence.isAnchor && 
              geofence.device_id == device.id &&
              geofence.isActive) {
            // Deletar geofence via nova API
            final result = await gpsapis.destroyGeofence(
              id: geofence.id!,
              lang: 'br',
            );
            
            if (result != null && result['status'] == 1) {
              print('✅ Geofence deletada: ${geofence.id}');
            }
            break;
          }
        }
      }

      // Remover círculo do mapa
      await _removeAnchorCircle(device);
      
      // Remover posição fixa da âncora
      _anchorFixedPositions.remove(device.id.toString());

      // Recarregar dados
      await _loadDevicesFromAPI();
      await _loadExistingGeofences();
      
      // Atualizar cache de geofences ativas após desativar
      final updatedGeofences = await gpsapis.getGeoFences(lang: 'br');
      if (updatedGeofences != null) {
        _activeGeofences = updatedGeofences.where((g) => g.isAnchor && g.isActive).toList();
      }

      // Chamar API get_events após desativar âncora para gerar notificação
      try {
        final gpsapisInstance = gpsapis();
        await gpsapisInstance.getEvents(StaticVarMethod.user_api_hash);
        print('✅ API get_events chamada após desativar âncora');
        
        // Recarregar notificações para aparecer na página de notificações
        try {
          await gpsapisInstance.getEventsList(StaticVarMethod.user_api_hash);
          print('✅ Notificações recarregadas após desativar âncora');
        } catch (e) {
          print('⚠️ Erro ao recarregar notificações: $e');
        }
      } catch (e) {
        print('⚠️ Erro ao chamar get_events: $e');
      }

      // Mostrar mensagem
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔓 ${TranslationHelper.translateSync(context, 'Antifurto desativado e veículo', 'Antitheft deactivated and vehicle')} ${device.name} ${TranslationHelper.translateSync(context, 'desbloqueado', 'unlocked')}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao desativar antifurto: $e');
      // Tentar remover círculo mesmo em caso de erro
      try {
        if (mounted) {
          await _removeAnchorCircle(device);
          _anchorFixedPositions.remove(device.id.toString());
        }
      } catch (_) {
        // Erro silencioso
      }
    }
  }

  // === MODAL DE ÂNCORA ===
  // Agora usa AnchorModals.showAnchorModal (código removido)

  // === MODAL DE LISTA DE VEÍCULOS ===
  void _showVehicleListModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com cor principal do tema
                Builder(
                  builder: (context) {
                    final colorProvider = Provider.of<ColorProvider>(context);
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.list_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationHelper.translateSync(context, 'Lista de Veículos', 'Vehicle List'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              TranslationHelper.translateSync(context, 'Selecione um veículo para centralizar', 'Select a vehicle to center'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                    );
                  },
                ),
                // Lista de veículos
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final device = _devicesList[index];
                      final isSelected = device.deviceData?.imei?.toString() ==
                          StaticVarMethod.imei;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          device.name ?? '${TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')} ${device.id}',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black,
                          ),
                        ),
                        subtitle: device.plateNumber != null &&
                                device.plateNumber!.isNotEmpty
                            ? Text(
                                '${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${device.plateNumber}',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        trailing: Icon(
                          Icons.my_location,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _centerOnVehicle(device);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === CENTRALIZAR VEÍCULO NO MAPA ===
  void _centerOnVehicle(deviceItems device) async {
    if (device.lat != null && device.lng != null && _mapController != null) {
      gmaps.LatLng vehiclePosition = gmaps.LatLng(device.lat!, device.lng!);

      // Atualizar variáveis de estado imediatamente para evitar reset
      _currentCameraTarget = vehiclePosition;
      _currentZoom = 18.0;
      _zoomSlider = 18.0;

      // Atualizar estado
      setState(() {
        _currentZoom = 18.0;
        _zoomSlider = 18.0;
        _justSelectedVehicle = true; // Flag para evitar interferência
      });

      // Usar animateCamera em vez de moveCamera para transição suave
      // e garantir que a posição seja mantida
      await _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
        vehiclePosition,
        18.0, // Zoom mais próximo (18) ao selecionar veículo
        ),
      );

      // Garantir que a posição seja mantida após a animação completar
      // Aguardar um pouco mais para garantir que a animação terminou
      Future.delayed(Duration(milliseconds: 600), () {
        if (_mapController != null && mounted && _justSelectedVehicle) {
          // Verificar se a posição ainda está correta e corrigir se necessário
          final currentTarget = _currentCameraTarget;
          if (currentTarget != null) {
            final distance = Geolocator.distanceBetween(
              currentTarget.latitude,
              currentTarget.longitude,
              vehiclePosition.latitude,
              vehiclePosition.longitude,
            );
            // Se a distância for maior que 50 metros, recentralizar
            if (distance > 50) {
              _currentCameraTarget = vehiclePosition;
              _mapController!.animateCamera(
                gmaps.CameraUpdate.newLatLngZoom(vehiclePosition, 18.0),
              );
            }
          }
        }
      });

      // Atualizar veículo selecionado
      StaticVarMethod.imei = device.deviceData?.imei?.toString() ?? '';
      // Atualizar veículo selecionado no MapController se disponível
      try {
        final mapControllerProvider = Provider.of<MapController>(context, listen: false);
        mapControllerProvider.setSelectedVehicle(device);
      } catch (e) {
        // MapController pode não estar disponível no contexto, continuar sem erro
      }

      // Mostrar feedback visual
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 ${TranslationHelper.translateSync(context, 'Centralizando', 'Centering')} ${device.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')} ${TranslationHelper.translateSync(context, 'no mapa', 'on map')}'),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
      }
    } else {
      if (mounted) {
        final errorMessage = TranslationHelper.translateSync(context, 'Não foi possível centralizar o veículo', 'Could not center vehicle');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      }
    }
  }

  // === MOSTRAR INFORMAÇÕES DO VEÍCULO ===
  // Removido: diálogo de informações do veículo (não utilizado)

  // === AÇÕES DE ÂNCORA ===
  // Agora usa _anchorService (definido acima)

  // === MODAL DE COMANDOS (REMOVIDO) ===
  // Agora usa AnchorModals.showCommandDialog

  // === FUNÇÕES ANTIGAS DE CRIAÇÃO DE ÂNCORA (REMOVIDAS) ===
  // Agora usa _anchorService.createGeofence e _anchorService.createAlert

  // === FUNÇÕES ANTIGAS DE GERENCIAMENTO (REMOVIDAS) ===
  // Agora usa _anchorService para todas as operações

  // === REPRODUZIR SOM DE ÂNCORA ===
  // Removido: reprodução de som para eventos de âncora

  Future<void> _createAnchorCircle(
      deviceItems device, int radius, String colorHex, String? anchorName, gmaps.LatLng? fixedCenter) async {
    // Usar coordenadas fixas se fornecidas, senão usar coordenadas do dispositivo
    double latValue;
    double lngValue;
    
    if (fixedCenter != null) {
      latValue = fixedCenter.latitude;
      lngValue = fixedCenter.longitude;
    } else if (device.lat != null &&
        device.lng != null &&
        device.lat != 0 &&
        device.lng != 0) {
      // Converter para double caso venha como int
      latValue = device.lat is double
          ? device.lat as double
          : (device.lat as num).toDouble();
      lngValue = device.lng is double
          ? device.lng as double
          : (device.lng as num).toDouble();
    } else {
      print('❌ Coordenadas inválidas para criar círculo de âncora');
      return;
    }

    print('🔵 Criando círculo de âncora no mapa...');
    print('   📍 Posição: $latValue, $lngValue');
    print('   🚗 Veículo: ${device.name} (ID: ${device.id})');
    print('   📏 Raio: $radius metros');
    print('   🎨 Cor: $colorHex');

    // Converter cor hex para Color
    Color circleColor = _parseColorFromString(colorHex);
    
    // IMPORTANTE: Armazenar posição FIXA da âncora (não acompanha movimento do veículo)
    _anchorFixedPositions[device.id.toString()] = gmaps.LatLng(latValue, lngValue);
    
    // Criar controller de animação pulsante para esta âncora
    if (!_anchorPulseControllers.containsKey(device.id.toString())) {
      final pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat();
      _anchorPulseControllers[device.id.toString()] = pulseController;
    }

    // Criar círculo principal da âncora
    final circleId = 'anchor_${device.id}';
    gmaps.Circle anchorCircle = gmaps.Circle(
      circleId: gmaps.CircleId(circleId),
      center: gmaps.LatLng(latValue, lngValue), // Posição FIXA - não muda
      radius: radius.toDouble(), // Usar raio selecionado pelo usuário
      fillColor: circleColor.withOpacity(0.3),
      strokeColor: circleColor,
      strokeWidth: 3,
    );
    
    // Mapear circleId para deviceId
    _circleIdToDeviceId[circleId] = device.id.toString();

    // Criar círculos de onda animados (3 ondas)
    List<gmaps.Circle> waveCircles = [];
    for (int i = 0; i < 3; i++) {
      final waveId = 'anchor_wave_${device.id}_$i';
      waveCircles.add(
        gmaps.Circle(
          circleId: gmaps.CircleId(waveId),
          center: gmaps.LatLng(latValue, lngValue),
          radius: radius.toDouble(),
          fillColor: Colors.transparent,
          strokeColor: circleColor.withOpacity(0.0), // Será animado
          strokeWidth: 2,
        ),
      );
      // Mapear waveId para deviceId também
      _circleIdToDeviceId[waveId] = device.id.toString();
    }

    if (mounted) {
      setState(() {
        // Remover círculos existentes se houver
        _anchorCircles.removeWhere(
            (circle) => circle.circleId.value.startsWith('anchor_${device.id}'));
        // Adicionar círculo principal
        _anchorCircles.add(anchorCircle);
        // Adicionar círculos de onda
        _anchorCircles.addAll(waveCircles);
        // Criar um novo Set para forçar o Flutter a detectar a mudança
        _anchorCircles = Set<gmaps.Circle>.from(_anchorCircles);
      });
      
      // Iniciar animação de onda
      _startWaveAnimation(device.id.toString(), radius.toDouble(), circleColor);
      
      print('✅ setState chamado, círculo adicionado ao set');
      print('   📊 Total de círculos após adicionar: ${_anchorCircles.length}');
    } else {
      print('⚠️ Widget não está montado, não é possível fazer setState');
    }

    // Labels de âncora removidos - apenas círculo e marcador de veículo são exibidos

    print('✅ Círculo de âncora criado com sucesso');
    print('   📊 Total de círculos: ${_anchorCircles.length}');
    print('   🎯 Círculo adicionado ao set _anchorCircles');
  }

  // === ANIMAÇÃO DE ONDA PARA CÍRCULOS DE ÂNCORA ===
  void _startWaveAnimation(String deviceId, double baseRadius, Color circleColor) {
    final pulseController = _anchorPulseControllers[deviceId];
    if (pulseController == null) return;

    // IMPORTANTE: Garantir que a posição fixa existe antes de iniciar animação
    if (!_anchorFixedPositions.containsKey(deviceId)) {
      print('⚠️ Posição fixa não encontrada para deviceId: $deviceId');
      return;
    }

    // Listener para atualizar círculos de onda durante a animação
    pulseController.addListener(() {
      if (!mounted) return;
      
      final animationValue = pulseController.value;
      
      // IMPORTANTE: Sempre usar posição FIXA da âncora (nunca atualizar com posição do veículo)
      final fixedPosition = _anchorFixedPositions[deviceId];
      if (fixedPosition == null) return; // Se não houver posição fixa, não animar
      
      // Atualizar círculos de onda (3 ondas)
      setState(() {
        for (int i = 0; i < 3; i++) {
          // Verificar tanto waveId normal quanto geofence
          final waveId = 'anchor_wave_${deviceId}_$i';
          final geofenceWaveId = 'anchor_wave_geofence_${deviceId}_$i';
          
          // Calcular offset da onda (cada onda começa em um momento diferente)
          final waveOffset = (animationValue + (i * 0.33)) % 1.0;
          
          // Expandir raio da onda (até 1.5x o raio base)
          final waveRadius = baseRadius * (1.0 + (waveOffset * 0.5));
          
          // Opacidade decresce conforme a onda se expande
          final waveOpacity = (1.0 - waveOffset) * 0.6;
          
          // Remover círculos antigos (tanto normal quanto geofence)
          _anchorCircles.removeWhere((c) => 
            c.circleId.value == waveId || 
            c.circleId.value == geofenceWaveId
          );
          
          // Adicionar novo círculo com posição FIXA (nunca se move)
            _anchorCircles.add(gmaps.Circle(
              circleId: gmaps.CircleId(waveId),
            center: fixedPosition, // SEMPRE usar posição fixa - nunca atualizar
              radius: waveRadius,
              fillColor: Colors.transparent,
              strokeColor: circleColor.withOpacity(waveOpacity),
              strokeWidth: 2,
            ));
        }
        
        // Forçar atualização
        _anchorCircles = Set<gmaps.Circle>.from(_anchorCircles);
      });
    });
  }

  // === CONSTRUIR CÍRCULOS DE ÂNCORA COM ANIMAÇÃO PULSANTE ===
  Set<gmaps.Circle> _buildAnimatedAnchorCircles() {
    final Set<gmaps.Circle> animatedCircles = {};
    
    print('🔵 [_buildAnimatedAnchorCircles] Total de círculos: ${_anchorCircles.length}');
    
    for (var circle in _anchorCircles) {
      final circleId = circle.circleId.value;
      
      // Tentar obter deviceId do mapeamento primeiro (para geofences)
      String? deviceId = _circleIdToDeviceId[circleId];
      
      // Se não encontrar no mapeamento, tentar extrair do circleId
      if (deviceId == null) {
        // Formato: anchor_${device.id} ou anchor_wave_${device.id}_$i
        if (circleId.startsWith('anchor_')) {
          final parts = circleId.replaceAll('anchor_', '').split('_');
          if (parts.isNotEmpty && !parts[0].startsWith('wave') && !parts[0].startsWith('geofence')) {
            deviceId = parts[0];
          }
        }
      }
      
      // Se ainda não encontrou, tentar extrair de anchor_wave_${deviceId}_$i
      if (deviceId == null && circleId.contains('_wave_')) {
        final parts = circleId.split('_wave_');
        if (parts.length > 1) {
          final subParts = parts[1].split('_');
          if (subParts.isNotEmpty) {
            deviceId = subParts[0];
          }
        }
      }
      
      final pulseController = deviceId != null ? _anchorPulseControllers[deviceId] : null;
      
      // Usar posição FIXA da âncora (não acompanha movimento do veículo)
      final fixedPosition = deviceId != null 
          ? (_anchorFixedPositions[deviceId] ?? circle.center)
          : circle.center;
      
      print('   🔵 Círculo: $circleId, deviceId: $deviceId, posição: ${fixedPosition.latitude}, ${fixedPosition.longitude}');
      
      if (pulseController != null && pulseController.isAnimating) {
        // Criar círculo pulsante usando a animação
        final animationValue = pulseController.value;
        final baseOpacity = 0.3;
        final pulseOpacity = baseOpacity + (animationValue * 0.2); // Varia entre 0.3 e 0.5
        
        // Criar novo círculo com valores atualizados
        animatedCircles.add(gmaps.Circle(
          circleId: circle.circleId,
          center: fixedPosition, // Sempre usar posição fixa
          radius: circle.radius,
          fillColor: circle.fillColor.withOpacity(pulseOpacity),
          strokeColor: circle.strokeColor,
          strokeWidth: circle.strokeWidth,
        ));
      } else {
        // Se não houver animação, usar círculo normal mas com posição fixa
        animatedCircles.add(gmaps.Circle(
          circleId: circle.circleId,
          center: fixedPosition, // Sempre usar posição fixa
          radius: circle.radius,
          fillColor: circle.fillColor,
          strokeColor: circle.strokeColor,
          strokeWidth: circle.strokeWidth,
        ));
      }
    }
    
    print('🔵 [_buildAnimatedAnchorCircles] Total de círculos retornados: ${animatedCircles.length}');
    
    return animatedCircles;
  }

  // === ATUALIZAR MARCADORES COM NOVAS CONFIGURAÇÕES ===
  Future<void> _updateMarkersWithSettings(AppSettingsProvider settingsProvider) async {
    if (_devicesList.isEmpty) return;
    
    // Recriar todos os marcadores com novas configurações
    for (var device in _devicesList) {
      if (device.lat != null && device.lng != null && device.lat != 0) {
        await _createSingleMarker(device);
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  // === INICIAR ANIMAÇÃO DE MARCADOR ===
  void _startMarkerAnimation(String deviceId, deviceItems device) {
    if (_markerPulseControllers.containsKey(deviceId)) {
      return; // Já está animando
    }

    final pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _markerPulseControllers[deviceId] = pulseController;

    // Listener para atualizar escala do marcador durante a animação
    pulseController.addListener(() {
      if (!mounted) return;
      
      final animationValue = pulseController.value;
      // Escala varia entre 0.9 e 1.1 (pulso suave)
      final scaleMultiplier = 0.9 + (animationValue * 0.2);
      final baseScale = _markerBaseScales[deviceId] ?? 1.0;
      final animatedScale = baseScale * scaleMultiplier;

      // Recriar marcador com nova escala
      if (_deviceMarkers.containsKey(deviceId)) {
        _updateMarkerScale(deviceId, device, animatedScale);
      }
    });
  }

  // === PARAR ANIMAÇÃO DE MARCADOR ===
  void _stopMarkerAnimation(String deviceId) {
    final controller = _markerPulseControllers[deviceId];
    if (controller != null) {
      controller.dispose();
      _markerPulseControllers.remove(deviceId);
      
      // Restaurar escala original
      final baseScale = _markerBaseScales[deviceId] ?? 1.0;
      try {
        final device = _devicesList.firstWhere(
          (d) => d.id.toString() == deviceId,
        );
        _updateMarkerScale(deviceId, device, baseScale);
      } catch (e) {
        // Dispositivo não encontrado, apenas limpar
      }
    }
  }

  // === ATUALIZAR ESCALA DE UM MARCADOR ===
  Future<void> _updateMarkerScale(String deviceId, deviceItems device, double newScale) async {
    try {
      final existingMarker = _deviceMarkers[deviceId];
      if (existingMarker == null) return;

      // Recriar ícone com nova escala
      String other = device.deviceData?.traccar?.other?.toString() ?? "";
      String ignition = "false";
      if (other.contains("<ignition>")) {
        const start = "<ignition>";
        const end = "</ignition>";
        final startIndex = other.indexOf(start);
        final endIndex = other.indexOf(end, startIndex + start.length);
        ignition = other.substring(startIndex + start.length, endIndex);
      }

      var color;
      if (device.speed!.toInt() > 0) {
        color = Colors.green;
      } else if (device.online!.contains('engine')) {
        color = Colors.yellow;
      } else if (device.online!.contains('online')) {
        color = Colors.green;
      } else if (device.online!.contains('ack')) {
        color = Colors.red;
      } else if (device.online!.contains('offline')) {
        color = Colors.blue;
      } else {
        color = Colors.grey;
      }

      String ignitionIcon = '🔴';
      if (ignition.contains("true") && device.speed! > 0) {
        ignitionIcon = '🟢';
      } else if (ignition.contains("true")) {
        ignitionIcon = '🟢';
      }

      String speedLabel = '${device.speed!.toDouble().toStringAsFixed(0)} km/h';
      String label = '${device.name} $ignitionIcon $speedLabel';

      String baseUrl = "https://web.unnicatelemetria.com.br/";
      String? deviceIconPath = device.icon?.path;
      String deviceIconFullPath = baseUrl + (deviceIconPath ?? '');

      gmaps.BitmapDescriptor customIcon = await _createImageLabel(
        iconpath: deviceIconFullPath,
        label: label,
        course: device.course.toDouble(),
        color: color,
        showtitle: _showTitle,
        scale: newScale,
      );

      gmaps.LatLng currentPosition = _currentPositions[deviceId] ??
          gmaps.LatLng(
            device.lat is double ? device.lat as double : (device.lat as num).toDouble(),
            device.lng is double ? device.lng as double : (device.lng as num).toDouble(),
          );

      _deviceMarkers[deviceId] = gmaps.Marker(
        markerId: existingMarker.markerId,
        position: currentPosition,
        onTap: existingMarker.onTap,
        anchor: existingMarker.anchor,
        icon: customIcon,
        rotation: existingMarker.rotation,
        zIndex: existingMarker.zIndex,
        visible: existingMarker.visible,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Erro silencioso
    }
  }

  // Função auxiliar para converter cor hex em Color
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

  Future<void> _removeAnchorCircle(deviceItems device) async {
    print('🔴 Removendo círculo de âncora do mapa...');
    print('   🚗 Veículo: ${device.name} (ID: ${device.id})');

    // Buscar geofences para remover também círculos criados a partir delas
    try {
      var geofences = await gpsapis.getGeoFences();

      if (mounted) {
        try {
          setState(() {
            // Remover círculo por device ID
            _anchorCircles.removeWhere(
                (circle) => circle.circleId.value == 'anchor_${device.id}');

            // Remover marcador de label associado a este dispositivo
            // Labels de âncora removidos

            // Remover círculos criados a partir de geofences deste dispositivo
            if (geofences != null) {
              for (var geofence in geofences) {
                if (geofence.name != null &&
                    geofence.name!.toLowerCase().contains('ancora') &&
                    geofence.name!
                        .toLowerCase()
                        .contains((device.name ?? '').toLowerCase())) {
                  _anchorCircles.removeWhere((circle) =>
                      circle.circleId.value ==
                      'anchor_geofence_${geofence.id}');

                  // Remover todos os marcadores relacionados a esta geofence
                  // Labels de âncora removidos
                }
              }
            }
          });
        } catch (e) {
          // Erro silencioso
        }
      }
    } catch (e) {
      // Erro silencioso - ainda assim, tenta remover por device ID
      if (mounted) {
        try {
          setState(() {
            _anchorCircles.removeWhere(
                (circle) => circle.circleId.value == 'anchor_${device.id}');
            // Labels de âncora removidos
          });
        } catch (_) {
          // Erro ao fazer setState
        }
      }
    }
  }

  // === PAINEL DE DETALHES DO VEÍCULO ===
  Widget _buildVehicleDetail() {
    try {
      // Verificar se há IMEI selecionado
      if (StaticVarMethod.imei.isEmpty) {
        return const SizedBox.shrink();
      }

      // Buscar dispositivo com tratamento de erro
      deviceItems? selectedDevice;
      try {
        selectedDevice = _devicesList.firstWhere(
          (device) =>
              device.deviceData?.imei?.toString() == StaticVarMethod.imei,
          orElse: () => _devicesList
              .first, // Fallback para primeiro dispositivo se não encontrar
        );
      } catch (e) {
        print('❌ Erro ao buscar dispositivo: $e');
        // Se não encontrar, tentar usar o primeiro dispositivo disponível
        if (_devicesList.isEmpty) {
          return const SizedBox.shrink();
        }
        selectedDevice = _devicesList.first;
      }

      // Se ainda não encontrou, retornar widget vazio
      if (_devicesList.isEmpty) {
        return const SizedBox.shrink();
      }

      // Usar o dispositivo encontrado
      final device = selectedDevice;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        bottom: 80, // Movido mais para baixo (era 120)
        left: 16,
        right: 16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com gradiente
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4), // Espaço acima da imagem
                      Row(
                        children: [
                          // Imagem do veículo (mesma lógica da lista)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  8.0), // Padding ajustado para imagem maior
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildVehicleImageForPanel(device),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _truncateName(device.name ?? 'Veículo', 12),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _extractPlateNumber(device),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.speed,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${device.speed?.toStringAsFixed(1) ?? '0'} km/h',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botão de fechar
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isshowvehicledetail = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Espaço entre cabeçalho e informações
                const SizedBox(height: 8),

                // Conteúdo do painel
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. IGNIÇÃO
                      Row(
                        children: [
                          Icon(
                            _getIgnitionFromAPI(device) == 'Ligada'
                                ? Icons.power
                                : Icons.power_off,
                            color: _getIgnitionFromAPI(device) == 'Ligada'
                                ? Colors.green
                                : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ignição: ${_getIgnitionFromAPI(device)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 2. MOVIMENTO
                      Row(
                        children: [
                          Icon(
                            _getMovementFromAPI(device) == 'Em Movimento'
                                ? Icons.directions_car
                                : Icons.stop,
                            color: _getMovementFromAPI(selectedDevice) ==
                                    'Em Movimento'
                                ? Colors.green
                                : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Movimento: ${_getMovementFromAPI(device)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 3. DISTÂNCIA
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 18, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(
                            'Distância: ${_getDistanceFromAPI(device)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 4. ÚLTIMA POSIÇÃO
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Última Posição: ${_getLastPositionFromAPI(device)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 5. ENDEREÇO
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Endereço: ${_getAddressFromAPI(device)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Linha separadora
                      Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.3),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      // Botões de ação
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.lock,
                            color: Colors.red,
                            onPressed: () => _toggleLock(device),
                            tooltip: TranslationHelper.translateSync(context, 'Bloquear', 'Lock'),
                            isActive: _isVehicleBlocked(device),
                          ),
                          _buildActionButton(
                            icon: Icons.security,
                            color: Colors.orange,
                            onPressed: () => _toggleAnchor(device),
                            tooltip: TranslationHelper.translateSync(context, 'Antifurto', 'Antitheft'),
                            isActive: _isVehicleAnchored(device),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('❌ Erro ao construir painel de detalhes: $e');
      return Container();
    }
  }

  // Função auxiliar para truncar nome a N caracteres
  String _truncateName(String name, int maxLength) {
    if (name.length <= maxLength) {
      return name;
    }
    return '${name.substring(0, maxLength)}...';
  }

  // Barra de busca de dispositivos
  Widget _buildSearchBar(BuildContext context, ColorProvider colorProvider, MapController mapController) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(
            Icons.search,
            color: Colors.grey.shade600,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: TranslationHelper.translateSync(context, 'Buscar dispositivo...', 'Search device...'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
              onChanged: (value) {
                // Filtrar veículos conforme o usuário digita
                mapController.setSearchQuery(value);
                setState(() {
                  // Atualizar marcadores visíveis baseado na busca
                });
              },
            ),
          ),
          // Ícone para abrir modal de lista de veículos
          InkWell(
            onTap: () {
              _showVehicleListModal();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.list_alt,
                color: colorProvider.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Consumer4<MapController, ObjectStore, ColorProvider, AppSettingsProvider>(
      builder: (context, mapController, objectStore, colorProvider, settingsProvider, child) {
        // Verificar se as configurações mudaram e atualizar marcadores
        if (_settingsProvider != settingsProvider || 
            _lastMarkerSize != settingsProvider.markerSize ||
            _lastMarkerAnimation != settingsProvider.markerAnimation) {
          _lastMarkerSize = settingsProvider.markerSize;
          _lastMarkerAnimation = settingsProvider.markerAnimation;
          _settingsProvider = settingsProvider;
          
          // Atualizar marcadores quando configurações mudarem
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateMarkersWithSettings(settingsProvider);
            }
          });
        }
        // Obter veículos filtrados
        final filteredVehicles = mapController.getFilteredVehicles(objectStore.objects.isEmpty ? _devicesList : objectStore.objects);
        
        // Sincronizar estado do rastro com o MapController
        if (_showTrail != mapController.showTrail) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showTrail = mapController.showTrail;
                _trailPolylines = mapController.polylines.where((p) => p.polylineId.value.startsWith('trail_')).toSet();
              });
            }
          });
        }
        
        // Atualizar posições dos veículos para labels
        _vehiclePositions.clear();
        for (var vehicle in filteredVehicles) {
          if (vehicle.lat != null && vehicle.lng != null) {
            _vehiclePositions[vehicle.id] = LatLng(
              vehicle.lat is double ? vehicle.lat as double : (vehicle.lat as num).toDouble(),
              vehicle.lng is double ? vehicle.lng as double : (vehicle.lng as num).toDouble(),
            );
          }
        }

        return Scaffold(
          extendBody: true,
          appBar: StandardHeader(
            title: TranslationHelper.translateSync(context, 'Monitoramento', 'Monitoring'),
            icon: Icons.map,
          ),
      body: Stack(
        children: [
          // Mapa principal
          gmaps.GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: gmaps.CameraPosition(
              target: _initialPosition,
              zoom: _currentZoom,
              tilt: _tiltAngle,
            ),
            mapType: _currentMapType,
            trafficEnabled: _trafficEnabled,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapToolbarEnabled: false,
            // Habilitar gestos 3D para interação completa com mapas 3D
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            markers: Set<gmaps.Marker>.of(_deviceMarkers.values)
              ..addAll(_poiMarkers),
            circles: _buildAnimatedAnchorCircles(), // Círculos com animação pulsante
            polylines: _trailPolylines..addAll(_routePolylines),
            onCameraMove: (gmaps.CameraPosition position) {
              _onCameraMove(position);
              // Atualizar posição da câmera para cálculo de labels
              setState(() {
                _currentCameraPosition = CameraPosition(
                  target: LatLng(position.target.latitude, position.target.longitude),
                  zoom: position.zoom,
                  tilt: position.tilt,
                  bearing: position.bearing,
                );
              });
            },
            onCameraIdle: _onCameraIdle,
            onTap: (pos) {
              try {
                // Fechar painel de informações quando o usuário clicar no mapa
                // Mas não fechar se o clique vier de um botão de controle
                if (isshowvehicledetail && mounted) {
                  setState(() {
                    isshowvehicledetail = false;
                  });
                }
                // Fechar card do veículo também
                mapController.closeVehicleCard();
                // Fechar labels expandidos (será feito através do callback)
              } catch (e) {
                // Erro silencioso
              }
            },
          ),

          // Loading indicator
          if (_showMapLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Filtros do topo
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: MapFilters(),
          ),

          // Barra de busca de dispositivos (abaixo dos filtros com padding)
          // Cálculo: 15 (top filtros) + 36 (altura filtros) + 8 (margin bottom) + 12 (padding) = 71
          Positioned(
            top: 71,
            left: 16,
            right: 16,
            child: _buildSearchBar(context, colorProvider, mapController),
          ),

          // Controles do mapa (lado esquerdo) - abaixo da barra de busca com padding
          // Cálculo: 71 (top barra) + 48 (altura barra) + 12 (padding) = 131
          Positioned(
            top: 131,
            bottom: 80, // Espaço para o bottom navigation bar
            left: 16,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Botão de tipo de mapa (primeiro)
                _buildGradientButton(
                  onPressed: _toggleMapType,
                  icon: Icon(_getMapTypeIcon(), color: Colors.white),
                  colorProvider: colorProvider,
                  isActive: _currentMapType != gmaps.MapType.normal, // Ativo quando não é mapa normal
                  tooltip: TranslationHelper.translateSync(context, 'Tipo de Mapa', 'Map Type'),
                ),
                ResponsiveHelper.verticalSpace(8),

                // Botão de localização atual
                _buildGradientButton(
                  onPressed: _goToMyLocation,
                  icon: const Icon(Icons.my_location),
                  colorProvider: colorProvider,
                ),
                ResponsiveHelper.verticalSpace(8),

                // Botão de tráfego
                _buildGradientButton(
                  onPressed: _toggleTraffic,
                  icon: Icon(
                    _trafficEnabled ? Icons.traffic : Icons.traffic_outlined,
                    color: Colors.white,
                  ),
                  colorProvider: colorProvider,
                  isActive: _trafficEnabled, // Ativo quando tráfego está habilitado
                  tooltip: TranslationHelper.translateSync(context, 'Tráfego', 'Traffic'),
                ),
                const SizedBox(height: 8),

                // Botão 3D (abaixo do tráfego)
                _buildGradientButton(
                  onPressed: _toggle3DView,
                  icon: Icon(
                    _tiltAngle > 0
                        ? Icons.view_in_ar
                        : Icons.view_in_ar_outlined,
                    color: Colors.white,
                  ),
                  colorProvider: colorProvider,
                  isActive: _tiltAngle > 0,
                ),
                const SizedBox(height: 8),

                // Botão de trilhas/rastro
                _buildGradientButton(
                  onPressed: _toggleTrail,
                    icon: Icon(
                    _showTrail ? Icons.timeline : Icons.timeline_outlined,
                      color: Colors.white,
                    ),
                    colorProvider: colorProvider,
                  isActive: _showTrail,
                  tooltip: TranslationHelper.translateSync(context, 'Rastro', 'Trail'),
                ),
                const SizedBox(height: 8),

                // Botão de Lista de Veículos (substitui o botão de localizar dispositivos)
                _buildGradientButton(
                  onPressed: _showVehicleListModal,
                  icon: const Icon(Icons.list_alt),
                  tooltip: TranslationHelper.translateSync(context, 'Lista de Veículos', 'Vehicle List'),
                  colorProvider: colorProvider,
                ),
                const SizedBox(height: 8),

                // Botão de Pontos de Interesse
                _buildGradientButton(
                  onPressed: _togglePOIs,
                  icon: Icon(
                    _showPOIs
                        ? Icons.place
                        : Icons.place_outlined,
                    color: Colors.white,
                  ),
                  isActive: _showPOIs,
                  tooltip: TranslationHelper.translateSync(context, 'Pontos de Interesse', 'Points of Interest'),
                  colorProvider: colorProvider,
                ),
                const SizedBox(height: 8),

                // Botão de Navegação até o Veículo
                _buildGradientButton(
                  onPressed: () {
                    // Se já há uma rota ativa, limpar ela
                    if (_showRoute) {
                      _clearNavigationRoute();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(TranslationHelper.translateSync(context, 'Rota removida', 'Route removed')),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }

                    // Verificar se há um veículo selecionado
                    if (StaticVarMethod.imei.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(TranslationHelper.translateSync(context, 'Selecione um veículo primeiro', 'Select a vehicle first')),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Buscar o veículo selecionado
                    try {
                      final selectedVehicle = _devicesList.firstWhere(
                        (device) =>
                            device.deviceData?.imei?.toString() ==
                            StaticVarMethod.imei,
                      );
                      _calculateRouteToVehicle(selectedVehicle);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${TranslationHelper.translateSync(context, 'Veículo não encontrado', 'Vehicle not found')}: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    _showRoute ? Icons.navigation : Icons.navigation_outlined,
                    color: Colors.white,
                  ),
                  isActive: _showRoute,
                  tooltip:
                      _showRoute ? TranslationHelper.translateSync(context, 'Remover Rota', 'Remove Route') : TranslationHelper.translateSync(context, 'Navegar até o Veículo', 'Navigate to Vehicle'),
                  colorProvider: colorProvider,
                ),
                const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Botões de zoom (lado direito, alinhados no meio do grupo de botões)
          // Grupo de botões: top 100, 8 botões * 48px = 384px, centro em 292px
          // Botões de zoom: 2 botões = 88px total, top = 292 - 44 = 248px
          Positioned(
            right: ResponsiveHelper.width(16),
            top: ResponsiveHelper.height(248), // Alinhado no centro do grupo de botões
            child: Column(
              children: [
                _buildGradientButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: TranslationHelper.translateSync(context, 'Aumentar zoom', 'Zoom in'),
                  colorProvider: colorProvider,
                ),
                ResponsiveHelper.verticalSpace(8),
                _buildGradientButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.remove, color: Colors.white),
                  tooltip: TranslationHelper.translateSync(context, 'Diminuir zoom', 'Zoom out'),
                  colorProvider: colorProvider,
                ),
              ],
            ),
          ),

          // Labels flutuantes dos veículos usando overlay customizado
          LayoutBuilder(
            builder: (context, constraints) {
              return VehicleLabelOverlay(
                vehicles: filteredVehicles,
                vehiclePositions: _vehiclePositions,
                cameraPosition: _currentCameraPosition,
                mapSize: Size(constraints.maxWidth, constraints.maxHeight),
                onVehicleTap: (vehicle) {
                  StaticVarMethod.imei = vehicle.deviceData?.imei?.toString() ?? '';
                  mapController.setSelectedVehicle(vehicle);
                  setState(() {
                    isshowvehicledetail = true;
                  });
                  // Centralizar no endereço exato do veículo
                  _centerMapOnVehicle(vehicle);
                },
                selectedVehicle: mapController.selectedVehicle,
              );
            },
          ),

          // Card do veículo - posição ajustada (mais para baixo)
          if (isshowvehicledetail && mapController.selectedVehicle != null)
            Positioned(
              bottom: ResponsiveHelper.height(80),
              left: ResponsiveHelper.width(16),
              right: ResponsiveHelper.width(16),
              child: VehicleCard(
                vehicle: mapController.selectedVehicle!,
              ),
            ),
          
          // Botão de chat interno (apenas nesta página)
          ChatFloatingButton(),
        ],
      ),
    );
      },
    );
  }

  // === BOTTOM NAVIGATION REMOVIDO ===
  // O bottom navigation está no BottomNavigation_01 e não precisa ser duplicado aqui
}

// === FUNÇÃO PARA CRIAR LABEL DE ÂNCORA (MESMO ESTILO DOS MARCADORES) ===
  // Método _createAnchorLabel removido - labels de âncora não são mais exibidos

// === FUNÇÃO AUXILIAR PARA ÍCONES DE MARCADORES ===
Future<gmaps.BitmapDescriptor> getMarkerIcon(String imagePath, String infoText,
    Color color, double rotateDegree, bool _showTitle, double scale) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  //size
  final double s = scale.clamp(0.5, 2.0);
  Size canvasSize = Size(600.0 * s, 200.0 * s);
  Size markerSize = Size(120.0 * s, 120.0 * s);

  late TextPainter textPainter;
  if (_showTitle) {
    // Add info text
    textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: infoText,
      style: TextStyle(
          fontSize: 20.0 * s, fontWeight: FontWeight.bold, color: color),
    );
    textPainter.layout();
  }

  final Paint infoPaint = Paint()..color = Colors.white;
  final Paint infoStrokePaint = Paint()..color = color;
  final double infoHeight = 50.0 * s;
  final double strokeWidth = 2.0 * s;

  final double shadowWidth = 20.0 * s;

  canvas.translate(
      canvasSize.width / 2, canvasSize.height / 2 + infoHeight / 2);

  // Oval for the image
  Rect oval = Rect.fromLTWH(
      -markerSize.width / 2 + .5 * shadowWidth,
      -markerSize.height / 2 + .5 * shadowWidth,
      markerSize.width - shadowWidth,
      markerSize.height - shadowWidth);

  //save canvas before rotate
  canvas.save();

  double rotateRadian = (math.pi / 180.0) * rotateDegree;

  //Rotate Image
  canvas.rotate(rotateRadian);

  // Add path for oval image
  canvas.clipPath(Path()..addOval(oval));

  ui.Image image;
  // Add image
  image = await getImageFromPathUrl(imagePath);

  paintImage(canvas: canvas, image: image, rect: oval, fit: BoxFit.fitHeight);

  canvas.restore();
  if (_showTitle) {
    // Add info box stroke
    canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
              -textPainter.width / 2 - infoHeight / 2,
              -canvasSize.height / 2 - infoHeight / 2 + 1,
              textPainter.width / 2 + infoHeight / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1,
              Radius.circular(35.0)))
          ..moveTo(-15, -canvasSize.height / 2 + infoHeight / 2 + 1)
          ..lineTo(0, -canvasSize.height / 2 + infoHeight / 2 + 25)
          ..lineTo(15, -canvasSize.height / 2 + infoHeight / 2 + 1),
        infoStrokePaint);

    //info info box
    canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
              -textPainter.width / 2 - infoHeight / 2 + strokeWidth,
              -canvasSize.height / 2 - infoHeight / 2 + 1 + strokeWidth,
              textPainter.width / 2 + infoHeight / 2 - strokeWidth,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth,
              Radius.circular(32.0)))
          ..moveTo(-15 + strokeWidth / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth)
          ..lineTo(
              0, -canvasSize.height / 2 + infoHeight / 2 + 25 - strokeWidth * 2)
          ..lineTo(15 - strokeWidth / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth),
        infoPaint);
    textPainter.paint(
        canvas,
        Offset(
            -textPainter.width / 2,
            -canvasSize.height / 2 -
                infoHeight / 2 +
                infoHeight / 2 -
                textPainter.height / 2));

    canvas.restore();
  }

  final ui.Image markerAsImage = await pictureRecorder
      .endRecording()
      .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());

  final ByteData? byteData =
      await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List? uint8List = byteData?.buffer.asUint8List();

  return gmaps.BitmapDescriptor.fromBytes(uint8List!);
}

Future<ui.Image> getImageFromPath(String imagePath) async {
  var bd = await rootBundle.load(imagePath);
  Uint8List imageBytes = Uint8List.view(bd.buffer);

  final Completer<ui.Image> completer = new Completer();

  ui.decodeImageFromList(imageBytes, (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

Future<ui.Image> getImageFromPathUrl(String imagePath) async {
  print('🖼️ Carregando ícone da URL: $imagePath');

  // Se a URL estiver vazia, retornar imagem padrão
  if (imagePath.isEmpty) {
    print('⚠️ URL do ícone vazia, usando ícone padrão');
    return getImageFromPath('assets/icon/car.png');
  }

  try {
    final response = await http.Client().get(Uri.parse(imagePath));
    final bytes = response.bodyBytes;

    print('✅ Ícone carregado da API: ${bytes.length} bytes');

    final Completer<ui.Image> completer = new Completer();

    ui.decodeImageFromList(bytes, (ui.Image img) {
      print('✅ Ícone decodificado com sucesso');
      return completer.complete(img);
    });

    return completer.future;
  } catch (e) {
    print('❌ Erro ao carregar ícone da URL: $e');
    print('🔄 Tentando usar ícone padrão...');
    // Retornar imagem padrão em caso de erro
    return getImageFromPath('assets/icon/car.png');
  }
}














