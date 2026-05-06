import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/driver_form_data.dart';
import 'package:uconnect/data/services/fleet_management_service.dart';

class FuelControlController extends ChangeNotifier {
  List<deviceItems> _vehicles = [];
  List<DriverData> _drivers = [];
  List<FuelRecord> _fuelRecords = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  String? _selectedVehicleId;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Estatísticas
  double _totalFuel = 0.0;
  double _totalCost = 0.0;
  double _averagePrice = 0.0;
  int _totalRecords = 0;
  
  // Consumo
  double _averageConsumption = 0.0; // km/litro
  double _totalDistance = 0.0; // km percorridos
  Map<String, double> _vehicleConsumption = {}; // Consumo por veículo
  Map<String, List<ConsumptionData>> _consumptionHistory = {}; // Histórico de consumo
  
  // Calibração de odômetro
  Map<String, double> _odometerCalibration = {}; // Diferença de calibração por veículo
  
  // Getters
  List<deviceItems> get vehicles => _vehicles;
  List<DriverData> get drivers => _drivers;
  List<FuelRecord> get fuelRecords => _fuelRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedVehicleId => _selectedVehicleId;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  double get totalFuel => _totalFuel;
  double get totalCost => _totalCost;
  double get averagePrice => _averagePrice;
  int get totalRecords => _totalRecords;
  double get averageConsumption => _averageConsumption;
  double get totalDistance => _totalDistance;
  Map<String, double> get vehicleConsumption => _vehicleConsumption;
  Map<String, List<ConsumptionData>> get consumptionHistory => _consumptionHistory;
  Map<String, double> get odometerCalibration => _odometerCalibration;
  
  FuelControlController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadVehicles();
      await _loadDrivers();
      await _loadFuelRecords();
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
  
  Future<void> _loadFuelRecords() async {
    // Carregar registros de abastecimento da API
    // TODO: Implementar chamada à API quando disponível
    _fuelRecords = [];
    
    // Em produção, isso viria da API:
    // final response = await gpsapis.getFuelRecords(...);
    // if (response != null) {
    //   _fuelRecords = response.map((r) => FuelRecord.fromJson(r)).toList();
    // }
    
    // Ordenar por data (mais recente primeiro)
    _fuelRecords.sort((a, b) => b.date.compareTo(a.date));
    
    // Atualizar serviço compartilhado
    FleetManagementService().updateFuelRecords(_fuelRecords);
    
    // Calcular histórico de consumo
    _calculateConsumptionHistory();
  }
  
  void _calculateStatistics() {
    _totalFuel = _fuelRecords.fold(0.0, (sum, record) => sum + record.fuelAmount);
    _totalCost = _fuelRecords.fold(0.0, (sum, record) => sum + record.totalCost);
    _averagePrice = _totalFuel > 0 ? _totalCost / _totalFuel : 0.0;
    _totalRecords = _fuelRecords.length;
    
    // Calcular consumo médio e distância total
    _calculateConsumption();
  }
  
  void _calculateConsumption() {
    _totalDistance = 0.0;
    _vehicleConsumption.clear();
    
    // Agrupar registros por veículo
    final vehicleRecords = <String, List<FuelRecord>>{};
    for (var record in _fuelRecords) {
      final vehicleId = record.vehicleId.toString();
      if (!vehicleRecords.containsKey(vehicleId)) {
        vehicleRecords[vehicleId] = [];
      }
      vehicleRecords[vehicleId]!.add(record);
    }
    
    // Calcular consumo por veículo
    for (var entry in vehicleRecords.entries) {
      final records = entry.value;
      if (records.length < 2) continue; // Precisa de pelo menos 2 registros
      
      // Ordenar por odômetro (crescente)
      records.sort((a, b) => a.odometer.compareTo(b.odometer));
      
      double totalDistance = 0.0;
      double totalFuel = 0.0;
      
      for (int i = 1; i < records.length; i++) {
        final prevRecord = records[i - 1];
        final currentRecord = records[i];
        
        final distance = currentRecord.odometer - prevRecord.odometer;
        if (distance > 0) {
          totalDistance += distance;
          totalFuel += currentRecord.fuelAmount;
        }
      }
      
      if (totalFuel > 0) {
        final consumption = totalDistance / totalFuel;
        _vehicleConsumption[entry.key] = consumption;
        _totalDistance += totalDistance;
      }
    }
    
    // Calcular consumo médio geral
    if (_totalFuel > 0 && _totalDistance > 0) {
      _averageConsumption = _totalDistance / _totalFuel;
    } else if (_vehicleConsumption.isNotEmpty) {
      _averageConsumption = _vehicleConsumption.values.reduce((a, b) => a + b) / _vehicleConsumption.length;
    } else {
      _averageConsumption = 0.0;
    }
  }
  
