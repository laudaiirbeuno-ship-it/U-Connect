import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/data/model/devices.dart';

/// Serviço de cache para dados do mapa - evita chamadas repetidas à API
class MapCacheService {
  static const String _cacheKey = 'map_vehicles_cache';
  static const String _cacheTimestampKey = 'map_vehicles_cache_timestamp';
  static const Duration _cacheValidDuration = Duration(minutes: 5); // Cache válido por 5 minutos
  
  /// Salvar veículos no cache usando toJson do deviceItems
  static Future<void> saveVehicles(List<deviceItems> vehicles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Converter lista de veículos para JSON usando o método toJson
      final vehiclesJson = vehicles.map((v) => v.toJson()).toList();
      
      await prefs.setString(_cacheKey, jsonEncode(vehiclesJson));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      print('💾 Cache salvo: ${vehicles.length} veículo(s)');
    } catch (e) {
      print('❌ Erro ao salvar cache: $e');
    }
  }
  
  /// Carregar veículos do cache
  static Future<List<deviceItems>?> loadVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar se cache existe
      final cacheData = prefs.getString(_cacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheData == null || cacheTimestamp == null) {
        print('📭 Cache não encontrado');
        return null;
      }
      
      // Verificar se cache ainda é válido
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      if (cacheAge > _cacheValidDuration.inMilliseconds) {
        print('⏰ Cache expirado (idade: ${cacheAge ~/ 1000}s)');
        await clearCache();
        return null;
      }
      
      // Converter JSON para lista de veículos usando fromJson
      final vehiclesJson = jsonDecode(cacheData) as List;
      final vehicles = vehiclesJson.map((json) => deviceItems.fromJson(json)).toList();
      
      print('✅ Cache carregado: ${vehicles.length} veículo(s) (idade: ${cacheAge ~/ 1000}s)');
      return vehicles;
    } catch (e) {
      print('❌ Erro ao carregar cache: $e');
      await clearCache();
      return null;
    }
  }
  
  /// Verificar se cache é válido
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) return false;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
      return cacheAge <= _cacheValidDuration.inMilliseconds;
    } catch (e) {
      return false;
    }
  }
  
  /// Limpar cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('🧹 Cache limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache: $e');
    }
  }
  
  /// Obter idade do cache em segundos
  static Future<int?> getCacheAge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) return null;
      
      return (DateTime.now().millisecondsSinceEpoch - cacheTimestamp) ~/ 1000;
    } catch (e) {
      return null;
    }
  }
}

