import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Testes para API de Permissões de Páginas
/// 
/// Para executar: flutter test test/api_permissions_test.dart
/// 
/// IMPORTANTE: Configure as variáveis abaixo antes de executar os testes
void main() {
  group('API - Permissões de Páginas', () {
    // ============================================
    // CONFIGURAÇÃO - ALTERE AQUI
    // ============================================
    const String baseUrl = 'https://web.unnicatelemetria.com.br'; // URL do servidor
    // Token de exemplo - substitua por um token válido
    const String userApiHash = '\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G';
    const int testClientId = 1; // ID de um cliente de teste
    // ============================================

    late String apiBaseUrl;

    setUp(() {
      apiBaseUrl = '$baseUrl/api';
    });

    test('GET /api/user/permissions - Obter permissões do usuário', () async {
      final url = Uri.parse('$apiBaseUrl/user/permissions');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Obter Permissões do Usuário');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200, reason: 'Status code deve ser 200');

      final jsonData = json.decode(response.body);
      expect(jsonData['status'], 1, reason: 'Status da resposta deve ser 1');
      expect(jsonData['data'], isNotNull, reason: 'Data não deve ser null');
      
      if (jsonData['data']['permissions'] != null) {
        final permissions = jsonData['data']['permissions'] as List;
        print('✅ Permissões encontradas: ${permissions.length}');
        
        final enabledCount = permissions.where((p) => p['isEnabled'] == true).length;
        print('✅ Permissões habilitadas: $enabledCount');
      }
    });

    test('GET /api/admin/pages - Listar todas as páginas (Admin)', () async {
      final url = Uri.parse('$apiBaseUrl/admin/pages');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Listar Todas as Páginas (Admin)');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        final pages = jsonData['data']['pages'] as List;
        print('✅ Total de páginas: ${pages.length}');
        
        // Agrupar por categoria
        final categories = <String, int>{};
        for (var page in pages) {
          final category = page['category'] as String;
          categories[category] = (categories[category] ?? 0) + 1;
        }
        
        print('✅ Páginas por categoria:');
        categories.forEach((category, count) {
          print('   $category: $count');
        });
      }
    });

    test('GET /api/admin/clients/{id}/permissions - Obter permissões de cliente', () async {
      final url = Uri.parse('$apiBaseUrl/admin/clients/$testClientId/permissions');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Obter Permissões de Cliente');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);
    });

    test('PUT /api/admin/clients/{id}/permissions - Atualizar permissões', () async {
      final url = Uri.parse('$apiBaseUrl/admin/clients/$testClientId/permissions');

      final requestBody = {
        'permissions': [
          {
            'pageId': 'bottom_nav_vehicles',
            'isEnabled': true,
          },
          {
            'pageId': 'bottom_nav_map',
            'isEnabled': true,
          },
          {
            'pageId': 'fleet_fuel_control',
            'isEnabled': true,
          },
          {
            'pageId': 'admin_my_users',
            'isEnabled': false,
          },
        ],
      };

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Atualizar Permissões');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1) {
        print('✅ Permissões atualizadas com sucesso');
        print('   Permissões atualizadas: ${jsonData['data']['updatedPermissions']}');
      }
    });

    test('PATCH /api/admin/clients/{id}/permissions/{pageId} - Atualizar permissão individual', () async {
      const pageId = 'fleet_fuel_control';
      final url = Uri.parse('$apiBaseUrl/admin/clients/$testClientId/permissions/$pageId');

      final requestBody = {
        'isEnabled': true,
      };

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Atualizar Permissão Individual');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);
    });

    test('POST /api/admin/clients/{id}/permissions/template - Aplicar template', () async {
      final url = Uri.parse('$apiBaseUrl/admin/clients/$testClientId/permissions/template');

      final requestBody = {
        'templateName': 'premium', // basic, premium, enterprise, full
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Aplicar Template de Permissões');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect([200, 201], contains(response.statusCode));

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1) {
        print('✅ Template aplicado com sucesso');
        print('   Template: ${jsonData['data']['templateName']}');
        print('   Permissões aplicadas: ${jsonData['data']['permissionsApplied']}');
      }
    });

    test('GET /api/admin/pages?category={category} - Filtrar por categoria', () async {
      final url = Uri.parse('$apiBaseUrl/admin/pages?category=Gestão de Frotas');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $userApiHash',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('\n📋 TESTE: Filtrar Páginas por Categoria');
      print('URL: $url');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      expect(response.statusCode, 200);

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        final pages = jsonData['data']['pages'] as List;
        print('✅ Páginas na categoria "Gestão de Frotas": ${pages.length}');
      }
    });
  });
}
