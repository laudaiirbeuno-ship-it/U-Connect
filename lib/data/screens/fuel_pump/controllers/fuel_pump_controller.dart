import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/services/fleet_management_service.dart';

/// Controller para controle de bomba de combustível
class FuelPumpController extends ChangeNotifier {
  List<deviceItems> _vehicles = [];
  List<FuelPumpRecord> _pumpRecords = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  String? _selectedVehicleId;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Estatísticas
  double _totalFuelPumped = 0.0;
  double _totalCost = 0.0;
  int _totalRecords = 0;
  Map<String, double> _vehicleFuelPumped = {}; // Consumo por veículo
  
  // Getters
  List<deviceItems> get vehicles => _vehicles;
  List<FuelPumpRecord> get pumpRecords => _pumpRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedVehicleId => _selectedVehicleId;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  double get totalFuelPumped => _totalFuelPumped;
  double get totalCost => _totalCost;
  int get totalRecords => _totalRecords;
  Map<String, double> get vehicleFuelPumped => _vehicleFuelPumped;
  
  FuelPumpController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadVehicles();
      await _loadPumpRecords();
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
  
  Future<void> _loadPumpRecords() async {
    // Carregar registros de bomba (integração com serviço de gestão de frota)
    final fuelRecords = FleetManagementService().fuelRecords;
    
    // Converter registros de abastecimento em registros de bomba
    _pumpRecords = fuelRecords.map((record) {
      return FuelPumpRecord(
        id: record.id,
        vehicleId: record.vehicleId,
        vehicleName: record.vehicleName,
        date: record.date,
        fuelAmount: record.fuelAmount,
        fuelPrice: record.fuelPrice,
        totalCost: record.totalCost,
        pumpNumber: record.station.isNotEmpty ? record.station : 'N/A',
        operatorName: record.driverName ?? '',
        fuelType: record.fuelType,
        odometer: record.odometer,
      );
    }).toList();
    
    // Aplicar filtros
    if (_selectedVehicleId != null) {
      _pumpRecords = _pumpRecords
          .where((r) => r.vehicleId?.toString() == _selectedVehicleId)
          .toList();
    }
    
    _pumpRecords = _pumpRecords
        .where((r) => r.date.isAfter(_fromDate.subtract(Duration(days: 1))) &&
                     r.date.isBefore(_toDate.add(Duration(days: 1))))
        .toList();
    
    // Ordenar por data (mais recente primeiro)
    _pumpRecords.sort((a, b) => b.date.compareTo(a.date));
  }
  
  void _calculateStatistics() {
    _totalFuelPumped = _pumpRecords.fold(0.0, (sum, record) => sum + record.fuelAmount);
    _totalCost = _pumpRecords.fold(0.0, (sum, record) => sum + record.totalCost);
    _totalRecords = _pumpRecords.length;
    
    // Calcular por veículo
    _vehicleFuelPumped.clear();
    for (var record in _pumpRecords) {
      if (record.vehicleId != null) {
        final vehicleId = record.vehicleId.toString();
        _vehicleFuelPumped[vehicleId] = 
            (_vehicleFuelPumped[vehicleId] ?? 0.0) + record.fuelAmount;
      }
    }
  }
  
  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _loadPumpRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    _loadPumpRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> addPumpRecord(FuelPumpRecord record) async {
    _pumpRecords.insert(0, record);
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> deletePumpRecord(String recordId) async {
    _pumpRecords.removeWhere((r) => r.id == recordId);
    _calculateStatistics();
    notifyListeners();
  }
}

class FuelPumpRecord {
  final String id;
  final int? vehicleId;
  final String vehicleName;
  final DateTime date;
  final double fuelAmount;
  final double fuelPrice;
  final double totalCost;
  final String pumpNumber;
  final String operatorName;
  final String fuelType;
  final double odometer;
  
  FuelPumpRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.date,
    required this.fuelAmount,
    required this.fuelPrice,
    required this.totalCost,
    required this.pumpNumber,
    required this.operatorName,
    required this.fuelType,
    required this.odometer,
  });
}
