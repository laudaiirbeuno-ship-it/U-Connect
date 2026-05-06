import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/driver_form_data.dart';

class FleetChecklistController extends ChangeNotifier {
  List<deviceItems> _vehicles = [];
  List<DriverData> _drivers = [];
  List<ChecklistTemplate> _templates = [];
  List<ChecklistRecord> _checklistRecords = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  String? _selectedVehicleId;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Estatísticas
  int _totalChecklists = 0;
  int _completedChecklists = 0;
  int _pendingChecklists = 0;
  
  // Getters
  List<deviceItems> get vehicles => _vehicles;
  List<DriverData> get drivers => _drivers;
  List<ChecklistTemplate> get templates => _templates;
  List<ChecklistRecord> get checklistRecords => _checklistRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedVehicleId => _selectedVehicleId;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  int get totalChecklists => _totalChecklists;
  int get completedChecklists => _completedChecklists;
  int get pendingChecklists => _pendingChecklists;
  
  FleetChecklistController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadVehicles();
      await _loadDrivers();
      await _loadTemplates();
      await _loadChecklistRecords();
      _calculateStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadVehicles() async {
    try {
      final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      if (devices != null) {
        _vehicles = devices;
      }
    } catch (e) {
      print('Erro ao carregar veículos: $e');
    }
  }
  
  Future<void> _loadDrivers() async {
    try {
      final drivers = await gpsapis.getUserDrivers();
      if (drivers != null) {
        _drivers = drivers;
      }
    } catch (e) {
      print('Erro ao carregar motoristas: $e');
    }
  }
  
  Future<void> _loadTemplates() async {
    // Templates padrão de checklist
    _templates = [
      ChecklistTemplate(
        id: 'pre_trip',
        name: 'Pré-Viagem',
        items: [
          ChecklistItem(id: '1', name: 'Verificar nível de óleo', required: true),
          ChecklistItem(id: '2', name: 'Verificar nível de água', required: true),
          ChecklistItem(id: '3', name: 'Verificar pneus', required: true),
          ChecklistItem(id: '4', name: 'Verificar freios', required: true),
          ChecklistItem(id: '5', name: 'Verificar faróis', required: true),
          ChecklistItem(id: '6', name: 'Verificar documentos', required: true),
        ],
      ),
      ChecklistTemplate(
        id: 'post_trip',
        name: 'Pós-Viagem',
        items: [
          ChecklistItem(id: '1', name: 'Verificar danos externos', required: false),
          ChecklistItem(id: '2', name: 'Verificar limpeza interna', required: false),
          ChecklistItem(id: '3', name: 'Verificar equipamentos', required: false),
        ],
      ),
      ChecklistTemplate(
        id: 'maintenance',
        name: 'Manutenção',
        items: [
          ChecklistItem(id: '1', name: 'Troca de óleo', required: true),
          ChecklistItem(id: '2', name: 'Troca de filtros', required: true),
          ChecklistItem(id: '3', name: 'Alinhamento', required: false),
          ChecklistItem(id: '4', name: 'Balanceamento', required: false),
        ],
      ),
    ];
  }
  
  Future<void> _loadChecklistRecords() async {
    // Carregar registros de checklist da API
    // TODO: Implementar chamada à API quando disponível
    _checklistRecords = [];
    
    // Em produção, isso viria da API:
    // final response = await gpsapis.getChecklistRecords(...);
    // if (response != null) {
    //   _checklistRecords = response.map((r) => ChecklistRecord.fromJson(r)).toList();
    // }
    
    // Aplicar filtros de data
    _checklistRecords = _checklistRecords
        .where((r) => r.date.isAfter(_fromDate.subtract(Duration(days: 1))) &&
                     r.date.isBefore(_toDate.add(Duration(days: 1))))
        .toList();
    
    _checklistRecords.sort((a, b) => b.date.compareTo(a.date));
  }
  
  void _calculateStatistics() {
    _totalChecklists = _checklistRecords.length;
    _completedChecklists = _checklistRecords.where((r) => r.completed).length;
    _pendingChecklists = _totalChecklists - _completedChecklists;
  }
  
  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _loadChecklistRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    _loadChecklistRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> addChecklistRecord(ChecklistRecord record) async {
    _checklistRecords.insert(0, record);
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> updateChecklistRecord(ChecklistRecord record) async {
    final index = _checklistRecords.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _checklistRecords[index] = record;
      _calculateStatistics();
      notifyListeners();
    }
  }
  
  Future<void> deleteChecklistRecord(String recordId) async {
    _checklistRecords.removeWhere((r) => r.id == recordId);
    _calculateStatistics();
    notifyListeners();
  }
}

class ChecklistTemplate {
  final String id;
  final String name;
  final List<ChecklistItem> items;
  
  ChecklistTemplate({
    required this.id,
    required this.name,
    required this.items,
  });
}

class ChecklistItem {
  final String id;
  final String name;
  final bool required;
  
  ChecklistItem({
    required this.id,
    required this.name,
    required this.required,
  });
}

class ChecklistRecord {
  final String id;
  final int? vehicleId;
  final String vehicleName;
  final int? deviceId; // ID do dispositivo vinculado
  final String? deviceName; // Nome do dispositivo vinculado
  final int? driverId; // ID do motorista (opcional)
  final String? driverName; // Nome do motorista (opcional)
  final String templateId;
  final String templateName;
  final DateTime date;
  final bool completed;
  final List<ChecklistItemResult> items;
  final String inspectorName;
  final String? notes;
  
  ChecklistRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    this.deviceId,
    this.deviceName,
    this.driverId,
    this.driverName,
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.completed,
    required this.items,
    required this.inspectorName,
    this.notes,
  });
}

class ChecklistItemResult {
  final String itemId;
  final String itemName;
  final bool checked;
  final String? notes;
  
  ChecklistItemResult({
    required this.itemId,
    required this.itemName,
    required this.checked,
    this.notes,
  });
}
