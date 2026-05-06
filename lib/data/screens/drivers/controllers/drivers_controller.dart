import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/driver_form_data.dart';

/// Controller para gerenciar motoristas
class DriversController extends ChangeNotifier {
  List<DriverData> _allDrivers = [];
  List<DriverData> _filteredDrivers = [];
  String? _selectedVehicleId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DriverData> get allDrivers => _allDrivers;
  List<DriverData> get filteredDrivers => _filteredDrivers;
  String? get selectedVehicleId => _selectedVehicleId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carregar motoristas da API
  Future<void> loadDrivers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('\n🔄 ========== INICIANDO CARREGAMENTO DE MOTORISTAS ==========');
      print('📅 Data/Hora: ${DateTime.now()}');
      print('🔄 Fazendo chamada para gpsapis.getUserDrivers()...');
      
      final startTime = DateTime.now();
      final drivers = await gpsapis.getUserDrivers();
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      
      if (drivers != null) {
        _allDrivers = drivers;
        _applyFilters();
        print('✅ ${_allDrivers.length} motorista(s) carregado(s) com sucesso!');
      } else {
        _allDrivers = [];
        _filteredDrivers = [];
        print('⚠️ API retornou null - nenhum motorista encontrado');
      }
    } catch (e, stackTrace) {
      _error = 'Erro ao carregar motoristas: $e';
      print('\n❌ ========== ERRO AO CARREGAR MOTORISTAS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      _allDrivers = [];
      _filteredDrivers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
      print('\n✅ Processo de carregamento finalizado');
    }
  }

  /// Obter dados para criar motorista
  Future<AddDriverDataResponse?> getAddDriverData() async {
    try {
      return await gpsapis.getAddDriverData();
    } catch (e) {
      print('❌ DriversController.getAddDriverData: Erro: $e');
      return null;
    }
  }

  /// Criar novo motorista
  Future<bool> createDriver(DriverFormData driverData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.addUserDriver(driverData);
      
      if (response != null && response.status == 1) {
        // Recarregar lista de motoristas
        await loadDrivers();
        return true;
      } else {
        _error = 'Erro ao criar motorista';
        return false;
      }
    } catch (e) {
      _error = 'Erro ao criar motorista: $e';
      print('❌ DriversController.createDriver: Erro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obter dados para editar motorista
  Future<EditDriverDataResponse?> getEditDriverData(int driverId) async {
    try {
      return await gpsapis.getEditDriverData(driverId);
    } catch (e) {
      print('❌ DriversController.getEditDriverData: Erro: $e');
      return null;
    }
  }

  /// Editar motorista
  Future<bool> updateDriver(DriverFormData driverData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.editUserDriver(driverData);
      
      if (response != null && response.status == 1) {
        // Recarregar lista de motoristas
        await loadDrivers();
        return true;
      } else {
        _error = 'Erro ao atualizar motorista';
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar motorista: $e';
      print('❌ DriversController.updateDriver: Erro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Excluir motorista
  Future<bool> deleteDriver(int driverId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.destroyUserDriver(driverId);
      
      if (response != null && response.status == 1) {
        // Recarregar lista de motoristas
        await loadDrivers();
        return true;
      } else {
        _error = 'Erro ao excluir motorista';
        return false;
      }
    } catch (e) {
      _error = 'Erro ao excluir motorista: $e';
      print('❌ DriversController.deleteDriver: Erro: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Definir veículo selecionado no filtro
  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _applyFilters();
    notifyListeners();
  }

  /// Definir query de busca
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Aplicar filtros
  void _applyFilters() {
    _filteredDrivers = _allDrivers.where((driver) {
      // Filtro por veículo
      if (_selectedVehicleId != null && driver.deviceId != null) {
        if (driver.deviceId.toString() != _selectedVehicleId) {
          return false;
        }
      }

      // Filtro por busca (nome, telefone, email)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (driver.name ?? '').toLowerCase();
        final phone = (driver.phone ?? '').toLowerCase();
        final email = (driver.email ?? '').toLowerCase();
        
        if (!name.contains(query) && 
            !phone.contains(query) && 
            !email.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Limpar filtros
  void clearFilters() {
    _selectedVehicleId = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Buscar veículo associado ao motorista
  deviceItems? getVehicleForDriver(DriverData driver, List<deviceItems> vehicles) {
    if (driver.deviceId == null) return null;
    
    try {
      return vehicles.firstWhere(
        (vehicle) => vehicle.id.toString() == driver.deviceId.toString(),
      );
    } catch (e) {
      return null;
    }
  }
}
