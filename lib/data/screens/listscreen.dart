import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:uconnect/data/screens/AlertList.dart';
import 'package:uconnect/data/screens/reports/reportselection.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_google_street_view/flutter_google_street_view.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:jiffy/jiffy.dart';
import 'package:uconnect/bloc/kmandfuelhistory/bloc/kmandfuelhistory_bloc.dart';
import 'package:uconnect/config/constant.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/services/health_check_service.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/data/model/history.dart';
import 'package:uconnect/data/model/loginModel.dart';
import 'package:uconnect/data/model/product_model.dart';
import 'package:uconnect/data/screens/historyscreen.dart';
import 'package:uconnect/data/screens/notificationscreen.dart';
import 'package:uconnect/data/screens/reports/reportselection.dart';
import 'package:uconnect/data/screens/testscreens/livelocation.dart';
import 'package:uconnect/data/screens/trip/tripinfoselectionscreen.dart';
import 'package:uconnect/mapconfig/CustomColor.dart';
import 'package:uconnect/data/screens/street_view/views/street_view_screen.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:uconnect/ui/reusable/cache_image_network.dart';
import 'package:uconnect/ui/reusable/global_function.dart';
import 'package:uconnect/ui/reusable/global_widget.dart';
import 'package:uconnect/ui/reusable/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/Session.dart';
import '../../mvvm/view_model/objects.dart';
import '../../provider/color_provider.dart';
import '../../provider/app_settings_provider.dart';
import '../../utils/MapUtils.dart';
import '../../utils/translation_helper.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uconnect/utils/command_logic.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uconnect/utils/responsive_helper.dart';
import 'package:uconnect/data/screens/map/widgets/vehicle_card.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:share_plus/share_plus.dart';

class listscreen extends StatefulWidget {
  @override
  _listscreen createState() => _listscreen();
}

