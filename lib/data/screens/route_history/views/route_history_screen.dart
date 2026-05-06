import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/config/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/utils/translation_helper.dart';

// ============================================
// MODELOS
// ============================================

class SavedRouteHistory {
  final String id;
  final int deviceId;
  final String deviceName;
  final DateTime startDate;
  final DateTime endDate;
  final List<HistoryPoint> points;
  final DateTime createdAt;

  SavedRouteHistory({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.startDate,
    required this.endDate,
    required this.points,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'points': points.map((p) => {
        'id': p.id,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'time': p.time,
        'serverTime': p.serverTime,
        'speed': p.speed,
        'altitude': p.altitude,
        'sensors': p.sensors,
        'status': p.status,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedRouteHistory.fromJson(Map<String, dynamic> json) {
    return SavedRouteHistory(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: json['deviceId'] ?? 0,
      deviceName: json['deviceName'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      points: (json['points'] as List? ?? []).map((p) => HistoryPoint.fromJson(p)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class HistoryPoint {
  final int id;
  final double? latitude;
  final double? longitude;
  final String time;
  final String serverTime;
  final String speed;
  final String altitude;
  final Map<String, dynamic>? sensors;
  final int? status;

  HistoryPoint({
    required this.id,
    this.latitude,
    this.longitude,
    required this.time,
    required this.serverTime,
    required this.speed,
    required this.altitude,
    this.sensors,
    this.status,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    // Converter speed e altitude para String (podem vir como int ou String)
    String speedStr = '0';
    if (json['speed'] != null) {
      if (json['speed'] is int || json['speed'] is double) {
        speedStr = json['speed'].toString();
      } else {
        speedStr = json['speed'].toString();
      }
    }
    
    String altitudeStr = '0';
    if (json['altitude'] != null) {
      if (json['altitude'] is int || json['altitude'] is double) {
        altitudeStr = json['altitude'].toString();
      } else {
        altitudeStr = json['altitude'].toString();
      }
    }
    
    return HistoryPoint(
      id: json['id'] ?? 0,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      time: json['time'] ?? '',
      serverTime: json['server_time'] ?? json['time'] ?? '',
      speed: speedStr,
      altitude: altitudeStr,
      sensors: json['popup_sensors'] ?? json['sensors_value'],
      status: json['status'],
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

// ============================================
// SERVIÇO DE API
// ============================================

class HistoryApiService {
  late final String baseUrl;
  String? token;

  HistoryApiService({String? baseUrl}) {
    this.baseUrl = (baseUrl == null || baseUrl.isEmpty) ? UserRepository.getServerURL() : baseUrl;
  }

  Future<List<HistoryPoint>> getHistory({
    required int deviceId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('Token não configurado'); // Não traduzir - erro interno
    }

    try {
      // Separar data e hora conforme esperado pela API
      final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate);
      final fromTimeStr = DateFormat('HH:mm:ss').format(fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd').format(toDate);
      final toTimeStr = DateFormat('HH:mm:ss').format(toDate);

      if (fromDateStr.isEmpty || toDateStr.isEmpty) {
        throw Exception('Datas inválidas: from_date=$fromDateStr, to_date=$toDateStr');
      }

      final url = Uri.parse('$baseUrl/api/get_history');
      
      final body = jsonEncode({
        'device_id': deviceId,
        'from_date': fromDateStr,
        'from_time': fromTimeStr,
        'to_date': toDateStr,
        'to_time': toTimeStr,
      });

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
          'Content-Type': 'application/json',
      };

      print('🔍 [DEBUG] Chamando API: POST $url');
      print('🔍 [DEBUG] device_id: $deviceId');
      print('🔍 [DEBUG] from_date: $fromDateStr');
      print('🔍 [DEBUG] from_time: $fromTimeStr');
      print('🔍 [DEBUG] to_date: $toDateStr');
      print('🔍 [DEBUG] to_time: $toTimeStr');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            'A requisição demorou mais de 90 segundos. Tente um período menor ou verifique sua conexão.',
            Duration(seconds: 90),
          );
        },
      );

      print('🔍 [DEBUG] Status Code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('❌ [DEBUG] Erro HTTP ${response.statusCode}');
        print('🔍 [DEBUG] Response Body: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }

        final data = jsonDecode(response.body);
      print('🔍 [DEBUG] Tipo de resposta: ${data.runtimeType}');
      
      if (data is Map && (data['status'] == 0 || data['status'] == false)) {
        final errorMsg = data['message'] ?? 'Erro ao buscar histórico';
        print('❌ [DEBUG] Erro na resposta da API: $errorMsg');
        throw Exception(errorMsg);
      }

        List<HistoryPoint> points = [];
        
      if (data is Map) {
        print('🔍 [DEBUG] Estrutura da resposta: ${data.keys}');
      } else {
        print('🔍 [DEBUG] Tipo de resposta: ${data.runtimeType}');
      }
        
      // A estrutura da resposta é: data['items'] = [grupos], cada grupo tem items[] com os pontos
      if (data is Map && data['items'] != null && data['items'] is List) {
          final grupos = data['items'] as List;
          print('🔍 [DEBUG] Encontrados ${grupos.length} grupos');
          for (var grupo in grupos) {
            if (grupo is Map && grupo['items'] != null && grupo['items'] is List) {
              final grupoItems = grupo['items'] as List;
              print('🔍 [DEBUG] Grupo com ${grupoItems.length} itens');
              for (var item in grupoItems) {
                try {
                  if (item is Map) {
                    final itemMap = item is Map<String, dynamic>
                        ? item
                        : Map<String, dynamic>.from(item);
                    final point = HistoryPoint.fromJson(itemMap);
                    points.add(point);
                  }
                } catch (e) {
                  print('⚠️ [DEBUG] Erro ao parsear item: $e');
                }
              }
            }
          }
        }
        
        print('✅ [DEBUG] Total de pontos parseados: ${points.length}');
        
        // Fallback para outras estruturas possíveis
        if (points.isEmpty && data['messages'] != null) {
          if (data['messages'] is List) {
            points = (data['messages'] as List)
                .map((item) {
                  try {
                    return HistoryPoint.fromJson(item);
                  } catch (e) {
                    print('⚠️ [DEBUG] Erro ao parsear item: $e');
                    return null;
                  }
                })
                .whereType<HistoryPoint>()
                .toList();
          }
        }
        
        if (points.isEmpty && data['data'] != null) {
          if (data['data'] is List) {
            points = (data['data'] as List)
                .map((item) {
                  try {
                    return HistoryPoint.fromJson(item);
                  } catch (e) {
                    print('⚠️ [DEBUG] Erro ao parsear item: $e');
                    return null;
                  }
                })
                .whereType<HistoryPoint>()
                .toList();
          }
        }

        print('✅ [DEBUG] Pontos encontrados: ${points.length}');
        return points;
    } catch (e) {
      print('❌ [DEBUG] Exceção ao buscar histórico: $e');
      throw Exception('Erro ao buscar histórico: $e');
    }
  }
}

// ============================================
// TELA PRINCIPAL
// ============================================

class RouteHistoryScreen extends StatefulWidget {
  final int? deviceId;
  final String? deviceName;

  const RouteHistoryScreen({
    Key? key,
    this.deviceId,
    this.deviceName,
  }) : super(key: key);

  // Função pública para abrir modal de histórico (usada pelo UnnicaBot)
  static void showRouteModalFromBot(BuildContext context, ColorProvider colorProvider, {
    required List<HistoryPoint> points,
    required DateTime startDate,
    required DateTime endDate,
    required String deviceName,
  }) {
    final validPoints = points.where((p) => p.hasLocation).toList();
    if (validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum ponto com localização válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteModal(
        points: validPoints,
        colorProvider: colorProvider,
        startDate: startDate,
        endDate: endDate,
        deviceName: deviceName,
      ),
    );
  }

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> with SingleTickerProviderStateMixin {
  final HistoryApiService _api = HistoryApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  
  List<HistoryPoint> _points = [];
  bool _isLoading = false;
  String? _error;
  
  DateTime _startDate = DateTime.now().subtract(Duration(days: 1));
  DateTime _endDate = DateTime.now();
  int? _selectedDeviceId;
  
  // Histórico salvo
  List<SavedRouteHistory> _savedHistories = [];
  bool _isLoadingHistory = false;
  String? _historyFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _savedHistories.isEmpty) {
        _loadSavedHistories();
      }
      // Atualizar estado quando a aba mudar para atualizar o ícone no cabeçalho
      if (mounted) {
        setState(() {});
      }
    });
    
    _api.token = StaticVarMethod.user_api_hash ?? '';
    _selectedDeviceId = widget.deviceId;
    
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(Duration(days: 1));
    
    if (_selectedDeviceId != null) {
      _loadHistory();
    }
    
    _loadSavedHistories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_selectedDeviceId == null) {
      print('⚠️ [DEBUG] _loadHistory: Nenhum dispositivo selecionado');
      _showError(getTranslated(context, 'selectAnyDevice') ?? 'Selecione um dispositivo primeiro');
      return;
    }

    // Validar período muito grande
    final periodDuration = _endDate.difference(_startDate);
    if (periodDuration.inDays > 30) {
      _showError(getTranslated(context, 'periodTooLarge') ?? 'Período muito grande. Selecione no máximo 30 dias.');
      return;
    }

    print('\n🔄 [DEBUG] ========== CARREGANDO HISTÓRICO ==========');
    print('📱 Device ID: $_selectedDeviceId');
    print('📅 Data Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
    print('📅 Data Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');
    print('⏱️ Duração do período: ${periodDuration.inDays} dias, ${periodDuration.inHours.remainder(24)} horas, ${periodDuration.inMinutes.remainder(60)} minutos');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final points = await _api.getHistory(
        deviceId: _selectedDeviceId!,
        fromDate: _startDate,
        toDate: _endDate,
      );

      print('✅ [DEBUG] Histórico carregado: ${points.length} pontos');

      setState(() {
          _points = points;
        _isLoading = false;
        _error = null; // Limpar erro anterior se houver
      });
      
      if (points.isEmpty) {
        // Não mostrar erro como snackbar, apenas deixar a tela vazia com mensagem
        print('⚠️ [DEBUG] Nenhum ponto encontrado para o período selecionado');
        } else {
        print('✅ [DEBUG] ${points.length} pontos carregados com sucesso');
        // Salvar histórico quando carregar com sucesso
        _saveHistory(points);
        }
    } on TimeoutException catch (e) {
      print('⏱️ [DEBUG] Timeout ao carregar histórico: $e');
      setState(() {
        _error = 'Timeout: A requisição demorou muito. Tente um período menor.';
        _isLoading = false;
      });
      _showError(getTranslated(context, 'requestTimeout') ?? 'A requisição demorou muito. Tente um período menor ou verifique sua conexão.');
    } catch (e) {
      print('❌ [DEBUG] Erro ao carregar histórico: $e');
      String errorMessage = getTranslated(context, 'errorLoadingHistory') ?? 'Erro ao carregar histórico';
      
      if (e.toString().contains('Timeout')) {
        errorMessage = getTranslated(context, 'requestTimeout') ?? 'A requisição demorou muito. Tente um período menor ou verifique sua conexão.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        errorMessage = getTranslated(context, 'connectionError') ?? 'Erro de conexão. Verifique sua internet.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = getTranslated(context, 'authenticationError') ?? 'Erro de autenticação. Faça login novamente.';
      } else {
        errorMessage = '${getTranslated(context, 'error') ?? 'Erro'}: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }
    
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      _showError(errorMessage);
    }
  }

  Future<void> _selectPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      final startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        0,
        0,
        0,
      );
      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      
      setState(() {
        _startDate = startDate;
        _endDate = endDate;
      });
      
      print('🕐 [DEBUG] Período personalizado selecionado:');
      print('   Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
      print('   Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');
      
      if (_selectedDeviceId != null) {
        _loadHistory();
      }
    }
  }

  void _setPeriod(Duration duration) {
    final now = DateTime.now();
    // Adicionar uma margem de segurança de 1 minuto para períodos pequenos
    // Isso garante que a API encontre dados mesmo com pequenas diferenças de tempo
    final margin = duration.inMinutes < 60 ? Duration(minutes: 1) : Duration.zero;
    final startDate = now.subtract(duration + margin);
    
    print('🕐 [DEBUG] _setPeriod:');
    print('   Duração solicitada: ${duration.inDays} dias, ${duration.inHours.remainder(24)} horas, ${duration.inMinutes.remainder(60)} minutos');
    print('   Margem de segurança: ${margin.inMinutes} minutos');
    print('   Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(startDate)}');
    print('   Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
    
    setState(() {
      _endDate = now;
      _startDate = startDate;
    });
    
    print('✅ [DEBUG] Período atualizado no estado');
    print('   _startDate: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
    print('   _endDate: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');
    print('   Duração real: ${_endDate.difference(_startDate).inMinutes} minutos');
    
    if (_selectedDeviceId != null) {
      print('📡 [DEBUG] Dispositivo selecionado, carregando histórico...');
      _loadHistory();
    } else {
      print('⚠️ [DEBUG] Período definido, mas nenhum dispositivo selecionado. O histórico será carregado quando um dispositivo for selecionado.');
    }
  }

  void _setToday() {
    print('📅 [DEBUG] _setToday');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    // Usar a hora atual como fim, já que o dia ainda não terminou
    final endOfNow = now;
    
    setState(() {
      _startDate = startOfDay;
      _endDate = endOfNow;
    });
    
    print('🕐 [DEBUG] Período "Hoje" definido:');
    print('   Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
    print('   Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');
    print('   Duração: ${_endDate.difference(_startDate).inHours} horas e ${_endDate.difference(_startDate).inMinutes.remainder(60)} minutos');
    
    if (_selectedDeviceId != null) {
      print('📡 [DEBUG] Dispositivo selecionado, carregando histórico...');
      _loadHistory();
    } else {
      print('⚠️ [DEBUG] Período definido, mas nenhum dispositivo selecionado. O histórico será carregado quando um dispositivo for selecionado.');
    }
  }
  
  void _setLastWeek() {
    print('📅 [DEBUG] Última semana');
    _setPeriod(Duration(days: 7));
  }
  
  void _setLast15Days() {
    print('📅 [DEBUG] Últimos 15 dias');
    _setPeriod(Duration(days: 15));
  }
  
  void _setLastMonth() {
    print('📅 [DEBUG] Último mês');
    _setPeriod(Duration(days: 30));
  }
  
  void _setYesterday() {
    print('📅 [DEBUG] Ontem');
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
    final endOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    
    setState(() {
      _startDate = startOfYesterday;
      _endDate = endOfYesterday;
    });
    
    print('🕐 [DEBUG] Período "Ontem" definido:');
    print('   Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
    print('   Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');
    
    if (_selectedDeviceId != null) {
      print('📡 [DEBUG] Dispositivo selecionado, carregando histórico...');
      _loadHistory();
    } else {
      print('⚠️ [DEBUG] Período definido, mas nenhum dispositivo selecionado. O histórico será carregado quando um dispositivo for selecionado.');
    }
  }

  Future<void> _selectDevice() async {
    try {
      final url = Uri.parse('${UserRepository.getServerURL()}/api/get_devices');
      
      final body = jsonEncode({});
      
      final headers = {
        'Authorization': 'Bearer ${StaticVarMethod.user_api_hash ?? ''}',
        'Accept': 'application/json',
          'Content-Type': 'application/json',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            'A requisição demorou mais de 90 segundos. Tente um período menor ou verifique sua conexão.',
            Duration(seconds: 90),
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && (data['status'] == 0 || data['status'] == false)) {
          _showError(data['message'] ?? (getTranslated(context, 'errorFetchingDevices') ?? 'Erro ao buscar dispositivos'));
          return;
        }

        List<Map<String, dynamic>> devices = [];
        
        if (data is List) {
          for (var group in data) {
            if (group is Map && group['items'] != null && group['items'] is List) {
              final groupItems = group['items'] as List;
              for (var item in groupItems) {
                if (item is Map<String, dynamic>) {
                  devices.add(item);
                } else if (item is Map) {
                  devices.add(Map<String, dynamic>.from(item));
                }
              }
            }
          }
        } else if (data is Map && data['items'] != null && data['items'] is List) {
          for (var item in data['items']) {
            if (item is Map<String, dynamic>) {
              devices.add(item);
            } else if (item is Map) {
              devices.add(Map<String, dynamic>.from(item));
            }
          }
        }

        if (devices.isEmpty) {
          _showError(getTranslated(context, 'noDevicesAvailable') ?? 'Nenhum dispositivo disponível');
          return;
        }

        final colorProvider = Provider.of<ColorProvider>(context, listen: false);
        
        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.devices, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getTranslated(context, 'selectDevice') ?? 'Selecionar Dispositivo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Lista de dispositivos
                Expanded(
              child: ListView.builder(
                    padding: EdgeInsets.all(8),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                      final deviceId = device['id'];
                      final deviceIdStr = deviceId?.toString() ?? '';
                      final deviceName = device['name'] ?? device['display'] ?? 'Dispositivo $deviceIdStr';
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                          title: Text(
                            deviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: device['plate'] != null 
                              ? Text('${getTranslated(context, 'plate') ?? 'Placa'}: ${device['plate']}')
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: colorProvider.primaryColor,
                            size: 18,
                          ),
                    onTap: () => Navigator.pop(context, device),
                        ),
                  );
                },
              ),
                ),
              ],
            ),
          ),
        );

        if (selected != null) {
          final deviceId = selected['id'];
          int? deviceIdInt;
          
          if (deviceId is int) {
            deviceIdInt = deviceId;
          } else if (deviceId is String) {
            deviceIdInt = int.tryParse(deviceId);
          } else if (deviceId != null) {
            deviceIdInt = int.tryParse(deviceId.toString());
          }
          
          if (deviceIdInt != null) {
          setState(() {
              _selectedDeviceId = deviceIdInt;
          });
          _loadHistory();
          } else {
            _showError(getTranslated(context, 'invalidDeviceId') ?? 'ID do dispositivo inválido');
          }
        }
      }
    } catch (e) {
      _showError('${getTranslated(context, 'errorFetchingDevices') ?? 'Erro ao buscar dispositivos'}: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openInGoogleMaps() {
    final validPoints = _points.where((p) => p.hasLocation).toList();
    if (validPoints.isEmpty) {
      _showError('Nenhum ponto com localização válida');
      return;
    }

    final firstPoint = validPoints.first;
    final lastPoint = validPoints.last;
    
    final url = 'https://www.google.com/maps/dir/${firstPoint.latitude},${firstPoint.longitude}/${lastPoint.latitude},${lastPoint.longitude}';
    
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showRouteModal({List<HistoryPoint>? points, DateTime? startDate, DateTime? endDate, String? deviceName}) {
    final validPoints = (points ?? _points).where((p) => p.hasLocation).toList();
    if (validPoints.isEmpty) {
      _showError('Nenhum ponto com localização válida');
      return;
    }

    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteModal(
        points: validPoints,
        colorProvider: colorProvider,
        startDate: startDate ?? _startDate,
        endDate: endDate ?? _endDate,
        deviceName: deviceName ?? widget.deviceName ?? (getTranslated(context, 'device') ?? 'Dispositivo'),
      ),
    );
  }


  Future<void> _saveHistory(List<HistoryPoint> points) async {
    if (_selectedDeviceId == null || points.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = SavedRouteHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: _selectedDeviceId!,
        deviceName: widget.deviceName ?? (getTranslated(context, 'device') ?? 'Dispositivo'),
        startDate: _startDate,
        endDate: _endDate,
        points: points,
        createdAt: DateTime.now(),
      );
      
      final historiesJson = prefs.getStringList('route_histories') ?? [];
      historiesJson.insert(0, jsonEncode(history.toJson()));
      
      // Limitar a 50 históricos salvos
      if (historiesJson.length > 50) {
        historiesJson.removeRange(50, historiesJson.length);
      }
      
      await prefs.setStringList('route_histories', historiesJson);
    } catch (e) {
      print('Erro ao salvar histórico: $e');
    }
  }

  Future<void> _loadSavedHistories() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final historiesJson = prefs.getStringList('route_histories') ?? [];
      
      final histories = historiesJson.map((json) {
        try {
          return SavedRouteHistory.fromJson(jsonDecode(json));
        } catch (e) {
          print('Erro ao parsear histórico: $e');
          return null;
        }
      }).whereType<SavedRouteHistory>().toList();
      
      setState(() {
        _savedHistories = histories;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Erro ao carregar históricos: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: FloatingMenuDrawer(),
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: colorProvider.secondaryColor, // Cor secundária no fundo do cabeçalho
            flexibleSpace: SafeArea(
              child: Column(
                children: [
                  // Cabeçalho principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Ícone da página
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.route,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 10),
                        // Título
                        Expanded(
                          child: Text(
                            widget.deviceName ?? TranslationHelper.translateSync(context, 'Histórico de Rotas', 'Route History'),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Ícone para alternar entre abas
                        IconButton(
                          icon: Icon(
                            _tabController.index == 0 ? Icons.history : Icons.route,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _tabController.animateTo(_tabController.index == 0 ? 1 : 0);
                            });
                          },
                          tooltip: _tabController.index == 0
                              ? TranslationHelper.translateSync(context, 'Histórico de Gerações', 'Generation History')
                              : TranslationHelper.translateSync(context, 'Gerar Histórico', 'Generate History'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Aba 1: Gerar Histórico
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFiltersSection(colorProvider),
                        
                        if (_selectedDeviceId != null && _points.isNotEmpty) ...[
                          _buildSummaryDescription(colorProvider),
                          _buildViewButtons(colorProvider),
                        ],
                        
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: _selectedDeviceId == null
                              ? _buildEmptyState(colorProvider, getTranslated(context, 'selectAnyDevice') ?? 'Selecione um dispositivo', Icons.devices, _selectDevice)
                              : _error != null
                                  ? _buildErrorState(colorProvider)
                                  : _points.isEmpty && !_isLoading
                                      ? _buildEmptyState(colorProvider, getTranslated(context, 'noHistoryFound') ?? 'Nenhum histórico encontrado', Icons.history, null)
                                      : _buildLoadingState(colorProvider),
                        ),
                      ],
                    ),
                  ),
                  // Aba 2: Histórico de Gerações
                  _buildHistoryTab(colorProvider),
                ],
              );
            },
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildFiltersSection(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
            ),
            child: Column(
              children: [
          _buildDeviceSelector(colorProvider),
          
          SizedBox(height: 12),
          _buildPeriodSelector(colorProvider),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(ColorProvider colorProvider) {
    return InkWell(
                    onTap: _selectDevice,
                    child: Container(
        padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorProvider.primaryColor.withOpacity(0.1),
              colorProvider.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorProvider.primaryColor.withOpacity(0.3),
            width: 2,
          ),
                      ),
                      child: Row(
                        children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.devices, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
                          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDeviceId == null 
                        ? (getTranslated(context, 'selectDevice') ?? 'Selecionar Dispositivo')
                        : (getTranslated(context, 'deviceSelected') ?? 'Dispositivo Selecionado'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedDeviceId == null
                        ? (getTranslated(context, 'tapToChooseVehicle') ?? 'Toque para escolher um veículo')
                        : (getTranslated(context, 'tapToChange') ?? 'Toque para alterar'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                        ],
                      ),
                    ),
            Icon(Icons.arrow_forward_ios, color: colorProvider.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ColorProvider colorProvider) {
    return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectPeriod,
                          child: Container(
              padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today, color: colorProvider.primaryColor, size: 20),
                  ),
                  SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getTranslated(context, 'period') ?? 'Período',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                                      ),
                        ),
                        SizedBox(height: 2),
                                      Text(
                                        '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                                      ),
                                    ],
                                  ),
                                ),
                  Icon(Icons.edit, color: Colors.grey[600], size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
      ],
    );
  }

  Widget _buildQuickPeriodButtons(ColorProvider colorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, 'quickPeriods') ?? 'Períodos Rápidos',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickPeriodButton(colorProvider, getTranslated(context, 'today') ?? 'Hoje', _setToday, Icons.today),
            _buildQuickPeriodButton(colorProvider, getTranslated(context, 'yesterday') ?? 'Ontem', _setYesterday, Icons.history),
            _buildQuickPeriodButton(colorProvider, getTranslated(context, 'week') ?? 'Semana', _setLastWeek, Icons.date_range),
            _buildQuickPeriodButton(colorProvider, getTranslated(context, '15days') ?? '15 dias', _setLast15Days, Icons.calendar_view_week),
            _buildQuickPeriodButton(colorProvider, getTranslated(context, 'month') ?? 'Mês', _setLastMonth, Icons.calendar_month),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPeriodButton(
    ColorProvider colorProvider,
    String label,
    VoidCallback onTap,
    IconData icon, {
    bool isCustom = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔘 [DEBUG] Botão clicado: $label');
          onTap();
          // Se não houver dispositivo, apenas define o período
          // O histórico será carregado automaticamente quando um dispositivo for selecionado
          if (_selectedDeviceId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(getTranslated(context, 'periodSetSelectDevice') ?? 'Período definido. Selecione um dispositivo para carregar o histórico.'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isCustom
                ? colorProvider.primaryColor.withOpacity(0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCustom
                  ? colorProvider.primaryColor.withOpacity(0.5)
                  : Colors.grey[300]!,
              width: isCustom ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isCustom
                    ? colorProvider.primaryColor
                    : Colors.grey[700],
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCustom ? FontWeight.bold : FontWeight.w500,
                  color: isCustom
                      ? colorProvider.primaryColor
                      : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewButtons(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showRouteModal,
              icon: Icon(Icons.route, color: Colors.white),
              label: Text(getTranslated(context, 'viewRoute') ?? 'Visualizar Rota'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openInGoogleMaps,
              icon: Icon(Icons.map, color: colorProvider.primaryColor),
              label: Text(getTranslated(context, 'viewOnGoogle') ?? 'Visualizar no Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorProvider.primaryColor,
                side: BorderSide(color: colorProvider.primaryColor, width: 2),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorProvider colorProvider) {
    if (_isLoading) {
      return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
            CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
              getTranslated(context, 'loadingHistory') ?? 'Carregando histórico...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildSummaryDescription(ColorProvider colorProvider) {
    final validPoints = _points.where((p) => p.hasLocation).toList();
    
    // Sempre mostrar informações do período, mesmo sem pontos
    final periodDuration = _endDate.difference(_startDate);
    String periodDurationText = '';
    if (periodDuration.inDays > 0) {
      periodDurationText = '${periodDuration.inDays} dias';
    } else if (periodDuration.inHours > 0) {
      periodDurationText = '${periodDuration.inHours} horas';
    } else if (periodDuration.inMinutes > 0) {
      periodDurationText = '${periodDuration.inMinutes} minutos';
    } else {
      periodDurationText = '${periodDuration.inSeconds} segundos';
    }
    
    if (validPoints.isEmpty) {
      // Mostrar informações do período mesmo sem pontos
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorProvider.primaryColor.withOpacity(0.1),
              colorProvider.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorProvider.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getTranslated(context, 'selectedPeriod') ?? 'Período Selecionado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '${getTranslated(context, 'searchedPeriod') ?? 'Período buscado'}: ${DateFormat('dd/MM/yyyy HH:mm').format(_startDate)} ${getTranslated(context, 'until') ?? 'até'} ${DateFormat('dd/MM/yyyy HH:mm').format(_endDate)} (${getTranslated(context, 'duration') ?? 'duração'}: $periodDurationText). '
              '${getTranslated(context, 'noHistoryFoundForPeriod') ?? 'Nenhum histórico encontrado para este período. Tente selecionar um período diferente ou verifique se o veículo estava em movimento.'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Calcular estatísticas
    final firstPoint = validPoints.first;
    final lastPoint = validPoints.last;
    final totalDistance = _calculateTotalDistance(validPoints);
    
    // Calcular velocidade média
    double totalSpeed = 0;
    int speedCount = 0;
    for (var point in validPoints) {
      final speed = double.tryParse(point.speed) ?? 0;
      if (speed > 0) {
        totalSpeed += speed;
        speedCount++;
      }
    }
    final avgSpeed = speedCount > 0 ? totalSpeed / speedCount : 0.0;
    
    // Calcular velocidade máxima
    double maxSpeed = 0;
    for (var point in validPoints) {
      final speed = double.tryParse(point.speed) ?? 0;
      if (speed > maxSpeed) {
        maxSpeed = speed;
      }
    }

    // Calcular duração do trajeto
    final startTime = DateTime.tryParse(firstPoint.time) ?? 
        (firstPoint.serverTime.isNotEmpty ? DateTime.tryParse(firstPoint.serverTime) : null);
    final endTime = DateTime.tryParse(lastPoint.time) ?? 
        (lastPoint.serverTime.isNotEmpty ? DateTime.tryParse(lastPoint.serverTime) : null);
    
    String durationText = 'N/A';
    if (startTime != null && endTime != null) {
      final duration = endTime.difference(startTime);
      if (duration.inHours > 0) {
        durationText = '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
      } else if (duration.inMinutes > 0) {
        durationText = '${duration.inMinutes}min';
      } else {
        durationText = '${duration.inSeconds}s';
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorProvider.primaryColor.withOpacity(0.1),
            colorProvider.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorProvider.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: colorProvider.primaryColor,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  getTranslated(context, 'periodSummary') ?? 'Resumo do Período',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '${getTranslated(context, 'duringSelectedPeriod') ?? 'Durante o período selecionado, o veículo registrou'} ${validPoints.length} ${getTranslated(context, 'locationPoints') ?? 'pontos de localização'}. '
            '${getTranslated(context, 'routeStartedAt') ?? 'O trajeto teve início em'} ${DateFormat('dd/MM/yyyy HH:mm').format(startTime ?? DateTime.now())} '
            '${getTranslated(context, 'andEndedAt') ?? 'e término em'} ${DateFormat('dd/MM/yyyy HH:mm').format(endTime ?? DateTime.now())}, '
            '${getTranslated(context, 'withTotalDuration') ?? 'com duração total de'} $durationText. '
            '${getTranslated(context, 'distanceTraveled') ?? 'A distância percorrida foi de'} ${totalDistance.toStringAsFixed(2)} km, '
            '${getTranslated(context, 'withAverageSpeed') ?? 'com velocidade média de'} ${avgSpeed.toStringAsFixed(1)} km/h '
            '${maxSpeed > 0 ? '${getTranslated(context, 'andMaxSpeed') ?? 'e velocidade máxima de'} ${maxSpeed.toStringAsFixed(1)} km/h' : ''}.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalDistance(List<HistoryPoint> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final lat1 = points[i].latitude ?? 0;
      final lon1 = points[i].longitude ?? 0;
      final lat2 = points[i + 1].latitude ?? 0;
      final lon2 = points[i + 1].longitude ?? 0;
      
      if (lat1 != 0 && lon1 != 0 && lat2 != 0 && lon2 != 0) {
        totalDistance += _calculateDistance(lat1, lon1, lat2, lon2);
      }
    }
    return totalDistance;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  Widget _buildEmptyState(ColorProvider colorProvider, String message, IconData icon, VoidCallback? onTap) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: colorProvider.primaryColor.withOpacity(0.6)),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (onTap != null) ...[
              SizedBox(height: 24),
                        ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.add),
                          label: Text(getTranslated(context, 'selectDevice') ?? 'Selecionar Dispositivo'),
                          style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            backgroundColor: colorProvider.primaryColor,
                            foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorProvider colorProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            ),
            SizedBox(height: 24),
                            Text(
                              getTranslated(context, 'errorLoading') ?? 'Erro ao carregar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                            ),
            ),
            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                              ),
                            ),
            ),
            SizedBox(height: 24),
                            ElevatedButton.icon(
              onPressed: _loadHistory,
                              icon: Icon(Icons.refresh),
                              label: Text(getTranslated(context, 'tryAgain') ?? 'Tentar Novamente'),
                              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: colorProvider.primaryColor,
                                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                              ),
                            ),
                          ],
                        ),
      ),
    );
  }

  Widget _buildHistoryTab(ColorProvider colorProvider) {
    final filteredHistories = _historyFilter != null && _historyFilter!.isNotEmpty
        ? _savedHistories.where((h) => 
            h.deviceName.toLowerCase().contains(_historyFilter!.toLowerCase()) ||
            h.id.contains(_historyFilter!)
          ).toList()
        : _savedHistories;

    return Column(
      children: [
        // Filtro
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(context, 'Filtrar por veículo ou ID...', 'Filter by vehicle or ID...'),
              prefixIcon: Icon(Icons.search, color: colorProvider.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorProvider.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorProvider.primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _historyFilter = value;
              });
            },
          ),
        ),
        
        // Lista de históricos
        Expanded(
          child: _isLoadingHistory
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                  ),
                )
              : filteredHistories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            TranslationHelper.translateSync(context, 'Nenhum histórico salvo', 'No saved history'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredHistories.length,
                      itemBuilder: (context, index) {
                        final history = filteredHistories[index];
                        return _buildHistoryCard(history, colorProvider);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(SavedRouteHistory history, ColorProvider colorProvider) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showRouteModal(
            points: history.points,
            startDate: history.startDate,
            endDate: history.endDate,
            deviceName: history.deviceName,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route,
                      color: colorProvider.primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.deviceName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(history.startDate)} - ${DateFormat('dd/MM/yyyy').format(history.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colorProvider.primaryColor,
                    size: 18,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    TranslationHelper.translateSync(context, 'Gerado em', 'Generated at') + ': ${DateFormat('dd/MM/yyyy HH:mm').format(history.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${history.points.length} ${TranslationHelper.translateSync(context, 'pontos', 'points')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorProvider.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// MODAL DE ROTA
// ============================================

class _RouteModal extends StatefulWidget {
  final List<HistoryPoint> points;
  final ColorProvider colorProvider;
  final DateTime startDate;
  final DateTime endDate;
  final String deviceName;

  const _RouteModal({
    required this.points,
    required this.colorProvider,
    required this.startDate,
    required this.endDate,
    required this.deviceName,
  });

  @override
  State<_RouteModal> createState() => _RouteModalState();
}

class _RouteModalState extends State<_RouteModal> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _isGeneratingPdf = false;
  
  // Controle de animação do carrinho
  Timer? _animationTimer;
  int _currentPointIndex = 0;
  bool _isPlaying = false;
  double _animationSpeed = 1.0; // Multiplicador de velocidade (0.5x a 5x)
  List<HistoryPoint> _validPoints = [];
  
  // Controle de eventos
  int? _selectedEventIndex;
  final ScrollController _eventsScrollController = ScrollController();
  
  // Eventos reais da API
  List<EventsData> _apiEvents = [];
  
  // Tipo de mapa
  MapType _currentMapType = MapType.normal;
  
  @override
  void initState() {
    super.initState();
    _validPoints = widget.points
        .where((p) => p.hasLocation && p.latitude != null && p.longitude != null)
        .toList();
    _loadApiEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }
  
  @override
  void dispose() {
    _animationTimer?.cancel();
    _eventsScrollController.dispose();
    super.dispose();
  }
  
  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case MapType.normal:
          _currentMapType = MapType.satellite;
          break;
        case MapType.satellite:
          _currentMapType = MapType.hybrid;
          break;
        case MapType.hybrid:
          _currentMapType = MapType.terrain;
          break;
        case MapType.terrain:
          _currentMapType = MapType.normal;
          break;
        default:
          _currentMapType = MapType.normal;
      }
    });
  }
  
  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case MapType.normal:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite;
      case MapType.hybrid:
        return Icons.layers;
      case MapType.terrain:
        return Icons.terrain;
      default:
        return Icons.map;
    }
  }
  
  Future<void> _loadApiEvents() async {
    try {
      final gpsapi = gpsapis();
      final eventsResult = await gpsapi.getEventsList_new(StaticVarMethod.user_api_hash);
      
      // Filtrar eventos pelo período do histórico
      final filteredEvents = eventsResult.where((event) {
        if (event.time == null || event.time!.isEmpty) return false;
        try {
          final eventDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(event.time!);
          return eventDate.isAfter(widget.startDate.subtract(Duration(seconds: 1))) &&
                 eventDate.isBefore(widget.endDate.add(Duration(seconds: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
      
      setState(() {
        _apiEvents = filteredEvents;
      });
    } catch (e) {
      print('Erro ao carregar eventos da API: $e');
    }
  }
  
  void _startAnimation() {
    if (_validPoints.isEmpty || _isPlaying) return;
    
    setState(() {
      _isPlaying = true;
    });
    
    _animationTimer = Timer.periodic(
      Duration(milliseconds: (1000 / _animationSpeed).round()),
      (timer) {
        if (_currentPointIndex < _validPoints.length - 1) {
          setState(() {
            _currentPointIndex++;
            _updateCameraPosition();
          });
        } else {
          _pauseAnimation();
        }
      },
    );
  }
  
  void _pauseAnimation() {
    _animationTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }
  
  void _resetAnimation() {
    _animationTimer?.cancel();
    setState(() {
      _currentPointIndex = 0;
      _isPlaying = false;
    });
    _updateCameraPosition();
  }
  
  void _updateCameraPosition() {
    if (_mapController == null || _currentPointIndex >= _validPoints.length) return;
    
    final currentPoint = _validPoints[_currentPointIndex];
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(currentPoint.latitude!, currentPoint.longitude!),
      ),
    );
  }
  
  void _setSpeed(double speed) {
    setState(() {
      _animationSpeed = speed;
    });
    
    // Se estiver rodando, reiniciar com nova velocidade
    if (_isPlaying) {
      _pauseAnimation();
      _startAnimation();
    }
  }

  void _fitBounds() {
    if (_mapController == null || widget.points.isEmpty) return;

    final validPoints = widget.points.where((p) => p.hasLocation && p.latitude != null && p.longitude != null).toList();
    if (validPoints.length < 2) return;

    double minLat = validPoints.first.latitude!;
    double maxLat = validPoints.first.latitude!;
    double minLng = validPoints.first.longitude!;
    double maxLng = validPoints.first.longitude!;

    for (var point in validPoints) {
      final lat = point.latitude!;
      final lng = point.longitude!;
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  List<LatLng> _getPolylinePoints() {
    return widget.points
        .where((p) => p.hasLocation && p.latitude != null && p.longitude != null)
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
  }

  Set<Marker> _getMarkers() {
    if (_validPoints.isEmpty) return {};

    final markers = <Marker>{};
    final events = _detectEvents();

    // Marcador de início
    if (_validPoints.isNotEmpty) {
      final first = _validPoints.first;
      markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: LatLng(first.latitude!, first.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: getTranslated(context, 'start') ?? 'Início',
            snippet: first.time,
          ),
        ),
      );
    }

    // Marcador de fim
    if (_validPoints.length > 1) {
      final last = _validPoints.last;
      markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: LatLng(last.latitude!, last.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: getTranslated(context, 'end') ?? 'Fim',
            snippet: last.time,
          ),
        ),
      );
    }

    // Marcadores de eventos detectados do histórico
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final point = event['point'] as HistoryPoint;
      
      if (point.latitude != null && point.longitude != null) {
        // Formatar data e hora
        String dateTimeStr = point.time;
        try {
          final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(point.time);
          dateTimeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
        } catch (_) {}
        
        markers.add(
          Marker(
            markerId: MarkerId('detected_event_$i'),
            position: LatLng(point.latitude!, point.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHueForEventType(event['type'] as String),
            ),
            infoWindow: InfoWindow(
              title: event['description'] as String,
              snippet: dateTimeStr,
            ),
            onTap: () {
              _onEventMarkerTapped(i);
            },
          ),
        );
      }
    }
    
    // Marcadores de eventos reais da API
    for (int i = 0; i < _apiEvents.length; i++) {
      final event = _apiEvents[i];
      
      if (event.latitude != null && event.longitude != null) {
        final lat = event.latitude is double 
            ? event.latitude as double 
            : double.tryParse(event.latitude.toString()) ?? 0.0;
        final lng = event.longitude is double 
            ? event.longitude as double 
            : double.tryParse(event.longitude.toString()) ?? 0.0;
        
        if (lat != 0.0 && lng != 0.0) {
          final markerInfo = _getMarkerInfoForApiEvent(event);
          markers.add(
            Marker(
              markerId: MarkerId('api_event_${event.id}'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerInfo['hue'] as double),
              infoWindow: InfoWindow(
                title: markerInfo['title'] as String,
                snippet: markerInfo['snippet'] as String,
              ),
            ),
          );
        }
      }
    }

    // Marcador do carrinho (veículo animado)
    if (_validPoints.isNotEmpty && _currentPointIndex < _validPoints.length) {
      final currentPoint = _validPoints[_currentPointIndex];
      final speed = double.tryParse(currentPoint.speed) ?? 0;
      
      markers.add(
        Marker(
          markerId: MarkerId('vehicle'),
          position: LatLng(currentPoint.latitude!, currentPoint.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: getTranslated(context, 'vehicle') ?? 'Veículo',
            snippet: '${currentPoint.time}\n${getTranslated(context, 'speed') ?? 'Velocidade'}: ${speed.toStringAsFixed(1)} km/h',
          ),
        ),
      );
    }

    return markers;
  }
  
  double _getMarkerHueForEventType(String type) {
    switch (type) {
      case 'status_change':
        return BitmapDescriptor.hueBlue;
      case 'high_speed':
        return BitmapDescriptor.hueOrange;
      case 'sensor_change':
        return BitmapDescriptor.hueViolet;
      case 'stop':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }
  
  Map<String, dynamic> _getMarkerInfoForApiEvent(EventsData event) {
    String title = event.name ?? event.type ?? (getTranslated(context, 'event') ?? 'Evento');
    String snippet = '';
    
    // Formatar data e hora
    String dateTimeStr = getTranslated(context, 'dateTimeNotAvailable') ?? 'Data/Hora não disponível';
    if (event.time != null && event.time!.isNotEmpty) {
      try {
        final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(event.time!);
        dateTimeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
      } catch (e) {
        dateTimeStr = event.time!;
      }
    }
    
    // Formatar endereço
    String addressStr = getTranslated(context, 'addressNotAvailable') ?? 'Endereço não disponível';
    if (event.address != null && event.address.toString().isNotEmpty && event.address.toString() != 'null') {
      addressStr = event.address.toString();
    }
    
    // Montar snippet com informações detalhadas
    snippet = '$dateTimeStr\n$addressStr';
    
    if (event.message != null && event.message!.isNotEmpty) {
      snippet += '\n${event.message}';
    }
    
    if (event.deviceName != null && event.deviceName!.isNotEmpty) {
      snippet += '\n${getTranslated(context, 'vehicle') ?? 'Veículo'}: ${event.deviceName}';
    }
    
    // Determinar cor do marcador baseado no tipo de evento
    double hue = BitmapDescriptor.hueAzure; // Padrão
    
    final type = (event.type ?? '').toLowerCase();
    final name = (event.name ?? '').toLowerCase();
    
    if (type.contains('ignition') || name.contains('ignição') || name.contains('ignicao')) {
      if (name.contains('on') || name.contains('ligada') || name.contains('ligado')) {
        hue = BitmapDescriptor.hueGreen; // Verde para ignição ligada
        title = getTranslated(context, 'ignitionOn') ?? 'Ignição Ligada';
      } else if (name.contains('off') || name.contains('desligada') || name.contains('desligado')) {
        hue = BitmapDescriptor.hueRed; // Vermelho para ignição desligada
        title = getTranslated(context, 'ignitionOff') ?? 'Ignição Desligada';
      }
    } else if (type.contains('overspeed') || name.contains('velocidade') || name.contains('excesso')) {
      hue = BitmapDescriptor.hueOrange; // Laranja para excesso de velocidade
    } else if (type.contains('geofence') || name.contains('cerca')) {
      hue = BitmapDescriptor.hueViolet; // Roxo para geofence
    } else if (type.contains('alert') || name.contains('alerta')) {
      hue = BitmapDescriptor.hueRed; // Vermelho para alertas
    } else if (type.contains('stop') || name.contains('parada')) {
      hue = BitmapDescriptor.hueYellow; // Amarelo para paradas
    } else if (type.contains('sensor') || name.contains('sensor')) {
      hue = BitmapDescriptor.hueBlue; // Azul para sensores
    }
    
    return {
      'title': title,
      'snippet': snippet,
      'hue': hue,
    };
  }
  
  void _onEventMarkerTapped(int eventIndex) {
    setState(() {
      _selectedEventIndex = eventIndex;
    });
    
    // Fazer scroll para o evento selecionado
    if (_eventsScrollController.hasClients) {
      final itemWidth = 200.0 + 8.0; // largura do card + margin
      final targetOffset = eventIndex * itemWidth;
      
      _eventsScrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _shareOnWhatsApp() async {
    try {
      final validPoints = widget.points.where((p) => p.hasLocation).toList();
      if (validPoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum ponto com localização válida')),
        );
        return;
      }

      final firstPoint = validPoints.first;
      final lastPoint = validPoints.last;
      final period = '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}';
      
      final message = '''
📍 *${getTranslated(context, 'vehicleRoute') ?? 'Rota do Veículo'}*

🚗 *${getTranslated(context, 'device') ?? 'Dispositivo'}:* ${widget.deviceName}
📅 *${getTranslated(context, 'period') ?? 'Período'}:* $period
📍 *${getTranslated(context, 'points') ?? 'Pontos'}:* ${validPoints.length}

🗺️ *${getTranslated(context, 'initialLocation') ?? 'Localização Inicial'}:*
${firstPoint.latitude}, ${firstPoint.longitude}

🗺️ *${getTranslated(context, 'finalLocation') ?? 'Localização Final'}:*
${lastPoint.latitude}, ${lastPoint.longitude}

📊 *${getTranslated(context, 'totalDistance') ?? 'Distância Total'}:* ${_calculateTotalDistance(validPoints).toStringAsFixed(2)} km
      ''';

      final link = WhatsAppUnilink(
        phoneNumber: '',
        text: message,
      );

      await launchUrl(link.asUri(), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${getTranslated(context, 'errorSharing') ?? 'Erro ao compartilhar'}: $e')),
      );
    }
  }

  double _calculateTotalDistance(List<HistoryPoint> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(
        points[i].latitude ?? 0,
        points[i].longitude ?? 0,
        points[i + 1].latitude ?? 0,
        points[i + 1].longitude ?? 0,
      );
    }
    return totalDistance;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180);

  Future<void> _downloadPdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final validPoints = widget.points.where((p) => p.hasLocation).toList();
      
      if (validPoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum ponto com localização válida')),
        );
        return;
      }

      final period = '${DateFormat('dd/MM/yyyy HH:mm').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy HH:mm').format(widget.endDate)}';
      final totalDistance = _calculateTotalDistance(validPoints);
      
      // Detectar paradas e movimentos
      final stops = _detectStops(validPoints);
      final movements = _detectMovements(validPoints);
      
      // Calcular estatísticas
      final stats = _calculateStatistics(validPoints);

      final buffer = StringBuffer();
      
      // Cabeçalho
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('                        ${getTranslated(context, 'detailedRouteReport') ?? 'RELATÓRIO DETALHADO DE ROTA'}');
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('${getTranslated(context, 'device') ?? 'Dispositivo'}: ${widget.deviceName}');
      buffer.writeln('${getTranslated(context, 'period') ?? 'Período'}: $period');
      buffer.writeln('${getTranslated(context, 'generationDate') ?? 'Data de Geração'}: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('');
      
      // Estatísticas Gerais
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('                           ${getTranslated(context, 'generalStatistics') ?? 'ESTATÍSTICAS GERAIS'}');
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('${getTranslated(context, 'totalRegisteredPoints') ?? 'Total de Pontos Registrados'}: ${validPoints.length}');
      buffer.writeln('${getTranslated(context, 'totalDistanceTraveled') ?? 'Distância Total Percorrida'}: ${totalDistance.toStringAsFixed(2)} km');
      buffer.writeln('${getTranslated(context, 'averageSpeed') ?? 'Velocidade Média'}: ${stats['avgSpeed'].toStringAsFixed(2)} km/h');
      buffer.writeln('${getTranslated(context, 'maximumSpeed') ?? 'Velocidade Máxima'}: ${stats['maxSpeed'].toStringAsFixed(2)} km/h');
      buffer.writeln('${getTranslated(context, 'minimumSpeed') ?? 'Velocidade Mínima'}: ${stats['minSpeed'].toStringAsFixed(2)} km/h');
      buffer.writeln('${getTranslated(context, 'averageAltitude') ?? 'Altitude Média'}: ${stats['avgAltitude'].toStringAsFixed(2)} m');
      buffer.writeln('${getTranslated(context, 'maximumAltitude') ?? 'Altitude Máxima'}: ${stats['maxAltitude'].toStringAsFixed(2)} m');
      buffer.writeln('${getTranslated(context, 'minimumAltitude') ?? 'Altitude Mínima'}: ${stats['minAltitude'].toStringAsFixed(2)} m');
      buffer.writeln('${getTranslated(context, 'totalStops') ?? 'Total de Paradas'}: ${stops.length}');
      buffer.writeln('${getTranslated(context, 'totalStopTime') ?? 'Tempo Total em Paradas'}: ${stats['totalStopTime']}');
      buffer.writeln('${getTranslated(context, 'totalMoveTime') ?? 'Tempo Total em Movimento'}: ${stats['totalMoveTime']}');
      buffer.writeln('');
      
      // Paradas Detalhadas
      if (stops.isNotEmpty) {
        buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
        buffer.writeln('                           ${getTranslated(context, 'detailedStops') ?? 'PARADAS DETALHADAS'}');
        buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
        buffer.writeln('');
        
        for (int i = 0; i < stops.length; i++) {
          final stop = stops[i];
          buffer.writeln('${getTranslated(context, 'stop') ?? 'PARADA'} #${i + 1}');
          buffer.writeln('───────────────────────────────────────────────────────────────────────────────');
          buffer.writeln('${getTranslated(context, 'start') ?? 'Início'}: ${stop['startTime']}');
          buffer.writeln('${getTranslated(context, 'end') ?? 'Fim'}: ${stop['endTime']}');
          buffer.writeln('${getTranslated(context, 'duration') ?? 'Duração'}: ${stop['duration']}');
          buffer.writeln('${getTranslated(context, 'location') ?? 'Localização'}: ${stop['latitude'].toStringAsFixed(6)}, ${stop['longitude'].toStringAsFixed(6)}');
          buffer.writeln('${getTranslated(context, 'pointsAtStop') ?? 'Pontos na Parada'}: ${stop['pointCount']}');
          buffer.writeln('');
          
          // Detalhes de cada ponto da parada
          buffer.writeln('  Detalhes dos Pontos:');
          for (var point in stop['points'] as List<HistoryPoint>) {
            buffer.writeln('    ──────────────────────────────────────────────────────────────────────');
            buffer.writeln('    Data/Hora: ${point.time}');
            buffer.writeln('    Coordenadas: ${point.latitude?.toStringAsFixed(6)}, ${point.longitude?.toStringAsFixed(6)}');
            buffer.writeln('    Velocidade: ${point.speed} km/h');
            buffer.writeln('    Altitude: ${point.altitude} m');
            if (point.sensors != null && point.sensors!.isNotEmpty) {
              buffer.writeln('    Sensores:');
              point.sensors!.forEach((key, value) {
                buffer.writeln('      - $key: $value');
              });
            }
            if (point.status != null) {
              buffer.writeln('    Status: ${point.status}');
            }
            buffer.writeln('');
          }
          buffer.writeln('');
        }
      }
      
      // Movimentos Detalhados
      if (movements.isNotEmpty) {
        buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
        buffer.writeln('                         ${getTranslated(context, 'detailedMovements') ?? 'MOVIMENTOS DETALHADOS'}');
        buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
        buffer.writeln('');
        
        for (int i = 0; i < movements.length; i++) {
          final movement = movements[i];
          buffer.writeln('${getTranslated(context, 'movement') ?? 'MOVIMENTO'} #${i + 1}');
          buffer.writeln('───────────────────────────────────────────────────────────────────────────────');
          buffer.writeln('${getTranslated(context, 'start') ?? 'Início'}: ${movement['startTime']}');
          buffer.writeln('${getTranslated(context, 'end') ?? 'Fim'}: ${movement['endTime']}');
          buffer.writeln('${getTranslated(context, 'duration') ?? 'Duração'}: ${movement['duration']}');
          buffer.writeln('${getTranslated(context, 'distance') ?? 'Distância'}: ${movement['distance'].toStringAsFixed(2)} km');
          buffer.writeln('${getTranslated(context, 'averageSpeed') ?? 'Velocidade Média'}: ${movement['avgSpeed'].toStringAsFixed(2)} km/h');
          buffer.writeln('${getTranslated(context, 'maximumSpeed') ?? 'Velocidade Máxima'}: ${movement['maxSpeed'].toStringAsFixed(2)} km/h');
          buffer.writeln('${getTranslated(context, 'pointsInMovement') ?? 'Pontos no Movimento'}: ${movement['pointCount']}');
          buffer.writeln('');
          
          // Detalhes de cada ponto do movimento
          buffer.writeln('  Detalhes dos Pontos:');
          for (var point in movement['points'] as List<HistoryPoint>) {
            buffer.writeln('    ──────────────────────────────────────────────────────────────────────');
            buffer.writeln('    Data/Hora: ${point.time}');
            buffer.writeln('    Coordenadas: ${point.latitude?.toStringAsFixed(6)}, ${point.longitude?.toStringAsFixed(6)}');
            buffer.writeln('    Velocidade: ${point.speed} km/h');
            buffer.writeln('    Altitude: ${point.altitude} m');
            if (point.sensors != null && point.sensors!.isNotEmpty) {
              buffer.writeln('    Sensores:');
              point.sensors!.forEach((key, value) {
                buffer.writeln('      - $key: $value');
              });
            }
            if (point.status != null) {
              buffer.writeln('    Status: ${point.status}');
            }
            buffer.writeln('');
          }
          buffer.writeln('');
        }
      }
      
      // Todos os Pontos em Ordem Cronológica
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('                    ${getTranslated(context, 'allPointsChronological') ?? 'TODOS OS PONTOS (ORDEM CRONOLÓGICA)'}');
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('');
      buffer.writeln('Nº | Data/Hora            | Latitude        | Longitude       | Velocidade | Altitude | Distância do Ponto Anterior');
      buffer.writeln('───┼─────────────────────┼─────────────────┼─────────────────┼────────────┼──────────┼────────────────────────────');
      
      double previousLat = 0;
      double previousLng = 0;
      bool isFirst = true;
      
      for (int i = 0; i < validPoints.length; i++) {
        final point = validPoints[i];
        final lat = point.latitude ?? 0;
        final lng = point.longitude ?? 0;
        
        double distanceFromPrevious = 0;
        if (!isFirst) {
          distanceFromPrevious = _calculateDistance(previousLat, previousLng, lat, lng);
        }
        isFirst = false;
        previousLat = lat;
        previousLng = lng;
        
        final pointNum = (i + 1).toString().padLeft(3);
        final time = point.time.padRight(20);
        final latitude = lat.toStringAsFixed(6).padRight(15);
        final longitude = lng.toStringAsFixed(6).padRight(15);
        final speed = point.speed.padRight(10);
        final altitude = point.altitude.padRight(8);
        final distance = distanceFromPrevious > 0 
            ? '${distanceFromPrevious.toStringAsFixed(3)} km'
            : '-';
        
        buffer.writeln('$pointNum | $time | $latitude | $longitude | $speed | $altitude | $distance');
      }
      
      buffer.writeln('');
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');
      buffer.writeln('                              ${getTranslated(context, 'endOfReport') ?? 'FIM DO RELATÓRIO'}');
      buffer.writeln('═══════════════════════════════════════════════════════════════════════════════');

      final output = await getTemporaryDirectory();
      final fileName = 'rota_detalhada_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${output.path}/$fileName');
      await file.writeAsString(buffer.toString());

      if (await file.exists()) {
        // Compartilhar o arquivo usando share_plus
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          text: '${getTranslated(context, 'detailedRouteReport') ?? 'Relatório detalhado de rota'} - ${widget.deviceName}',
          subject: getTranslated(context, 'routeReport') ?? 'Relatório de Rota',
        );
        
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getTranslated(context, 'reportSharedSuccess') ?? 'Relatório compartilhado com sucesso!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${getTranslated(context, 'reportGenerated') ?? 'Relatório gerado'}! ${getTranslated(context, 'fileSavedAt') ?? 'Arquivo salvo em'}: ${file.path}'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${getTranslated(context, 'error') ?? 'Erro'}: ${getTranslated(context, 'fileNotCreated') ?? 'Arquivo não foi criado'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${getTranslated(context, 'errorGeneratingReport') ?? 'Erro ao gerar relatório'}: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }
  
  // Detectar paradas (velocidade < 5 km/h por mais de 2 minutos)
  List<Map<String, dynamic>> _detectStops(List<HistoryPoint> points) {
    final stops = <Map<String, dynamic>>[];
    final stopThreshold = 5.0; // km/h
    final minStopDuration = Duration(minutes: 2);
    
    List<HistoryPoint> currentStopPoints = [];
    DateTime? stopStartTime;
    
    for (var point in points) {
      final speed = double.tryParse(point.speed) ?? 0;
      final pointTime = DateTime.tryParse(point.time) ?? 
          (point.serverTime.isNotEmpty ? DateTime.tryParse(point.serverTime) : null);
      
      if (speed < stopThreshold) {
        if (currentStopPoints.isEmpty) {
          stopStartTime = pointTime ?? DateTime.now();
        }
        currentStopPoints.add(point);
      } else {
        if (currentStopPoints.isNotEmpty && stopStartTime != null) {
          final stopEndTime = currentStopPoints.last.time;
          final stopDuration = pointTime?.difference(stopStartTime) ?? Duration.zero;
          
          if (stopDuration >= minStopDuration) {
            stops.add({
              'startTime': DateFormat('dd/MM/yyyy HH:mm:ss').format(stopStartTime),
              'endTime': stopEndTime,
              'duration': _formatDuration(stopDuration),
              'latitude': currentStopPoints.first.latitude ?? 0,
              'longitude': currentStopPoints.first.longitude ?? 0,
              'pointCount': currentStopPoints.length,
              'points': List<HistoryPoint>.from(currentStopPoints),
            });
          }
          currentStopPoints.clear();
          stopStartTime = null;
        }
      }
    }
    
    // Adicionar última parada se existir
    if (currentStopPoints.isNotEmpty && stopStartTime != null) {
      final stopEndTime = currentStopPoints.last.time;
      final stopDuration = DateTime.tryParse(stopEndTime)?.difference(stopStartTime) ?? Duration.zero;
      
      if (stopDuration >= minStopDuration) {
        stops.add({
          'startTime': DateFormat('dd/MM/yyyy HH:mm:ss').format(stopStartTime),
          'endTime': stopEndTime,
          'duration': _formatDuration(stopDuration),
          'latitude': currentStopPoints.first.latitude ?? 0,
          'longitude': currentStopPoints.first.longitude ?? 0,
          'pointCount': currentStopPoints.length,
          'points': List<HistoryPoint>.from(currentStopPoints),
        });
      }
    }
    
    return stops;
  }
  
  // Detectar movimentos (velocidade >= 5 km/h)
  List<Map<String, dynamic>> _detectMovements(List<HistoryPoint> points) {
    final movements = <Map<String, dynamic>>[];
    final movementThreshold = 5.0; // km/h
    
    List<HistoryPoint> currentMovementPoints = [];
    DateTime? movementStartTime;
    
    for (var point in points) {
      final speed = double.tryParse(point.speed) ?? 0;
      final pointTime = DateTime.tryParse(point.time) ?? 
          (point.serverTime.isNotEmpty ? DateTime.tryParse(point.serverTime) : null);
      
      if (speed >= movementThreshold) {
        if (currentMovementPoints.isEmpty) {
          movementStartTime = pointTime ?? DateTime.now();
        }
        currentMovementPoints.add(point);
      } else {
        if (currentMovementPoints.isNotEmpty && movementStartTime != null) {
          final movementEndTime = currentMovementPoints.last.time;
          final movementDuration = pointTime?.difference(movementStartTime) ?? Duration.zero;
          final distance = _calculateTotalDistance(currentMovementPoints);
          
          double totalSpeed = 0;
          double maxSpeed = 0;
          for (var p in currentMovementPoints) {
            final s = double.tryParse(p.speed) ?? 0;
            totalSpeed += s;
            if (s > maxSpeed) maxSpeed = s;
          }
          final avgSpeed = currentMovementPoints.isNotEmpty 
              ? totalSpeed / currentMovementPoints.length 
              : 0;
          
          movements.add({
            'startTime': DateFormat('dd/MM/yyyy HH:mm:ss').format(movementStartTime),
            'endTime': movementEndTime,
            'duration': _formatDuration(movementDuration),
            'distance': distance,
            'avgSpeed': avgSpeed,
            'maxSpeed': maxSpeed,
            'pointCount': currentMovementPoints.length,
            'points': List<HistoryPoint>.from(currentMovementPoints),
          });
          currentMovementPoints.clear();
          movementStartTime = null;
        }
      }
    }
    
    // Adicionar último movimento se existir
    if (currentMovementPoints.isNotEmpty && movementStartTime != null) {
      final movementEndTime = currentMovementPoints.last.time;
      final movementDuration = DateTime.tryParse(movementEndTime)?.difference(movementStartTime) ?? Duration.zero;
      final distance = _calculateTotalDistance(currentMovementPoints);
      
      double totalSpeed = 0;
      double maxSpeed = 0;
      for (var p in currentMovementPoints) {
        final s = double.tryParse(p.speed) ?? 0;
        totalSpeed += s;
        if (s > maxSpeed) maxSpeed = s;
      }
      final avgSpeed = currentMovementPoints.isNotEmpty 
          ? totalSpeed / currentMovementPoints.length 
          : 0;
      
      movements.add({
        'startTime': DateFormat('dd/MM/yyyy HH:mm:ss').format(movementStartTime),
        'endTime': movementEndTime,
        'duration': _formatDuration(movementDuration),
        'distance': distance,
        'avgSpeed': avgSpeed,
        'maxSpeed': maxSpeed,
        'pointCount': currentMovementPoints.length,
        'points': List<HistoryPoint>.from(currentMovementPoints),
      });
    }
    
    return movements;
  }
  
  // Calcular estatísticas gerais
  Map<String, dynamic> _calculateStatistics(List<HistoryPoint> points) {
    double totalSpeed = 0;
    double maxSpeed = 0;
    double minSpeed = double.infinity;
    double totalAltitude = 0;
    double maxAltitude = 0;
    double minAltitude = double.infinity;
    int speedCount = 0;
    int altitudeCount = 0;
    
    Duration totalStopTime = Duration.zero;
    Duration totalMoveTime = Duration.zero;
    
    final stops = _detectStops(points);
    final movements = _detectMovements(points);
    
    for (var stop in stops) {
      final durationStr = stop['duration'] as String;
      totalStopTime = totalStopTime + _parseDuration(durationStr);
    }
    
    for (var movement in movements) {
      final durationStr = movement['duration'] as String;
      totalMoveTime = totalMoveTime + _parseDuration(durationStr);
    }
    
    for (var point in points) {
      final speed = double.tryParse(point.speed) ?? 0;
      final altitude = double.tryParse(point.altitude) ?? 0;
      
      if (speed > 0) {
        totalSpeed += speed;
        speedCount++;
        if (speed > maxSpeed) maxSpeed = speed;
        if (speed < minSpeed) minSpeed = speed;
      }
      
      if (altitude != 0) {
        totalAltitude += altitude;
        altitudeCount++;
        if (altitude > maxAltitude) maxAltitude = altitude;
        if (altitude < minAltitude) minAltitude = altitude;
      }
    }
    
    return {
      'avgSpeed': speedCount > 0 ? totalSpeed / speedCount : 0,
      'maxSpeed': maxSpeed == double.infinity ? 0 : maxSpeed,
      'minSpeed': minSpeed == double.infinity ? 0 : minSpeed,
      'avgAltitude': altitudeCount > 0 ? totalAltitude / altitudeCount : 0,
      'maxAltitude': maxAltitude == double.infinity ? 0 : maxAltitude,
      'minAltitude': minAltitude == double.infinity ? 0 : minAltitude,
      'totalStopTime': _formatDuration(totalStopTime),
      'totalMoveTime': _formatDuration(totalMoveTime),
    };
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min ${duration.inSeconds.remainder(60)}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  // Detectar eventos do trajeto
  List<Map<String, dynamic>> _detectEvents() {
    final events = <Map<String, dynamic>>[];
    final validPoints = widget.points.where((p) => p.hasLocation).toList();
    
    if (validPoints.isEmpty) return events;
    
    int? previousStatus;
    Map<String, dynamic>? previousSensors;
    
    for (int i = 0; i < validPoints.length; i++) {
      final point = validPoints[i];
      final speed = double.tryParse(point.speed) ?? 0;
      
      // Evento: Mudança de status
      if (point.status != null && point.status != previousStatus) {
        events.add({
          'type': 'status_change',
          'time': point.time,
          'description': '${getTranslated(context, 'statusChange') ?? 'Mudança de status'}: ${point.status}',
          'icon': Icons.info,
          'color': Colors.blue,
          'point': point,
        });
        previousStatus = point.status;
      }
      
      // Evento: Velocidade alta (> 100 km/h)
      if (speed > 100) {
        events.add({
          'type': 'high_speed',
          'time': point.time,
          'description': '${getTranslated(context, 'highSpeed') ?? 'Velocidade alta'}: ${speed.toStringAsFixed(1)} km/h',
          'icon': Icons.speed,
          'color': Colors.orange,
          'point': point,
        });
      }
      
      // Evento: Sensores importantes
      if (point.sensors != null && point.sensors!.isNotEmpty) {
        for (var key in point.sensors!.keys) {
          final value = point.sensors![key];
          final prevValue = previousSensors?[key];
          
          // Detectar mudanças em sensores importantes
          if (prevValue != null && prevValue != value) {
            String sensorName = key;
            if (key.toLowerCase().contains('ignition') || key.toLowerCase().contains('ignicao')) {
              sensorName = getTranslated(context, 'ignition') ?? 'Ignição';
            } else if (key.toLowerCase().contains('door') || key.toLowerCase().contains('porta')) {
              sensorName = getTranslated(context, 'door') ?? 'Porta';
            } else if (key.toLowerCase().contains('alarm') || key.toLowerCase().contains('alarme')) {
              sensorName = getTranslated(context, 'alarm') ?? 'Alarme';
            }
            
            events.add({
              'type': 'sensor_change',
              'time': point.time,
              'description': '$sensorName: $prevValue → $value',
              'icon': Icons.sensors,
              'color': Colors.purple,
              'point': point,
            });
          }
        }
        previousSensors = Map<String, dynamic>.from(point.sensors!);
      }
      
      // Evento: Parada detectada (velocidade = 0 após movimento)
      if (i > 0) {
        final prevSpeed = double.tryParse(validPoints[i - 1].speed) ?? 0;
        if (prevSpeed > 5 && speed == 0) {
          events.add({
            'type': 'stop',
            'time': point.time,
            'description': getTranslated(context, 'stopDetected') ?? 'Parada detectada',
            'icon': Icons.stop_circle,
            'color': Colors.grey,
            'point': point,
          });
        }
      }
    }
    
    return events;
  }
  
  Widget _buildEventsSection() {
    final events = _detectEvents();
    
    if (events.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
                            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          // Margem acima do título
                                SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.event_note, size: 14, color: widget.colorProvider.primaryColor),
                SizedBox(width: 6),
                                Text(
                  '${getTranslated(context, 'routeEvents') ?? 'Eventos do Trajeto'} (${events.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.colorProvider.primaryColor,
                  ),
                                ),
                              ],
                            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _eventsScrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              itemCount: events.length,
                            itemBuilder: (context, index) {
                final event = events[index];
                final isSelected = _selectedEventIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEventIndex = index;
                    });
                    // Mover câmera para o evento
                    final point = event['point'] as HistoryPoint;
                    if (point.latitude != null && point.longitude != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(point.latitude!, point.longitude!),
                                  ),
                                );
                              }
                  },
                  child: Container(
                    width: 160,
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? widget.colorProvider.primaryColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? widget.colorProvider.primaryColor
                            : widget.colorProvider.primaryColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: widget.colorProvider.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              event['icon'] as IconData,
                              size: 12,
                              color: widget.colorProvider.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event['description'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: widget.colorProvider.primaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                          ),
          ),
        ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          event['time'] as String,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Duration _parseDuration(String durationStr) {
    // Formato: "Xh Ymin Zs" ou "Ymin Zs" ou "Zs"
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    
    final hourMatch = RegExp(r'(\d+)h').firstMatch(durationStr);
    if (hourMatch != null) {
      hours = int.tryParse(hourMatch.group(1) ?? '0') ?? 0;
    }
    
    final minuteMatch = RegExp(r'(\d+)min').firstMatch(durationStr);
    if (minuteMatch != null) {
      minutes = int.tryParse(minuteMatch.group(1) ?? '0') ?? 0;
    }
    
    final secondMatch = RegExp(r'(\d+)s').firstMatch(durationStr);
    if (secondMatch != null) {
      seconds = int.tryParse(secondMatch.group(1) ?? '0') ?? 0;
    }
    
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  @override
  Widget build(BuildContext context) {
    final polylinePoints = _getPolylinePoints();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho igual ao das páginas
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: widget.colorProvider.primaryColor,
            ),
            child: SafeArea(
              bottom: false,
        child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
            children: [
                    // Ícone da página
              Container(
                      padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                        Icons.route,
                        color: Colors.white,
                  size: 24,
                ),
              ),
                    const SizedBox(width: 10),
              Expanded(
                child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          Text(
                            getTranslated(context, 'routeTraveled') ?? 'Rota Percorrida',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão fechar
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: getTranslated(context, 'close') ?? 'Fechar',
                    ),
                  ],
                ),
              ),
            ),
          ),
                        Expanded(
            child: Column(
                      children: [
                        Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: polylinePoints.isNotEmpty
                        ? polylinePoints.first
                        : LatLng(0, 0),
                    zoom: 13,
                  ),
                  mapType: _currentMapType,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitBounds();
                  },
                  polylines: polylinePoints.length > 1
                      ? {
                          Polyline(
                            polylineId: PolylineId('route'),
                            points: polylinePoints,
                            color: widget.colorProvider.primaryColor,
                            width: 5,
                          ),
                        }
                      : {},
                  markers: _getMarkers(),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
                // Botão de tipo de mapa
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleMapType,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            _getMapTypeIcon(),
                            color: widget.colorProvider.primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Controles de animação
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botões de controle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                      children: [
                            IconButton(
                              icon: Icon(Icons.skip_previous, size: 18),
                              onPressed: _resetAnimation,
                              tooltip: getTranslated(context, 'restart') ?? 'Reiniciar',
                              color: widget.colorProvider.primaryColor,
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 20,
                              ),
                              onPressed: _isPlaying ? _pauseAnimation : _startAnimation,
                              tooltip: _isPlaying ? (getTranslated(context, 'pause') ?? 'Pausar') : (getTranslated(context, 'play') ?? 'Reproduzir'),
                              color: widget.colorProvider.primaryColor,
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.stop, size: 18),
                              onPressed: _pauseAnimation,
                              tooltip: getTranslated(context, 'stop') ?? 'Parar',
                              color: Colors.red,
                              padding: EdgeInsets.all(8),
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        // Controle de velocidade
                        Container(
                          width: 150,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.speed, size: 14, color: Colors.grey[700]),
                                  SizedBox(width: 4),
                      Text(
                                    '${_animationSpeed.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _animationSpeed,
                                min: 0.5,
                                max: 5.0,
                                divisions: 9,
                                label: '${_animationSpeed.toStringAsFixed(1)}x',
                                onChanged: _setSpeed,
                                activeColor: widget.colorProvider.primaryColor,
                              ),
            ],
          ),
        ),
                        // Indicador de progresso
                        Container(
                          width: 150,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                  Text(
                                    getTranslated(context, 'progress') ?? 'Progresso',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${_currentPointIndex + 1}/${_validPoints.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                ),
              ],
            ),
                              SizedBox(height: 2),
                              LinearProgressIndicator(
                                value: _validPoints.isNotEmpty
                                    ? (_currentPointIndex + 1) / _validPoints.length
                                    : 0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.colorProvider.primaryColor,
                                ),
                                minHeight: 4,
                              ),
                            ],
                          ),
                        ),
          ],
        ),
      ),
                      ),
                    ],
                  ),
                ),
                // Seção de Eventos
                _buildEventsSection(),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
      child: Row(
        children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _shareOnWhatsApp,
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text(getTranslated(context, 'share') ?? 'Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _downloadPdf,
                    icon: _isGeneratingPdf
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(_isGeneratingPdf ? (getTranslated(context, 'generating') ?? 'Gerando...') : (getTranslated(context, 'downloadPdf') ?? 'Baixar PDF')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
  }
}
