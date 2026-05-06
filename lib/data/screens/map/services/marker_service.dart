import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/storage/user_repository.dart';

class MarkerService {
  static const String _baseUrl = "https://web.unnicatelemetria.com.br";
  
  /// Carregar dados dos veículos diretamente do servidor
  static Future<List<deviceItems>> loadVehiclesFromServer() async {
    try {
      print('🌐 Carregando veículos diretamente do servidor...');
      
      final url = "${UserRepository.getServerURL()}/api/get_devices"
          "?lang=br&user_api_hash=${StaticVarMethod.user_api_hash}";
      
      print('📡 URL da requisição: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 Status da resposta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        print('✅ Dados recebidos do servidor');
        print('📈 Total de grupos: ${jsonData.length}');
        
        List<deviceItems> vehicles = [];
        
        for (var i = 0; i < jsonData.length; i++) {
          final devices = Devices.fromJson(jsonData[i]);
          if (devices.items != null) {
            vehicles.addAll(devices.items!);
          }
        }
        
        print('🚗 Total de veículos carregados: ${vehicles.length}');
        
        // Log detalhado dos primeiros veículos
        for (int i = 0; i < (vehicles.length > 3 ? 3 : vehicles.length); i++) {
          final vehicle = vehicles[i];
          print('   ${i + 1}. ${vehicle.name ?? 'Sem nome'}');
          print('      📍 Posição: ${vehicle.lat}, ${vehicle.lng}');
          print('      🎯 IMEI: ${vehicle.deviceData?.imei}');
          print('      🖼️ Ícone: ${vehicle.icon?.path}');
          print('      📏 Velocidade: ${vehicle.speed ?? 0} km/h');
        }
        
        if (vehicles.length > 3) {
          print('   ... e mais ${vehicles.length - 3} veículos');
        }
        
        return vehicles;
        
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('📄 Body: ${response.body}');
        return [];
      }
      
    } catch (e) {
      print('❌ Erro ao carregar veículos do servidor: $e');
      return [];
    }
  }
  
  /// Carregar dados de um veículo específico com mais detalhes
  static Future<Map<String, dynamic>?> loadVehicleDetails(String deviceId) async {
    try {
      print('🔍 Carregando detalhes do veículo: $deviceId');
      
      final url = "${UserRepository.getServerURL()}/api/get_device_details"
          "?device_id=$deviceId&user_api_hash=${StaticVarMethod.user_api_hash}";
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('✅ Detalhes do veículo carregados');
        print('📊 Dados extras: ${data.keys.join(', ')}');
        
        return data;
        
      } else {
        print('❌ Erro ao carregar detalhes: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Erro ao carregar detalhes do veículo: $e');
      return null;
    }
  }
  
  /// Atualizar posição de um veículo específico
  static Future<LatLng?> updateVehiclePosition(String deviceId) async {
    try {
      print('📍 Atualizando posição do veículo: $deviceId');
      
      final url = "${UserRepository.getServerURL()}/api/get_last_position"
          "?device_id=$deviceId&user_api_hash=${StaticVarMethod.user_api_hash}";
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['lat'] != null && data['lng'] != null) {
          // Função auxiliar para converter dynamic para double com segurança
          double? _toDouble(dynamic value) {
            if (value == null) return null;
            if (value is double) return value;
            if (value is int) return value.toDouble();
            if (value is num) return value.toDouble();
            if (value is String) {
              final parsed = double.tryParse(value);
              return parsed;
            }
            return null;
          }
          
          final lat = _toDouble(data['lat']);
          final lng = _toDouble(data['lng']);
          if (lat == null || lng == null) return null;
          
          final newPosition = LatLng(lat, lng);
          
          print('✅ Posição atualizada: $newPosition');
          return newPosition;
        }
      }
      
      return null;
      
    } catch (e) {
      print('❌ Erro ao atualizar posição: $e');
      return null;
    }
  }
  
  /// Carregar ícones personalizados do servidor
  static Future<String> getVehicleIconFromServer(deviceItems vehicle) async {
    try {
      // Se o veículo tem um caminho de ícone definido, usar ele
      if (vehicle.icon?.path != null && vehicle.icon!.path!.isNotEmpty) {
        final iconUrl = "$_baseUrl${vehicle.icon!.path!}";
        print('🎨 Usando ícone personalizado: $iconUrl');
        return iconUrl;
      }
      
      // Senão, usar ícone padrão baseado no tipo de dispositivo
      final defaultIcon = "$_baseUrl/images/device_icons/rotating/1.png";
      print('🎨 Usando ícone padrão: $defaultIcon');
      return defaultIcon;
      
    } catch (e) {
      print('❌ Erro ao obter ícone: $e');
      return "$_baseUrl/images/device_icons/rotating/1.png";
    }
  }
  
  /// Carregar marcadores com dados frescos do servidor
  static Future<List<deviceItems>> refreshVehicleData() async {
    try {
      print('🔄 Atualizando dados dos veículos...');
      
      final freshVehicles = await loadVehiclesFromServer();
      
      if (freshVehicles.isNotEmpty) {
        // Atualizar dados locais se necessário
        print('✅ ${freshVehicles.length} veículos atualizados do servidor');
        
        // Log de estatísticas
        final onlineVehicles = freshVehicles.where((v) => 
          v.lat != null && v.lng != null && v.lat != 0 && v.lng != 0).length;
        final movingVehicles = freshVehicles.where((v) => 
          (v.speed ?? 0) > 0).length;
        
        print('📊 Estatísticas atualizadas:');
        print('   🟢 Online: $onlineVehicles/${freshVehicles.length}');
        print('   🚗 Em movimento: $movingVehicles/${freshVehicles.length}');
      }
      
      return freshVehicles;
      
    } catch (e) {
      print('❌ Erro ao atualizar dados: $e');
      return [];
    }
  }
  
  /// Verificar se há novos dados no servidor
  static Future<bool> hasServerUpdates() async {
    try {
      final url = "${UserRepository.getServerURL()}/api/check_updates"
          "?user_api_hash=${StaticVarMethod.user_api_hash}";
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_updates'] == true;
      }
      
      return false;
      
    } catch (e) {
      print('⚠️ Erro ao verificar atualizações: $e');
      return true; // Em caso de erro, assumir que há atualizações
    }
  }
}
