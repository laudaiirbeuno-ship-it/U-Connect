import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/services/map_cache_service.dart';
import 'package:uconnect/data/screens/map/services/custom_marker_service.dart';
import 'package:uconnect/provider/logo_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Serviço centralizado para limpar todos os caches do aplicativo
class CacheClearService {
  /// Limpar todos os caches do aplicativo
  static Future<void> clearAllCache() async {
    print('\n🧹 ========== LIMPANDO TODOS OS CACHES ==========');
    
    int clearedCount = 0;
    
    try {
      // 1. Limpar cache de veículos (MapCacheService)
      print('📦 Limpando cache de veículos...');
      await MapCacheService.clearCache();
      clearedCount++;
      print('✅ Cache de veículos limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de veículos: $e');
    }
    
    try {
      // 2. Limpar cache de marcadores (CustomMarkerService)
      print('📍 Limpando cache de marcadores...');
      CustomMarkerService.clearCache();
      clearedCount++;
      print('✅ Cache de marcadores limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de marcadores: $e');
    }
    
    try {
      // 3. Limpar cache de logos (LogoProvider)
      print('🖼️ Limpando cache de logos...');
      final logoProvider = LogoProvider();
      await logoProvider.clearLogoCache();
      clearedCount++;
      print('✅ Cache de logos limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de logos: $e');
    }
    
    // Nota: Cache de endereços é limpo automaticamente quando necessário
    // pois é um método de instância do HistoryAdvancedController
    
    try {
      // 5. Limpar cache de imagens (DefaultCacheManager)
      print('🖼️ Limpando cache de imagens...');
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      clearedCount++;
      print('✅ Cache de imagens limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache de imagens: $e');
    }
    
    try {
      // 6. Limpar dados temporários do SharedPreferences relacionados a cache
      print('💾 Limpando dados temporários do SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      
      // Lista de chaves de cache conhecidas
      final cacheKeys = [
        'map_vehicles_cache',
        'map_vehicles_cache_timestamp',
        'map_settings_',
        // Adicionar outras chaves de cache se necessário
      ];
      
      // Remover chaves de cache (incluindo variações por usuário)
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        for (final cacheKey in cacheKeys) {
          if (key.contains(cacheKey)) {
            await prefs.remove(key);
            print('   🗑️ Removido: $key');
          }
        }
      }
      
      clearedCount++;
      print('✅ Dados temporários limpos');
    } catch (e) {
      print('❌ Erro ao limpar SharedPreferences: $e');
    }
    
    print('\n✅ ========== LIMPEZA CONCLUÍDA ==========');
    print('📊 Total de caches limpos: $clearedCount');
    print('=' * 50 + '\n');
  }
  
  /// Limpar apenas cache de veículos
  static Future<void> clearVehiclesCache() async {
    await MapCacheService.clearCache();
  }
  
  /// Limpar apenas cache de marcadores
  static void clearMarkersCache() {
    CustomMarkerService.clearCache();
  }
  
  /// Limpar apenas cache de imagens
  static Future<void> clearImagesCache() async {
    final cacheManager = DefaultCacheManager();
    await cacheManager.emptyCache();
  }
  
  /// Obter informações sobre os caches
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final info = <String, dynamic>{};
    
    try {
      final cacheAge = await MapCacheService.getCacheAge();
      info['vehicles_cache_age'] = cacheAge != null ? '${cacheAge}s' : 'N/A';
      info['vehicles_cache_valid'] = await MapCacheService.isCacheValid();
    } catch (e) {
      info['vehicles_cache_error'] = e.toString();
    }
    
    try {
      final cacheHealth = CustomMarkerService.checkCacheHealth();
      info['markers_cache_health'] = cacheHealth ? 'OK' : 'Needs cleanup';
    } catch (e) {
      info['markers_cache_error'] = e.toString();
    }
    
    return info;
  }
}
