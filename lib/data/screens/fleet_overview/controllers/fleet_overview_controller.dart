import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/events.dart';

class FleetOverviewController extends ChangeNotifier {
  List<deviceItems> _allDevices = [];
  List<deviceItems> _filteredDevices = [];
  String? _selectedVehicleId;
  String? _selectedGroupId;
  String _filterType = 'all'; // 'vehicle', 'group', 'all'
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _toDate = DateTime.now();
  
  // Status dos veículos
  int _totalVehicles = 0;
  int _onlineCount = 0;
  int _offlineCount = 0;
  int _movingCount = 0;
  int _stoppedCount = 0;
  int _ignitionOnCount = 0;
  int _ignitionOnStoppedCount = 0;
  
  // Quilometragem
  double _kmToday = 0.0;
  double _kmWeek = 0.0;
  double _kmMonth = 0.0;
  double _kmTotal = 0.0;
  
  // Combustível
  double _fuelToday = 0.0;
  double _fuelWeek = 0.0;
  double _fuelMonth = 0.0;
  double _fuelTotal = 0.0;
  
  // Estatísticas globais
  double _topSpeed = 0.0;
  String _moveDuration = '0h 0min';
  String _stopDuration = '0h 0min';
  int _ignitionOnEvents = 0;
  int _ignitionOffEvents = 0;
  String _offlineDuration = '0h 0min';
  
  // Dados detalhados por veículo
  List<VehicleDetailedData> _vehicleDetailedData = [];
  
  // Alertas
  List<EventsData> _recentAlerts = [];
  List<EventsData> _criticalAlerts = [];
  
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<deviceItems> get allDevices => _allDevices;
  List<deviceItems> get filteredDevices => _filteredDevices;
  String? get selectedVehicleId => _selectedVehicleId;
  String? get selectedGroupId => _selectedGroupId;
  String get filterType => _filterType;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  
  int get totalVehicles => _totalVehicles;
  int get onlineCount => _onlineCount;
  int get offlineCount => _offlineCount;
  int get movingCount => _movingCount;
  int get stoppedCount => _stoppedCount;
  int get ignitionOnCount => _ignitionOnCount;
  int get ignitionOnStoppedCount => _ignitionOnStoppedCount;
  
  double get kmToday => _kmToday;
  double get kmWeek => _kmWeek;
  double get kmMonth => _kmMonth;
  double get kmTotal => _kmTotal;
  
  double get fuelToday => _fuelToday;
  double get fuelWeek => _fuelWeek;
  double get fuelMonth => _fuelMonth;
  double get fuelTotal => _fuelTotal;
  
  double get topSpeed => _topSpeed;
  String get moveDuration => _moveDuration;
  String get stopDuration => _stopDuration;
  int get ignitionOnEvents => _ignitionOnEvents;
  int get ignitionOffEvents => _ignitionOffEvents;
  String get offlineDuration => _offlineDuration;
  
  List<VehicleDetailedData> get vehicleDetailedData => _vehicleDetailedData;
  
  List<EventsData> get recentAlerts => _recentAlerts;
  List<EventsData> get criticalAlerts => _criticalAlerts;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  FleetOverviewController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadDevices();
      await _calculateStatus();
      await _loadKilometers();
      await _loadFuel();
      await _loadDetailedData();
      await _loadAlerts();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadDevices() async {
    try {
      final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      if (devices != null) {
        _allDevices = devices;
        _applyFilter();
      }
    } catch (e) {
      print('Erro ao carregar dispositivos: $e');
    }
  }
  
  void setFilterType(String type, {String? vehicleId, String? groupId}) {
    _filterType = type;
    _selectedVehicleId = vehicleId;
    _selectedGroupId = groupId;
    _applyFilter();
    loadData();
  }

  void setDeviceId(String? deviceId) {
    _selectedVehicleId = deviceId;
    if (deviceId != null) {
      _filterType = 'vehicle';
    }
    _applyFilter();
    notifyListeners();
  }

  void setFromDate(DateTime date) {
    _fromDate = date;
    notifyListeners();
  }