class _listscreen extends State<listscreen>
    with SingleTickerProviderStateMixin {
  String? userName = '';
  String? firstname = '';
  String? lastname = '';

  late gmaps.GoogleMapController _controller;
  // Removidas variáveis locais - agora usa as do command_logic.dart

  // initialize global function and global widget
  final _globalFunction = GlobalFunction();
  final _globalWidget = GlobalWidget();
  final _shimmerLoading = ShimmerLoading();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  PersistentBottomSheetController? _bottomSheetController;

  String filtertext = "All";
  bool _loading = true;

  // Set<Marker> markers = new Set();
  // final Completer<GoogleMapController> _mapController = Completer();

  Color _color1 = Color(0xff777777);
  Color _color2 = Color(0xFF515151);
  Color _topSearchColor = Colors.white;
  List<deviceItems> _vehiclesData = [];
  List<deviceItems> _vehiclesData_sorted = [];
  List<deviceItems> _vehiclesData_duplicate = [];

  // _listKey is used for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  TextEditingController _etSearch = TextEditingController();

  int _tabIndex = 0;

  bool _mapLoading = true;
  // StreetViewController? _controller;
  static Color primaryDark = const Color.fromARGB(255, 13, 61, 101);
  double _currentZoom = 14;

  Map<int, bool> _showMiniMap = {};

  List<String> carstatusList = [
    'All Vehicle',
    'Running',
    'Stopped',
    'Idle',
    'In Active',
    'Expired'
  ];

  int starIndex = 0;
  Color CHARCOAL = Color(0xFF515151);
  bool _searchEnabled = false;
  List<deviceItems> _inactiveVehicles = [];
  List<deviceItems> _runningVehicles = [];
  List<deviceItems> _idleVehicles = [];
  List<deviceItems> _stoppedVehicles = [];
  List<deviceItems> _noDataVehicles = [];
  late SharedPreferences prefs;
  late ObjectStore objectStore;
  String? filterSelected;

  @override
  void initState() {
    super.initState();
    setUserName();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    checkPreference();
    filterSelected = carstatusList.first;
    _loadNotifications();
  }
  
  // Função para carregar notificações e atualizar contador
  Future<void> _loadNotifications() async {
    try {
      gpsapis api = gpsapis();
      List<EventsData> events = await api.getEventsList(StaticVarMethod.user_api_hash);
      if (events.isNotEmpty) {
        StaticVarMethod.eventList = events;
        StaticVarMethod.updateUnreadNotificationCount();
        if (mounted) {
          setState(() {}); // Atualizar UI do contador
        }
      }
    } catch (e) {
      print('Erro ao carregar notificações: $e');
    }
  }

  Future<void> setUserName() async {
    final client = json.decode(
      (await SharedPreferences.getInstance()).getString('user')!,
    )['user']['client'];

    setState(() {
      firstname = client['first_name'];
      lastname = client['last_name'];
      userName = "${client['first_name']} ${client['last_name']}";
    });
  }

  /// Formata o nome do motorista: Primeiro Nome + Primeira Inicial do Sobrenome
  /// Exemplo: "João Silva" -> "João S."
  String _formatDriverName(String fullName) {
    if (fullName.isEmpty || fullName.toLowerCase() == 'null' || fullName.toLowerCase() == 'sem motorista') {
      return TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    }

    // Remove espaços extras e divide o nome
    final parts = fullName.trim().split(' ').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) {
      return TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    }

    // Se tiver apenas um nome, retorna ele
    if (parts.length == 1) {
      return parts[0];
    }

    // Primeiro nome + primeira inicial do sobrenome
    final firstName = parts[0];
    final lastNameInitial = parts[1][0].toUpperCase();
    
    return '$firstName $lastNameInitial.';
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _etSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    objectStore = Provider.of<ObjectStore>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    _vehiclesData = objectStore.objects;
    _runningVehicles = [];
    _idleVehicles = [];
    _stoppedVehicles = [];
    _inactiveVehicles = [];
    _noDataVehicles = [];

    if (_vehiclesData.isNotEmpty) {
      _vehiclesData_duplicate.clear();
      _vehiclesData_sorted.clear();
      _vehiclesData_sorted.addAll(_vehiclesData);

      if (filtertext != "All") {
        for (int i = 0; i < _vehiclesData_sorted.length; i++) {
          deviceItems model = _vehiclesData_sorted[i];
          String other = model.deviceData!.traccar!.other.toString();
          String ignition = "false";
          if (other.contains("<ignition>")) {
            final startIndex = other.indexOf("<ignition>");
            final endIndex = other.indexOf("</ignition>", startIndex);
            ignition = other.substring(startIndex + 10, endIndex);
          }

          if (filtertext == "Idle" &&
              model.online!.toLowerCase().contains("engine")) {
            _vehiclesData_duplicate.add(model);
          } else if (filtertext == "In Active" &&
              model.online!.toLowerCase().contains("offline")) {
            _vehiclesData_duplicate.add(model);
          } else if (filtertext == "Running" &&
              model.online!.toLowerCase().contains("online")) {
            _vehiclesData_duplicate.add(model);
          } else if (filtertext == "Stopped" &&
              model.online!.toLowerCase().contains("ack") &&
              model.time!.toLowerCase() != "not connected") {
            _vehiclesData_duplicate.add(model);
          } else if (filtertext == "Expired" &&
              model.time!.toLowerCase().contains("expire")) {
            _vehiclesData_duplicate.add(model);
          } else if (model.name!
              .toLowerCase()
              .contains(filtertext.toLowerCase())) {
            _vehiclesData_duplicate.add(model);
          }
        }
      } else {
        _vehiclesData_duplicate.addAll(_vehiclesData);
      }

      StaticVarMethod.devicelist = _vehiclesData;

      for (deviceItems model in StaticVarMethod.devicelist) {
        String other = model.deviceData!.traccar!.other.toString();

        if (model.online!.toLowerCase().contains("engine")) {
          _idleVehicles.add(model);
        } else if (model.online!.toLowerCase().contains("offline")) {
          _inactiveVehicles.add(model);
        } else if (model.online!.toLowerCase().contains("online")) {
          _runningVehicles.add(model);
        } else if (model.online!.toLowerCase().contains("ack")) {
          _stoppedVehicles.add(model);
        } else if (model.time!.toLowerCase() == "not connected") {
          _noDataVehicles.add(model);
        }
      }

      _loading = false;
    } else {
      _loading = false;
      _vehiclesData_duplicate.clear();
      _vehiclesData_sorted.clear();
    }

    final double boxImageSize = (MediaQuery.of(context).size.width / 12);

    Widget _child = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: refreshData,
            child: devicesListwidget(boxImageSize),
          );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(240),
        child: Builder(
          builder: (context) {
            final colorProvider = Provider.of<ColorProvider>(context);
            return AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: colorProvider.primaryColor, // Cor principal no fundo do cabeçalho
              flexibleSpace: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.padding(left: 16, right: 16, top: 12, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${TranslationHelper.translateSync(context, 'Olá', 'Hello')}, $firstname',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.fontSize(24),
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            ResponsiveHelper.verticalSpace(4),
                            Text(
                              TranslationHelper.translateSync(context, 'Gerencie sua frota', 'Manage your fleet'),
                              style: TextStyle(
                                fontSize: ResponsiveHelper.fontSize(14),
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botão de notificação moderno com corneta
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  // Atualizar contador antes de navegar
                                  StaticVarMethod.updateUnreadNotificationCount();
                                  setState(() {});
                                  
                                  // Navegar para página de notificações
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NotificationsPage(),
                                    ),
                                  );
                                  
                                  // Atualizar contador ao voltar da página de notificações
                                  StaticVarMethod.updateUnreadNotificationCount();
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  
                                  // Garantir que estamos dentro do BottomNavigation_01
                                  // Se não estiver, navegar de volta para ele
                                  final bottomNav = context.findAncestorWidgetOfExactType<BottomNavigation_01>();
                                  if (bottomNav == null && mounted) {
                                    // Se não estiver dentro do BottomNavigation_01, navegar de volta
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => BottomNavigation_01()),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.campaign,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Contador de notificações
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Builder(
                              builder: (context) {
                                final notificationCount = StaticVarMethod.notificationCount;
                                if (notificationCount <= 0) {
                                  return SizedBox.shrink();
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      notificationCount > 99
                                          ? '99+'
                                          : notificationCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Card Status da Frota dentro do header
                  _buildFleetStatusCardInHeader(),
                ],
              ),
            ),
          ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Fundo animado
          AnimatedBackground(opacity: 0.03),
          // Conteúdo
          _child,
          // Botão de chat interno (apenas nesta página)
          ChatFloatingButton(),
        ],
      ),
      // drawer removido - já está no BottomNavigation_01
      // bottomNavigationBar removido - já está no BottomNavigation_01
    );
  }

  Widget devicesListwidget(double boxImageSize) {
    final List<deviceItems> filteredList =
        _vehiclesData_duplicate.where((device) {
      final name = device.name?.toLowerCase() ?? '';
      final plate = device.deviceData?.plateNumber?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) ||
          plate.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Tabs de filtro
        _buildFilterTabs(),
        
        // Lista dos veículos filtrados
        Expanded(
          child: ListView.builder(
            padding: ResponsiveHelper.padding(top: 8, bottom: 100),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final productData = filteredList[index];
              return buildCompactDeviceCard(productData);
            },
          ),
        ),
      ],
    );
  }

  void filterSearchResults(String query) {
    filtertext = query;
    print("inside filter");
    _vehiclesData_duplicate.clear();
    if (query.isNotEmpty && query != "All") {
      for (int i = 0; i < _vehiclesData_sorted.length; i++) {
        deviceItems model = _vehiclesData_sorted.elementAt(i);

        String other = model.deviceData!.traccar!.other.toString();
        String ignition = "false";
        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }
        if (query == "Idle") {
          if (model.online.toString().toLowerCase().contains("engine")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Idle');
          }
        } else if (query == "In Active") {
          if (model.online.toString().toLowerCase().contains("offline")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print(model.online.toString());
            print('Offline');
          }
        } else if (query == "Running") {
          if (model.online.toString().toLowerCase().contains("online")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Running');
          }
        } else if (query == "Stopped") {
          if (model.online.toString().toLowerCase().contains("ack")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Stopped');
            print(model.online.toString());
          }
        } else if (query == "expire") {
          if (model.time.toString().toLowerCase().contains("expire")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('expire');
          }
        }
      }
    } else {
      if (query == "All") {
        _vehiclesData_duplicate.addAll(_vehiclesData_sorted);
        print('All');
      }
    }
  }

  // Função auxiliar para buscar dados da API de Health Check (mesma da tela de sensores da frota)
  Future<Map<String, String>> _getSensorsDataFromAPI(deviceItems productData) async {
    Map<String, String> result = {
      'odometer': '---',
      'engineHours': '---',
      'totalDistance': '0 km',
      'gpsSignal': '0',
      'gsmSignal': '0',
      'ignition': '---',
      'motion': '---',
      'battery': '---',
      'voltage': '---',
      'uptime': '---',
      'validPosition': '---',
    };
    
    // Fallback inicial com dados locais
    if (productData.totalDistance != null) {
      double totalDist = (productData.totalDistance as num).toDouble();
      if (totalDist >= 1000) {
        result['totalDistance'] = '${(totalDist / 1000).toStringAsFixed(0)} km';
      } else {
        if (totalDist > 0 && totalDist < 1000) {
           result['totalDistance'] = '${totalDist.toStringAsFixed(0)} km';
        } else {
           result['totalDistance'] = '${(totalDist / 1000).toStringAsFixed(0)} km';
        }
      }
    }

    try {
      final deviceIdInt = int.tryParse(productData.id.toString());
      if (deviceIdInt != null) {
        // Usar HealthCheckService para garantir consistência com a tela de Sensores da Frota
        final healthService = HealthCheckService();
        final deviceDetails = await healthService.getDeviceDetails(deviceIdInt);
        
        if (deviceDetails['health_data'] != null) {
          final healthData = deviceDetails['health_data']; 
          
          // Se for Map (json)
          if (healthData is Map) {
             // Odômetro
             if (healthData['odometer'] != null) {
               result['odometer'] = '${double.parse(healthData['odometer'].toString()).toStringAsFixed(0)} km';
             }
             
             // Horas Motor
             if (healthData['engine_hours'] != null) {
               result['engineHours'] = '${double.parse(healthData['engine_hours'].toString()).toStringAsFixed(1)} h';
             }
             
             // Distância Total
             if (healthData['total_distance'] != null) {
               double td = double.parse(healthData['total_distance'].toString());
               if (td >= 1000) {
                 result['totalDistance'] = '${(td / 1000).toStringAsFixed(0)} km';
               } else {
                 result['totalDistance'] = '${td.toStringAsFixed(0)} km';
               }
             }

             // GPS Signal
             if (healthData['gps_signal'] != null) result['gpsSignal'] = healthData['gps_signal'].toString();

             // GSM Signal
             if (healthData['gsm_signal'] != null) result['gsmSignal'] = healthData['gsm_signal'].toString();

             // Ignição
             if (healthData['ignition'] != null) {
               bool ign = healthData['ignition'] == true || healthData['ignition'] == 'true';
               result['ignition'] = ign ? 'Ligada' : 'Desligada';
             }

             // Movimento
             if (healthData['motion'] != null) {
               bool mov = healthData['motion'] == true || healthData['motion'] == 'true';
               result['motion'] = mov ? 'Movendo' : 'Parado';
             }

             // Bateria
             if (healthData['battery_level'] != null) result['battery'] = '${healthData['battery_level']}%';

             // Voltagem
             if (healthData['power_voltage'] != null) result['voltage'] = '${double.parse(healthData['power_voltage'].toString()).toStringAsFixed(1)}V';

             // Uptime
             if (healthData['uptime_percentage'] != null) result['uptime'] = '${double.parse(healthData['uptime_percentage'].toString()).toStringAsFixed(1)}%';

             // Posição Válida
             if (healthData['valid_position'] != null) {
               bool valid = healthData['valid_position'] == true || healthData['valid_position'] == 'true';
               result['validPosition'] = valid ? 'Sim' : 'Não';
             }
          } 
          // Se for objeto DeviceHealthData
          else {
             dynamic health = healthData; // Cast dinâmico
             
             if (health.odometer != null) result['odometer'] = '${health.odometer.toStringAsFixed(0)} km';
             if (health.engineHours != null) result['engineHours'] = '${health.engineHours.toStringAsFixed(1)} h';
             if (health.totalDistance != null) {
               double td = health.totalDistance;
               result['totalDistance'] = td >= 1000 ? '${(td / 1000).toStringAsFixed(0)} km' : '${td.toStringAsFixed(0)} km';
             }
             result['gpsSignal'] = health.gpsSignal.toString();
             result['gsmSignal'] = health.gsmSignal.toString();
             result['ignition'] = health.ignition == true ? 'Ligada' : 'Desligada';
             result['motion'] = health.motion == true ? 'Movendo' : 'Parado';
             if (health.batteryLevel != null) result['battery'] = '${health.batteryLevel}%';
             if (health.powerVoltage != null) result['voltage'] = '${health.powerVoltage.toStringAsFixed(1)}V';
             result['uptime'] = '${health.uptimePercentage.toStringAsFixed(1)}%';
             result['validPosition'] = health.validPosition == true ? 'Sim' : 'Não';
          }
        }
      }
    } catch (e) {
      print('⚠️ Erro ao buscar dados do Health Check: $e');
    }
    
    return result;
  }

  Color randomColor() =>
      Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0);

  Widget _getPeriodIcon() {
    final hour = DateTime.now().hour;
    IconData icon;
    Color color;
    String period;

    if (hour >= 5 && hour < 12) {
      // Bom dia (5h - 11h59)
      icon = Icons.wb_sunny;
      color = Colors.orange;
      period = TranslationHelper.translateSync(context, 'Bom dia', 'Good morning');
    } else if (hour >= 12 && hour < 18) {
      // Boa tarde (12h - 17h59)
      icon = Icons.wb_twilight;
      color = Colors.deepOrange;
      period = TranslationHelper.translateSync(context, 'Boa tarde', 'Good afternoon');
    } else {
      // Boa noite (18h - 4h59)
      icon = Icons.nightlight_round;
      color = Colors.indigo;
      period = TranslationHelper.translateSync(context, 'Boa noite', 'Good evening');
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildFleetStatusCardInHeader() {
    return Container(
      width: double.infinity,
      // Mantém o card na mesma posição no cabeçalho azul,
      // aumentando apenas a altura para baixo com mais padding inferior.
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.radius(20)),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha com ícone de grid e títulos
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone de grid
                  Builder(
                    builder: (context) {
                      final colorProvider = Provider.of<ColorProvider>(context);
                      return Container(
                        width: ResponsiveHelper.width(36),
                        height: ResponsiveHelper.height(36),
                        decoration: BoxDecoration(
                          color: colorProvider.primaryColor, // Cor principal
                          borderRadius: BorderRadius.circular(ResponsiveHelper.radius(8)),
                        ),
                        child: Icon(
                          Icons.grid_view,
                          color: Colors.white,
                          size: ResponsiveHelper.iconSize(20),
                        ),
                      );
                    },
                  ),
                  ResponsiveHelper.horizontalSpace(10),
                  // Títulos na mesma linha do ícone de grid
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Status da Frota', 'Fleet Status'),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.fontSize(16),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A), // Preto fosco
                          ),
                        ),
                        ResponsiveHelper.verticalSpace(3),
                        Text(
                          TranslationHelper.translateSync(context, 'Visão geral dos veículos', 'Vehicle overview'),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.fontSize(12),
                            color: Color(0xFF1A1A1A).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ResponsiveHelper.verticalSpace(12),
              // Número e palavra "Veículos" na mesma linha
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Builder(
                    builder: (context) {
                      final colorProvider = Provider.of<ColorProvider>(context);
                      return Text(
                        '${_vehiclesData.length}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.fontSize(28),
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor, // Cor principal
                        ),
                      );
                    },
                  ),
                  ResponsiveHelper.horizontalSpace(6),
                  Builder(
                    builder: (context) {
                      final colorProvider = Provider.of<ColorProvider>(context);
                      return Text(
                        TranslationHelper.translateSync(context, 'Veículos', 'Vehicles'),
                        style: TextStyle(
                          fontSize: ResponsiveHelper.fontSize(16),
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor, // Cor do tema do usuário
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              // Botão verde com círculo e checkmark (menor)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      TranslationHelper.translateSync(context, 'Todos os status', 'All statuses'),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Ícone de carro animado no lado direito
          Builder(
            builder: (context) {
              final colorProvider = Provider.of<ColorProvider>(context);
              return Positioned(
                right: 0,
                top: -10,
                bottom: -10,
                child: Consumer<AppSettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return _AnimatedVehicleIcon(
                      icon: settingsProvider.getFleetStatusIconData(),
                      size: 120,
                      color: colorProvider.primaryColor.withOpacity(0.25),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    int allCount = _vehiclesData.length;
    int runningCount = _runningVehicles.length;
    int stoppedCount = _stoppedVehicles.length;
    int idleCount = _idleVehicles.length;
    
    String currentFilter = filtertext == "All" ? TranslationHelper.translateSync(context, "Todos", "All") : 
                          filtertext == "Running" ? TranslationHelper.translateSync(context, "Correndo", "Running") :
                          filtertext == "Stopped" ? TranslationHelper.translateSync(context, "Parou", "Stopped") :
                          filtertext == "Idle" ? TranslationHelper.translateSync(context, "Parada", "Idle") : TranslationHelper.translateSync(context, "Todos", "All");
    
    return Container(
      height: 35,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterTab(TranslationHelper.translateSync(context, "Todos", "All"), allCount, currentFilter == TranslationHelper.translateSync(context, "Todos", "All"), () {
            setState(() {
              filtertext = "All";
              filterSearchResults("All");
            });
          }),
          SizedBox(width: 6),
          _buildFilterTab(TranslationHelper.translateSync(context, "Correndo", "Running"), runningCount, currentFilter == TranslationHelper.translateSync(context, "Correndo", "Running"), () {
            setState(() {
              filtertext = "Running";
              filterSearchResults("Running");
            });
          }),
          SizedBox(width: 6),
          _buildFilterTab(TranslationHelper.translateSync(context, "Parou", "Stopped"), stoppedCount, currentFilter == TranslationHelper.translateSync(context, "Parou", "Stopped"), () {
            setState(() {
              filtertext = "Stopped";
              filterSearchResults("Stopped");
            });
          }),
          SizedBox(width: 6),
          _buildFilterTab(TranslationHelper.translateSync(context, "Parada", "Idle"), idleCount, currentFilter == TranslationHelper.translateSync(context, "Parada", "Idle"), () {
            setState(() {
              filtertext = "Idle";
              filterSearchResults("Idle");
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int count, bool isSelected, VoidCallback onTap) {
    return Builder(
      builder: (context) {
        final colorProvider = Provider.of<ColorProvider>(context);
        
        // Definir ícone baseado no label
        IconData filterIcon;
        if (label == TranslationHelper.translateSync(context, "Todos", "All") || label == "All") {
          filterIcon = Icons.list;
        } else if (label == TranslationHelper.translateSync(context, "Correndo", "Running") || label == "Running") {
          filterIcon = Icons.directions_run;
        } else if (label == TranslationHelper.translateSync(context, "Parou", "Stopped") || label == "Stopped") {
          filterIcon = Icons.stop_circle;
        } else if (label == TranslationHelper.translateSync(context, "Parada", "Idle") || label == "Idle") {
          filterIcon = Icons.pause_circle;
        } else {
          filterIcon = Icons.filter_list;
        }
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? colorProvider.primaryColor : Colors.white, // Cor principal
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colorProvider.primaryColor : Colors.grey.withOpacity(0.2), // Cor principal
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterIcon,
                  size: 14,
                  color: isSelected ? Colors.white : colorProvider.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '$label $count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(TranslationHelper.translateSync(context, 'Filtrar por status', 'Filter by status')),
          children: carstatusList.map((String value) {
            int count = 0;
            if (value == "All Vehicle") count = _vehiclesData.length;
            if (value == "Running") count = _runningVehicles.length;
            if (value == "Stopped") count = _stoppedVehicles.length;
            if (value == "Idle") count = _idleVehicles.length;
            if (value == "In Active") count = _inactiveVehicles.length;
            if (value == "Expired") count = _noDataVehicles.length;

            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  filterSelected = value;
                  if (value == "All Vehicle") {
                    filterSearchResults("All");
                  } else if (value == "Running") {
                    filterSearchResults("Running");
                  } else if (value == "Stopped") {
                    filterSearchResults("Stopped");
                  } else if (value == "Idle") {
                    filterSearchResults("Idle");
                  } else if (value == "In Active") {
                    filterSearchResults("In Active");
                  } else if (value == "Expired") {
                    filterSearchResults("expire");
                  }
                });
              },
              child: Text(
                "${_getTranslatedStatus(context, value)} ($count)",
                style: TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getTranslatedStatus(BuildContext context, String status) {
    switch (status) {
      case "All Vehicle":
        return getTranslated(context, 'all') ?? "Todos";
      case "Running":
        return getTranslated(context, 'running') ?? "Correndo";
      case "Stopped":
        return getTranslated(context, 'stopped') ?? "Parou";
      case "Idle":
        return getTranslated(context, 'idle') ?? "Parada";
      case "In Active":
        return getTranslated(context, 'offline') ?? "Desligada";
      case "Expired":
        return getTranslated(context, 'noData') ?? "Sem dados";
      default:
        return status;
    }
  }

  Widget _buildItem(deviceItems productData, boxImageSize, index) {
    double imageSize = MediaQuery.of(context).size.width / 25;
    double lat = productData.lat!.toDouble();
    double lng = productData.lng!.toDouble();
    double course = productData.course!.toDouble();
    int speed = productData.speed!.toInt();
    String imei = productData.deviceData!.imei.toString();
    String carstatus = productData.online!.toString();
    String time = productData.time.toString();
    String stoppedTime = productData.stopDuration.toString();

    Color statuscolor = Colors.red;

    String other = productData.deviceData!.traccar!.other.toString();

    bool ignitionOn = false;
    if (other.contains("<ignition>")) {
      const start = "<ignition>";
      const end = "</ignition>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      ignitionOn =
          other.substring(startIndex + start.length, endIndex) == "true";
    }

    bool isMoving = ignitionOn && (productData.speed! > 0);
    Color ignitionColor = isMoving
        ? Colors.blue
        : ignitionOn
            ? Colors.green
            : Colors.red;
    String ignition = "false";
    String enginehours = "0h";
    String sat = "0";
    String totaldistance = "0";
    String distance = "0";
    String devicestatus = "0";

    if (other.contains("<ignition>")) {
      const start = "<ignition>";
      const end = "</ignition>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      ignition = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<enginehours>")) {
      const start = "<enginehours>";
      const end = "</enginehours>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      int hours =
          int.parse(other.substring(startIndex + start.length, endIndex));
      enginehours = (hours / 3600).toStringAsFixed(2);
    }
    if (other.contains("<sat>")) {
      const start = "<sat>";
      const end = "</sat>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      sat = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<totaldistance>")) {
      const start = "<totaldistance>";
      const end = "</totaldistance>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      double dis =
          double.parse(other.substring(startIndex + start.length, endIndex));
      totaldistance = (dis / 1000).toStringAsFixed(2);
      // totaldistance = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<distance>")) {
      const start = "<distance>";
      const end = "</distance>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      distance = other.substring(startIndex + start.length, endIndex);
    }

    String labelStatusType = "not_connected";

    if (productData.time!.toLowerCase().contains('not connected')) {
      devicestatus = TranslationHelper.translateSync(context, "Desconectado", "Disconnected");
      labelStatusType = "not_connected";
      statuscolor = Colors.blue;
    } else if (productData.speed!.toInt() > 0) {
      devicestatus = TranslationHelper.translateSync(context, "Em movimento", "Moving");
      labelStatusType = "moving";
      statuscolor = Colors.green;
    } else if (productData.online!.toLowerCase().contains('engine')) {
      devicestatus = TranslationHelper.translateSync(context, "Ligado", "On");
      labelStatusType = "idle";
      statuscolor = Colors.yellow;
    } else if (productData.online!.toLowerCase().contains('online')) {
      devicestatus = TranslationHelper.translateSync(context, "Online", "Online");
      labelStatusType = "online";
      statuscolor = Colors.green;
    } else if (productData.online!.toLowerCase().contains('ack')) {
      devicestatus = TranslationHelper.translateSync(context, "Parado", "Stopped");
      labelStatusType = "stopped";
      statuscolor = Colors.red;
    } else {
      devicestatus = TranslationHelper.translateSync(context, "Desconectado", "Disconnected");
      labelStatusType = "not_connected";
      statuscolor = Colors.blue;
    }

    print("@@@ ATUALIZOU");

    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(
              12, 0, 12, 0), // lateral alinhada e espaço entre cards
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // <-- novo, aparece antes do nome do carro
                  buildCompactDeviceCard(productData),
                  //_buildGoogleMap(lat, lng, course, imei, productData.id),
                  //_buildDivider(),
                  //if (productData.sensors != null && productData.sensors!.isNotEmpty)
                  // _buildCardSectionSensors(productData),
                  // _buildCardSectionAddress(productData, lat, lng),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _collapseMapContainer(int deviceId) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_showMiniMap[deviceId] == true) {
                  _showMiniMap[deviceId] = false;
                } else {
                  _showMiniMap[deviceId] = true;
                }
              });
            },
            child: Icon(
              (_showMiniMap[deviceId] ?? true)
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1, // Altura da linha
      width: double.infinity, // Largura total
      margin: EdgeInsets.symmetric(horizontal: 20), // Margem lateral
      color: Colors.grey[300], // Cor da linha
    );
  }

  // Supondo que productData.time seja uma String no formato '2025-03-12 01:37:29'
  String formatDate(String dateString) {
    try {
      // Tenta converter a string para um objeto DateTime
      DateTime dateTime = DateTime.parse(dateString);

      // Formata a data no formato desejado
      String formattedDate =
          DateFormat('dd/MM/yyyy \'às\' HH:mm:ss').format(dateTime);

      return formattedDate;
    } catch (e) {
      // Se ocorrer um erro, retorna a mensagem padrão
      return 'Ainda não conectado';
    }
  }

  Widget _buildCardSectionAddress(
      deviceItems productData, double lat, double lng) {
    String lastUpdated =
        '${TranslationHelper.translateSync(context, 'Última Atualização em', 'Last Update on')} ${formatDate(productData.time.toString())}';

    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informações do Endereço
          addressLoad(lat.toString(), lng.toString()),
          SizedBox(height: 5), // Espaçamento entre os textos
          // Data de Atualização
          Text(
            lastUpdated, // Texto da última atualização
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSectionSensors(deviceItems productData) {
    List<Sensors>? allSensors = productData.sensors;

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            child: Row(
              children: (allSensors ?? []).map((sensor) {
                IconData sensorIcon = _getSensorIconData(sensor.type ?? '');
                return _buildSensorIconCard(
                  sensorIcon,
                  sensor.name ?? TranslationHelper.translateSync(context, 'Desconhecido', 'Unknown'),
                  sensor.value ?? 'N/A',
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  IconData _getSensorIconData(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case "acc":
        return FontAwesomeIcons.carCrash;
      case "anonymizer":
        return FontAwesomeIcons.userSecret;
      case "battery":
        return FontAwesomeIcons.batteryFull;
      case "battery_external":
        return FontAwesomeIcons.bolt;
      case "counter":
        return FontAwesomeIcons.hashtag;
      case "datetime":
        return FontAwesomeIcons.calendarAlt;
      case "door":
        return FontAwesomeIcons.doorClosed;
      case "engine":
        return FontAwesomeIcons.cogs;
      case "engine_hours":
        return FontAwesomeIcons.clock;
      case "fuel_consumption":
        return FontAwesomeIcons.gasPump;
      case "fuel_tank":
        return FontAwesomeIcons.oilCan;
      case "gsm":
        return FontAwesomeIcons.signal;
      case "harsh_acceleration":
        return FontAwesomeIcons.tachographDigital;
      case "harsh_breaking":
        return FontAwesomeIcons.exclamationTriangle;
      case "harsh_turning":
        return FontAwesomeIcons.syncAlt;
      case "ignition":
        return FontAwesomeIcons.powerOff;
      case "load":
        return FontAwesomeIcons.truckLoading;
      case "logical":
        return FontAwesomeIcons.code;
      case "numerical":
        return FontAwesomeIcons.sortNumericUp;
      case "odometer":
        return FontAwesomeIcons.tachometerAlt;
      case "plugged":
        return FontAwesomeIcons.plug;
      case "rfid":
        return FontAwesomeIcons.idCard;
      case "satellites":
        return FontAwesomeIcons.satellite;
      case "seatbelt":
        return FontAwesomeIcons.userLock;
      case "speed_ecm":
        return FontAwesomeIcons.tachometerAltFast;
      case "tachometer":
        return FontAwesomeIcons.tachometerAlt;
      case "temperature":
        return FontAwesomeIcons.thermometerHalf;
      case "textual":
        return FontAwesomeIcons.font;
      case "vin":
        return FontAwesomeIcons.key;
      default:
        return FontAwesomeIcons.questionCircle;
    }
  }

  // Função auxiliar para criar o card de velocidade
  Widget _buildSensorIconCard(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final colorProvider = Provider.of<ColorProvider>(context);
        return Container(
          width: 72,
          margin: EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor, // Cor principal
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Sombra leve
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: ResponsiveHelper.iconSize(20), color: Colors.white),
                ),
              ),
              ResponsiveHelper.verticalSpace(6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(11),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: ResponsiveHelper.fontSize(10), color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSensorColor(String label) {
    switch (label.toLowerCase()) {
      case 'ignição':
        return Colors.orange;
      case 'gsm':
        return Colors.teal;
      case 'satellite':
      case 'satélite':
        return Colors.indigo;
      case 'bateria':
        return Colors.green;
      case 'motor':
      case 'motor on off':
        return Colors.red;
      case 'horas do motor':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String truncate(String text, [int maxLength = 20]) {
    return (text.length <= maxLength)
        ? text
        : '${text.substring(0, maxLength)}...';
  }

  void _showVehicleCardModal(BuildContext context, deviceItems vehicle) {
    // Criar um MapController temporário para o VehicleCard
    final tempMapController = MapController();
    final bottomNavHeight = 85.0; // Altura do bottom navigation
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomNavHeight),
          child: ChangeNotifierProvider.value(
            value: tempMapController,
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = screenWidth * 0.90; // 90% da largura da tela
                final maxCardWidth = 480.0; // Máximo aumentado para 480px
                final actualCardWidth = cardWidth > maxCardWidth ? maxCardWidth : cardWidth;
                final horizontalMargin = (screenWidth - actualCardWidth) / 2;
                
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: actualCardWidth,
                    margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: VehicleCard(
                        vehicle: vehicle,
                        isModal: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Limpar o controller quando o modal fechar
      tempMapController.dispose();
    });
  }

  Widget buildCompactDeviceCard(deviceItems productData) {
    final String baseUrl = "https://web.unnicatelemetria.com.br/";
    final String deviceName = productData.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle');
    final String? imagePath = productData.image;
    final String imageUrl = imagePath != null && imagePath.trim().isNotEmpty
        ? "$baseUrl$imagePath"
        : "$baseUrl/images/device_icons/rotating/1.png";

    final String xmlData = productData.deviceData?.traccar?.other ?? '';
    final bool isIgnitionOn = productData.deviceData?.traccar?.other
            ?.contains("<ignition>true</ignition>") ==
        true;

    final int speed = productData.speed?.toInt() ?? 0;
    final bool isOffline = productData.online?.toLowerCase().contains("offline") ?? false;

    // Obter a placa do carro - tentar múltiplas fontes
    String plateNumber = '';
    if (productData.plateNumber != null &&
        productData.plateNumber!.isNotEmpty) {
      plateNumber = productData.plateNumber!;
    } else if (productData.deviceData?.plateNumber != null &&
        productData.deviceData!.plateNumber!.isNotEmpty) {
      plateNumber = productData.deviceData!.plateNumber!;
    } else if (productData.deviceData?.registrationNumber != null &&
        productData.deviceData!.registrationNumber!.isNotEmpty) {
      plateNumber = productData.deviceData!.registrationNumber!;
    } else if (productData.name != null && productData.name!.contains(' ')) {
      final nameParts = productData.name!.split(' ');
      if (nameParts.length >= 2) {
        final possiblePlate = nameParts[1];
        if (RegExp(r'[A-Za-z].*\d|\d.*[A-Za-z]').hasMatch(possiblePlate)) {
          plateNumber = possiblePlate;
        }
      }
    }
    if (plateNumber.isEmpty) {
      plateNumber = deviceName;
    }

    // Formatar data/hora
    String lastUpdate = TranslationHelper.translateSync(context, 'Sem registro', 'No record');
    if (productData.time != null && productData.time!.isNotEmpty) {
      try {
        final parsedDate = DateFormat("dd-MM-yyyy HH:mm:ss").parse(productData.time!);
        lastUpdate = DateFormat('dd/MM/yyyy HH:mm:ss', 'pt_BR').format(parsedDate);
      } catch (e) {
        try {
          // Tentar outros formatos de data
          final parsedDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(productData.time!);
          lastUpdate = DateFormat('dd/MM/yyyy HH:mm:ss', 'pt_BR').format(parsedDate);
        } catch (e2) {
          lastUpdate = productData.time!;
        }
      }
    }

    // Obter nome do motorista
    String driverName = productData.driver ?? TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    if (driverName.isEmpty || driverName.toLowerCase() == 'null') {
      driverName = TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    } else {
      // Formatar nome: Primeiro Nome + Primeira Inicial do Sobrenome
      driverName = _formatDriverName(driverName);
    }

    // Removido GestureDetector do card - mantendo apenas o modal da imagem
    return Builder(
        builder: (context) {
          final colorProvider = Provider.of<ColorProvider>(context);
          // Cor da borda baseada no status da ignição e movimento
          // Verde: ligado e movimentando (ignição ligada E velocidade > 0)
          // Amarelo: parado (ignição ligada mas velocidade = 0)
          // Vermelho: desligado (ignição desligada) E também offline
          final Color borderColor;
          if (isOffline) {
            borderColor = Colors.red; // Offline = vermelho
          } else if (isIgnitionOn && speed > 0) {
            borderColor = Colors.green; // Ligado e movimentando = verde
          } else if (isIgnitionOn && speed == 0) {
            borderColor = Colors.orange; // Parado (ligado mas sem movimento) = amarelo/laranja
          } else {
            borderColor = Colors.red; // Desligado = vermelho
          }
          
          return Container(
            margin: ResponsiveHelper.margin(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveHelper.radius(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12), // Sombra mais pronunciada para efeito levantado
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Container(
                  padding: ResponsiveHelper.padding(all: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.radius(12)),
                    border: Border(
                      left: BorderSide(
                        color: borderColor,
                        width: 4.w,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagem do carro em círculo com borda da cor do status da ignição
                          GestureDetector(
                            onTap: () {
                              _showVehicleCardModal(context, productData);
                            },
                            child: Builder(
                              builder: (context) {
                                // Se houver imagem → mostrar, se não → ícone padrão
                                if (imagePath != null && imagePath.trim().isNotEmpty) {
                                  return Container(
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: borderColor,
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Container(
                                        color: Colors.white,
                                        child: Center(
                                          child: Image.network(
                                            imageUrl,
                                            width: 85,
                                            height: 85,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: borderColor.withOpacity(0.1),
                                                child: Icon(
                                                  Icons.directions_car,
                                                  color: borderColor,
                                                  size: 38,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Ícone padrão com cor da ignição
                                  return Container(
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: borderColor.withOpacity(0.1),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.directions_car,
                                      color: borderColor,
                                      size: 38,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Dados do veículo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Nome do veículo
                                Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Placa do veículo
                                Text(
                                  'Placa: $plateNumber',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Motorista
                                Builder(
                                  builder: (context) {
                                    final colorProvider = Provider.of<ColorProvider>(context);
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 12,
                                          color: colorProvider.primaryColor, // Cor principal
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          driverName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                // Status de ignição e botão de velocidade embaixo
                                Row(
                                  children: [
                                    // Status de ignição
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isOffline ? Colors.red : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: isOffline
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.power_off,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  TranslationHelper.translateSync(context, 'Desligada', 'Off'),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.power,
                                                  size: 12,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  TranslationHelper.translateSync(context, 'Ligada', 'On'),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Botão de velocidade
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.speed,
                                            size: 12,
                                            color: Colors.grey[700],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${speed.toStringAsFixed(1)} km/h',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Street View com botão de compartilhar
                      if (productData.lat != null && productData.lng != null)
                        Container(
                          width: double.infinity,
                          height: 130,
                          margin: EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GestureDetector(
                              onTap: () {
                                if (productData.lat != null && productData.lng != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StreetViewScreen(
                                        initialPosition: gmaps.LatLng(
                                          CoordinateUtils.toDouble(productData.lat) ?? 0.0,
                                          CoordinateUtils.toDouble(productData.lng) ?? 0.0,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Stack(
                                children: [
                                  // Street View Image
                                  Image.network(
                                    'https://maps.googleapis.com/maps/api/streetview?size=400x200&location=${productData.lat},${productData.lng}&key=AIzaSyAD3aCRNglXgQNU1vnQAbC14YQyrcLH4V0&heading=345&pitch=0',
                                    width: double.infinity,
                                    height: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 130,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.streetview, size: 35, color: Colors.grey.shade400),
                                            SizedBox(height: 6),
                                            Text(
                                              TranslationHelper.translateSync(context, 'Street View não disponível', 'Street View not available'),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      final colorProvider = Provider.of<ColorProvider>(context, listen: false);
                                      return Container(
                                        height: 130,
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / 
                                                  loadingProgress.expectedTotalBytes!
                                                : null,
                                            valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Botão de compartilhar no canto superior direito
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _shareLocationFromCard(productData),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.share,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Overlay indicando que é clicável
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.streetview, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            TranslationHelper.translateSync(context, 'Toque para ver', 'Tap to view'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // KM total, Tempo Parado e Bateria (todos da API de sensores da frota)
                      Builder(
                        builder: (context) {
                          final colorProvider = Provider.of<ColorProvider>(context);
                          
                          return FutureBuilder<Map<String, String>>(
                            future: _getSensorsDataFromAPI(productData),
                            builder: (context, snapshot) {
                              final sensorsData = snapshot.hasData 
                                  ? snapshot.data! 
                                  : {
                                      'odometer': '---',
                                      'engineHours': '---',
                                      'totalDistance': productData.totalDistance != null 
                                          ? ((productData.totalDistance as num).toDouble() / 1000).toStringAsFixed(0) + ' km'
                                          : '0 km',
                                      'gpsSignal': '0',
                                      'gsmSignal': '0',
                                    };
                              
                              return Column(
                            children: [
                              // Linha com Sensores (Scroll Horizontal)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ... (código dos badges mantido igual) ...
                                      // Odômetro (Azul)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.speed, size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${sensorsData['odometer']}',
                                              style: TextStyle(fontSize: 11, color: Colors.blue[800], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Horas do Motor (Laranja)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_filled, size: 14, color: Colors.orange[800]),
                                            const SizedBox(width: 4),
                                            Text(
                                              sensorsData['engineHours'] ?? '---',
                                              style: TextStyle(fontSize: 11, color: Colors.orange[900], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Distância Total (Teal)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.teal.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.map, size: 14, color: Colors.teal),
                                            const SizedBox(width: 4),
                                            Text(
                                              sensorsData['totalDistance'] ?? '0 km',
                                              style: TextStyle(fontSize: 11, color: Colors.teal[800], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // GPS (Indigo)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.satellite_alt, size: 14, color: Colors.indigo),
                                            const SizedBox(width: 4),
                                            Text(
                                              'GPS: ${sensorsData['gpsSignal']}',
                                              style: TextStyle(fontSize: 11, color: Colors.indigo[800], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // GSM (Pink)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.pink.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.pink.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.signal_cellular_alt, size: 14, color: Colors.pink),
                                            const SizedBox(width: 4),
                                            Text(
                                              'GSM: ${sensorsData['gsmSignal']}',
                                              style: TextStyle(fontSize: 11, color: Colors.pink[800], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ADICIONADO: Padding vertical maior entre sensores e endereço
                              const SizedBox(height: 12),
                              // Endereço e Última Posição na mesma linha
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: colorProvider.primaryColor, // Cor principal
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          TranslationHelper.translateSync(context, 'Última Posição', 'Last Position'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            productData.address ?? TranslationHelper.translateSync(context, 'Sem endereço', 'No address'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Última Atualização
                      Builder(
                        builder: (context) {
                          final colorProvider = Provider.of<ColorProvider>(context);
                          return Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: colorProvider.primaryColor, // Cor principal
                              ),
                              const SizedBox(width: 3),
                              Text(
                                TranslationHelper.translateSync(context, 'Última Atualização', 'Last Update'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lastUpdate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
      );
  }

  // Função para compartilhar localização do card
  Future<void> _shareLocationFromCard(deviceItems productData) async {
    // Verificar se tem coordenadas
    if (productData.lat == null || productData.lng == null) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Coordenadas não disponíveis para compartilhar', 'Coordinates not available to share'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    final deviceName = productData.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle');
    
    // Obter a placa do carro - mesma lógica do card
    String plateNumber = '';
    if (productData.plateNumber != null &&
        productData.plateNumber!.isNotEmpty) {
      plateNumber = productData.plateNumber!;
    } else if (productData.deviceData?.plateNumber != null &&
        productData.deviceData!.plateNumber!.isNotEmpty) {
      plateNumber = productData.deviceData!.plateNumber!;
    } else if (productData.deviceData?.registrationNumber != null &&
        productData.deviceData!.registrationNumber!.isNotEmpty) {
      plateNumber = productData.deviceData!.registrationNumber!;
    } else if (productData.name != null && productData.name!.contains(' ')) {
      final nameParts = productData.name!.split(' ');
      if (nameParts.length >= 2) {
        final possiblePlate = nameParts[1];
        if (RegExp(r'[A-Za-z].*\d|\d.*[A-Za-z]').hasMatch(possiblePlate)) {
          plateNumber = possiblePlate;
        }
      }
    }
    if (plateNumber.isEmpty) {
      plateNumber = deviceName;
    }
    
    final lat = productData.lat!.toDouble();
    final lng = productData.lng!.toDouble();
    
    // Criar link do Google Maps
    final googleMapsLink = 'https://www.google.com/maps?q=$lat,$lng';
    
    // Formatar coordenadas
    final coordinates = 'Lat: ${lat.toStringAsFixed(6)}, Long: ${lng.toStringAsFixed(6)}';
    
    // Montar mensagem profissional e completa
    final message = '''📍 ${TranslationHelper.translateSync(context, 'Olá, essa é minha localização atual:', 'Hello, this is my current location:')}

🚗 ${TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')}: $deviceName
🔢 ${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: $plateNumber
📍 ${TranslationHelper.translateSync(context, 'Coordenadas', 'Coordinates')}: $coordinates

🗺️ ${TranslationHelper.translateSync(context, 'Visualizar no mapa:', 'View on map:')}
$googleMapsLink

---
${TranslationHelper.translateSync(context, 'Enviado via U-Connect - Sistema de Rastreamento GPS', 'Sent via U-Connect - GPS Tracking System')}''';

    try {
      await Share.share(
        message,
        subject: '${TranslationHelper.translateSync(context, 'Localização do veículo', 'Vehicle location')} $deviceName',
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao compartilhar localização', 'Error sharing location'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Widget _showDeliveryPopup(deviceItems productData) {
    String imageUrl = productData.image != null &&
            productData.image!.trim().isNotEmpty
        ? "https://web.unnicatelemetria.com.br/${productData.image}"
        : "https://web.unnicatelemetria.com.br/images/device_icons/rotating/1.png";

    bool ignitionOn = productData.deviceData!.traccar!.other
            ?.contains("<ignition>true</ignition>") ==
        true;
    bool isMoving = ignitionOn && (productData.speed! > 0);
    Color ignitionColor = isMoving
        ? Colors.blue
        : ignitionOn
            ? Colors.green
            : Colors.red;
    String ignitionStatus = isMoving
        ? TranslationHelper.translateSync(context, "Em movimento", "Moving")
        : ignitionOn
            ? TranslationHelper.translateSync(context, "Ligado", "On")
            : TranslationHelper.translateSync(context, "Desligado", "Off");

    // Função para truncar texto
    String truncateText(String text, int maxLength) {
      return text.length <= maxLength
          ? text
          : '${text.substring(0, maxLength)}...';
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header Azul Escuro (mais compacto)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF001F5C), // azul escuro
                  Color(0xFF1976D2), // azul claro
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Imagem do veículo (menor)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                          "assets/images/defaultcar.png",
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Nome e status (mais compacto)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truncateText(productData.name ?? 'Veículo', 16),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Badge de status (menor)
                          Container(
                            height: 28,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: ignitionOn ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  ignitionStatus,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Badge de velocidade (menor)
                          Container(
                            height: 28,
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 3),
                                Text(
                                  "${productData.speed?.toInt() ?? 0} km/h",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botão de fechar (menor e mais elegante)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Bloco de Status (Branco) - Dinâmico
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            _buildLockStatusIcon(productData),
                            SizedBox(height: 4),
                            Text(_getLockStatusText(productData),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  // fontWeight: FontWeight.w600, // Removido para ficar igual aos outros
                                )),
                          ],
                        ),
                        Column(
                          children: [
                            (productData.deviceData?.alert_id != null &&
                                    productData.deviceData?.alert_id != 0)
                                ? _animatedStatusIcon(Icons.anchor,
                                    Colors.green) // se diferente de null e 0
                                : _animatedStatusIcon(Icons.anchor, Colors.red),
                            SizedBox(height: 4),
                            Text(
                                (productData.deviceData?.alert_id != null &&
                                        productData.deviceData?.alert_id != 0)
                                    ? "Ativado"
                                    : "Desativado",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                        Column(
                          children: [
                            _animatedStatusIcon(Icons.warning, Colors.red),
                            SizedBox(height: 4),
                            Text(TranslationHelper.translateSync(context, "SOS Inativo", "SOS Inactive"),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Ações Rápidas (Design Moderno Monocromático)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.flash_on,
                                size: 20,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              TranslationHelper.translateSync(context, "Ações Rápidas", "Quick Actions"),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // _quickAction(Icons.query_stats, 'KM', () {
                            //   Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //           builder: (ctx) => kmdetail()));
                            // }),
                            // _quickAction(Icons.play_circle_fill, 'Reprodução',
                            //     () {
                            //   Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //           builder: (ctx) => playbackselection()));
                            // }),
                            _quickAction(Icons.description, TranslationHelper.translateSync(context, 'Relatórios', 'Reports'), () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => reportselection()));
                            }),
                            _quickAction(Icons.notifications, TranslationHelper.translateSync(context, 'Alertas', 'Alerts'), () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (ctx) => AlertListPage()));
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Visualização da Rua (Bloco Cinza Claro)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map, size: 20, color: Colors.black87),
                            SizedBox(width: 8),
                            Text(TranslationHelper.translateSync(context, "Visualização da rua", "Street View"),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // Imagem do Street View
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'https://maps.googleapis.com/maps/api/streetview?size=400x200&location=${productData.lat},${productData.lng}&key=AIzaSyAD3aCRNglXgQNU1vnQAbC14YQyrcLH4V0&heading=345&pitch=0',
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 150,
                                    color: Color(0xFFF8F9FA),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Color(0xFF6B7280),
                                          size: 32,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          TranslationHelper.translateSync(context, 'Street View não disponível', 'Street View not available'),
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Lat: ${productData.lat?.toStringAsFixed(6)}, Lng: ${productData.lng?.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Overlay com informações
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.streetview,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Street View',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: productData.speed > 0
                          ? Color(0xFFE8F5E8)
                          : Color.fromARGB(29, 255, 17, 0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          productData.speed > 0
                              ? Icons.speed
                              : Icons.stop_circle,
                          size: 18,
                          color:
                              productData.speed > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          productData.speed > 0 ? 'Em movimento' : 'Parado',
                          style: TextStyle(
                            fontSize: 12,
                            color: productData.speed > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          productData.speed == 0
                              ? ' há ${productData.stopDuration}'
                              : '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(52, 58, 154, 209),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: Color.fromARGB(255, 18, 107, 196),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ultima atualização: ' +
                                  (productData.time != null &&
                                          productData.time!.isNotEmpty
                                      ? DateFormat('dd/MM/yyyy HH:mm', 'pt_BR')
                                          .format(
                                              DateFormat("dd-MM-yyyy HH:mm:ss")
                                                  .parse(
                                          productData.time!,
                                        ))
                                      : 'Sem registro'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  // Localização (Bloco Verde Claro)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 22,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            productData.address!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Consumo de Combustível (Bloco Branco)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_gas_station,
                                size: 20, color: Colors.black87),
                            SizedBox(width: 8),
                            Text("Consumo de Combustível",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.query_stats,
                                        size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text("Consumo/km",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                                Text("0.0000 L/km",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_gas_station,
                                        size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text("Quantidade",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                                Text("0.00 L",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.attach_money,
                                        size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text("Preço/L",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                                Text("R\$ 0.00",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Custo por km",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                Text("R\$ 0.00",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE3F2FD),
                                foregroundColor: Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text("Eficiência"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Botões de Ação (Bloco Branco)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ações",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _circleAction(
                              icon: Icons.lock_outline,
                              color: Color(0xFF1976D2),
                              onTap: () async {
                                StaticVarMethod.deviceId =
                                    productData.id.toString();
                                await getCommands();
                                commandDialog(context);
                              },
                            ),
                            _circleAction(
                              icon: Icons.anchor,
                              color: (productData.deviceData?.alert_id !=
                                          null &&
                                      productData.deviceData?.alert_id != 0)
                                  ? Colors.green // se for diferente de null e 0
                                  : const Color(0xFF1976D2), // se for null ou 0
                              onTap: () async {
                                _showSecurityOnOFF(context, productData);
                              },
                            ),
                            AnimatedActionButton(
                              icon: Icons.sos,
                              label: 'SOS',
                              message: "Função SOS em construção.",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSecurityOnOFF(
      BuildContext context, dynamic productData) async {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            padding: EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Âncora',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Qual opção deseja executar?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () {
                            print('Botão Desabilitar');
                            Navigator.of(context).pop();
                            if (productData.deviceData?.alert_id != null &&
                                productData.deviceData?.alert_id != 0) {
                              removerEstacionamento(context, productData);
                            } else {
                              Future.delayed(Duration.zero, () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    Future.delayed(const Duration(seconds: 5),
                                        () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                    });
                                    return const AlertDialog(
                                      content: Text(
                                        "Âncora não habilitada!",
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                );
                              });
                            }
                          },
                          child: Text(
                            'Desabilitar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () {
                            print('Botão Habilitar');
                            Navigator.of(context).pop();
                            if (productData.deviceData?.alert_id != null &&
                                productData.deviceData?.alert_id != 0) {
                              Future.delayed(Duration.zero, () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    Future.delayed(const Duration(seconds: 5),
                                        () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                    });
                                    return const AlertDialog(
                                      content: Text(
                                        "Âncora já habilitada,\ndesabilite a anterior para tentar novamente!",
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                );
                              });
                            } else {
                              criarGeofence(context, productData);
                            }
                          },
                          child: Text(
                            'Habilitar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => simpleDialog,
    );
  }

  Future<void> removerEstacionamento(
      BuildContext context, deviceItems productData) async {
    // deleta alerta
    var alert_id = "${productData.deviceData?.alert_id!}";
    var response_alert = await gpsapis.destroyAlertAncor(alert_id);
    if (response_alert != null && response_alert.statusCode == 200) {
      print("Alerta excluido com sucesso!");
    } else {
      print("Erro ao excluir alerta");
    }

    // deleta geofence
    var geofence_id = "${productData.deviceData?.geofence_id!}";
    var response_geofence = await gpsapis.destroyGeofenceAncor(geofence_id);
    if (response_geofence != null && response_geofence.statusCode == 200) {
      print("Geofence excluido com sucesso!");
    } else {
      print("Erro ao excluir geofence");
    }

    // Altera veiculo
    var request_device =
        "id=${productData.id!.toString()}&alert_id=0&geofence_id=0";
    var response = await gpsapis.editDeviceAncor(request_device);
    if (response != null && response.statusCode == 400) {
      print("Veículo alterado com sucesso!");
    } else {
      print("Erro ao alterar veículo");
    }
  }

  Future<void> criarGeofence(
      BuildContext context, deviceItems productData) async {
    var response = await gpsapis.addGeofence(
      name: "Âncora: ${productData.name}",
      active: true,
      device_id: productData.id,
      type: "circle",
      lat: productData.lat,
      lng: productData.lng,
      radius: 50.0, // raio em metros
      polygon_color: "#000000",
    );
    
    if (response != null && response['item'] != null) {
      var geofenceId = response['item']['id'];
      await criarAlert(geofenceId, productData);
      print("Geofence criada com sucesso! ID: $geofenceId");
    } else {
      print("Erro ao criar geofence");
    }
  }

// Cria o alerta
  Future<void> criarAlert(int? geofenceId, deviceItems productData) async {
    //print("Cerca criada numero: ${productData.lng!.toDouble()}");
    String deviceParams = "devices[]=${productData.id!.toString()}";
    String geofencesParams = "geofences[]=${geofenceId}";
    String commandParam = "command[active]=1&command[type]=engineStop";
    var request = "&name=Âncora: " +
        productData.name!.toString() +
        "&type=geofence_out&" +
        deviceParams +
        "&" +
        geofencesParams +
        "&" +
        commandParam;

    var response = await gpsapis.addAlertAncor(request);
    if (response != null && response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var alertId = data['item']['id'];
      alterarDevice(alertId, geofenceId, productData);
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 10), () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            return const AlertDialog(
              content: Text(
                "Âncora criada com sucesso!",
                textAlign: TextAlign.center,
              ),
            );
          },
        );
      });
      print("Alert criado com sucesso! ID: $alertId");
    } else {
      print("Erro ao criar geofence: ${response?.statusCode}");
    }
  }

  // Alteração de itens no veiculo
  Future<void> alterarDevice(
      int? alertId, int? geofenceId, deviceItems productData) async {
    var request_device =
        "id=${productData.id!.toString()}&alert_id=${alertId}&geofence_id=${geofenceId}";
    var response = await gpsapis.editDeviceAncor(request_device);
    if (response != null && response.statusCode == 200) {
      print("Veículo alterado com sucesso!");
    } else {
      print("Erro ao alterar veículo");
    }
  }

  Widget _popupIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }

  Widget _circleAction(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

// Removidas as implementações locais - agora usa as funções do command_logic.dart
  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: EdgeInsets.symmetric(vertical: 10),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500))
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(
      double? lat, double? lng, double course, String imei, int deviceId) {
    double latitude = lat ?? 0.0;
    double longitude = lng ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16), // 🔄 Bordas arredondadas em tudo
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
          ),
          child: Image.network(
            'https://web.unnicatelemetria.com.br/streetview.jpg?size=290x125&location=$lat,$lng&heading=345',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Icon(Icons.image_not_supported));
            },
          ),
        ),
      ),
    );
  }

  void showPopupDeleteFavorite(index, boxImageSize) {
    // set up the buttons
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text('No', style: TextStyle(color: SOFT_BLUE)));
    Widget continueButton = TextButton(
        onPressed: () {
          int removeIndex = index;

          // Remove the item from the data list.
          var removedItem = _vehiclesData.removeAt(removeIndex);

          // Use the AnimatedList's removeItem method to trigger the animation.
          _listKey.currentState!.removeItem(
            removeIndex,
            (BuildContext context, Animation<double> animation) {
              // Build the widget for the removed item during the animation.
              return SizeTransition(
                sizeFactor: animation,
                child: _buildItem(removedItem, boxImageSize, removeIndex),
              );
            },
          );

          // Navigate back and show a toast message.
          Navigator.pop(context);
          Fluttertoast.showToast(
            msg: 'Item has been deleted from your favorites',
            toastLength: Toast.LENGTH_SHORT,
          );
        },
        child: Text('Yes', style: TextStyle(color: SOFT_BLUE)));

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Text(
        'Delete Favorite',
        style: TextStyle(fontSize: 18),
      ),
      content: Text('Are you sure to delete this item from your Favorite ?',
          style: TextStyle(fontSize: 13, color: _color1)),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future refreshData() async {
    // IMPLEMENTAR ATUALIZAÇÃO DE DADOS
  }

  Widget kmandfueldetail(int deviceId) {
    var dev = deviceId;
    return FutureBuilder<History>(
        future: gpsapis.getHistory(deviceId),
        builder: (context, AsyncSnapshot<History> snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '${snapshot.data!.distanceSum} mi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0.00',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0 km',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0.00',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            );
          }
        });
  }

  Widget addressLoad(String lat, String lng) {
    return FutureBuilder<String>(
      future: gpsapis.geocode(lat, lng),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Container(
            child: Text(
              (snapshot.data!.replaceAll('"', '')),
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              maxLines: 2,
            ),
          );
        } else {
          return Text("Carregando...");
        }
      },
    );
  }

// Removida implementação local - usa a função do command_logic.dart

  Future<ImageInfo?> _checkStreetViewImage(double lat, double lng) async {
    final completer = Completer<ImageInfo?>();
    final image = NetworkImage(
      'https://web.unnicatelemetria.com.br/streetview.jpg?size=290x125&location=$lat,$lng&heading=345',
    );

    final stream = image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(info),
      onError: (dynamic _, __) => completer.complete(null),
    );

    stream.addListener(listener);
    return completer.future;
  }

  // Funções para status de bloqueio dinâmico
  Widget _buildLockStatusIcon(deviceItems productData) {
    final String xmlData = productData.deviceData?.traccar?.other ?? '';
    final bool isBlocked = xmlData.contains('<blocked>true</blocked>');

    return Icon(
      isBlocked ? Icons.lock : Icons.lock_open,
      color: isBlocked ? Colors.green : Colors.red,
      size: 24,
    );
  }

  String _getLockStatusText(deviceItems productData) {
    final String xmlData = productData.deviceData?.traccar?.other ?? '';
    final bool isBlocked = xmlData.contains('<blocked>true</blocked>');

    return isBlocked ? "Bloqueado" : "Desbloqueado";
  }

  Color _getLockStatusColor(deviceItems productData) {
    final String xmlData = productData.deviceData?.traccar?.other ?? '';
    final bool isBlocked = xmlData.contains('<blocked>true</blocked>');

    return isBlocked ? Colors.green : Colors.red;
  }

  // Ícone animado para status de âncora e SOS
  Widget _animatedStatusIcon(IconData icon, Color color) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isAnimating = false;

        return GestureDetector(
          onTap: () async {
            setState(() {
              isAnimating = true;
            });

            // Mostra a animação por 2 segundos
            await Future.delayed(Duration(seconds: 2));

            setState(() {
              isAnimating = false;
            });

            // Mostra mensagem de função não implementada
            Fluttertoast.showToast(msg: "Função ainda não implementada.");
          },
          child: isAnimating
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: Duration(milliseconds: 2000),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Icon(icon, color: color, size: 24),
                    );
                  },
                )
              : Icon(icon, color: color, size: 24),
        );
      },
    );
  }
}

// Botão animado reutilizável para ações como Âncora e SOS
class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String message;
  final Duration animationDuration;

  const AnimatedActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.message,
    this.animationDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  void _handleTap() async {
    // Mostra a animação como overlay na tela inteira
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo externo rotativo
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: widget.animationDuration,
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: CustomPaint(
                          painter: LoadingPainter(
                            progress: value,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Círculo interno pulsante
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: Duration(milliseconds: 1500),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Ícone central
                Icon(
                  widget.icon,
                  size: 40,
                  color: Color(0xFF001F5C),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Aguarda a duração da animação
    await Future.delayed(widget.animationDuration);

    // Fecha o dialog
    Navigator.of(context).pop();

    // Mostra a mensagem
    Fluttertoast.showToast(msg: widget.message);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF1976D2).withOpacity(0.4)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Color(0xFF1976D2),
              size: 24,
            ),
            SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.w500,
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para animar o ícone do veículo
class _AnimatedVehicleIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _AnimatedVehicleIcon({
    Key? key,
    required this.icon,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<_AnimatedVehicleIcon> createState() => _AnimatedVehicleIconState();
}

class _AnimatedVehicleIconState extends State<_AnimatedVehicleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

// Classe para desenhar o círculo de loading animado
class LoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  LoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Desenha o arco de progresso
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -1.5708, // -90 graus em radianos
      progress * 2 * 3.14159, // 360 graus * progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

