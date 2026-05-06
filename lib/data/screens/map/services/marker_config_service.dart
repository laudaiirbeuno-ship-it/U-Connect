import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MarkerConfigService {
  /// Obter ID do usuário atual
  static Future<String> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        return userData['id']?.toString() ?? '0';
      }
      return '0';
    } catch (e) {
      print('❌ Erro ao obter ID do usuário: $e');
      return '0';
    }
  }

  /// Carregar configurações de marcadores salvas (isoladas por usuário)
  static Future<Map<int, VehicleMarkerConfig>> loadVehicleConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _getCurrentUserId();
      final configKey = 'vehicle_marker_configs_$userId';
      final configsJson = prefs.getString(configKey);
      
      if (configsJson == null) {
        return {};
      }
      
      final Map<String, dynamic> configs = jsonDecode(configsJson);
      final Map<int, VehicleMarkerConfig> result = {};
      
      configs.forEach((vehicleId, configData) {
        result[int.parse(vehicleId)] = VehicleMarkerConfig(
          markerTypeId: configData['markerTypeId'] ?? 'default',
          customImagePath: configData['customImagePath'],
        );
      });
      
      return result;
    } catch (e) {
      print('❌ Erro ao carregar configurações de marcadores: $e');
      return {};
    }
  }

  /// Obter configuração de um veículo específico
  static Future<VehicleMarkerConfig> getVehicleConfig(int vehicleId) async {
    final configs = await loadVehicleConfigs();
    return configs[vehicleId] ?? VehicleMarkerConfig(
      markerTypeId: 'default',
    );
  }

  /// Verificar se existe configuração para um veículo
  static Future<bool> hasConfig(int vehicleId) async {
    final configs = await loadVehicleConfigs();
    return configs.containsKey(vehicleId);
  }
}

class VehicleMarkerConfig {
  final String markerTypeId;
  final String? customImagePath; // Caminho para imagem customizada

  VehicleMarkerConfig({
    required this.markerTypeId,
    this.customImagePath,
  });
  
  /// Obter o ID do marcador (incluindo prefixo custom_ se for imagem customizada)
  String get effectiveMarkerTypeId {
    if (customImagePath != null && customImagePath!.isNotEmpty) {
      return 'custom_$customImagePath';
    }
    return markerTypeId;
  }
}