  void setToDate(DateTime date) {
    _toDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _selectedVehicleId = null;
    _selectedGroupId = null;
    _filterType = 'all';
    _fromDate = DateTime.now().subtract(Duration(days: 7));
    _toDate = DateTime.now();
    _applyFilter();
    notifyListeners();
  }
  
  void _applyFilter() {
    if (_filterType == 'vehicle' && _selectedVehicleId != null) {
      _filteredDevices = _allDevices.where((d) => d.id.toString() == _selectedVehicleId).toList();
    } else if (_filterType == 'group' && _selectedGroupId != null) {
      // Por enquanto, grupos não estão implementados na API, então mostra todos
      _filteredDevices = _allDevices;
    } else {
      _filteredDevices = _allDevices;
    }
    notifyListeners();
  }
  
  Future<void> _calculateStatus() async {
    _totalVehicles = _filteredDevices.length;
    _onlineCount = 0;
    _offlineCount = 0;
    _movingCount = 0;
    _stoppedCount = 0;
    _ignitionOnCount = 0;
    _ignitionOnStoppedCount = 0;
    
    for (var device in _filteredDevices) {
      final online = device.online?.toLowerCase() ?? '';
      final speed = double.tryParse(device.speed?.toString() ?? '0') ?? 0.0;
      
      // Extrair status de ignição
      String ignitionStatus = "false";
      String other = device.deviceData?.traccar?.other?.toString() ?? "";
      if (other.contains("<ignition>")) {
        const start = "<ignition>";
        const end = "</ignition>";
        final startIndex = other.indexOf(start);
        final endIndex = other.indexOf(end, startIndex + start.length);
        if (startIndex != -1 && endIndex != -1) {
          ignitionStatus = other.substring(startIndex + start.length, endIndex);
        }
      }
      
      final isIgnitionOn = ignitionStatus.contains("true");
      final isMoving = speed > 5.0;
      final isStopped = speed <= 5.0;
      
      if (online.contains('online')) {
        _onlineCount++;
        if (isMoving) {
          _movingCount++;
        } else {
          _stoppedCount++;
        }
      } else if (online.contains('offline')) {
        _offlineCount++;
        _stoppedCount++;
      } else {
        _stoppedCount++;
      }
      
      // Contagem de ignição
      if (isIgnitionOn) {
        _ignitionOnCount++;
        if (isStopped) {
          _ignitionOnStoppedCount++;
        }
      }
    }
  }
  
