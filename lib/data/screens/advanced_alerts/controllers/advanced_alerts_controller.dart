import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/add_alert_data.dart';
import 'package:uconnect/data/model/protocol.dart';
import 'package:uconnect/model/Alert.dart';

class AdvancedAlertsController with ChangeNotifier {
  List<deviceItems> _devices = [];
  List<Alert> _existingAlerts = [];
  List<Alert> _filteredAlerts = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  String? _selectedVehicleId;
  String _filterType = 'all'; // 'vehicle', 'all'

  // Formulário
  String _name = '';
  String _type = 'overspeed';
  List<String> _selectedDeviceIds = [];
  String? _overspeed;
  String? _overspeedDistance;
  List<String> _selectedGeofenceIds = [];
  List<String> _selectedDriverIds = [];
  List<String> _selectedEventCustomIds = [];
  String? _selectedZone;
  List<String> _selectedZones = [];
  String? _email;
  String? _mobilePhone;
  int? _stopDuration;
  int? _idleDuration;
  int? _ignitionDuration;
  int? _offlineDuration;
  int? _moveDuration;
  int? _minParkingDuration;
  int? _distance;
  int? _distanceTolerance;

  // API Data
  AddAlertData? _addAlertData;
  ProtocolResponse? _protocols;
  List<AlertOption>? _availableDevices;
  List<AlertOption>? _availableGeofences;
  List<AlertOption>? _availableDrivers;
  List<AlertOption>? _availableZones;
  List<AlertOption>? _availableEventTypes;
  List<AlertOption>? _availableProtocols;

  List<deviceItems> get devices => _devices;
  List<Alert> get existingAlerts => _existingAlerts;
  List<Alert> get filteredAlerts => _filteredAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedVehicleId => _selectedVehicleId;
  String get filterType => _filterType;

  String get name => _name;
  String get type => _type;
  List<String> get selectedDeviceIds => _selectedDeviceIds;
  String? get overspeed => _overspeed;
  String? get overspeedDistance => _overspeedDistance;
  List<String> get selectedGeofenceIds => _selectedGeofenceIds;
  List<String> get selectedDriverIds => _selectedDriverIds;
  List<String> get selectedEventCustomIds => _selectedEventCustomIds;
  String? get selectedZone => _selectedZone;
  List<String> get selectedZones => _selectedZones;
  String? get email => _email;
  String? get mobilePhone => _mobilePhone;
  int? get stopDuration => _stopDuration;
  int? get idleDuration => _idleDuration;
  int? get ignitionDuration => _ignitionDuration;
  int? get offlineDuration => _offlineDuration;
  int? get moveDuration => _moveDuration;
  int? get minParkingDuration => _minParkingDuration;
  int? get distance => _distance;
  int? get distanceTolerance => _distanceTolerance;

  AddAlertData? get addAlertData => _addAlertData;
  ProtocolResponse? get protocols => _protocols;
  List<AlertOption>? get availableDevices => _availableDevices;
  List<AlertOption>? get availableGeofences => _availableGeofences;
  List<AlertOption>? get availableDrivers => _availableDrivers;
  List<AlertOption>? get availableZones => _availableZones;
  List<AlertOption>? get availableEventTypes => _availableEventTypes;
  List<AlertOption>? get availableProtocols => _availableProtocols;

