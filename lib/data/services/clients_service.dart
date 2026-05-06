import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/model/client.dart';

/// Serviço para gerenciar clientes usando os endpoints da documentação
/// Endpoints:
/// - GET /api/clients - Listar clientes
/// - GET /api/clients/statistics - Estatísticas
/// - GET /api/clients/{id} - Buscar cliente por ID
/// - POST /api/clients - Criar cliente
/// - PUT /api/clients/{id} - Atualizar cliente
/// - DELETE /api/clients/{id} - Excluir cliente
/// - POST /api/clients/set-active - Ativar/desativar clientes
/// - GET /api/clients/{id}/devices - Dispositivos do cliente
/// - GET /api/clients/check-email - Verificar email
/// - GET /api/clients/check-phone - Verificar telefone
/// - GET /api/clients/search-cep - Buscar CEP
class ClientsService {
  String get baseUrl => StaticVarMethod.baseurlall;

  Future<Map<String, String>> _getHeaders() async {
    final token = StaticVarMethod.user_api_hash ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Converte lista de mapas (strings ou números) para lista de números (IDs)
  /// O endpoint /api/clients requer available_maps como array de números
  List<int> _convertMapsToIds(List<dynamic> maps) {
    return maps.map((map) {
      if (map is int) {
        return map;
      } else if (map is String) {
        // Mapear strings comuns para IDs
        switch (map.toLowerCase()) {
          case 'google':
            return 2;
          case 'mapbox':
            return 3;
          case 'osm':
          case 'openstreetmap':
            return 1;
          default:
            // Tentar converter string para número
            return int.tryParse(map) ?? 2; // Padrão: Google (2)
        }
      } else {
        // Tentar converter para int
        return int.tryParse(map.toString()) ?? 2;
      }
    }).toList();
  }

  /// Listar clientes
  /// GET /api/clients
  Future<ClientsResponse> getClients({
    String? searchPhrase,
    String? status,
    String? contractHas,
    String? searchDevice,
    int page = 1,
    int limit = 25,
    String sortBy = 'email',
    String sort = 'asc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sorting[sort_by]': sortBy,
      'sorting[sort]': sort,
    };
    
    if (searchPhrase != null && searchPhrase.isNotEmpty) {
      queryParams['search_phrase'] = searchPhrase;
    }
    
    if (status != null && status.isNotEmpty) {
      queryParams['filter[status]'] = status;
    }
    
    if (contractHas != null && contractHas.isNotEmpty) {
      queryParams['filter[contract.has]'] = contractHas;
    }
    
    if (searchDevice != null && searchDevice.isNotEmpty) {
      queryParams['search_device'] = searchDevice;
    }
    
    final uri = Uri.parse('$baseUrl/api/clients').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return ClientsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erro ao buscar clientes: ${response.statusCode}');
    }
  }