  Future<void> _loadKilometers() async {
    _kmToday = 0.0;
    _kmWeek = 0.0;
    _kmMonth = 0.0;
    _kmTotal = 0.0;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Formatar datas para a API
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    
    String formatTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    // Buscar dados de cada dispositivo
    for (var device in _filteredDevices) {
      final deviceId = device.id?.toString() ?? '';
      if (deviceId.isEmpty) continue;
      
      try {
        // Total (usar totalDistance do dispositivo)
        final totalDistance = double.tryParse(device.totalDistance?.toString() ?? '0') ?? 0.0;
        _kmTotal += totalDistance;
        
        // Hoje
        try {
          final historyToday = await gpsapis.getHistorynew(
            deviceId,
            formatDate(todayStart),
            formatTime(todayStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyToday != null && historyToday.distance_sum != null) {
            final kmStr = historyToday.distance_sum!.replaceAll(' Km', '').replaceAll(',', '');
            _kmToday += double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM hoje para dispositivo $deviceId: $e');
        }
        
        // Semana
        try {
          final historyWeek = await gpsapis.getHistorynew(
            deviceId,
            formatDate(weekStart),
            formatTime(weekStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyWeek != null && historyWeek.distance_sum != null) {
            final kmStr = historyWeek.distance_sum!.replaceAll(' Km', '').replaceAll(',', '');
            _kmWeek += double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM semana para dispositivo $deviceId: $e');
        }
        
        // Mês
        try {
          final historyMonth = await gpsapis.getHistorynew(
            deviceId,
            formatDate(monthStart),
            formatTime(monthStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyMonth != null && historyMonth.distance_sum != null) {
            final kmStr = historyMonth.distance_sum!.replaceAll(' Km', '').replaceAll(',', '');
            _kmMonth += double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM mês para dispositivo $deviceId: $e');
        }
      } catch (e) {
        print('Erro ao processar dispositivo $deviceId: $e');
      }
    }
  }
  
  Future<void> _loadFuel() async {
    _fuelToday = 0.0;
    _fuelWeek = 0.0;
    _fuelMonth = 0.0;
    _fuelTotal = 0.0;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    
    // Formatar datas para a API
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    
    String formatTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    // Buscar dados de cada dispositivo
    for (var device in _filteredDevices) {
      final deviceId = device.id?.toString() ?? '';
      if (deviceId.isEmpty) continue;
      
      try {
        // Hoje
        try {
          final historyToday = await gpsapis.getHistorynew(
            deviceId,
            formatDate(todayStart),
            formatTime(todayStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyToday != null && historyToday.fuel_consumption != null) {
            final fuelStr = historyToday.fuel_consumption!.replaceAll(' Liters', '').replaceAll(',', '');
            _fuelToday += double.tryParse(fuelStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar combustível hoje para dispositivo $deviceId: $e');
        }
        
        // Semana
        try {
          final historyWeek = await gpsapis.getHistorynew(
            deviceId,
            formatDate(weekStart),
            formatTime(weekStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyWeek != null && historyWeek.fuel_consumption != null) {
            final fuelStr = historyWeek.fuel_consumption!.replaceAll(' Liters', '').replaceAll(',', '');
            _fuelWeek += double.tryParse(fuelStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar combustível semana para dispositivo $deviceId: $e');
        }
        
        // Mês
        try {
          final historyMonth = await gpsapis.getHistorynew(
            deviceId,
            formatDate(monthStart),
            formatTime(monthStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyMonth != null && historyMonth.fuel_consumption != null) {
            final fuelStr = historyMonth.fuel_consumption!.replaceAll(' Liters', '').replaceAll(',', '');
            _fuelMonth += double.tryParse(fuelStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar combustível mês para dispositivo $deviceId: $e');
        }
        
        // Total - somar todos os períodos ou usar uma estimativa baseada no totalDistance
        // Como não temos histórico total, vamos somar o mês como aproximação
        // Em produção, pode-se fazer uma chamada com data de início muito antiga
        _fuelTotal += _fuelMonth; // Aproximação
      } catch (e) {
        print('Erro ao processar combustível para dispositivo $deviceId: $e');
      }
    }
  }
  
  Future<void> _loadDetailedData() async {
    _topSpeed = 0.0;
    _moveDuration = '0h 0min';
    _stopDuration = '0h 0min';
    _ignitionOnEvents = 0;
    _ignitionOffEvents = 0;
    _offlineDuration = '0h 0min';
    _vehicleDetailedData.clear();
    
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    
    String formatTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    double totalMoveDuration = 0.0; // em segundos
    double totalStopDuration = 0.0; // em segundos
    double totalOfflineDuration = 0.0; // em segundos
    
    for (var device in _filteredDevices) {
      final deviceId = device.id?.toString() ?? '';
      if (deviceId.isEmpty) continue;
      
      try {
        // Buscar histórico do mês
        final history = await gpsapis.getHistorynew(
          deviceId,
          formatDate(monthStart),
          formatTime(monthStart),
          formatDate(now),
          formatTime(now),
        );
        
        if (history != null) {
          // Top speed
          if (history.top_speed != null) {
            final speedStr = history.top_speed!.replaceAll(' km/h', '').replaceAll(',', '').trim();
            final speed = double.tryParse(speedStr) ?? 0.0;
            if (speed > _topSpeed) {
              _topSpeed = speed;
            }
          }
          
          // Move duration
          if (history.move_duration != null) {
            totalMoveDuration += _parseDurationToSeconds(history.move_duration!);
          }
          
          // Stop duration
          if (history.stop_duration != null) {
            totalStopDuration += _parseDurationToSeconds(history.stop_duration!);
          }
          
          // Contar eventos de ignição no histórico
          int deviceIgnitionOn = 0;
          int deviceIgnitionOff = 0;
          double deviceOfflineDuration = 0.0;
          DateTime? lastOfflineTime;
          bool wasOffline = false;
          List<dynamic> allHistoryItems = [];
          
          // Coletar todos os items do histórico (pode estar em trips)
          if (history.items != null) {
            for (var trip in history.items!) {
              if (trip is Map && trip['items'] != null) {
                allHistoryItems.addAll(trip['items']);
              } else if (trip is Map) {
                allHistoryItems.add(trip);
              }
            }
          }
          
          String? lastIgnitionState;
          
          for (var item in allHistoryItems) {
            if (item is Map) {
                // Verificar status online/offline
                final timeStr = item['time']?.toString() ?? item['serverTime']?.toString();
                final onlineStatus = item['online']?.toString().toLowerCase() ?? '';
                
                if (timeStr != null) {
                  try {
                    final itemTime = DateTime.parse(timeStr);
                    final isOffline = onlineStatus.contains('offline') || 
                                    onlineStatus.contains('not connected') ||
                                    onlineStatus.isEmpty;
                    
                    if (isOffline && !wasOffline) {
                      // Início do período offline
                      lastOfflineTime = itemTime;
                      wasOffline = true;
                    } else if (!isOffline && wasOffline && lastOfflineTime != null) {
                      // Fim do período offline
                      deviceOfflineDuration += itemTime.difference(lastOfflineTime).inSeconds.toDouble();
                      lastOfflineTime = null;
                      wasOffline = false;
                    }
                  } catch (e) {
                    // Ignorar erros de parsing
                  }
                }
                
                // Verificar eventos de ignição
                final other = item['other']?.toString() ?? '';
                if (other.contains('<ignition>')) {
                  const start = '<ignition>';
                  const end = '</ignition>';
                  final startIndex = other.indexOf(start);
                  final endIndex = other.indexOf(end, startIndex + start.length);
                  if (startIndex != -1 && endIndex != -1) {
                    final ignitionState = other.substring(startIndex + start.length, endIndex);
                    if (lastIgnitionState != null && lastIgnitionState != ignitionState) {
                      if (ignitionState.contains('true') && lastIgnitionState.contains('false')) {
                        deviceIgnitionOn++;
                      } else if (ignitionState.contains('false') && lastIgnitionState.contains('true')) {
                        deviceIgnitionOff++;
                      }
                    } else if (lastIgnitionState == null) {
                      // Primeiro estado detectado
                      lastIgnitionState = ignitionState;
                    }
                  }
                }
              }
            }
            
            // Se ainda estava offline no último item, calcular até agora
            if (wasOffline && lastOfflineTime != null) {
              deviceOfflineDuration += DateTime.now().difference(lastOfflineTime).inSeconds.toDouble();
            }
          
          _ignitionOnEvents += deviceIgnitionOn;
          _ignitionOffEvents += deviceIgnitionOff;
          totalOfflineDuration += deviceOfflineDuration;
          
          // Criar dados detalhados do veículo
          final driverName = device.driver ?? device.driverData?.name ?? 'Sem motorista';
          final imei = device.deviceData?.imei?.toString() ?? 'N/A';
          
          _vehicleDetailedData.add(VehicleDetailedData(
            vehicle: device,
            driverName: driverName,
            imei: imei,
            topSpeed: history.top_speed ?? '0 km/h',
            moveDuration: history.move_duration ?? '0h 0min',
            stopDuration: history.stop_duration ?? '0h 0min',
            fuelConsumption: history.fuel_consumption ?? '0 Liters',
            distanceSum: history.distance_sum ?? '0 Km',
            ignitionOnCount: deviceIgnitionOn,
            ignitionOffCount: deviceIgnitionOff,
            offlineDuration: _formatDuration(deviceOfflineDuration),
            historyItems: allHistoryItems,
          ));
        }
      } catch (e) {
        print('Erro ao carregar dados detalhados para dispositivo $deviceId: $e');
      }
    }
    
    // Formatar durações totais
    _moveDuration = _formatDuration(totalMoveDuration);
    _stopDuration = _formatDuration(totalStopDuration);
    _offlineDuration = _formatDuration(totalOfflineDuration);
  }
  
  double _parseDurationToSeconds(String duration) {
    try {
      // Formatos: "2h 35min 13s", "35min 13s", "13s"
      double seconds = 0.0;
      
      // Extrair horas
      final hourMatch = RegExp(r'(\d+)h').firstMatch(duration);
      if (hourMatch != null) {
        seconds += double.parse(hourMatch.group(1)!) * 3600;
      }
      
      // Extrair minutos
      final minuteMatch = RegExp(r'(\d+)min').firstMatch(duration);
      if (minuteMatch != null) {
        seconds += double.parse(minuteMatch.group(1)!) * 60;
      }
      
      // Extrair segundos
      final secondMatch = RegExp(r'(\d+)s').firstMatch(duration);
      if (secondMatch != null) {
        seconds += double.parse(secondMatch.group(1)!);
      }
      
      return seconds;
    } catch (e) {
      return 0.0;
    }
  }
  
  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toInt()}s';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).floor();
      final secs = (seconds % 60).floor();
      return '${minutes}min ${secs}s';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      final secs = (seconds % 60).floor();
      return '${hours}h ${minutes}min ${secs}s';
    }
  }
  
  Future<void> _loadAlerts() async {
    try {
      final gpsApi = gpsapis();
      final events = await gpsApi.getEvents(StaticVarMethod.user_api_hash);
      if (events.items != null && events.items!.data != null) {
        final allAlerts = events.items!.data!;
        final now = DateTime.now();
        final yesterday = now.subtract(Duration(hours: 24));
        
        // Alertas das últimas 24h
        _recentAlerts = allAlerts.where((alert) {
          try {
            final timeStr = alert.time ?? alert.createdAt ?? '';
            if (timeStr.isEmpty) return false;
            final alertTime = DateTime.parse(timeStr);
            return alertTime.isAfter(yesterday);
          } catch (e) {
            return false;
          }
        }).toList();
        
        // Alertas críticos
        _criticalAlerts = allAlerts.where((alert) {
          final type = alert.type?.toLowerCase() ?? '';
          return type.contains('overspeed') || 
                 type.contains('panic') || 
                 type.contains('geofence') ||
                 type.contains('disconnect');
        }).toList();
        
        // Ordenar por data (mais recentes primeiro)
        _recentAlerts.sort((a, b) {
          try {
            final timeA = DateTime.parse(a.time ?? a.createdAt ?? '');
            final timeB = DateTime.parse(b.time ?? b.createdAt ?? '');
            return timeB.compareTo(timeA);
          } catch (e) {
            return 0;
          }
        });
        
        _criticalAlerts.sort((a, b) {
          try {
            final timeA = DateTime.parse(a.time ?? a.createdAt ?? '');
            final timeB = DateTime.parse(b.time ?? b.createdAt ?? '');
            return timeB.compareTo(timeA);
          } catch (e) {
            return 0;
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar alertas: $e');
    }
  }
  
  Future<String> getAddress(double lat, double lng) async {
    try {
      final response = await gpsapis.getGeocoder(lat, lng);
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      print('Erro ao buscar endereço: $e');
    }
    return 'Endereço não disponível';
  }
}

// Classe para dados detalhados por veículo
class VehicleDetailedData {
  final deviceItems vehicle;
  final String driverName;
  final String imei;
  final String topSpeed;
  final String moveDuration;
  final String stopDuration;
  final String fuelConsumption;
  final String distanceSum;
  final int ignitionOnCount;
  final int ignitionOffCount;
  final String offlineDuration;
  final List<dynamic> historyItems;  VehicleDetailedData({
    required this.vehicle,
    required this.driverName,
    required this.imei,
    required this.topSpeed,
    required this.moveDuration,
    required this.stopDuration,
    required this.fuelConsumption,
    required this.distanceSum,
    required this.ignitionOnCount,
    required this.ignitionOffCount,
    required this.offlineDuration,
    required this.historyItems,
  });
}