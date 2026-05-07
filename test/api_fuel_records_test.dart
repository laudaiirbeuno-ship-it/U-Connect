import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Testes para API de Controle de Abastecimento
/// 
/// Para executar: flutter test test/api_fuel_records_test.dart
/// 
/// IMPORTANTE: Configure as variáveis abaixo antes de executar os testes
void main() {
  group('API - Controle de Abastecimento', () {
    // ============================================
    // CONFIGURAÇÃO - ALTERE AQUI
    // ============================================
    const String baseUrl = 'https://web.unnicatelemetria.com.br'; // URL do servidor
    // Token de exemplo - substitua por um token válido
    const String userApiHash = '\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G';
    const int testVehicleId = 1; // ID de um veículo de teste
    const int testDeviceId = 1; // ID de um dispositivo de teste
    // ============================================

    late String apiBaseUrl;

    setUp(() {
      apiBaseUrl = '$baseUrl/api';
    });

    test('GET /api/fuel_records - Listar registros de abastecimento', () async {
      final url = Uri.parse('$apiBaseUrl/fuel_records?user_api_hash=$userApiHash');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Listar Registros de Abastecimento');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200, reason: 'Status code deve ser 200');

      final jsonData = json.decode(response.body);
      expect(jsonData['status'], 1, reason: 'Status da resposta deve ser 1');
      expect(jsonData['data'], isNotNull, reason: 'Data não deve ser null');
      
      if (jsonData['data']['records'] != null) {
        print('✅ Registros encontrados: ${jsonData['data']['records'].length}');
      }
    });

    test('GET /api/fuel_records - Listar com filtros', () async {
      final fromDate = DateTime.now().subtract(Duration(days: 30));
      final toDate = DateTime.now();
      
      final url = Uri.parse(
        '$apiBaseUrl/fuel_records?user_api_hash=$userApiHash'
        '&vehicle_id=$testVehicleId'
        '&from_date=${fromDate.toIso8601String().split('T')[0]}'
        '&to_date=${toDate.toIso8601String().split('T')[0]}'
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Listar com Filtros');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);
    });

    test('POST /api/fuel_records - Criar registro de abastecimento', () async {
      final url = Uri.parse('$apiBaseUrl/fuel_records');

      final requestBody = {
        'vehicleId': testVehicleId,
        'deviceId': testDeviceId,
        'date': DateTime.now().toIso8601String(),
        'fuelAmount': 50.5,
        'fuelPrice': 5.89,
        'odometer': 125000.0,
        'fuelType': 'Gasolina',
        'station': 'Posto Shell - Teste',
        'notes': 'Teste de API',
        'paymentMethod': 'Cartão de Crédito',
        'fuelQuality': 'Aditivada',
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Criar Registro de Abastecimento');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect([200, 201], contains(response.statusCode), 
        reason: 'Status code deve ser 200 ou 201');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        expect(jsonData['status'], 1);
        expect(jsonData['data'], isNotNull);
        
        if (jsonData['data']['id'] != null) {
          print('✅ Registro criado com ID: ${jsonData['data']['id']}');
        }
      }
    });

    test('GET /api/fuel_records/statistics - Obter estatísticas', () async {
      final url = Uri.parse(
        '$apiBaseUrl/fuel_records/statistics?user_api_hash=$userApiHash'
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Obter Estatísticas');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        print('✅ Estatísticas:');
        print('   Total de Combustível: ${jsonData['data']['totalFuel']} L');
        print('   Custo Total: R\$ ${jsonData['data']['totalCost']}');
        print('   Preço Médio: R\$ ${jsonData['data']['averagePrice']}/L');
        print('   Total de Registros: ${jsonData['data']['totalRecords']}');
      }
    });

    test('GET /api/fuel_records/consumption_history - Histórico de consumo', () async {
      final url = Uri.parse(
        '$apiBaseUrl/fuel_records/consumption_history?user_api_hash=$userApiHash'
        '&vehicle_id=$testVehicleId'
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Histórico de Consumo');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);
    });

    test('DELETE /api/fuel_records/{id} - Deletar registro', () async {
      // Primeiro, criar um registro para deletar
      final createUrl = Uri.parse('$apiBaseUrl/fuel_records');
      final createBody = {
        'vehicleId': testVehicleId,
        'deviceId': testDeviceId,
        'date': DateTime.now().toIso8601String(),
        'fuelAmount': 10.0,
        'fuelPrice': 5.0,
        'odometer': 1000.0,
        'fuelType': 'Gasolina',
        'station': 'Teste Delete',
      };

      final createResponse = await http.post(
        createUrl,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(createBody),
      );

      String? recordId;
      if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
        final createData = json.decode(createResponse.body);
        recordId = createData['data']?['id']?.toString();
      }

      if (recordId == null) {
        print('⚠️ Não foi possível criar registro para teste de delete');
        return;
      }

      // Agora deletar
      final deleteUrl = Uri.parse('$apiBaseUrl/fuel_records/$recordId');
      final deleteResponse = await http.delete(
        deleteUrl,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Deletar Registro');
      print('URL: $deleteUrl');
      print('Status Code: ${deleteResponse.statusCode}');
      print('Response Body: ${deleteResponse.body}');

      expect(deleteResponse.statusCode, 200);
    });
  });
}
