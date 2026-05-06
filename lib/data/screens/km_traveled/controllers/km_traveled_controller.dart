import 'package:flutter/material.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/services/fleet_management_service.dart';
import 'package:intl/intl.dart';

class KmTraveledController with ChangeNotifier {
  List<deviceItems> _devices = [];
  List<deviceItems> _filteredDevices = [];
  deviceItems? _selectedDevice;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String _fromTime = '00:00';
  String _toTime = '23:59';
  String _filterPeriod = 'week'; // 'today', 'week', 'month', 'custom'
  
  bool _isLoading = false;
  Map<String, Map<String, double>> _kmData = {}; // deviceId -> {today, week, month, total}
  List<Map<String, dynamic>> _detailedData = []; // Dados detalhados por veículo/data
  
  List<deviceItems> get devices => _devices;
  List<deviceItems> get filteredDevices => _filteredDevices;
  deviceItems? get selectedDevice => _selectedDevice;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  String get fromTime => _fromTime;
  String get toTime => _toTime;
  String get filterPeriod => _filterPeriod;
  bool get isLoading => _isLoading;
  Map<String, Map<String, double>> get kmData => _kmData;
  List<Map<String, dynamic>> get detailedData => _detailedData;
  
  double get totalKm => _detailedData.fold(0.0, (sum, item) => sum + (item['km'] as double? ?? 0.0));
  
  KmTraveledController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadDevices();
      await _loadKmData();
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadDevices() async {
    try {
      _devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash) ?? [];
      _filteredDevices = _devices;
      if (_selectedDevice == null && _devices.isNotEmpty) {
        _selectedDevice = _devices.first;
      }
    } catch (e) {
      print('Erro ao carregar dispositivos: $e');
      _devices = [];
      _filteredDevices = [];
    }
  }
  
  Future<void> _loadKmData() async {
    _kmData.clear();
    _detailedData.clear();
    
    final devicesToProcess = _selectedDevice != null 
        ? [_selectedDevice!] 
        : _filteredDevices;
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    
    for (var device in devicesToProcess) {
      final deviceId = device.id?.toString() ?? '';
      if (deviceId.isEmpty) continue;
      
      try {
        double kmToday = 0.0;
        double kmWeek = 0.0;
        double kmMonth = 0.0;
        double kmTotal = 0.0;
        
        // KM Total do dispositivo
        kmTotal = double.tryParse(device.totalDistance?.toString() ?? '0') ?? 0.0;
        
        // KM Hoje
        try {
          final historyToday = await gpsapis.getHistorynew(
            deviceId,
            formatDate(todayStart),
            formatTime(todayStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyToday != null && historyToday.distance_sum != null) {
            final kmStr = historyToday.distance_sum!.replaceAll(' Km', '').replaceAll(',', '').trim();
            kmToday = double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM hoje: $e');
        }
        
        // KM Semana
        try {
          final historyWeek = await gpsapis.getHistorynew(
            deviceId,
            formatDate(weekStart),
            formatTime(weekStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyWeek != null && historyWeek.distance_sum != null) {
            final kmStr = historyWeek.distance_sum!.replaceAll(' Km', '').replaceAll(',', '').trim();
            kmWeek = double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM semana: $e');
        }
        
        // KM Mês
        try {
          final historyMonth = await gpsapis.getHistorynew(
            deviceId,
            formatDate(monthStart),
            formatTime(monthStart),
            formatDate(now),
            formatTime(now),
          );
          if (historyMonth != null && historyMonth.distance_sum != null) {
            final kmStr = historyMonth.distance_sum!.replaceAll(' Km', '').replaceAll(',', '').trim();
            kmMonth = double.tryParse(kmStr) ?? 0.0;
          }
        } catch (e) {
          print('Erro ao buscar KM mês: $e');
        }
        
        // KM Período customizado
        double kmCustom = 0.0;
        if (_filterPeriod == 'custom') {
          try {
            final historyCustom = await gpsapis.getHistorynew(
              deviceId,
              formatDate(_fromDate),
              _fromTime,
              formatDate(_toDate),
              _toTime,
            );
            if (historyCustom != null && historyCustom.distance_sum != null) {
              final kmStr = historyCustom.distance_sum!.replaceAll(' Km', '').replaceAll(',', '').trim();
              kmCustom = double.tryParse(kmStr) ?? 0.0;
            }
          } catch (e) {
            print('Erro ao buscar KM período customizado: $e');
          }
        }
        
        // Determinar KM baseado no período selecionado
        double kmPeriod = 0.0;
        switch (_filterPeriod) {
          case 'today':
            kmPeriod = kmToday;
            break;
          case 'week':
            kmPeriod = kmWeek;
            break;
          case 'month':
            kmPeriod = kmMonth;
            break;
          case 'custom':
            kmPeriod = kmCustom;
            break;
        }
        
        _kmData[deviceId] = {
          'today': kmToday,
          'week': kmWeek,
          'month': kmMonth,
          'total': kmTotal,
          'custom': kmCustom,
          'period': kmPeriod,
        };
        
        // Adicionar aos dados detalhados
        _detailedData.add({
          'deviceId': deviceId,
          'deviceName': device.name ?? 'Sem nome',
          'imei': device.deviceData?.imei ?? 'N/A',
          'km': kmPeriod,
          'kmToday': kmToday,
          'kmWeek': kmWeek,
          'kmMonth': kmMonth,
          'kmTotal': kmTotal,
          'status': device.online == 1 ? 'Online' : 'Offline',
          'lastUpdate': device.time?.toString() ?? 'N/A',
        });
      } catch (e) {
        print('Erro ao processar dispositivo $deviceId: $e');
      }
    }
    
    // Ordenar por KM (maior primeiro)
    _detailedData.sort((a, b) => (b['km'] as double).compareTo(a['km'] as double));
  }
  
  void setSelectedDevice(deviceItems? device) {
    _selectedDevice = device;
    _filteredDevices = device != null ? [device] : _devices;
    _loadKmData();
  }
  
  void setFilterPeriod(String period) {
    _filterPeriod = period;
    
    final now = DateTime.now();
    switch (period) {
      case 'today':
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = now;
        _fromTime = '00:00';
        _toTime = formatTime(now);
        break;
      case 'week':
        _fromDate = now.subtract(Duration(days: now.weekday - 1));
        _toDate = now;
        _fromTime = '00:00';
        _toTime = formatTime(now);
        break;
      case 'month':
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = now;
        _fromTime = '00:00';
        _toTime = formatTime(now);
        break;
      case 'custom':
        // Manter datas customizadas
        break;
    }
    
    _loadKmData();
  }
  
  void setCustomDateRange(DateTime from, DateTime to, String fromTimeStr, String toTimeStr) {
    _fromDate = from;
    _toDate = to;
    _fromTime = fromTimeStr;
    _toTime = toTimeStr;
    _filterPeriod = 'custom';
    _loadKmData();
  }
  
  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}

