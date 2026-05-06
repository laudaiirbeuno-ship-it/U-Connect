import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/service.dart';

/// Controller para gerenciar serviços de dispositivos
class ServicesController extends ChangeNotifier {
  Map<int, List<Service>> _servicesByDevice = {};
  Map<int, ServicePagination?> _paginationByDevice = {};
  Map<int, bool> _isLoadingByDevice = {};
  Map<int, String?> _errorByDevice = {};
  Map<int, int> _currentPageByDevice = {};
  Timer? _refreshTimer;

  // Getters
  List<Service> getServicesForDevice(int deviceId) {
    return _servicesByDevice[deviceId] ?? [];
  }

  ServicePagination? getPaginationForDevice(int deviceId) {
    return _paginationByDevice[deviceId];
  }

  bool isLoadingForDevice(int deviceId) {
    return _isLoadingByDevice[deviceId] ?? false;
  }

  String? getErrorForDevice(int deviceId) {
    return _errorByDevice[deviceId];
  }

  int getCurrentPageForDevice(int deviceId) {
    return _currentPageByDevice[deviceId] ?? 1;
  }

  bool hasMorePages(int deviceId) {
    final pagination = _paginationByDevice[deviceId];
    if (pagination == null) return false;
    final current = _currentPageByDevice[deviceId] ?? 1;
    final last = pagination.lastPage ?? 1;
    return current < last;
  }

  /// Carregar serviços de um dispositivo
  Future<void> loadServicesForDevice(int deviceId, {bool forceRefresh = false, int? page}) async {
    // Se já está carregando, não fazer nova chamada
    if (_isLoadingByDevice[deviceId] == true && !forceRefresh) {
      return;
    }

    final pageToLoad = page ?? 1;
    _isLoadingByDevice[deviceId] = true;
    _errorByDevice[deviceId] = null;
    notifyListeners();

    try {
      print('\n🔄 ========== CARREGANDO SERVIÇOS DO DISPOSITIVO ==========');
      print('📅 Data/Hora: ${DateTime.now()}');
      print('🔧 Device ID: $deviceId');
      print('📄 Página: $pageToLoad');
      
      final response = await gpsapis.getDeviceServices(deviceId, page: pageToLoad);
      
      if (response != null) {
        if (pageToLoad == 1 || forceRefresh) {
          // Primeira página ou refresh - substituir dados
          _servicesByDevice[deviceId] = response.data;
        } else {
          // Páginas seguintes - adicionar aos dados existentes
          final existing = _servicesByDevice[deviceId] ?? [];
          _servicesByDevice[deviceId] = [...existing, ...response.data];
        }
        
        _paginationByDevice[deviceId] = response.pagination;
        _currentPageByDevice[deviceId] = pageToLoad;
        
        print('✅ ${response.data.length} serviço(s) carregado(s) para o dispositivo $deviceId');
        print('   Total de serviços: ${response.pagination?.total ?? response.data.length}');
      } else {
        if (pageToLoad == 1) {
          _servicesByDevice[deviceId] = [];
          _paginationByDevice[deviceId] = null;
        }
        print('⚠️ Nenhum serviço retornado da API para o dispositivo $deviceId');
      }
    } catch (e, stackTrace) {
      _errorByDevice[deviceId] = 'Erro ao carregar serviços: $e';
      print('\n❌ ========== ERRO AO CARREGAR SERVIÇOS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      if (pageToLoad == 1) {
        _servicesByDevice[deviceId] = [];
      }
    } finally {
      _isLoadingByDevice[deviceId] = false;
      notifyListeners();
      print('\n✅ Processo de carregamento finalizado');
      print('=' * 60 + '\n');
    }
  }

  /// Carregar próxima página
  Future<void> loadNextPage(int deviceId) async {
    if (!hasMorePages(deviceId) || isLoadingForDevice(deviceId)) {
      return;
    }
    
    final nextPage = getCurrentPageForDevice(deviceId) + 1;
    await loadServicesForDevice(deviceId, page: nextPage);
  }

  /// Filtrar serviços por status
  List<Service> getFilteredServices(int deviceId, ServiceStatus? status) {
    final services = getServicesForDevice(deviceId);
    if (status == null) return services;
    return services.where((service) => service.status == status).toList();
  }

  /// Iniciar atualização automática
  void startAutoRefresh(int deviceId, {Duration interval = const Duration(minutes: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (timer) {
      loadServicesForDevice(deviceId, forceRefresh: true);
    });
  }

  /// Parar atualização automática
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}





































