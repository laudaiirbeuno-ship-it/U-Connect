import 'dart:convert';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/model/PositionHistory.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/data/model/history.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/utils/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uconnect/model/Alert.dart';
import 'package:uconnect/data/model/GeofenceModel.dart';
import 'package:uconnect/data/model/User.dart';
import 'package:uconnect/data/model/loginModel.dart';
import 'package:http/http.dart' as http;

import 'package:uconnect/data/model/admin_device.dart' as admin_device;
class gpsapis {
  static Map<String, String> headers = {};

  static final History_URL = "${UserRepository.getServerURL()}/api/get_history";
  static final registerUrl = "${UserRepository.getServerURL()}/api/register";

  static Future<admin_device.DeviceListResponse?> getDevices({int page = 1, int limit = 30}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getDevices");
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/get_devices?lang=br&user_api_hash=$userApiHash"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'page': page, 'limit': limit}),
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return admin_device.DeviceListResponse.fromJson(json.decode(response.body));
      } else {
        print("Erro ao carregar dispositivos: ${response.statusCode}");
        print("Corpo da resposta: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção ao carregar dispositivos: $e");
      return null;
    }
  }

  static Future<admin_device.DeviceResponse?> getDevice(int deviceId) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getDevice");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/get_device?lang=br&user_api_hash=$userApiHash&device_id=$deviceId"),
        headers: headers,
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return admin_device.DeviceResponse.fromJson(json.decode(response.body));
      } else {
        print("Erro ao carregar dispositivo: ${response.statusCode}");
        print("Corpo da resposta: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção ao carregar dispositivo: $e");
      return null;
    }
  }



  static Future<bool> deleteDevice(int deviceId) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return false;
    }

    try {
      final response = await http.get( // Assumindo GET para delete_device
        Uri.parse("${UserRepository.getServerURL()}/api/destroy_device?user_api_hash=$userApiHash&lang=br&device_id=$deviceId"),
        headers: headers,
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse['status'] == 1; // Supondo que a API retorna {'status': 1} para sucesso
      } else {
        print("Erro ao deletar dispositivo: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exceção ao deletar dispositivo: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> changeDeviceStatus(int deviceId, admin_device.UpdateDeviceStatusRequest request) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/change_active_device?user_api_hash=$userApiHash&device_id=$deviceId&lang=br"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao alterar status: ${response.body}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao alterar status: $e'};
    }
  }

  static Future<Map<String, dynamic>> changeDeviceExpiration(int deviceId, admin_device.UpdateDeviceExpirationRequest request) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/change_expiration_date?user_api_hash=$userApiHash&device_id=$deviceId&lang=br"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao alterar expiração: ${response.body}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao alterar expiração: $e'};
    }
  }

  static Future<Map<String, dynamic>> assignUserToDevice(int deviceId, admin_device.AssignUserToDeviceRequest request) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/assign_user_device?user_api_hash=$userApiHash&device_id=$deviceId&lang=br"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao atribuir usuário: ${response.body}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao atribuir usuário: $e'};
    }
  }

  static Future<Map<String, dynamic>> revokeUserFromDevice(int deviceId) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.get( // Assumindo GET para revoke
        Uri.parse("${UserRepository.getServerURL()}/api/revoke_user_device?user_api_hash=$userApiHash&device_id=$deviceId&lang=br"),
        headers: headers,
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao revogar usuário: ${response.body}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao revogar usuário: $e'};
    }
  }

  static Future<admin_device.DeviceUsersResponse?> getDeviceUsers(int deviceId) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getDeviceUsers");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/get_device_users?user_api_hash=$userApiHash&device_id=$deviceId&lang=br"),
        headers: headers,
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return admin_device.DeviceUsersResponse.fromJson(json.decode(response.body));
      } else {
        print("Erro ao listar usuários do dispositivo: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exceção ao listar usuários do dispositivo: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> getFinancialCharges({
    String? gateway,
    String? status,
    String? search,
    String? billingType,
    String? chargeType,
    int? page,
    int? perPage,
  }) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final queryParams = <String, String>{
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (gateway != null) 'gateway': gateway,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (billingType != null) 'billing_type': billingType,
        // chargeType: 'created' = apenas cobranças criadas pelo usuário
        // chargeType: 'oneoff' = apenas cobranças avulsas
        // chargeType: 'plan' = apenas cobranças de planos
        // Sem chargeType = todas as cobranças (padrão: apenas a pagar para usuário comum)
        if (chargeType != null) 'charge_type': chargeType,
      };

      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges").replace(queryParameters: queryParams),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar cobranças: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar cobranças: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFinancialCharge({required int id}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/$id"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar cobrança: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar cobrança: $e'};
    }
  }

  static Future<Map<String, dynamic>> syncFinancialCharge({required int id}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/$id/sync"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao sincronizar cobrança: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao sincronizar cobrança: $e'};
    }
  }

  static Future<Map<String, dynamic>> cancelFinancialCharge({required int id}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/$id/cancel"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao cancelar cobrança: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao cancelar cobrança: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFinancialChargeQrCode({required int id}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/$id/qrcode"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar QR code: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar QR code: $e'};
    }
  }

  // Buscar comprovantes
  static Future<Map<String, dynamic>> getFinancialReceipts({
    int? page,
    int? perPage,
  }) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final queryParams = <String, String>{
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
      };

      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/receipts").replace(queryParameters: queryParams),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar comprovantes: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar comprovantes: $e'};
    }
  }

  // Buscar comprovante de uma cobrança específica
  static Future<Map<String, dynamic>> getFinancialChargeReceipt({required int id}) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/$id/receipt"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar comprovante: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar comprovante: $e'};
    }
  }

  // Buscar estatísticas
  static Future<Map<String, dynamic>> getFinancialChargesStatistics() async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final response = await http.get(
        Uri.parse("${UserRepository.getServerURL()}/api/charges/statistics"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao carregar estatísticas: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao carregar estatísticas: $e'};
    }
  }

  static Future<Map<String, dynamic>> createFinancialCharge({
    // Campos para cobrança avulsa
    String? gateway,
    double? value,
    String? dueDate,
    String? description,
    String? billingType,
    int? customerId,
    String? customerName,
    String? customerEmail,
    String? customerDocument,
    String? customerPhone,
    // Campos para cobrança vinculada a plano
    int? planId,
    int? blockAfterDue, // 0 ou 1 (não boolean)
  }) async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      return {'status': 0, 'message': 'user_api_hash é null ou vazio'};
    }

    try {
      final body = <String, dynamic>{};
      
      // Se tem plan_id, é cobrança vinculada a plano
      if (planId != null) {
        body['plan_id'] = planId;
        body['customer_id'] = customerId;
        body['due_date'] = dueDate;
        body['billing_type'] = billingType;
        body['gateway'] = gateway;
        if (blockAfterDue != null) body['block_after_due'] = blockAfterDue; // 0 ou 1
        if (description != null) body['description'] = description;
      } else {
        // Cobrança avulsa
        body['gateway'] = gateway;
        body['value'] = value;
        body['due_date'] = dueDate;
        body['billing_type'] = billingType;
        body['customer_name'] = customerName;
        if (description != null) body['description'] = description;
        if (customerId != null) body['customer_id'] = customerId;
        if (customerEmail != null) body['customer_email'] = customerEmail;
        if (customerDocument != null) body['customer_document'] = customerDocument;
        if (customerPhone != null) body['customer_phone'] = customerPhone;
      }

      final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/charges"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userApiHash',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(minutes: 1));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {'status': 0, 'message': 'Erro ao criar cobrança: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 0, 'message': 'Exceção ao criar cobrança: $e'};
    }
  }


  // Métodos antigos para compatibilidade ou uso específico


  Future<http.Response> getlogin(String email, String password) async {
    print(UserRepository.getServerURL());
    print(
      Uri.parse(
        "https://web.unnicatelemetria.com.br/api/login?email=$email&password=$password",
      ),
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(
      Uri.parse(
        "https://web.unnicatelemetria.com.br/api/login?email=$email&password=$password",
      ),
    );

    print(response.statusCode);
    if (response.statusCode == 200) {
      var res = LoginModel.fromJson(json.decode(response.body));
      StaticVarMethod.user_api_hash = res.userApiHash;
      StaticVarMethod.username = email.toString();
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      await prefs.setBool("notival", true);
      return response;
    } else {
      print(response.statusCode);
      return response;
    }
  }

/*   Future<List<Devices>> getDevices(String? user_api_hash) async {
    //headers['Accept'] = "application/json";
    final response = await http.get(Uri.parse(Devices_URL + "?lang=en&user_api_hash=$user_api_hash"));
    if (response.statusCode == 200) {
      print(response.body);
     // return Devices.fromJson(json.decode(response.body));
      Iterable list = json.decode(response.body);
      return list.map((model) => Devices.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      List<Devices> list=[];
      return list;
    }
  }*/
  /*Future<List<Devices>> getDevices(String? user_api_hash)async {
    //headers['Accept'] = "application/json";
    String? udre=user_api_hash;
    final response = await http.get(Uri.parse(Devices_URL + "?lang=en&user_api_hash=$user_api_hash"));
    if (response.statusCode == 200) {
      //print(response.body);
      //return Devices.fromJson(json.decode(response.body));
      //Iterable list = json.decode(response.body);
      // return list.map((model) => Devices.fromJson(model)).toList();
      var jsonData = json.decode(response.body);
      try {
        List<Devices> list = [];
        list.clear();
        for (var i = 0; i < jsonData.length; i++) {
          Devices listModel = Devices.fromJson(jsonData[i]);
          list.add(listModel);
        }
        return list;
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
        List<Devices> list = [];
        return list;
      }
    } else {
      print(response.statusCode);
      List<Devices> list = [];
      return list;
    }
  }*/

  Future<List<EventsData>> getEventsList_new(String? user_api_hash) async {
    List<EventsData> list = [];

    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_events?lang=en&user_api_hash=$user_api_hash"));
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      /*for (var i = 0; i < jsonData[1].items!.data!.length; i++) {
          list.add(jsonData[1].items!.data![i]);
        }*/
      var events = Events.fromJson(response);
      for (var i = 0; i < events.items!.data!.length; i++) {
        list.add(events.items!.data![i]);
      }
      return list;
    } else {
      print(response.statusCode);
      //LoginModel model =new LoginModel();
      return list;
    }
  }

  getEventsList(String? user_api_hash) async {
    print("📋 getEventsList chamado");
    print("🔑 user_api_hash: ${user_api_hash?.substring(0, 20)}...");
    
    if (user_api_hash == null || user_api_hash.isEmpty) {
      print("❌ user_api_hash é null ou vazio");
      return <EventsData>[];
    }
    
    try {
      final response = await Session.apiGet(
        "${UserRepository.getServerURL()}/api/get_events?lang=br&limit=5000&user_api_hash=$user_api_hash"
      );
      
      print("📡 Resposta da API recebida");
      
      if (response == null) {
        print("⚠️ Resposta da API é null");
        return <EventsData>[];
      }

      var jsonData = json.decode(response.toString());
      print("✅ JSON decodificado com sucesso");
      
      try {
        List<EventsData> list = [];

        // Verificar se o JSON tem a estrutura esperada
        if (jsonData == null) {
          print("⚠️ jsonData é null");
          return <EventsData>[];
        }

        var events = Events.fromJson(jsonData);
        
        // Verificar se events.items existe
        if (events.items == null) {
          print("⚠️ events.items é null");
          return <EventsData>[];
        }
        
        // Verificar se events.items.data existe
        final itemsData = events.items!.data;
        if (itemsData == null) {
          print("⚠️ events.items.data é null");
          return <EventsData>[];
        }
        
        for (var i = 0; i < itemsData.length; i++) {
          list.add(itemsData[i]);
        }
        
        print("✅ ${list.length} eventos processados");
        return list;
      } catch (parseEx) {
        print("❌ Erro ao processar eventos: $parseEx");
        print("Stack trace: ${parseEx.toString()}");
        return <EventsData>[];
      }
    } catch (e) {
      print("❌ Erro na requisição getEventsList: $e");
      print("Stack trace: ${e.toString()}");
      return <EventsData>[];
    }
  }

  getHistoryTripList(String? user_api_hash) async {
    return Session.apiGet(
            "${UserRepository.getServerURL()}/api/get_history?lang=en&user_api_hash=$user_api_hash&device_id=369&from_date=2022-08-13&from_time=00:00&to_date=2022-08-13&to_time=11:45")
        .then((dynamic res) {
      print(res.toString());
      var jsonData = json.decode(res.toString());
      try {
        List<TripsItems> list = [];

        /*for (var i = 0; i < jsonData[1].items!.data!.length; i++) {
          list.add(jsonData[1].items!.data![i]);
        }*/
        var history = History.fromJson(jsonData);
        for (var i = 0; i < history.items!.length; i++) {
          list.add(history.items![i]);
        }
        return list;
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
      }
    });
  }

  getHistoryAllList(String? user_api_hash) async {
    return Session.apiGet(
            "${UserRepository.getServerURL()}/api/get_history?lang=en&user_api_hash=$user_api_hash&device_id=${StaticVarMethod.deviceId}&from_date=${StaticVarMethod.fromdate}&from_time=${StaticVarMethod.fromtime}&to_date=${StaticVarMethod.todate}&to_time=${StaticVarMethod.totime}")
        .then((dynamic res) {
      print(res.toString());
      var jsonData = json.decode(res.toString());
      try {
        List<AllItems> list = [];

        /*for (var i = 0; i < jsonData[1].items!.data!.length; i++) {
          list.add(jsonData[1].items!.data![i]);
        }*/
        var history = History.fromJson(jsonData);
        for (var i = 0; i < history.items!.length; i++) {
          for (var p in history.items![i].items ?? []) {
            list.add(p);
          }
        }
        return list;
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
      }
    });
  }

  static Future<History> getHistory(deviceId) async {
    final response = await http
        .get(Uri.parse(
            "${UserRepository.getServerURL()}/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date=${StaticVarMethod.fromdate}&from_time=${StaticVarMethod.fromtime}&to_date=${StaticVarMethod.todate}&to_time=${StaticVarMethod.totime}&device_id=" +
                deviceId +
                ""))
        .timeout(const Duration(minutes: 5));
    if (response.statusCode == 200) {
      //print(response.body);
      // var jsonData = json.decode(response.body);
      // return Devices.fromJson(json.decode(response.body));
      try {
        /*  List<History> list = [];
     list.clear();
     for (var i = 0; i < jsonData.length; i++) {
       var jsondataitem=jsonData[i];
       History listModel = History.fromJson(jsonData[i]);
       list.add(listModel);
     }
     return list;*/
        var jsonData = json.decode(response.body.toString());
        var history = History.fromJson(jsonData);
        return history;
        /* Iterable list = json.decode(response.body);
      return list.map((model) => History.fromJson(model)).toList();*/
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
        History model = new History();
        return model;
      }
    } else {
      print(response.statusCode);
      /* List<History> list=[];
      return list;*/
      History model = new History();
      return model;
    }
  }

  Future<Events> getEvents(String? user_api_hash) async {
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_events?lang=en&user_api_hash=$user_api_hash"));
    if (response.statusCode == 200) {
      //print(response.body);
      try {
        return Events.fromJson(json.decode(response.body));
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
        Events model = new Events();
        return model;
      }
    } else {
      print(response.statusCode);
      Events model = new Events();
      return model;
    }
  }

  static Future<PositionHistory?> getHistorynew(String deviceID,
      String fromDate, String fromTime, String toDate, String toTime) async {
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date=$fromDate&from_time=$fromTime&to_date=$toDate&to_time=$toTime&device_id=$deviceID"));
    print(response.request);
    if (response.statusCode == 200) {
      print(
          "dod${"$History_URL?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date=$fromDate&from_time=$fromTime&to_date=$toDate&to_time=$toTime&device_id=$deviceID"}");
      return PositionHistory.fromJson(json.decode(response.body));
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> getGeocoder(lat, lng) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";

    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/geo_address?lat=$lat&lon=$lng&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  static Future<String> geocode(lat, lng) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";

    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/geo_address?lat=$lat&lon=$lng&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);

    return response.body.toString();
  }

  //reports

  static Future<RouteReport?> getReport(
      String deviceID, String fromDate, String toDate, int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/generate_report?user_api_hash=${StaticVarMethod.user_api_hash!}&date_from=$fromDate&devices[]=$deviceID&date_to=$toDate&format=pdf&type=$type"));
    if (response.statusCode == 200) {
      print(
          "monir${"${UserRepository.getServerURL()}/api/generate_report?user_api_hash=${StaticVarMethod.user_api_hash!}&date_from=$fromDate&devices[]=$deviceID&date_to=$toDate&format=pdf&type=$type"}");
      var report = RouteReport.fromJson(json.decode(response.body));
      StaticVarMethod.reporturl = report.url.toString();

      return report;
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<RouteReport?> getKMReport(String deviceID, String fromDate,
      String toDate, int type, String toTime, String fromTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}api/generate_report?user_api_hash=${prefs.getString('user_api_hash')}&date_from=$fromDate&devices[]=$deviceID&date_to=$toDate&format=pdf&type=2&from_time=$fromTime&to_time=$toTime"));
    if (response.statusCode == 200) {
      print(
          "${UserRepository.getServerURL()}api/generate_report?user_api_hash=${prefs.getString('user_api_hash')}&date_from=$fromDate&devices[]=$deviceID&date_to=$toDate&format=pdf&type=2&from_time=$fromTime&to_time=$toTime");
      return RouteReport.fromJson(json.decode(response.body));
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<User?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_user_data?user_api_hash=${StaticVarMethod.user_api_hash!}"));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      print(response.statusCode);
      return null;
    }
  }

  // static Future<http.Response> changePassword(val) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   headers['content-type'] =
  //   "application/x-www-form-urlencoded; charset=UTF-8";
  //   print(json.encode(val));
  //   final response = await http.post(
  //       Uri.parse(UserRepository.getServerURL() +
  //           "/api/edit_alert?user_api_hash=" +StaticVarMethod.user_api_hash!),
  //       body: val,
  //       headers: headers);
  //   print(response.body);
  //   return response;
  // }

  // static Future<http.Response> changePassword(String val) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   headers['content-type'] =
  //   "application/x-www-form-urlencoded; charset=UTF-8";
  //   print(json.encode(val));
  //   final response = await http.post(
  //       Uri.parse(UserRepository.getServerURL() + "/api/change_password?user_api_hash=" +StaticVarMethod.user_api_hash!+"&lang=en&password="+val+"&password_confirmation="+val)
  //       //body: val,
  //      // headers: headers
  //   );
  //   print(response.body);
  //   return response;
  // }

  static changePassword(String val) async {
    String url =
        "${UserRepository.getServerURL()}/api/change_password?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=en&password=$val&password_confirmation=$val";

    print(url.toString());
    return Session.apiPost(url, "").then((dynamic res) {
      print(res.toString());

      var responseBool = res;
      return responseBool;
    });
  }

  static Future<http.Response> activateFCM(token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 🔧 CORREÇÃO: Usar POST em vez de GET para melhor segurança
    final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/fcm_token"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${StaticVarMethod.user_api_hash!}',
          ...headers,
        },
        body: jsonEncode({
          'token': token,
          'user_api_hash': StaticVarMethod.user_api_hash!,
        }));

    print("📱 FCM Token enviado: $token");
    print("📡 Resposta do servidor: ${response.statusCode} - ${response.body}");
    return response;
  }

  static Future<http.Response> deactivateFCM(token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/delete_fcm_token?user_api_hash=" +
                token),
        headers: headers);

    print(response.body);
    print(response.body);
    return response;
  }

  static Future<http.Response> activateAlert(val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    print(json.encode(val));
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/change_active_alert?user_api_hash=${StaticVarMethod.user_api_hash!}"),
        body: val,
        headers: headers);
    print(response.body);
    return response;
  }

  static Future<List<Alert>?> getAlertList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_alerts?user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    if (response.statusCode == 200) {
      print("Alertas");
      print(response.body);
      Iterable list = json.decode(response.body)['items']['alerts'];
      if (list.isNotEmpty) {
        return list.map((model) => Alert.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response?> login(email, password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.post(Uri.parse(
          "${UserRepository.getServerURL()}/api/login?email=" +
              email +
              "&password=" +
              password));

      if (response.statusCode == 200) {
        await prefs.setString('email', email);
        await prefs.setString('password', password);
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return null;
    }
  }

  ////////////////commands//////////////
  static Future<http.Response?> getSavedCommands(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_device_commands?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=$id"));
    if (response.statusCode == 200) {
      return response;
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response?> getSendCommands(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/send_command_data?user_api_hash=${StaticVarMethod.user_api_hash!}"));
    if (response.statusCode == 200) {
      return response;
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> sendCommands(body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/send_gprs_command?user_api_hash=${StaticVarMethod.user_api_hash!}"),
        body: body,
        headers: headers);
    print(body);
    return response;
  }

  static Future<http.Response> destroyAlertAncor(id) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/destroy_alert?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br&alert_id=" +
                id.toString()),
        headers: headers);
    return response;
  }

  static Future<http.Response> destroyGeofenceAncor(id) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/destroy_geofence?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br&geofence_id=" +
                id.toString()),
        headers: headers);
    return response;
  }

  ////////////////Geofences//////////////
  static Future<List<Geofence>?> getGeoFences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_geofences?user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body)['items']['geofences'];
      if (list.isNotEmpty) {
        return list.map((model) => Geofence.fromJson(model)).toList();
      } else {
        return null;
      }
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> addGeofence(fence) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_geofence?user_api_hash=${StaticVarMethod.user_api_hash!}"),
        body: fence,
        headers: headers);
    return response;
  }

  static Future<http.Response> updateGeofence(String fence, String id) async {
    headers['content-type'] = "application/json; charset=utf-8";
    final response = await http.put(
        Uri.parse("${UserRepository.getServerURL()}/api/geofences/$id"),
        body: fence,
        headers: headers);
    return response;
  }

  ////////////////devices//////////////



  ////////////////Alerts//////////////
  static Future<http.Response> addalert(name, type, device, overspeed) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_alert?user_api_hash=${StaticVarMethod.user_api_hash!}&name=" +
                name +
                "&type=" +
                type +
                "&devices[]=" +
                device +
                "&overspeed=" +
                overspeed +
                ""),
        headers: headers);
    return response;
  }

  static Future<http.Response> addAlertAncor(String request) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_alert?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br" +
                request),
        headers: headers);
    return response;
  }

  static Future<http.Response> getRegister(
      String name, String email, String phone, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await http.post(Uri.parse(registerUrl), body: {
      'name': name,
      'email': email,
      "phone": phone,
      'password': password,
    });
    //log(response.request!.url.toString());
    //log(response.body.toString());
    if (response.statusCode == 200) {
      // call login api
      //loginwith(email, password);
      return response;
    } else {
      //LoginModel model =new LoginModel();
      return response;
    }
  }

  static Future<http.Response> sendwhatsappsms(
      String phone, String text) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "http://62.171.191.144:3001/api/message?token=dk_4e8a1960a32b4df88716cfdc1c967bd1&phone=$phone&message=$text"),
        headers: headers);
    if (response.statusCode == 200) {
      return response;
    } else {
      print(response.statusCode);
      return response;
    }
  }

  ////////////////TASK//////////////
  static Future<http.Response> AddTask(title, comment, pickup_address,
      pickup_address_lat, pickup_address_lng) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_task?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=${StaticVarMethod.deviceId}"),
        body: {
          'device_id': StaticVarMethod.deviceId,
          'title': title,
          'comment': comment,
          'priority': 1,
          'status': 1,
          'pickup_address': pickup_address,
          'pickup_address_lat': pickup_address_lat,
          'pickup_address_lng': pickup_address_lng
        });
    if (response.statusCode == 200) {
      return response;
    } else {
      print(response.statusCode);
      return response;
    }
  }
}

class RouteReport extends Object {
  int? status;
  String? url;
  RouteReport({this.status, this.url});

  RouteReport.fromJson(Map<String, dynamic> json) {
    status = json["status"];
    url = json["url"];
  }
}