  /// Buscar estatísticas
  /// GET /api/clients/statistics
  Future<ClientsStatistics> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/statistics'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ClientsStatistics.fromJson(data['data']);
    } else {
      throw Exception('Erro ao buscar estatísticas: ${response.statusCode}');
    }
  }

  /// Buscar cliente por ID
  /// GET /api/clients/{id}
  Future<Client> getClient(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/$id'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Client.fromJson(data['data']);
    } else if (response.statusCode == 404) {
      throw Exception('Cliente não encontrado');
    } else {
      throw Exception('Erro ao buscar cliente: ${response.statusCode}');
    }
  }

  /// Criar cliente
  /// POST /api/clients
  /// Campos obrigatórios: email, password, password_confirmation, available_maps, group_id, name, client (com first_name e last_name)
  Future<Client> createClient({
    required String email,
    required String name,
    required String password,
    required List<String> availableMaps,
    required int groupId,
    String? phoneNumber,
    String status = 'active',
    Address? address,
    PaymentInfo? paymentInfo,
    String? firstName,
    String? lastName,
  }) async {
    // Separar nome em first_name e last_name
    final nameParts = name.split(' ');
    final firstNameValue = firstName ?? nameParts.first;
    final lastNameValue = lastName ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    
    // Converter available_maps para números (IDs) - o endpoint requer números
    final mapsAsIds = _convertMapsToIds(availableMaps);
    
    final body = {
      'email': email,
      'name': name,
      'password': password,
      'password_confirmation': password,
      'available_maps': mapsAsIds, // Enviar como array de números
      'group_id': groupId,
      'client': {
        'first_name': firstNameValue,
        'last_name': lastNameValue,
      },
      if (phoneNumber != null) 'phone_number': phoneNumber,
      'status': status,
      'active': true,
      if (address != null) 'address': address.toJson(),
      if (paymentInfo != null) 'paymentInfo': paymentInfo.toJson(),
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/clients'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Client.fromJson(data['data']);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar cliente');
      } catch (e) {
        throw Exception('Erro ao criar cliente: ${response.statusCode} - ${response.body}');
      }
    }
  }

  /// Atualizar cliente
  /// PUT /api/clients/{id}
  Future<Client> updateClient({
    required int id,
    required String email,
    required List<String> availableMaps,
    String? name,
    String? phoneNumber,
    String? status,
    String? password,
    Address? address,
    PaymentInfo? paymentInfo,
  }) async {
    // Converter available_maps para números (IDs) - o endpoint requer números
    final mapsAsIds = _convertMapsToIds(availableMaps);
    
    final body = <String, dynamic>{
      'email': email,
      'available_maps': mapsAsIds, // Enviar como array de números
    };
    
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (status != null) body['status'] = status;
    if (password != null) {
      body['password'] = password;
      body['password_confirmation'] = password;
    }
    if (address != null) body['address'] = address.toJson();
    if (paymentInfo != null) body['paymentInfo'] = paymentInfo.toJson();
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/clients/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Client.fromJson(data['data']);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao atualizar cliente');
      } catch (e) {
        throw Exception('Erro ao atualizar cliente: ${response.statusCode} - ${response.body}');
      }
    }
  }

  /// Excluir cliente
  /// DELETE /api/clients/{id}
  Future<void> deleteClient(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/clients/$id'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return;
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao excluir cliente');
      } catch (e) {
        throw Exception('Erro ao excluir cliente: ${response.statusCode} - ${response.body}');
      }
    }
  }

  /// Ativar/desativar clientes
  /// POST /api/clients/set-active
  Future<void> setClientsActive({
    required List<int> ids,
    required bool active,
  }) async {
    final body = {
      'ids': ids,
      'active': active,
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/clients/set-active'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return;
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao atualizar status');
      } catch (e) {
        throw Exception('Erro ao atualizar status: ${response.statusCode} - ${response.body}');
      }
    }
  }

  /// Buscar dispositivos do cliente
  /// GET /api/clients/{id}/devices
  Future<List<Device>> getClientDevices(int clientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/$clientId/devices'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((item) => Device.fromJson(item))
          .toList();
    } else {
      throw Exception('Erro ao buscar dispositivos: ${response.statusCode}');
    }
  }

  /// Verificar email
  /// GET /api/clients/check-email?email={email}
  Future<bool> checkEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/check-email').replace(
        queryParameters: {'email': email},
      ),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    } else {
      throw Exception('Erro ao verificar email: ${response.statusCode}');
    }
  }

  /// Verificar telefone
  /// GET /api/clients/check-phone?phone={phone}
  Future<bool> checkPhone(String phone) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/check-phone').replace(
        queryParameters: {'phone': phone},
      ),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] ?? false;
    } else {
      throw Exception('Erro ao verificar telefone: ${response.statusCode}');
    }
  }

  /// Buscar CEP
  /// GET /api/clients/search-cep?cep={cep}
  Future<Address> searchCEP(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api/clients/search-cep').replace(
        queryParameters: {'cep': cleanCep},
      ),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Address.fromJson(data['data']);
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar CEP');
      } catch (e) {
        throw Exception('Erro ao buscar CEP: ${response.statusCode} - ${response.body}');
      }
    }
  }
}
