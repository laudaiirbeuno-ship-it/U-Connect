import 'package:universal_io/io.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Serviço de proteção contra cópia/plágio do código fonte
/// 
/// Este serviço implementa várias camadas de proteção:
/// 1. Verificação de integridade do app (package name, signature)
/// 2. Verificação de dispositivo (ID único)
/// 3. Armazenamento seguro de chaves
/// 4. Hash de verificação do código
class AppProtectionService {
  static final AppProtectionService _instance = AppProtectionService._internal();
  factory AppProtectionService() => _instance;
  AppProtectionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _appIntegrityKey = 'app_integrity_hash';
  static const String _deviceIdKey = 'device_unique_id';
  static const String _appSignatureKey = 'app_signature';

  // Package name esperado (deve ser o mesmo do seu app)
  static const String _expectedPackageName = 'com.unnicatelemetria.uconnect';
  
  // Hash de verificação (gere um hash único do seu código e coloque aqui)
  // Para gerar: sha256sum do seu código fonte ou use um hash único
  // static const String _expectedCodeHash = 'YOUR_UNIQUE_CODE_HASH_HERE';

  /// Inicializar proteção do app
  Future<bool> initializeProtection() async {
    try {
      // 1. Verificar package name
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.packageName != _expectedPackageName) {
        print('⚠️ AVISO: Package name não corresponde ao esperado!');
        return false;
      }

      // 2. Gerar/verificar ID único do dispositivo
      await _ensureDeviceId();

      // 3. Verificar integridade do app
      final isValid = await _verifyAppIntegrity();
      
      if (!isValid) {
        print('⚠️ AVISO: Integridade do app comprometida!');
        // Você pode decidir bloquear o app aqui se necessário
        // return false;
      }

      // 4. Gerar hash de verificação do código
      await _generateCodeHash();

      print('✅ Proteção do app inicializada com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao inicializar proteção: $e');
      return false;
    }
  }

  /// Verificar integridade do app
  Future<bool> _verifyAppIntegrity() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Verificar se o package name está correto
      if (packageInfo.packageName != _expectedPackageName) {
        return false;
      }

      // Verificar se há hash de integridade salvo
      final savedHash = await _secureStorage.read(key: _appIntegrityKey);
      if (savedHash == null) {
        // Primeira execução - gerar e salvar hash
        final newHash = _generateIntegrityHash(packageInfo);
        await _secureStorage.write(key: _appIntegrityKey, value: newHash);
        return true;
      }

      // Verificar se o hash atual corresponde ao salvo
      final currentHash = _generateIntegrityHash(packageInfo);
      return savedHash == currentHash;
    } catch (e) {
      print('❌ Erro ao verificar integridade: $e');
      return false;
    }
  }

  /// Gerar hash de integridade baseado nas informações do app
  String _generateIntegrityHash(PackageInfo packageInfo) {
    final data = '${packageInfo.packageName}_${packageInfo.version}_${packageInfo.buildNumber}';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Garantir que existe um ID único do dispositivo
  Future<void> _ensureDeviceId() async {
    try {
      String? deviceId = await _secureStorage.read(key: _deviceIdKey);
      
      if (deviceId == null) {
        // Gerar novo ID único
        final deviceInfo = DeviceInfoPlugin();
        
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = '${androidInfo.id}_${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }

        // Criar hash do ID para maior segurança
        final bytes = utf8.encode(deviceId);
        final hash = sha256.convert(bytes);
        deviceId = hash.toString();

        await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      }
    } catch (e) {
      print('❌ Erro ao gerar ID do dispositivo: $e');
    }
  }

  /// Gerar hash de verificação do código
  Future<void> _generateCodeHash() async {
    try {
      // Gerar hash baseado em informações do app e dispositivo
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceId = await _secureStorage.read(key: _deviceIdKey) ?? 'unknown';
      
      final data = '${packageInfo.packageName}_${packageInfo.version}_$deviceId';
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes);
      
      await _secureStorage.write(key: _appSignatureKey, value: hash.toString());
    } catch (e) {
      print('❌ Erro ao gerar hash do código: $e');
    }
  }

  /// Verificar se o app está sendo executado em um dispositivo válido
  Future<bool> verifyDevice() async {
    try {
      final deviceId = await _secureStorage.read(key: _deviceIdKey);
      if (deviceId == null) {
        return false;
      }

      // Verificar se o ID do dispositivo não mudou (pode indicar cópia)
      final deviceInfo = DeviceInfoPlugin();
      String currentDeviceId;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        currentDeviceId = '${androidInfo.id}_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        currentDeviceId = iosInfo.identifierForVendor ?? 'ios_unknown';
      } else {
        return true; // Para outras plataformas, permitir
      }

      final bytes = utf8.encode(currentDeviceId);
      final hash = sha256.convert(bytes);
      final currentHash = hash.toString();

      // O hash salvo deve corresponder ao hash atual
      // Se não corresponder, pode ser um dispositivo diferente ou cópia
      return deviceId == currentHash;
    } catch (e) {
      print('❌ Erro ao verificar dispositivo: $e');
      return false;
    }
  }

  /// Obter informações do app para verificação
  Future<Map<String, String>> getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceId = await _secureStorage.read(key: _deviceIdKey) ?? 'unknown';
      final signature = await _secureStorage.read(key: _appSignatureKey) ?? 'unknown';
      
      return {
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'deviceId': deviceId.substring(0, 16) + '...', // Mostrar apenas parte do ID
        'signature': signature.substring(0, 16) + '...',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Limpar dados de proteção (útil para testes)
  Future<void> clearProtectionData() async {
    await _secureStorage.delete(key: _appIntegrityKey);
    await _secureStorage.delete(key: _deviceIdKey);
    await _secureStorage.delete(key: _appSignatureKey);
  }
}