  void _calculateConsumptionHistory() {
    _consumptionHistory.clear();
    
    // Agrupar registros por veículo
    final vehicleRecords = <String, List<FuelRecord>>{};
    for (var record in _fuelRecords) {
      final vehicleId = record.vehicleId.toString();
      if (!vehicleRecords.containsKey(vehicleId)) {
        vehicleRecords[vehicleId] = [];
      }
      vehicleRecords[vehicleId]!.add(record);
    }
    
    // Calcular histórico de consumo por veículo
    for (var entry in vehicleRecords.entries) {
      final records = entry.value;
      if (records.length < 2) continue;
      
      // Ordenar por data (mais antigo primeiro)
      records.sort((a, b) => a.date.compareTo(b.date));
      
      final consumptionList = <ConsumptionData>[];
      
      for (int i = 1; i < records.length; i++) {
        final prevRecord = records[i - 1];
        final currentRecord = records[i];
        
        final distance = (currentRecord.odometer - prevRecord.odometer).abs();
        if (distance > 0 && currentRecord.fuelAmount > 0) {
          final consumption = distance / currentRecord.fuelAmount;
          consumptionList.add(ConsumptionData(
            date: currentRecord.date,
            consumption: consumption,
            distance: distance,
            fuelAmount: currentRecord.fuelAmount,
          ));
        }
      }
      
      _consumptionHistory[entry.key] = consumptionList;
    }
  }
  
  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _loadFuelRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  void setDateRange(DateTime from, DateTime to) {
    _fromDate = from;
    _toDate = to;
    _loadFuelRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> addFuelRecord(FuelRecord record) async {
    // Em produção, isso salvaria na API
    _fuelRecords.insert(0, record);
    
    // Atualizar serviço compartilhado
    FleetManagementService().addFuelRecord(record);
    
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> deleteFuelRecord(String recordId) async {
    // Em produção, isso deletaria na API
    _fuelRecords.removeWhere((r) => r.id == recordId);
    _calculateStatistics();
    _calculateConsumptionHistory();
    notifyListeners();
  }
  
  // Calibrar odômetro do veículo
  Future<void> calibrateOdometer(String vehicleId, double vehicleOdometer, double manualOdometer) async {
    // Calcular diferença
    final difference = manualOdometer - vehicleOdometer;
    _odometerCalibration[vehicleId] = difference;
    
    // Recalcular registros e estatísticas
    await _loadFuelRecords();
    _calculateStatistics();
    notifyListeners();
  }
  
  // Obter odômetro atual do veículo (com calibração aplicada)
  double getVehicleOdometer(deviceItems vehicle) {
    double baseOdometer = (vehicle.totalDistance != null) 
        ? double.tryParse(vehicle.totalDistance.toString()) ?? 0.0 
        : 0.0;
    
    final vehicleId = vehicle.id.toString();
    if (_odometerCalibration.containsKey(vehicleId)) {
      baseOdometer += _odometerCalibration[vehicleId]!;
    }
    
    return baseOdometer;
  }
  
  // Obter histórico de abastecimento de um veículo específico
  List<FuelRecord> getVehicleHistory(String? vehicleId) {
    if (vehicleId == null) return _fuelRecords;
    return _fuelRecords.where((r) => r.vehicleId.toString() == vehicleId).toList();
  }
}

class FuelRecord {
  final String id;
  final int? vehicleId;
  final String vehicleName;
  final int? deviceId; // ID do dispositivo vinculado
  final String? deviceName; // Nome do dispositivo vinculado
  final int? driverId; // ID do motorista (opcional)
  final String? driverName; // Nome do motorista (opcional)
  final DateTime date;
  final double fuelAmount; // Litros
  final double fuelPrice; // Preço por litro
  final double totalCost; // Custo total
  final double odometer; // Odômetro no momento do abastecimento
  final double currentOdometer; // Odômetro atual do veículo (NOVO)
  final String fuelType; // Tipo de combustível
  final String station; // Nome do posto
  final String? notes; // Observações
  final String? invoiceNumber; // Número da nota fiscal (NOVO)
  final String? paymentMethod; // Método de pagamento (NOVO)
  final double? previousOdometer; // Odômetro anterior (NOVO)
  final double? distanceSinceLastFuel; // Distância desde último abastecimento (NOVO)
  final double? consumptionSinceLastFuel; // Consumo desde último abastecimento (NOVO)
  final String? fuelQuality; // Qualidade do combustível (NOVO)
  
  FuelRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    this.deviceId,
    this.deviceName,
    this.driverId,
    this.driverName,
    required this.date,
    required this.fuelAmount,
    required this.fuelPrice,
    required this.totalCost,
    required this.odometer,
    required this.currentOdometer, // NOVO
    required this.fuelType,
    required this.station,
    this.notes,
    this.invoiceNumber, // NOVO
    this.paymentMethod, // NOVO
    this.previousOdometer, // NOVO
    this.distanceSinceLastFuel, // NOVO
    this.consumptionSinceLastFuel, // NOVO
    this.fuelQuality, // NOVO
  });
}

class ConsumptionData {
  final DateTime date;
  final double consumption; // km/litro
  final double distance; // km
  final double fuelAmount; // litros
  
  ConsumptionData({
    required this.date,
    required this.consumption,
    required this.distance,
    required this.fuelAmount,
  });
}
