import 'package:flutter/material.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/services/fleet_management_service.dart';
import 'package:uconnect/data/screens/fuel_control/controllers/fuel_control_controller.dart';

class FuelConsumptionController extends ChangeNotifier {
  bool _isLoading = false;
  double _fuelToday = 0.0;
  double _fuelWeek = 0.0;
  double _fuelMonth = 0.0;
  double _fuelTotal = 0.0;
  
  List<VehicleFuelData> _vehicleFuelData = [];
  
  bool get isLoading => _isLoading;
  double get fuelToday => _fuelToday;
  double get fuelWeek => _fuelWeek;
  double get fuelMonth => _fuelMonth;
  double get fuelTotal => _fuelTotal;
  List<VehicleFuelData> get vehicleFuelData => _vehicleFuelData;

  Future<void> loadFuelData(List<deviceItems> devices) async {
    _isLoading = true;
    notifyListeners();

    _fuelToday = 0.0;
    _fuelWeek = 0.0;
    _fuelMonth = 0.0;
    _fuelTotal = 0.0;
    _vehicleFuelData.clear();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    // Carregar registros de abastecimento reais
    final fuelService = FleetManagementService();
    final fuelRecords = fuelService.fuelRecords;

    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    String formatTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    for (var device in devices) {
      final deviceId = device.id?.toString() ?? '';
      if (deviceId.isEmpty) continue;

      double vehicleFuelToday = 0.0;
      double vehicleFuelWeek = 0.0;
      double vehicleFuelMonth = 0.0;
      double vehicleConsumption = 0.0; // Consumo real em km/L
      double vehicleDistance = 0.0; // Distância percorrida

      try {
        // Buscar registros de abastecimento reais para este veículo
        final vehicleFuelRecords = fuelRecords.where((r) => 
          r.vehicleId != null && r.vehicleId.toString() == deviceId
        ).toList();

        // Ordenar por data (mais antigo primeiro)
        vehicleFuelRecords.sort((a, b) => a.date.compareTo(b.date));

        // Calcular consumo real baseado em abastecimentos e km percorridos
        if (vehicleFuelRecords.length >= 2) {
          double totalDistance = 0.0;
          double totalFuel = 0.0;

          for (int i = 1; i < vehicleFuelRecords.length; i++) {
            final prevRecord = vehicleFuelRecords[i - 1];
            final currentRecord = vehicleFuelRecords[i];

            // Calcular distância percorrida entre abastecimentos
            final distance = (currentRecord.odometer - prevRecord.odometer).abs();
            if (distance > 0 && currentRecord.fuelAmount > 0) {
              totalDistance += distance;
              totalFuel += currentRecord.fuelAmount;
            }
          }

          if (totalFuel > 0) {
            vehicleConsumption = totalDistance / totalFuel; // km/L
            vehicleDistance = totalDistance;
          }
        }

        // Calcular consumo por período baseado nos abastecimentos reais
        for (var record in vehicleFuelRecords) {
          if (record.date.isAfter(todayStart) || record.date.isAtSameMomentAs(todayStart)) {
            vehicleFuelToday += record.fuelAmount;
          }
          if (record.date.isAfter(weekStart)) {
            vehicleFuelWeek += record.fuelAmount;
          }
          if (record.date.isAfter(monthStart) || record.date.isAtSameMomentAs(monthStart)) {
            vehicleFuelMonth += record.fuelAmount;
          }
        }

        _fuelToday += vehicleFuelToday;
        _fuelWeek += vehicleFuelWeek;
        _fuelMonth += vehicleFuelMonth;

        // Adicionar dados do veículo (mesmo sem abastecimentos, mostrar o veículo)
        _vehicleFuelData.add(VehicleFuelData(
          vehicle: device,
          fuelToday: vehicleFuelToday,
          fuelWeek: vehicleFuelWeek,
          fuelMonth: vehicleFuelMonth,
          fuelTotal: vehicleFuelMonth,
          realConsumption: vehicleConsumption, // Consumo real em km/L
          distanceTraveled: vehicleDistance, // Distância percorrida
        ));
      } catch (e) {
        print('Erro geral ao processar dispositivo $deviceId: $e');
      }
    }

    _fuelTotal = _fuelMonth; // Total aproximado
    _vehicleFuelData.sort((a, b) => b.fuelMonth.compareTo(a.fuelMonth)); // Ordenar por consumo mensal

    _isLoading = false;
    notifyListeners();
  }
}

class VehicleFuelData {
  final deviceItems vehicle;
  final double fuelToday;
  final double fuelWeek;
  final double fuelMonth;
  final double fuelTotal;
  final double realConsumption; // Consumo real em km/L
  final double distanceTraveled; // Distância percorrida em km

  VehicleFuelData({
    required this.vehicle,
    required this.fuelToday,
    required this.fuelWeek,
    required this.fuelMonth,
    required this.fuelTotal,
    this.realConsumption = 0.0,
    this.distanceTraveled = 0.0,
  });
}

