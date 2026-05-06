import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:uconnect/data/model/device_api.dart' as device_api;
import 'package:uconnect/data/model/admin_device.dart' as admin_device;

/// Controller para gerenciar dispositivos
class DevicesController extends ChangeNotifier {
  admin_device.DeviceListResponse? _devicesList;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  String? _selectedDeviceId; // Para o filtro de dispositivo
  String _searchQuery = '';

  // Getters
  admin_device.DeviceListResponse? get devicesList => _devicesList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _devicesList != null && _currentPage < _devicesList!.lastPage;
  String? get selectedDeviceId => _selectedDeviceId;
  String get searchQuery => _searchQuery;

  List<admin_device.DeviceItem> get devices => _devicesList?.data ?? [];

  List<admin_device.DeviceItem> get filteredDevices {
    List<admin_device.DeviceItem> tempDevices = devices;

    // Aplicar filtro por dispositivo selecionado
    if (_selectedDeviceId != null) {
      tempDevices = tempDevices
          .where((device) => device.id.toString() == _selectedDeviceId)
          .toList();
    }

    // Aplicar filtro de busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tempDevices = tempDevices.where((device) {
        return (device.name ?? '').toLowerCase().contains(query) ||
            (device.imei ?? '').toLowerCase().contains(query) ||
            (device.plateNumber ?? '').toLowerCase().contains(query) ||
            (device.simNumber ?? '').toLowerCase().contains(query);
      }).toList();
    }
    return tempDevices;
  }

  void setSelectedDeviceId(String? deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDeviceId = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Carregar lista de dispositivos
  Future<void> loadDevices({bool forceRefresh = false, int? page}) async {
    if (_isLoading && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final targetPage = page ?? _currentPage;
      print('\n🔄 ========== CARREGANDO DISPOSITIVOS ==========');
      print('📅 Data/Hora: ${DateTime.now()}');
      print('📄 Página: $targetPage');
      
      final admin_device.DeviceListResponse? list = await gpsapis.getDevices(page: targetPage);
      
      if (list != null) {
        if (forceRefresh || page != null) {
          _devicesList = list!;
          _currentPage = targetPage;
        } else {
          // Merge com lista existente para paginação
          final existingData = _devicesList?.data ?? [];
          _devicesList = admin_device.DeviceListResponse(
            status: list!.status,
            data: [...existingData, ...list!.data],
            pagination: list!.pagination,
          );
        }
        print('✅ Dispositivos carregados: ${list.data.length}');
      } else {
        _error = 'Nenhum dado retornado da API';
        print('⚠️ Nenhum dado retornado da API');
      }
    } catch (e, stackTrace) {
      _error = 'Erro ao carregar dispositivos: $e';
      print('\n❌ ========== ERRO AO CARREGAR DISPOSITIVOS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
    } finally {
      _isLoading = false;
      notifyListeners();
      print('\n✅ Processo de carregamento finalizado');
      print('=' * 60 + '\n');
    }
  }

  /// Carregar próxima página
  Future<void> loadNextPage() async {
    if (hasMorePages && !_isLoading) {
      _currentPage++;
      await loadDevices(page: _currentPage);
    }
  }

  /// Obter dispositivo específico
  Future<admin_device.DeviceItem?> getDevice(int deviceId) async {
    try {
      final response = await gpsapis.getDevice(deviceId);
      return response?.data;
    } catch (e) {
      print('❌ Erro ao obter dispositivo: $e');
      return null;
    }
  }



  /// Deletar dispositivo
  Future<bool> deleteDevice(int deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bool success = await gpsapis.deleteDevice(deviceId);
      
      if (success) {
        // Recarregar lista
        await loadDevices(forceRefresh: true, page: _currentPage);
        return true;
      } else {
        _error = 'Erro ao deletar dispositivo';
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterar status do dispositivo
  Future<bool> changeDeviceStatus(int deviceId, bool active) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = admin_device.UpdateDeviceStatusRequest(
        deviceId: deviceId,
        active: active,
      );
      
      final response = await gpsapis.changeDeviceStatus(deviceId, request);
      
      if (response != null && response['status'] == 1) {
        // Recarregar lista
        await loadDevices(forceRefresh: true, page: _currentPage);
        return true;
      } else {
        _error = response?['message'] ?? 'Erro ao alterar status';
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alterar data de expiração do dispositivo
  Future<bool> changeDeviceExpiration(int deviceId, String? expirationDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = admin_device.UpdateDeviceExpirationRequest(
        deviceId: deviceId,
        expirationDate: expirationDate,
      );
      
      final response = await gpsapis.changeDeviceExpiration(deviceId, request);
      
      if (response != null && response['status'] == 1) {
        // Recarregar lista
        await loadDevices(forceRefresh: true, page: _currentPage);
        return true;
      } else {
        _error = response?['message'] ?? 'Erro ao alterar data de expiração';
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Atribuir usuário ao dispositivo
  Future<bool> assignUserToDevice(int deviceId, {int? userId, String? email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = admin_device.AssignUserToDeviceRequest(
        userId: userId,
        email: email,
      );
      
      final response = await gpsapis.assignUserToDevice(deviceId, request);
      
      if (response != null && response['status'] == 1) {
        return true;
      } else {
        _error = response?['message'] ?? 'Erro ao atribuir usuário';
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Revogar usuário do dispositivo
  Future<bool> revokeUserFromDevice(int deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await gpsapis.revokeUserFromDevice(deviceId);
      
      if (response != null && response['status'] == 1) {
        return true;
      } else {
        _error = response?['message'] ?? 'Erro ao revogar usuário';
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listar usuários do dispositivo
  Future<admin_device.DeviceUsersResponse?> getDeviceUsers(int deviceId) async {
    try {
      return await gpsapis.getDeviceUsers(deviceId);
    } catch (e) {
      print('❌ Erro ao listar usuários do dispositivo: $e');
      return null;
    }
  }
}

