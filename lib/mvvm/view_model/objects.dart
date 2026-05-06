import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/services/map_cache_service.dart';
import 'package:uconnect/services/cache_clear_service.dart';

class ObjectStore extends ChangeNotifier {
  List<deviceItems> _objects = [];
  bool _isLoading = false;
  String? _error;

  List<deviceItems> get objects => _objects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getObjects({bool forceRefresh = false}) async {
    try {
      print('\n🔄 ========== ObjectStore.getObjects() ==========');
      print('📡 user_api_hash: ${StaticVarMethod.user_api_hash}');
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Tentar carregar do cache primeiro (se não for refresh forçado)
      if (!forceRefresh) {
        final cachedVehicles = await MapCacheService.loadVehicles();
        if (cachedVehicles != null && cachedVehicles.isNotEmpty) {
          _objects = cachedVehicles;
          _isLoading = false;
          print('✅ ObjectStore carregado do cache: ${_objects.length} veículo(s)');
          notifyListeners();
          
          // Atualizar em background sem bloquear a UI
          _updateInBackground();
          return;
        }
      }

      // Se não há cache válido ou é refresh forçado, buscar da API
      print('🌐 Buscando veículos da API...');
      final result = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      
      print('📦 Resultado da API: ${result != null ? result.length : "null"} veículo(s)');
      
      if (result != null && result is List<deviceItems>) {
        _objects = result;
        _isLoading = false;
        
        // Salvar no cache após sucesso
        await MapCacheService.saveVehicles(_objects);
        
        print('✅ ObjectStore atualizado com ${_objects.length} veículo(s)');
        
        // Log detalhado dos primeiros 3 veículos
        if (_objects.isNotEmpty) {
          print('📋 Primeiros veículos carregados:');
          for (int i = 0; i < _objects.length && i < 3; i++) {
            final v = _objects[i];
            print('   ${i + 1}. ${v.name ?? "Sem nome"} (ID: ${v.id}) - Lat: ${v.lat}, Lng: ${v.lng}');
          }
        }
        
        notifyListeners();
      } else {
        _error = 'Erro ao buscar dispositivos';
        _isLoading = false;
        print('❌ Erro: resultado não é uma lista válida');
        notifyListeners();
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      _isLoading = false;
      print('❌ Erro ao carregar veículos: $e');
      print('📚 Stack Trace: $stackTrace');
      
      // Se houver erro, tentar usar cache mesmo expirado
      final cachedVehicles = await MapCacheService.loadVehicles();
      if (cachedVehicles != null && cachedVehicles.isNotEmpty) {
        _objects = cachedVehicles;
        print('⚠️ Usando cache expirado devido ao erro: ${_objects.length} veículo(s)');
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }
  
  /// Limpar todos os caches
  Future<void> clearAllCache() async {
    await CacheClearService.clearAllCache();
    _objects = [];
    notifyListeners();
  }
  
  /// Atualizar dados em background sem bloquear a UI
  Future<void> _updateInBackground() async {
    try {
      print('🔄 Atualizando dados em background...');
      final result = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      
      if (result != null && result is List<deviceItems>) {
        _objects = result;
        await MapCacheService.saveVehicles(_objects);
        print('✅ Dados atualizados em background: ${_objects.length} veículo(s)');
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Erro ao atualizar em background: $e');
    }
  }

  void clearObjects() {
    _objects = [];
    notifyListeners();
  }
}

