import 'package:uconnect/data/screens/fuel_control/controllers/fuel_control_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/driver_form_data.dart';

/// Serviço centralizado para gerenciamento de dados da frota
/// Integra: Abastecimento, Consumo, Km Percorrido, Bomba, Documentação
class FleetManagementService {
  static final FleetManagementService _instance = FleetManagementService._internal();
  factory FleetManagementService() => _instance;
  FleetManagementService._internal();

  // Cache de dados compartilhados
  List<FuelRecord> _fuelRecords = [];
  Map<String, double> _vehicleOdometer = {}; // vehicleId -> odômetro atual
  Map<String, DateTime> _lastFuelDate = {}; // vehicleId -> última data de abastecimento
  
  // Getters
  List<FuelRecord> get fuelRecords => _fuelRecords;
  Map<String, double> get vehicleOdometer => _vehicleOdometer;
  Map<String, DateTime> get lastFuelDate => _lastFuelDate;

  /// Atualizar registros de abastecimento
  void updateFuelRecords(List<FuelRecord> records) {
    _fuelRecords = records;
    _updateOdometerFromRecords();
  }

  /// Adicionar novo registro de abastecimento
  void addFuelRecord(FuelRecord record) {
    _fuelRecords.insert(0, record);
    _updateOdometerFromRecords();
  }

  /// Atualizar odômetro atual baseado nos registros
  void _updateOdometerFromRecords() {
    for (var record in _fuelRecords) {
      if (record.vehicleId != null) {
        final vehicleId = record.vehicleId.toString();
        final currentOdometer = _vehicleOdometer[vehicleId] ?? 0.0;
        
        // Atualizar odômetro se o registro for mais recente
        if (record.odometer > currentOdometer) {
          _vehicleOdometer[vehicleId] = record.odometer;
          _lastFuelDate[vehicleId] = record.date;
        }
      }
    }
  }

  /// Obter odômetro atual de um veículo
  double getVehicleOdometer(int? vehicleId) {
    if (vehicleId == null) return 0.0;
    return _vehicleOdometer[vehicleId.toString()] ?? 0.0;
  }

  /// Obter última data de abastecimento de um veículo
  DateTime? getLastFuelDate(int? vehicleId) {
    if (vehicleId == null) return null;
    return _lastFuelDate[vehicleId.toString()];
  }

  /// Calcular consumo médio de um veículo
  double calculateAverageConsumption(int? vehicleId) {
    if (vehicleId == null) return 0.0;
    
    final vehicleRecords = _fuelRecords
        .where((r) => r.vehicleId == vehicleId)
        .toList();
    
    if (vehicleRecords.length < 2) return 0.0;
    
    // Ordenar por odômetro
    vehicleRecords.sort((a, b) => a.odometer.compareTo(b.odometer));
    
    double totalDistance = 0.0;
    double totalFuel = 0.0;
    
    for (int i = 1; i < vehicleRecords.length; i++) {
      final distance = vehicleRecords[i].odometer - vehicleRecords[i - 1].odometer;
      if (distance > 0) {
        totalDistance += distance;
        totalFuel += vehicleRecords[i].fuelAmount;
      }
    }
    
    return totalFuel > 0 ? totalDistance / totalFuel : 0.0;
  }

  /// Calcular distância total percorrida de um veículo
  double calculateTotalDistance(int? vehicleId) {
    if (vehicleId == null) return 0.0;
    
    final vehicleRecords = _fuelRecords
        .where((r) => r.vehicleId == vehicleId)
        .toList();
    
    if (vehicleRecords.length < 2) return 0.0;
    
    vehicleRecords.sort((a, b) => a.odometer.compareTo(b.odometer));
    
    return vehicleRecords.last.odometer - vehicleRecords.first.odometer;
  }

  /// Obter estatísticas de combustível de um veículo
  Map<String, dynamic> getVehicleFuelStats(int? vehicleId) {
    if (vehicleId == null) {
      return {
        'totalFuel': 0.0,
        'totalCost': 0.0,
        'averagePrice': 0.0,
        'averageConsumption': 0.0,
        'totalDistance': 0.0,
        'recordCount': 0,
      };
    }
    
    final vehicleRecords = _fuelRecords
        .where((r) => r.vehicleId == vehicleId)
        .toList();
    
    final totalFuel = vehicleRecords.fold(0.0, (sum, r) => sum + r.fuelAmount);
    final totalCost = vehicleRecords.fold(0.0, (sum, r) => sum + r.totalCost);
    final averagePrice = totalFuel > 0 ? totalCost / totalFuel : 0.0;
    final averageConsumption = calculateAverageConsumption(vehicleId);
    final totalDistance = calculateTotalDistance(vehicleId);
    
    return {
      'totalFuel': totalFuel,
      'totalCost': totalCost,
      'averagePrice': averagePrice,
      'averageConsumption': averageConsumption,
      'totalDistance': totalDistance,
      'recordCount': vehicleRecords.length,
    };
  }

  /// Limpar cache
  void clearCache() {
    _fuelRecords.clear();
    _vehicleOdometer.clear();
    _lastFuelDate.clear();
  }
}
