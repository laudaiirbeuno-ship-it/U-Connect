import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uconnect/config/static.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/data/datasources.dart' as gpsapis_module;
import '../models/antifurto_model.dart';

class AntifurtoService {
  // Verificar se há antifurto ativo para um veículo
  static Future<ActiveAnchorModel?> checkActiveAntifurto(int deviceId) async {
    try {
      final url = "${UserRepository.getServerURL()}/api/geofences/antifurto/check?device_id=$deviceId&user_api_hash=${StaticVarMethod.user_api_hash!}";
      
      print('\n📡 ========== VERIFICAR ANTIFURTO ATIVO ==========');
      print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Se o endpoint não existir, tentar buscar via geofences
        if (jsonData['has_active'] == null) {
          return await _checkActiveAntifurtoViaGeofences(deviceId);
        }
        
        if (jsonData['has_active'] == true && jsonData['active_anchor'] != null) {
          print('✅ Antifurto ativo encontrado');
          return ActiveAnchorModel.fromJson(jsonData['active_anchor']);
        }
        
        print('ℹ️ Nenhum antifurto ativo encontrado');
        return null;
      } else {
        // Se o endpoint não existir (404), tentar buscar via geofences
        if (response.statusCode == 404) {
          print('⚠️ Endpoint não encontrado, usando método alternativo');
          return await _checkActiveAntifurtoViaGeofences(deviceId);
        }
        
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao verificar antifurto ativo: $e');
      // Em caso de erro, tentar método alternativo
      return await _checkActiveAntifurtoViaGeofences(deviceId);
    }
  }

  // Método alternativo: buscar via geofences
  static Future<ActiveAnchorModel?> _checkActiveAntifurtoViaGeofences(int deviceId) async {
    try {
      final geofences = await gpsapis_module.gpsapis.getGeoFences(lang: 'br');
      
      if (geofences != null && geofences.isNotEmpty) {
        for (var geofence in geofences) {
          final isAnchor = geofence.isAnchor;
          final isActive = geofence.isActive;
          final isCircle = geofence.type == 'circle';
          
          if (!isAnchor || !isActive || !isCircle) continue;
          
          // Verificar por device_id
          if (geofence.device_id == deviceId && geofence.center != null && geofence.radius != null) {
            return ActiveAnchorModel(
              id: geofence.id ?? 0,
              name: geofence.name ?? 'Antifurto',
              deviceId: geofence.device_id,
              deviceName: null,
              radius: geofence.radius!,
              center: {
                'lat': geofence.center!.lat,
                'lng': geofence.center!.lng,
              },
              createdAt: geofence.created_at != null 
                  ? DateTime.parse(geofence.created_at!) 
                  : DateTime.now(),
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao verificar via geofences: $e');
      return null;
    }
  }

  // Ativar antifurto
  static Future<Map<String, dynamic>> activateAntifurto(AntifurtoModel antifurto) async {
    try {
      // Usar o endpoint /api/geofences se disponível, senão usar /api/add_geofence
      final url = "${UserRepository.getServerURL()}/api/geofences?user_api_hash=${StaticVarMethod.user_api_hash!}";
      
      print('\n📡 ========== ATIVAR ANTIFURTO ==========');
      print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
      
      final body = antifurto.toJson();
      print('📤 Body: ${json.encode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1) {
          print('✅ Antifurto ativado com sucesso!');
          return {
            'success': true,
            'data': jsonData['data'],
          };
        }
        
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Erro ao ativar antifurto',
        };
      } else {
        // Se o endpoint /api/geofences não existir, usar /api/add_geofence
        if (response.statusCode == 404) {
          return await _activateAntifurtoViaAddGeofence(antifurto);
        }
        
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao ativar antifurto',
        };
      }
    } catch (e) {
      print('❌ Erro ao ativar antifurto: $e');
      // Tentar método alternativo
      return await _activateAntifurtoViaAddGeofence(antifurto);
    }
  }

  // Método alternativo usando add_geofence
  static Future<Map<String, dynamic>> _activateAntifurtoViaAddGeofence(AntifurtoModel antifurto) async {
    try {
      final result = await gpsapis_module.gpsapis.addGeofence(
        name: antifurto.name,
        active: true,
        device_id: antifurto.deviceId,
        type: 'circle',
        lat: antifurto.centerLat,
        lng: antifurto.centerLng,
        radius: antifurto.radius,
        speed_limit: antifurto.alertSpeedLimit?.toInt(),
        movement_allowed: antifurto.alertMovement,
        polygon_color: antifurto.polygonColor,
        lang: 'br',
      );

      if (result != null && (result['status'] == 1 || result['geofence_id'] != null)) {
        return {
          'success': true,
          'data': result,
        };
      }
      
      return {
        'success': false,
        'message': result?['message'] ?? 'Erro ao ativar antifurto',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Desativar antifurto
  static Future<bool> deactivateAntifurto(int geofenceId) async {
    try {
      // Tentar usar DELETE /api/geofences/{id}
      final url = "${UserRepository.getServerURL()}/api/geofences/$geofenceId?user_api_hash=${StaticVarMethod.user_api_hash!}";
      
      print('\n📡 ========== DESATIVAR ANTIFURTO ==========');
      print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 1) {
          print('✅ Antifurto desativado com sucesso!');
          return true;
        }
      }
      
      // Se não funcionar, tentar método alternativo
      if (response.statusCode == 404) {
        return await _deactivateAntifurtoViaDestroy(geofenceId);
      }
      
      return false;
    } catch (e) {
      print('❌ Erro ao desativar antifurto: $e');
      // Tentar método alternativo
      return await _deactivateAntifurtoViaDestroy(geofenceId);
    }
  }

  // Método alternativo usando destroy_geofence
  static Future<bool> _deactivateAntifurtoViaDestroy(int geofenceId) async {
    try {
      final result = await gpsapis_module.gpsapis.destroyGeofence(id: geofenceId, lang: 'br');
      
      if (result != null && result['status'] == 1) {
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erro ao desativar via destroy: $e');
      return false;
    }
  }
}