  AdvancedAlertsController() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadDevices(),
      loadAlerts(),
      loadAddAlertData(),
      loadProtocols(),
    ]);
  }

  Future<void> loadDevices() async {
    try {
      final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      if (devices != null) {
        _devices = devices;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar dispositivos: $e');
    }
  }

  Future<void> loadAlerts() async {
    try {
      final alerts = await gpsapis.getAlertList();
      if (alerts != null) {
        _existingAlerts = alerts;
        _applyFilter();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  void setDeviceId(String? deviceId) {
    _selectedVehicleId = deviceId;
    if (deviceId != null) {
      _filterType = 'vehicle';
    } else {
      _filterType = 'all';
    }
    _applyFilter();
    notifyListeners();
  }
  
  void _applyFilter() {
    if (_filterType == 'vehicle' && _selectedVehicleId != null) {
      _filteredAlerts = _existingAlerts.where((alert) {
        if (alert.devices == null || alert.devices!.isEmpty) return false;
        return alert.devices!.any((device) => device.toString() == _selectedVehicleId);
      }).toList();
    } else {
      _filteredAlerts = _existingAlerts;
    }
  }

  Future<void> loadAddAlertData() async {
    try {
      final response = await gpsapis.getAddAlertData(lang: 'br');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _addAlertData = AddAlertData.fromJson(jsonData);
        _availableDevices = _addAlertData?.devices;
        _availableGeofences = _addAlertData?.geofences;
        _availableDrivers = _addAlertData?.drivers;
        _availableZones = _addAlertData?.alertZones;
        _availableEventTypes = _addAlertData?.eventTypes;
        _availableProtocols = _addAlertData?.eventProtocols;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar dados de alerta: $e');
    }
  }

  Future<void> loadProtocols() async {
    try {
      final response = await gpsapis.getProtocols(lang: 'br');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _protocols = ProtocolResponse.fromJson(jsonData);
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar protocolos: $e');
    }
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setType(String value) {
    _type = value;
    notifyListeners();
  }

  void toggleDevice(String deviceId) {
    if (_selectedDeviceIds.contains(deviceId)) {
      _selectedDeviceIds.remove(deviceId);
    } else {
      _selectedDeviceIds.add(deviceId);
    }
    notifyListeners();
  }

  void setOverspeed(String? value) {
    _overspeed = value;
    notifyListeners();
  }

  void setOverspeedDistance(String? value) {
    _overspeedDistance = value;
    notifyListeners();
  }

  void toggleGeofence(String geofenceId) {
    if (_selectedGeofenceIds.contains(geofenceId)) {
      _selectedGeofenceIds.remove(geofenceId);
    } else {
      _selectedGeofenceIds.add(geofenceId);
    }
    notifyListeners();
  }

  void toggleDriver(String driverId) {
    if (_selectedDriverIds.contains(driverId)) {
      _selectedDriverIds.remove(driverId);
    } else {
      _selectedDriverIds.add(driverId);
    }
    notifyListeners();
  }

  void toggleEventCustom(String eventId) {
    if (_selectedEventCustomIds.contains(eventId)) {
      _selectedEventCustomIds.remove(eventId);
    } else {
      _selectedEventCustomIds.add(eventId);
    }
    notifyListeners();
  }

  void setEmail(String? value) {
    _email = value;
    notifyListeners();
  }

  void setMobilePhone(String? value) {
    _mobilePhone = value;
    notifyListeners();
  }

  void setStopDuration(int? value) {
    _stopDuration = value;
    notifyListeners();
  }

  void setIdleDuration(int? value) {
    _idleDuration = value;
    notifyListeners();
  }

  void setIgnitionDuration(int? value) {
    _ignitionDuration = value;
    notifyListeners();
  }

  void setOfflineDuration(int? value) {
    _offlineDuration = value;
    notifyListeners();
  }

  void setMoveDuration(int? value) {
    _moveDuration = value;
    notifyListeners();
  }

  void setMinParkingDuration(int? value) {
    _minParkingDuration = value;
    notifyListeners();
  }

  void setDistance(int? value) {
    _distance = value;
    notifyListeners();
  }

  void setDistanceTolerance(int? value) {
    _distanceTolerance = value;
    notifyListeners();
  }

  Future<bool> createAlert() async {
    if (_name.isEmpty) {
      _error = 'Nome do alerta é obrigatório';
      notifyListeners();
      return false;
    }

    if (_selectedDeviceIds.isEmpty) {
      _error = 'Selecione pelo menos um dispositivo';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Build JSON body for add_alert API
      Map<String, dynamic> alertData = {
        'active': 1,
        'type': _type,
        'name': _name,
        'devices': _selectedDeviceIds.map((id) => int.tryParse(id) ?? 0).toList(),
        'schedules': {},
        'notifications': {
          'push': {'active': 1},
          'email': {
            'active': _email != null && _email!.isNotEmpty ? 1 : 0,
            'input': _email ?? '',
          },
          'webhook': {'active': 0, 'input': ''},
        },
        'command': {'active': 0, 'type': ''},
      };

      // Add overspeed if provided
      if (_overspeed != null && _overspeed!.isNotEmpty) {
        alertData['overspeed'] = int.tryParse(_overspeed!) ?? 0;
      }

      // Add geofences
      if (_selectedGeofenceIds.isNotEmpty) {
        alertData['geofences'] = _selectedGeofenceIds.map((id) => int.tryParse(id) ?? 0).toList();
      }

      // Add drivers
      if (_selectedDriverIds.isNotEmpty) {
        alertData['drivers'] = _selectedDriverIds.map((id) => int.tryParse(id) ?? 0).toList();
      }

      // Add custom events
      if (_selectedEventCustomIds.isNotEmpty) {
        alertData['events_custom'] = _selectedEventCustomIds.map((id) => int.tryParse(id) ?? 0).toList();
      }

      // Add durations
      if (_stopDuration != null) alertData['stop_duration'] = _stopDuration;
      if (_idleDuration != null) alertData['idle_duration'] = _idleDuration;
      if (_ignitionDuration != null) alertData['ignition_duration'] = _ignitionDuration;
      if (_offlineDuration != null) alertData['offline_duration'] = _offlineDuration;
      if (_moveDuration != null) alertData['move_duration'] = _moveDuration;
      if (_minParkingDuration != null) alertData['min_parking_duration'] = _minParkingDuration;
      if (_distance != null) alertData['distance'] = _distance;
      if (_distanceTolerance != null) alertData['distance_tolerance'] = _distanceTolerance;

      final response = await gpsapis.addAlertJson(alertData, lang: 'br');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          await loadAlerts();
          _resetForm();
          return true;
        } else {
          _error = 'Erro ao criar alerta';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Erro ao criar alerta: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    _name = '';
    _type = 'overspeed';
    _selectedDeviceIds = [];
    _overspeed = null;
    _overspeedDistance = null;
    _selectedGeofenceIds = [];
    _selectedDriverIds = [];
    _selectedEventCustomIds = [];
    _selectedZone = null;
    _selectedZones = [];
    _email = null;
    _mobilePhone = null;
    _stopDuration = null;
    _idleDuration = null;
    _ignitionDuration = null;
    _offlineDuration = null;
    _moveDuration = null;
    _minParkingDuration = null;
    _distance = null;
    _distanceTolerance = null;
    notifyListeners();
  }
  
  // Editar alerta
  Future<bool> editAlert(Alert alert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      Map<String, dynamic> alertData = alert.toJson();
      final response = await gpsapis.editAlertJson(alertData, lang: 'br');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          await loadAlerts();
          return true;
        } else {
          _error = 'Erro ao editar alerta';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Erro ao editar alerta: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Excluir alerta
  Future<bool> deleteAlert(int alertId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await gpsapis.destroyAlertAncor(alertId);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 1) {
          await loadAlerts();
          return true;
        } else {
          _error = 'Erro ao excluir alerta';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Erro ao excluir alerta: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Associar alerta a dispositivo
  Future<bool> associateAlertToDevice(int alertId, int deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Buscar alerta atual
      final alert = _existingAlerts.firstWhere((a) => a.id == alertId);
      List<dynamic> currentDevices = alert.devices ?? [];
      
      // Adicionar dispositivo se não estiver na lista
      if (!currentDevices.contains(deviceId)) {
        currentDevices.add(deviceId);
        alert.devices = currentDevices;
        return await editAlert(alert);
      }
      
      return true;
    } catch (e) {
      _error = 'Erro: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Carregar dados de edição de alerta
  Future<Map<String, dynamic>?> getEditAlertData(int alertId) async {
    try {
      final response = await gpsapis.getEditAlertData(lang: 'br');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      }
      return null;
    } catch (e) {
      print('Erro ao carregar dados de edição: $e');
      return null;
    }
  }
}

