import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/device_health_data.dart';
import '../../config/static.dart';
import '../../storage/user_repository.dart';

class HealthCheckService {
  final String baseUrl;

  HealthCheckService({String? baseUrl}) 
      : baseUrl = (baseUrl == null || baseUrl.isEmpty) 
          ? UserRepository.getServerURL() 
          : baseUrl;

  Future<Map<String, dynamic>> getDevices({
    String? search,
    String? status,
    int? signalLevel,
    String? batteryLevel,
  }) async {
    final token = StaticVarMethod.user_api_hash;
    if (token == null || token.isEmpty) {
      throw Exception('Token não configurado');
    }

    final uri = Uri.parse('$baseUrl/api/health-check/devices').replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (signalLevel != null) 'signal_level': signalLevel.toString(),
        if (batteryLevel != null && batteryLevel.isNotEmpty) 
          'battery_level': batteryLevel,
      },
    );

    print('\n📡 ========== CHAMADA API HEALTH-CHECK/DEVICES ==========');
    print('🌐 URL: ${uri.toString().replaceAll(token, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🔑 Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('❌ Timeout ao buscar dispositivos');
          throw Exception('Timeout ao buscar dispositivos');
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body (primeiros 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Resposta recebida com sucesso');
        
        if (data['status'] == 1 || data['status'] == true) {
          final devicesList = data['data']?['devices'] ?? data['devices'] ?? [];
          final statsData = data['data']?['stats'] ?? data['stats'] ?? {};
          
          print('📱 Dispositivos encontrados: ${devicesList.length}');
          print('📊 Stats: ${statsData.toString()}');
          
          final devices = (devicesList as List)
              .map((d) {
                try {
                  return DeviceHealthData.fromJson(d);
                } catch (e) {
                  print('⚠️ Erro ao parsear dispositivo: $e');
                  print('   Dados: $d');
                  return null;
                }
              })
              .where((d) => d != null)
              .cast<DeviceHealthData>()
              .toList();
          
          return {
            'devices': devices,
            'stats': HealthStats.fromJson(statsData),
          };
        } else {
          final errorMsg = data['message'] ?? 'Erro ao buscar dispositivos';
          print('❌ Erro na resposta: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erro ao buscar dispositivos: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Exceção ao buscar dispositivos: $e');
      print('📚 Stack Trace: $stackTrace');
      rethrow;
    } finally {
      print('=' * 60);
    }
  }

  Future<Map<String, dynamic>> getDeviceDetails(int deviceId) async {
    final token = StaticVarMethod.user_api_hash;
    if (token == null || token.isEmpty) {
      throw Exception('Token não configurado');
    }

    final uri = Uri.parse('$baseUrl/api/health-check/devices/$deviceId');

    print('\n📡 ========== CHAMADA API HEALTH-CHECK/DEVICES/$deviceId ==========');
    print('🌐 URL: ${uri.toString().replaceAll(token, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    print('🔑 Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('❌ Timeout ao buscar detalhes do dispositivo');
          throw Exception('Timeout ao buscar detalhes do dispositivo');
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body (primeiros 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Resposta recebida com sucesso');
        
        if (data['status'] == 1 || data['status'] == true) {
          final deviceData = data['data']?['device'] ?? data['device'] ?? {};
          final healthData = data['data']?['health_data'] ?? data['health_data'] ?? {};
          
          print('📱 Device Data: ${deviceData.toString()}');
          print('💚 Health Data: ${healthData.toString()}');
          
          try {
            final health = DeviceHealthData.fromJson(healthData);
            return {
              'device': deviceData,
              'health_data': health,
            };
          } catch (e) {
            print('⚠️ Erro ao parsear health_data: $e');
            print('   Dados: $healthData');
            throw Exception('Erro ao processar dados de saúde do dispositivo: $e');
          }
        } else {
          final errorMsg = data['message'] ?? 'Erro ao buscar detalhes';
          print('❌ Erro na resposta: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erro ao buscar detalhes: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Exceção ao buscar detalhes: $e');
      print('📚 Stack Trace: $stackTrace');
      rethrow;
    } finally {
      print('=' * 60);
    }
  }
}
