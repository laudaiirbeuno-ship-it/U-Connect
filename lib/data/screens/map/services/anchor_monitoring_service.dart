import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:uconnect/config/static.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

/// Serviço responsável por monitorar âncoras e acionar bloqueio automático
/// quando o veículo sair da área da âncora
class AnchorMonitoringService {
  static final AnchorMonitoringService _instance = AnchorMonitoringService._internal();
  factory AnchorMonitoringService() => _instance;
  AnchorMonitoringService._internal();

  Timer? _monitoringTimer;
  final Map<String, DateTime> _lastBlockTime = {}; // deviceId -> última vez que bloqueou
  final Map<String, bool> _isBlocked = {}; // deviceId -> se está bloqueado
  static const Duration _checkInterval = Duration(seconds: 5); // Verificar a cada 5 segundos
  static const Duration _blockCooldown = Duration(minutes: 1); // Evitar bloqueios repetidos

  /// Iniciar monitoramento de âncoras
  void startMonitoring(MapController mapController, List<deviceItems> vehicles) {
    stopMonitoring(); // Parar monitoramento anterior se houver
    
    _monitoringTimer = Timer.periodic(_checkInterval, (timer) {
      _checkAnchors(mapController, vehicles);
    });
    
    print('🔵 Monitoramento de âncoras iniciado');
  }

  /// Parar monitoramento
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    print('🔴 Monitoramento de âncoras parado');
  }

  /// Verificar todas as âncoras ativas
  Future<void> _checkAnchors(MapController mapController, List<deviceItems> vehicles) async {
    for (var vehicle in vehicles) {
      // Verificar se o veículo tem âncora ativa
      final anchorInfo = mapController.getAnchorInfo(vehicle.id.toString());
      if (anchorInfo == null) continue;

      // Verificar se o veículo saiu da área da âncora
      final isOutside = mapController.checkVehicleOutsideAnchor(vehicle);
      
      if (isOutside) {
        // Verificar se já bloqueou recentemente (cooldown)
        final lastBlock = _lastBlockTime[vehicle.id.toString()];
        final now = DateTime.now();
        
        if (lastBlock == null || now.difference(lastBlock) > _blockCooldown) {
          // Verificar se já está bloqueado
          if (!(_isBlocked[vehicle.id.toString()] ?? false)) {
            await _triggerAutoBlock(vehicle, anchorInfo);
          }
        }
      } else {
        // Veículo voltou para dentro da âncora - resetar flag de bloqueio
        _isBlocked[vehicle.id.toString()] = false;
      }
    }
  }

  /// Acionar bloqueio automático do veículo
  Future<void> _triggerAutoBlock(deviceItems vehicle, AnchorInfo anchorInfo) async {
    try {
      print('🚨 VEHÍCULO SAIU DA ÂNCORA: ${vehicle.name} (ID: ${vehicle.id})');
      print('📍 Posição atual: ${vehicle.lat}, ${vehicle.lng}');
      print('📍 Posição da âncora: ${anchorInfo.center.latitude}, ${anchorInfo.center.longitude}');
      print('📏 Raio da âncora: ${anchorInfo.radius} metros');

      // Calcular distância atual
      final vehicleLat = CoordinateUtils.toDouble(vehicle.lat) ?? 0.0;
      final vehicleLng = CoordinateUtils.toDouble(vehicle.lng) ?? 0.0;
      
      if (vehicleLat == 0.0 || vehicleLng == 0.0) {
        print('❌ Coordenadas inválidas do veículo');
        return;
      }

      final distance = Geolocator.distanceBetween(
        anchorInfo.center.latitude,
        anchorInfo.center.longitude,
        vehicleLat,
        vehicleLng,
      );

      print('📏 Distância da âncora: ${distance.toStringAsFixed(2)} metros');

      // Registrar log da violação
      _logViolation(vehicle, anchorInfo, distance);

      // Enviar comando de bloqueio usando a API real
      await _sendBlockCommand(vehicle);

      // Marcar como bloqueado e registrar tempo
      _isBlocked[vehicle.id.toString()] = true;
      _lastBlockTime[vehicle.id.toString()] = DateTime.now();

      // Mostrar notificação ao usuário
      _showBlockNotification(vehicle, distance);

    } catch (e) {
      print('❌ Erro ao acionar bloqueio automático: $e');
    }
  }

  /// Enviar comando de bloqueio usando a API real
  Future<void> _sendBlockCommand(deviceItems vehicle) async {
    try {
      // Definir deviceId para o sistema de comandos
      StaticVarMethod.deviceId = vehicle.id.toString();
      StaticVarMethod.deviceName = vehicle.name ?? 'Veículo';

      // Preparar body do comando (formato esperado pela API)
      final requestBody = {
        'id': '',
        'device_id': vehicle.id.toString(),
        'type': 'engineStop', // Comando para parar o motor
      };

      print('📤 Enviando comando de bloqueio para veículo ${vehicle.id}...');
      
      // Enviar comando usando a API real
      final response = await gpsapis.sendCommands(requestBody);

      if (response.statusCode == 200) {
        print('✅ Comando de bloqueio enviado com sucesso!');
        
        // Tentar parsear resposta
        try {
          final responseData = json.decode(response.body);
          print('📦 Resposta da API: $responseData');
        } catch (e) {
          print('⚠️ Resposta não é JSON válido: ${response.body}');
        }
      } else {
        print('❌ Falha ao enviar comando de bloqueio. Status: ${response.statusCode}');
        print('📦 Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao enviar comando de bloqueio: $e');
      rethrow;
    }
  }

  /// Registrar log da violação
  void _logViolation(deviceItems vehicle, AnchorInfo anchorInfo, double distance) {
    final logMessage = '''
🚨 VIOLAÇÃO DE ÂNCORA DETECTADA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Veículo: ${vehicle.name} (ID: ${vehicle.id})
Data/Hora: ${DateTime.now().toString()}
Posição do veículo: ${vehicle.lat}, ${vehicle.lng}
Posição da âncora: ${anchorInfo.center.latitude}, ${anchorInfo.center.longitude}
Raio da âncora: ${anchorInfo.radius} metros
Distância atual: ${distance.toStringAsFixed(2)} metros
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    
    print(logMessage);
    
    // TODO: Salvar log em arquivo ou banco de dados se necessário
  }

  /// Mostrar notificação ao usuário
  void _showBlockNotification(deviceItems vehicle, double distance) {
    Fluttertoast.showToast(
      msg: '🚨 Veículo ${vehicle.name} saiu da âncora!\nDistância: ${distance.toStringAsFixed(0)}m\nBloqueio automático acionado.',
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Resetar estado de bloqueio para um veículo (útil quando desbloqueado manualmente)
  void resetBlockStatus(String deviceId) {
    _isBlocked[deviceId] = false;
    _lastBlockTime.remove(deviceId);
  }

  /// Verificar se um veículo está bloqueado
  bool isVehicleBlocked(String deviceId) {
    return _isBlocked[deviceId] ?? false;
  }

  /// Limpar todos os estados
  void clear() {
    _lastBlockTime.clear();
    _isBlocked.clear();
  }
}





































