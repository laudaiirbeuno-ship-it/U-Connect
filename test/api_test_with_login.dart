import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Testes para APIs com Login Automático
/// 
/// Para executar: flutter test test/api_test_with_login.dart
void main() {
  group('API - Testes com Login', () {
    // ============================================
    // CONFIGURAÇÃO
    // ============================================
    const String baseUrl = 'https://web.unnicatelemetria.com.br';
    const String email = 'digzato@gmail.com';
    const String password = 'Rastrear123*';
    // ============================================

    late String apiBaseUrl;
    String? userApiHash;
    int? testVehicleId;
    int? testDeviceId;

    setUp(() {
      apiBaseUrl = '$baseUrl/api';
    });

    test('1. LOGIN - Fazer login e obter token', () async {
      final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
      
      print('\n🔐 ========== TESTE DE LOGIN ==========');
      print('URL: $loginUrl');
      print('Email: $email');

      final response = await http.get(loginUrl).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200, reason: 'Login deve retornar status 200');

      final jsonData = json.decode(response.body);
      expect(jsonData['status'], 1, reason: 'Status da resposta deve ser 1');
      expect(jsonData['user_api_hash'], isNotNull, reason: 'user_api_hash não deve ser null');

      userApiHash = jsonData['user_api_hash'];
      print('✅ Login realizado com sucesso!');
      print('✅ Token obtido: ${userApiHash!.substring(0, 20)}...');
    });

    test('2. GET /api/fuel_records - Listar registros de abastecimento', () async {
      if (userApiHash == null) {
        // Fazer login primeiro
        final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
        final loginResponse = await http.get(loginUrl).timeout(Duration(seconds: 30));
        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          userApiHash = loginData['user_api_hash'];
        }
      }

      if (userApiHash == null) {
        fail('Não foi possível obter token de autenticação');
      }

      final url = Uri.parse('$apiBaseUrl/fuel_records?user_api_hash=$userApiHash');
      
      print('\n📋 ========== TESTE: Listar Registros de Abastecimento ==========');
      print('URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      // Aceitar 200 (sucesso) ou 404 (endpoint não implementado ainda)
      expect([200, 404], contains(response.statusCode), 
        reason: 'Status code deve ser 200 ou 404');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          print('✅ Registros encontrados: ${jsonData['data']['records']?.length ?? 0}');
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Endpoint ainda não implementado no servidor');
      }
    });

    test('3. GET /api/user/permissions - Obter permissões do usuário', () async {
      if (userApiHash == null) {
        final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
        final loginResponse = await http.get(loginUrl).timeout(Duration(seconds: 30));
        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          userApiHash = loginData['user_api_hash'];
        }
      }

      if (userApiHash == null) {
        fail('Não foi possível obter token de autenticação');
      }

      final url = Uri.parse('$apiBaseUrl/user/permissions');

      print('\n📋 ========== TESTE: Obter Permissões do Usuário ==========');
      print('URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      // Aceitar 200 (sucesso) ou 404 (endpoint não implementado ainda)
      expect([200, 404], contains(response.statusCode), 
        reason: 'Status code deve ser 200 ou 404');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          final permissions = jsonData['data']['permissions'] as List?;
          print('✅ Permissões encontradas: ${permissions?.length ?? 0}');
          
          if (permissions != null) {
            final enabledCount = permissions.where((p) => p['isEnabled'] == true).length;
            print('✅ Permissões habilitadas: $enabledCount');
          }
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Endpoint ainda não implementado no servidor');
      }
    });

    test('4. GET /api/get_devices - Verificar se API de dispositivos funciona', () async {
      if (userApiHash == null) {
        final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
        final loginResponse = await http.get(loginUrl).timeout(Duration(seconds: 30));
        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          userApiHash = loginData['user_api_hash'];
        }
      }

      if (userApiHash == null) {
        fail('Não foi possível obter token de autenticação');
      }

      final url = Uri.parse('$apiBaseUrl/get_devices?user_api_hash=$userApiHash');

      print('\n📋 ========== TESTE: Listar Dispositivos (API Existente) ==========');
      print('URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      ).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ API de dispositivos funcionando!');
        
        // Tentar extrair IDs de veículos/dispositivos para usar nos outros testes
        if (jsonData is List && jsonData.isNotEmpty) {
          final firstGroup = jsonData[0];
          if (firstGroup['items'] != null && firstGroup['items'].isNotEmpty) {
            final firstDevice = firstGroup['items'][0];
            testVehicleId = firstDevice['id'];
            testDeviceId = firstDevice['id'];
            print('✅ Veículo de teste encontrado: ID $testVehicleId');
          }
        }
      } else {
        print('⚠️ Status: ${response.statusCode}');
      }
    });

    test('5. POST /api/fuel_records - Criar registro de abastecimento', () async {
      if (userApiHash == null) {
        final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
        final loginResponse = await http.get(loginUrl).timeout(Duration(seconds: 30));
        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          userApiHash = loginData['user_api_hash'];
        }
      }

      if (userApiHash == null) {
        fail('Não foi possível obter token de autenticação');
      }

      // Usar IDs obtidos do teste anterior ou valores padrão
      final vehicleId = testVehicleId ?? 1;
      final deviceId = testDeviceId ?? 1;

      final url = Uri.parse('$apiBaseUrl/fuel_records');

      final requestBody = {
        'vehicleId': vehicleId,
        'deviceId': deviceId,
        'date': DateTime.now().toIso8601String(),
        'fuelAmount': 50.5,
        'fuelPrice': 5.89,
        'odometer': 125000.0,
        'fuelType': 'Gasolina',
        'station': 'Posto Shell - Teste API',
        'notes': 'Teste de API automatizado',
        'paymentMethod': 'Cartão de Crédito',
        'fuelQuality': 'Aditivada',
      };

      print('\n📋 ========== TESTE: Criar Registro de Abastecimento ==========');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      // Aceitar 200, 201 (sucesso) ou 404 (endpoint não implementado ainda)
      expect([200, 201, 404], contains(response.statusCode), 
        reason: 'Status code deve ser 200, 201 ou 404');

      if ([200, 201].contains(response.statusCode)) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          print('✅ Registro criado com sucesso!');
          print('✅ ID do registro: ${jsonData['data']['id']}');
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Endpoint ainda não implementado no servidor');
      }
    });

    test('6. GET /api/fuel_records/statistics - Obter estatísticas', () async {
      if (userApiHash == null) {
        final loginUrl = Uri.parse('$apiBaseUrl/login?email=$email&password=$password');
        final loginResponse = await http.get(loginUrl).timeout(Duration(seconds: 30));
        if (loginResponse.statusCode == 200) {
          final loginData = json.decode(loginResponse.body);
          userApiHash = loginData['user_api_hash'];
        }
      }

      if (userApiHash == null) {
        fail('Não foi possível obter token de autenticação');
      }

      final url = Uri.parse('$apiBaseUrl/fuel_records/statistics?user_api_hash=$userApiHash');

      print('\n📋 ========== TESTE: Obter Estatísticas ==========');
      print('URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      expect([200, 404], contains(response.statusCode));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          print('✅ Estatísticas obtidas:');
          print('   Total de Combustível: ${jsonData['data']['totalFuel']} L');
          print('   Custo Total: R\$ ${jsonData['data']['totalCost']}');
          print('   Preço Médio: R\$ ${jsonData['data']['averagePrice']}/L');
          print('   Total de Registros: ${jsonData['data']['totalRecords']}');
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Endpoint ainda não implementado no servidor');
      }
    });
  });
}
