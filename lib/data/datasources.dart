import 'dart:convert';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/model/PositionHistory.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/data/model/history.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/utils/Session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Alert.dart';
import 'model/GeofenceModel.dart';
import 'model/User.dart';
import 'model/devices.dart';
import 'model/loginModel.dart';
import 'model/service.dart';
import 'model/sensor_response.dart';
import 'model/command_data.dart';
import 'model/device_command.dart';
import 'model/sent_command.dart';
import 'model/admin_client.dart';
import 'model/admin_device.dart';
import 'model/route_response.dart';
import 'model/driver_form_data.dart';
import 'model/device_latest_response.dart';
import 'model/Review.dart';
import 'model/ReportModel.dart';
import 'package:http/http.dart' as http;

class gpsapis {
  // static final StaticVarMethod.baseurlall =StaticVarMethod.baseurlall;

  static final LOGIN_URL = "${UserRepository.getServerURL()}/api/login";
  static final Devices_URL = "${UserRepository.getServerURL()}/api/get_devices";
  static final History_URL = "${UserRepository.getServerURL()}/api/get_history";
  static final Events_URL = "${UserRepository.getServerURL()}/api/get_events";
  static final Address_URL = "${UserRepository.getServerURL()}/api/geo_address";
  static final registerUrl = "${UserRepository.getServerURL()}/api/register";

  static final InstPriceBySKUAuto_URL =
      "${UserRepository.getServerURL()}/api/Mapi/InstPriceBySKUAuto";

  static final SupplierList_URL =
      "${UserRepository.getServerURL()}/api/Mapi/GetSuppliers";
  static final GetAllBranchesDailySale_URL =
      "${UserRepository.getServerURL()}/api/Mapi/GetAllBranchesDailySale";

  static Map<String, String> headers = {};

  static getDevicesList(String? user_api_hash) async {
    try {
      print('🔍 [getDevicesList] Iniciando busca de dispositivos...');
      
      final url = Uri.parse('${UserRepository.getServerURL()}/api/get_devices');
      
      final body = jsonEncode({});
      
      final headers = {
        'Authorization': 'Bearer $user_api_hash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      print('🔍 [getDevicesList] URL: $url');
      print('🔍 [getDevicesList] Headers: Authorization: Bearer ${user_api_hash?.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 30));

      print('🔍 [getDevicesList] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        
        print('🔍 [getDevicesList] Resposta recebida, processando...');

        // Verificar se há erro na resposta
        if (jsonData is Map && (jsonData['status'] == 0 || jsonData['status'] == false)) {
          final errorMsg = jsonData['message'] ?? 'Erro ao buscar dispositivos';
          print('❌ [getDevicesList] Erro na resposta: $errorMsg');
          throw Exception(errorMsg);
        }

        List<deviceItems> list = [];
        
        // A resposta pode ser uma lista de grupos ou um objeto com 'items'
        if (jsonData is List) {
          print('✅ [getDevicesList] Resposta é uma lista com ${jsonData.length} grupos');
          for (var i = 0; i < jsonData.length; i++) {
            try {
              final group = Devices.fromJson(jsonData[i]);
              if (group.items != null) {
                for (var p in group.items!) {
                  list.add(p);
                }
              }
            } catch (Ex) {
              print('⚠️ [getDevicesList] Erro ao processar grupo $i: $Ex');
            }
          }
        } else if (jsonData is Map && jsonData['items'] != null && jsonData['items'] is List) {
          print('✅ [getDevicesList] Resposta é um Map com items');
          // Tentar processar como lista de grupos dentro de items
          for (var item in jsonData['items']) {
            try {
              final group = Devices.fromJson(item);
              if (group.items != null) {
                for (var p in group.items!) {
                  list.add(p);
                }
              }
            } catch (Ex) {
              print('⚠️ [getDevicesList] Erro ao processar item: $Ex');
            }
          }
        } else {
          print('⚠️ [getDevicesList] Formato de resposta inesperado');
        }

        print('✅ [getDevicesList] Total de dispositivos encontrados: ${list.length}');
        return list;
      } else {
        print('❌ [getDevicesList] Erro HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ [getDevicesList] Exceção: $e');
      rethrow;
    }
  }

  Future<List<deviceItems>> getDevicesItems(String? user_api_hash) async {
    //headers['Accept'] = "application/json";
    String? udre = user_api_hash;
    final response = await http.get(Uri.parse(
        "${UserRepository.getServerURL()}/api/get_devices?lang=br&user_api_hash=$user_api_hash"));
    if (response.statusCode == 200) {
      //print(response.body);
      //return Devices.fromJson(json.decode(response.body));
      //Iterable list = json.decode(response.body);
      // return list.map((model) => Devices.fromJson(model)).toList();
      var jsonData = json.decode(response.body);
      try {
        List<deviceItems> list = [];
        for (var i = 0; i < jsonData.length; i++) {
          for (var p in Devices.fromJson(jsonData[i]).items ?? []) {
            list.add(p);
          }
        }
        return list;
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
        List<deviceItems> list = [];
        return list;
      }
    } else {
      print(response.statusCode);
      List<deviceItems> list = [];
      return list;
    }
  }

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
      //LoginModel model =new LoginModel();
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
    print("@@@USER");
    print(user_api_hash);
    return Session.apiGet(
            "${UserRepository.getServerURL()}/api/get_events?lang=br&limit=5000&user_api_hash=$user_api_hash")
        .then((dynamic res) {
      print("@@@REST@@@");
      print(res.toString());

      var jsonData = json.decode(res.toString());
      try {
        List<EventsData> list = [];

        /*for (var i = 0; i < jsonData[1].items!.data!.length; i++) {
          list.add(jsonData[1].items!.data![i]);
        }*/
        var events = Events.fromJson(jsonData);
        for (var i = 0; i < events.items!.data!.length; i++) {
          list.add(events.items!.data![i]);
        }
        return list;
      } catch (Ex) {
        print(Ex);
        print("Error occurred");
      }
    });
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
      String deviceID, String fromDate, String toDate, int type, {String? userApiHash}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final hash = userApiHash ?? StaticVarMethod.user_api_hash ?? prefs.getString('user_api_hash') ?? '';
    
    if (hash.isEmpty) {
      print('❌ Erro: user_api_hash não encontrado');
      return null;
    }
    
    final url = "${UserRepository.getServerURL()}/api/generate_report?user_api_hash=$hash&date_from=$fromDate&devices[]=$deviceID&date_to=$toDate&format=pdf&type=$type";
    
    print('\n📊 ========== GERANDO RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(hash, '***')}');
    print('🚗 Device ID: $deviceID');
    print('📅 De: $fromDate');
    print('📅 Até: $toDate');
    print('📋 Tipo: $type');
    
    final response = await http.get(Uri.parse(url));
    
    print('📊 Status Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      try {
        var report = RouteReport.fromJson(json.decode(response.body));
        StaticVarMethod.reporturl = report.url.toString();
        print('✅ Relatório gerado: ${report.url}');
        return report;
      } catch (e) {
        print('❌ Erro ao processar resposta: $e');
        print('📄 Resposta: ${response.body}');
        return null;
      }
    } else {
      print('❌ Erro HTTP: ${response.statusCode}');
      print('📄 Resposta: ${response.body}');
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
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/fcm_token?user_api_hash=${StaticVarMethod.user_api_hash!}&token=" +
                token),
        headers: headers);

    print(response.body);
    print(response.body);
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
  ////////////////Get Device Commands//////////////
  /// Buscar comandos disponíveis para um dispositivo específico
  /// Endpoint: /api/get_device_commands
  static Future<List<DeviceCommand>?> getDeviceCommands(String deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/get_device_commands?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=$deviceId&lang=br";
    
    print('\n📡 ========== CHAMADA API GET_DEVICE_COMMANDS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🔧 Device ID: $deviceId');
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          if (jsonData is List) {
            final commands = jsonData
                .map((item) => DeviceCommand.fromJson(item as Map<String, dynamic>))
                .toList();
            
            print('\n✅ Comandos do dispositivo carregados:');
            print('   Total de comandos: ${commands.length}');
            for (var cmd in commands) {
              print('   - ${cmd.type}: ${cmd.title} (${cmd.attributes.length} atributos)');
            }
            
            print('=' * 60);
            return commands;
          } else {
            print('⚠️ Resposta não é uma lista');
            print('=' * 60);
            return null;
          }
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  ////////////////Get Sent Commands//////////////
  /// Buscar histórico de comandos enviados
  /// Endpoint: /api/sent_commands
  static Future<SentCommandResponse?> getSentCommands({int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    var url = "${UserRepository.getServerURL()}/api/sent_commands?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    if (page != null) {
      url += "&page=$page";
    }
    
    print('\n📡 ========== CHAMADA API SENT_COMMANDS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    if (page != null) {
      print('📄 Página: $page');
    }
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          final sentCommands = SentCommandResponse.fromJson(jsonData as Map<String, dynamic>);
          
          print('\n✅ Comandos enviados carregados:');
          print('   Total: ${sentCommands.pagination.total}');
          print('   Por página: ${sentCommands.pagination.perPage}');
          print('   Página atual: ${sentCommands.pagination.currentPage}');
          print('   Última página: ${sentCommands.pagination.lastPage}');
          print('   Comandos nesta página: ${sentCommands.data.length}');
          
          if (sentCommands.data.isNotEmpty) {
            print('\n📋 Comandos:');
            for (var cmd in sentCommands.data) {
              print('   - ${cmd.commandTitle} (${cmd.device?.name ?? "N/A"}) - ${cmd.statusText}');
            }
          }
          
          print('=' * 60);
          return sentCommands;
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  // Método de compatibilidade (mantido para código existente)
  static Future<http.Response?> getSavedCommands(String id) async {
    final commands = await getDeviceCommands(id);
    if (commands != null) {
      return http.Response(
        json.encode(commands.map((c) => c.toJson()).toList()),
        200,
      );
    }
    return null;
  }

  ////////////////Command Data//////////////
  /// Buscar dados de comandos disponíveis
  /// Endpoint: /api/send_command_data
  static Future<CommandData?> getSendCommandData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/send_command_data?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== CHAMADA API SEND_COMMAND_DATA ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          final commandData = CommandData.fromJson(jsonData);
          
          print('\n✅ Dados de comandos carregados:');
          print('   Dispositivos SMS: ${commandData.devicesSms.length}');
          print('   Dispositivos GPRS: ${commandData.devicesGprs.length}');
          print('   Templates SMS: ${commandData.smsTemplates.length}');
          print('   Templates GPRS: ${commandData.gprsTemplates.length}');
          print('   Comandos disponíveis: ${commandData.commands.length}');
          print('   Unidades: ${commandData.units.length}');
          print('   Ações: ${commandData.actions.length}');
          
          if (commandData.commands.isNotEmpty) {
            print('\n📋 Comandos disponíveis:');
            for (var cmd in commandData.commands) {
              print('   - ${cmd.id}: ${cmd.value}');
            }
          }
          
          print('=' * 60);
          return commandData;
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  ////////////////Send GPRS Command//////////////
  /// Enviar comando GPRS para um dispositivo
  /// Endpoint: /api/send_gprs_command
  /// Content-Type: multipart/form-data
  static Future<Map<String, dynamic>> sendGprsCommand({
    required String deviceId,
    required String type,
    String? message,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final url = Uri.parse(
      "${UserRepository.getServerURL()}/api/send_gprs_command?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br"
    );
    
    print('\n📡 ========== ENVIANDO COMANDO GPRS ==========');
    print('🌐 URL: ${url.toString().replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🔧 Device ID: $deviceId');
    print('📝 Tipo: $type');
    if (message != null) {
      print('💬 Mensagem: $message');
    }
    
    try {
      // Usar o método antigo sendCommands que pode ter lógica diferente
      // Este método usa headers globais e pode processar o custom corretamente
      headers['content-type'] = "application/x-www-form-urlencoded; charset=UTF-8";
      
      final body = <String, String>{
        'device_id': deviceId,
        'type': type,
      };
      
      // Adicionar custom como array vazio (formato que o PHP pode processar)
      // Tentar enviar como custom[]= para criar array vazio
      body['custom[]'] = '';
      
      if (message != null && message.isNotEmpty) {
        body['message'] = message;
      }
      
      print('📤 Campos do formulário (método antigo):');
      print('   device_id: $deviceId');
      print('   type: $type');
      print('   custom[]: (array vazio)');
      if (message != null) {
        print('   message: $message');
      }
      
      final startTime = DateTime.now();
      final response = await http.post(
        url,
        body: body,
        headers: headers,
      );
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      
      print('📦 Resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('✅ Comando GPRS enviado com sucesso!');
          print('   Status: ${jsonData['status']}');
          print('=' * 60);
          return {
            'success': true,
            'status': jsonData['status'],
            'message': 'Comando enviado com sucesso',
          };
        } catch (e) {
          print('⚠️ Resposta não é JSON válido, mas status é 200');
          print('=' * 60);
          return {
            'success': true,
            'status': 1,
            'message': 'Comando enviado com sucesso',
          };
        }
      } else {
        print('❌ Erro ao enviar comando GPRS');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        
        // Tentar extrair mensagem de erro da resposta JSON
        String errorMessage = 'Erro ao enviar comando';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMessage = errorData['message']?.toString() ?? 
                          errorData['errors']?.toString() ?? 
                          'Erro ao enviar comando';
          }
        } catch (e) {
          // Se não conseguir parsear, usar a resposta bruta
          errorMessage = response.body.length > 100 
              ? response.body.substring(0, 100) + '...'
              : response.body;
        }
        
        return {
          'success': false,
          'status': response.statusCode,
          'message': errorMessage,
          'raw_response': response.body,
        };
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO AO ENVIAR COMANDO GPRS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return {
        'success': false,
        'status': 0,
        'message': 'Erro: $e',
      };
    }
  }

  ////////////////Send SMS Command//////////////
  /// Enviar comando SMS para dispositivos
  /// Endpoint: /api/send_sms_command
  /// Content-Type: multipart/form-data
  static Future<Map<String, dynamic>> sendSmsCommand({
    required String message,
    required List<String> devices,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final url = Uri.parse(
      "${UserRepository.getServerURL()}/api/send_sms_command?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br"
    );
    
    print('\n📡 ========== ENVIANDO COMANDO SMS ==========');
    print('🌐 URL: ${url.toString().replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('💬 Mensagem: $message');
    print('📱 Dispositivos: ${devices.join(", ")}');
    
    try {
      final request = http.MultipartRequest('POST', url);
      
      // Headers
      request.headers['Accept'] = 'application/json';
      
      // Campos do formulário
      request.fields['message'] = message;
      for (int i = 0; i < devices.length; i++) {
        request.fields['devices[$i]'] = devices[i];
      }
      
      print('📤 Campos do formulário:');
      print('   message: $message');
      for (int i = 0; i < devices.length; i++) {
        print('   devices[$i]: ${devices[i]}');
      }
      
      final startTime = DateTime.now();
      final streamedResponse = await request.send();
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${streamedResponse.statusCode}');
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📦 Resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('✅ Comando SMS enviado com sucesso!');
          print('   Status: ${jsonData['status']}');
          print('=' * 60);
          return {
            'success': true,
            'status': jsonData['status'],
            'message': 'SMS enviado com sucesso',
          };
        } catch (e) {
          print('⚠️ Resposta não é JSON válido, mas status é 200');
          print('=' * 60);
          return {
            'success': true,
            'status': 1,
            'message': 'SMS enviado com sucesso',
          };
        }
      } else {
        print('❌ Erro ao enviar comando SMS');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return {
          'success': false,
          'status': response.statusCode,
          'message': 'Erro ao enviar SMS',
        };
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO AO ENVIAR COMANDO SMS ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return {
        'success': false,
        'status': 0,
        'message': 'Erro: $e',
      };
    }
  }

  // Método de compatibilidade (mantido para código existente)
  static Future<http.Response> sendCommands(body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Se body é um Map, converter para usar o novo método
    if (body is Map<String, String>) {
      final deviceId = body['device_id'] ?? '';
      final type = body['type'] ?? '';
      final message = body['data'] ?? body['message'];
      
      if (deviceId.isNotEmpty && type.isNotEmpty) {
        final result = await sendGprsCommand(
          deviceId: deviceId,
          type: type,
          message: message,
        );
        
        // Criar uma resposta simulada para compatibilidade
        return http.Response(
          json.encode(result),
          result['success'] == true ? 200 : 400,
        );
      }
    }
    
    // Fallback para o método antigo
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
  /// Buscar todas as geofences (cercas/âncoras)
  /// Endpoint: GET /api/get_geofences
  static Future<List<Geofence>?> getGeoFences({String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/get_geofences?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BUSCAR GEOFENCES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['items'] != null && jsonData['items']['geofences'] != null) {
          final list = jsonData['items']['geofences'] as List;
          if (list.isNotEmpty) {
            final geofences = list.map((model) => Geofence.fromJson(Map<String, dynamic>.from(model))).toList();
            print('✅ ${geofences.length} geofences encontradas');
            return geofences;
          }
        }
        return [];
      } else {
        print('❌ Erro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar geofences: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Criar uma nova geofence (âncora)
  /// Endpoint: POST /api/add_geofence
  static Future<Map<String, dynamic>?> addGeofence({
    required String name,
    required bool active,
    int? device_id,
    int? group_id,
    String type = 'circle',
    required double lat,
    required double lng,
    required double radius,
    int? speed_limit,
    bool? movement_allowed,
    String? polygon_color,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/add_geofence?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
      final body = {
      'name': name,
      'active': active,
      'device_id': device_id ?? 0,
      'group_id': group_id ?? 0,
      'type': type,
      'center': {
        'lat': lat,
        'lng': lng,
      },
      'radius': radius,
      'speed_limit': speed_limit ?? 0,
      'movement_allowed': movement_allowed ?? false,
      'polygon_color': polygon_color ?? '#FFA500',
    };
    
    print('\n📡 ========== CRIAR GEOFENCE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Geofence criada com sucesso!');
        // A API retorna geofence_id, não id
        if (jsonData is Map && jsonData['geofence_id'] != null) {
          jsonData['id'] = jsonData['geofence_id'];
        }
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao criar geofence: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Editar uma geofence existente
  /// Endpoint: POST /api/edit_geofence
  static Future<Map<String, dynamic>?> editGeofence({
    required int id,
    required String name,
    required bool active,
    int? device_id,
    int? group_id,
    String type = 'circle',
    required double lat,
    required double lng,
    required double radius,
    int? speed_limit,
    bool? movement_allowed,
    String? polygon_color,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/edit_geofence?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
      final body = {
      'id': id,
      'name': name,
      'active': active,
      'device_id': device_id ?? 0,
      'group_id': group_id ?? 0,
      'type': type,
      'center': {
        'lat': lat,
        'lng': lng,
      },
      'radius': radius,
      'speed_limit': speed_limit ?? 0,
      'movement_allowed': movement_allowed ?? false,
      'polygon_color': polygon_color ?? '#FFA500',
    };
    
    print('\n📡 ========== EDITAR GEOFENCE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Geofence editada com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao editar geofence: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Deletar uma geofence
  /// Endpoint: GET /api/destroy_geofence
  static Future<Map<String, dynamic>?> destroyGeofence({
    required int id,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/destroy_geofence?id=$id&lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== DELETAR GEOFENCE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Geofence deletada com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao deletar geofence: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Alterar status ativo/inativo de uma geofence
  /// Endpoint: GET /api/change_active_geofence
  static Future<Map<String, dynamic>?> changeActiveGeofence({
    required int id,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/change_active_geofence?id=$id&lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== ALTERAR STATUS GEOFENCE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Status da geofence alterado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao alterar status da geofence: $e');
      print(stackTrace);
      return null;
    }
  }

  // Método legado para compatibilidade
  static Future<http.Response> updateGeofence(String fence, String id) async {
    headers['content-type'] = "application/json; charset=utf-8";
    final response = await http.put(
        Uri.parse("${UserRepository.getServerURL()}/api/geofences/$id"),
        body: fence,
        headers: headers);
    return response;
  }

  ////////////////devices//////////////
  static Future<http.Response> adddevice(name, imei, sim_number) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse("${UserRepository.getServerURL()}/api/add_device?user_api_hash=${StaticVarMethod.user_api_hash!}&name=" +
            name +
            "&imei=" +
            imei +
            "&icon_id=2&min_moving_speed=5&min_fuel_fillings=7&min_fuel_thefts=5&tail_length=5&fuel_measurement_id=1&sim_number=" +
            sim_number +
            "&installation_date=18-08-2023&msisdn=123456&device_model=enter device model&city=enter city&sales_person=sales_person&installer=installer&mobile_1=mobile_1&address=address&customer_name=customer_name"),
        headers: headers);
    return response;
  }

  static Future<http.Response> editdevice(device_id, name, imei) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/edit_device?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=" +
                device_id +
                "&name=" +
                name +
                "&imei=" +
                imei +
                "&icon_id=2&min_moving_speed=5&min_fuel_fillings=7&min_fuel_thefts=5&tail_length=5&fuel_measurement_id=1"),
        headers: headers);
    return response;
  }

  static Future<http.Response> editDeviceAncor(val) async {
    headers['content-type'] =
        "application/x-www-form-urlencoded; charset=UTF-8";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/edit_device?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br"),
        body: val,
        headers: headers);
    return response;
  }

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

  ////////////////Protocols//////////////
  /// Get available protocols
  /// Endpoint: GET /api/get_protocols
  static Future<http.Response> getProtocols({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_protocols?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  ////////////////Alerts - Extended Endpoints//////////////
  /// Get data needed for adding a new alert
  /// Endpoint: GET /api/add_alert_data
  static Future<http.Response> getAddAlertData({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_alert_data?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Add alert with JSON body
  /// Endpoint: POST /api/add_alert
  static Future<http.Response> addAlertJson(Map<String, dynamic> alertData, {String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/add_alert?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers,
        body: json.encode(alertData));
    return response;
  }

  /// Get data needed for editing an alert
  /// Endpoint: GET /api/edit_alert_data
  static Future<http.Response> getEditAlertData({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/edit_alert_data?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Edit alert with JSON body
  /// Endpoint: POST /api/edit_alert
  static Future<http.Response> editAlertJson(Map<String, dynamic> alertData, {String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/edit_alert?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers,
        body: json.encode(alertData));
    return response;
  }

  /// Get custom events by device
  /// Endpoint: GET /api/get_custom_events_by_device
  static Future<http.Response> getCustomEventsByDevice({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_custom_events_by_device?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Set alert devices
  /// Endpoint: GET /api/set_alert_devices
  static Future<http.Response> setAlertDevices({String lang = 'en'}) async {
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/set_alert_devices?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Get alerts for a specific device
  /// Endpoint: GET /api/devices/{device_id}/alerts
  static Future<http.Response> getDeviceAlerts(int deviceId, {String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/devices/$deviceId/alerts?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Set time period when alerts are active
  /// Endpoint: POST /api/devices/{device_id}/alerts/{alert_id}/time_period
  static Future<http.Response> setAlertTimePeriod(
      int deviceId, int alertId, Map<String, dynamic> timeData, {String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    final response = await http.post(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/devices/$deviceId/alerts/$alertId/time_period?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers,
        body: json.encode(timeData));
    return response;
  }

  /// Get events by protocol
  /// Endpoint: GET /api/get_events_by_protocol
  static Future<http.Response> getEventsByProtocol({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_events_by_protocol?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Get alert types with input fields
  /// Endpoint: GET /api/get_alerts_attributes
  static Future<http.Response> getAlertsAttributes({String lang = 'en'}) async {
    headers['Accept'] = "application/json";
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_alerts_attributes?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Get alert commands
  /// Endpoint: GET /api/get_alerts_commands
  static Future<http.Response> getAlertsCommands({String lang = 'en'}) async {
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_alerts_commands?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
        headers: headers);
    return response;
  }

  /// Get alerts summary
  /// Endpoint: GET /api/get_alerts_summary
  static Future<http.Response> getAlertsSummary({String lang = 'en'}) async {
    final response = await http.get(
        Uri.parse(
            "${UserRepository.getServerURL()}/api/get_alerts_summary?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}"),
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

  ////////////////Drivers//////////////
  /// Buscar lista de motoristas do usuário
  /// Endpoint: POST /api/get_user_drivers
  static Future<List<DriverData>?> getUserDrivers() async {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print('❌ getUserDrivers: user_api_hash não disponível');
      return null;
    }
    
    final url = Uri.parse('${UserRepository.getServerURL()}/api/get_user_drivers');
    final body = jsonEncode({});
    
    final headers = {
      'Authorization': 'Bearer $userApiHash',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    print('\n📡 ========== CHAMADA API GET_USER_DRIVERS ==========');
    print('🌐 URL: $url');
    print('🔑 User API Hash: ${userApiHash.substring(0, 10)}...');
    print('📅 Data/Hora: ${DateTime.now()}');
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          // Verificar diferentes formatos de resposta
          List<dynamic>? driversList;
          
          if (jsonData is List) {
            print('✅ Formato: Lista direta');
            driversList = jsonData;
          } else if (jsonData is Map) {
            print('✅ Formato: Objeto Map');
            print('   Chaves disponíveis: ${jsonData.keys.join(", ")}');
            
            // Estrutura real: {items: {drivers: {data: [...], pagination: {...}}}, status: 1}
            if (jsonData['items'] != null && 
                jsonData['items'] is Map &&
                jsonData['items']['drivers'] != null &&
                jsonData['items']['drivers'] is Map &&
                jsonData['items']['drivers']['data'] != null) {
              driversList = jsonData['items']['drivers']['data'];
              print('   ✅ Estrutura encontrada: items.drivers.data');
              
              // Log de paginação se disponível
              final driversObj = jsonData['items']['drivers'] as Map<String, dynamic>;
              if (driversObj['total'] != null) {
                print('   📄 Paginação:');
                print('      Total: ${driversObj['total']}');
                print('      Página atual: ${driversObj['current_page']}');
                print('      Última página: ${driversObj['last_page']}');
                print('      Por página: ${driversObj['per_page']}');
              }
            }
            // Fallback para outras estruturas possíveis
            else if (jsonData['items'] != null && jsonData['items'] is List) {
              driversList = jsonData['items'];
              print('   ✅ Estrutura encontrada: items (lista direta)');
            } else if (jsonData['drivers'] != null && jsonData['drivers'] is List) {
              driversList = jsonData['drivers'];
              print('   ✅ Estrutura encontrada: drivers (lista direta)');
            } else if (jsonData['data'] != null && jsonData['data'] is List) {
              driversList = jsonData['data'];
              print('   ✅ Estrutura encontrada: data (lista direta)');
            } else {
              print('   ⚠️ Estrutura não reconhecida');
              print('   📋 Estrutura completa:');
              print(json.encode(jsonData));
            }
          } else {
            print('⚠️ Formato inesperado: ${jsonData.runtimeType}');
            print('   Resposta completa:');
            print(response.body);
          }
          
          if (driversList != null && driversList.isNotEmpty) {
            print('\n✅ ${driversList.length} motorista(s) encontrado(s) na resposta');
            print('\n📝 Estrutura do primeiro item:');
            print(json.encode(driversList[0]));
            
            final drivers = driversList.map((model) => DriverData.fromJson(model)).toList();
            print('\n✅ ${drivers.length} motorista(s) convertido(s) com sucesso');
            print('=' * 60);
            return drivers;
          } else {
            print('\n⚠️ Nenhum motorista encontrado na resposta');
            print('   A resposta pode estar vazia ou em formato diferente');
            print('=' * 60);
            return [];
          }
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  ////////////////Sensors//////////////
  /// Buscar sensores de um dispositivo específico
  /// Endpoint: /api/get_sensors
  /// Documentação: https://gpswox.stoplight.io/docs/tracking-software/ft4wgfoo1dwcf-get-device-sensors
  static Future<SensorResponse?> getDeviceSensors(int deviceId, {int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    String url = "${UserRepository.getServerURL()}/api/get_sensors?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=$deviceId&lang=br";
    if (page != null) {
      url += "&page=$page";
    }
    
    print('\n📡 ========== CHAMADA API GET_SENSORS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🔧 Device ID: $deviceId');
    if (page != null) {
      print('📄 Página: $page');
    }
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          // Processar resposta conforme estrutura fornecida
          final sensorResponse = SensorResponse.fromJson(jsonData);
          
          print('\n✅ ${sensorResponse.data.length} sensor(es) encontrado(s)');
          if (sensorResponse.pagination != null) {
            print('📄 Paginação:');
            print('   Total: ${sensorResponse.pagination!.total}');
            print('   Página atual: ${sensorResponse.pagination!.currentPage}');
            print('   Última página: ${sensorResponse.pagination!.lastPage}');
            print('   Por página: ${sensorResponse.pagination!.perPage}');
          }
          
          // Log detalhado de cada sensor
          if (sensorResponse.data.isNotEmpty) {
            print('\n📋 DETALHES DOS SENSORES CARREGADOS:');
            for (int i = 0; i < sensorResponse.data.length; i++) {
              final sensor = sensorResponse.data[i];
              print('\n   ┌─ Sensor ${i + 1} ──────────────────────────────');
              print('   │ ID: ${sensor.id}');
              print('   │ Nome: ${sensor.name ?? "❌ Não informado"}');
              print('   │ Tipo: ${sensor.type ?? "❌ Não informado"}');
              print('   │ Tipo Título: ${sensor.typeTitle ?? "❌ Não informado"}');
              print('   │ Tag Name: ${sensor.tagName ?? "❌ Não informado"}');
              print('   │ Valor: ${sensor.value ?? "❌ Não informado"}');
              print('   │ Unidade: ${sensor.unitOfMeasurement ?? "❌ Não informado"}');
              print('   │ Mostrar no Popup: ${sensor.showInPopup ?? "❌ Não informado"}');
              print('   └─────────────────────────────────────────────');
            }
          }
          
          print('=' * 60);
          return sensorResponse;
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  ////////////////Services//////////////
  /// Buscar serviços de um dispositivo específico
  /// Endpoint: /api/get_services
  /// Documentação: https://gpswox.stoplight.io/docs/tracking-software/mgrl8cf74jwxy-get-services
  static Future<ServiceResponse?> getDeviceServices(int deviceId, {int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    String url = "${UserRepository.getServerURL()}/api/get_services?user_api_hash=${StaticVarMethod.user_api_hash!}&device_id=$deviceId&lang=br";
    if (page != null) {
      url += "&page=$page";
    }
    
    print('\n📡 ========== CHAMADA API GET_SERVICES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🔧 Device ID: $deviceId');
    if (page != null) {
      print('📄 Página: $page');
    }
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou mais de 30 segundos');
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Tamanho da resposta: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        print('✅ Resposta recebida com sucesso!');
        print('\n📋 Corpo da resposta (primeiros 500 caracteres):');
        final preview = response.body.length > 500 
            ? response.body.substring(0, 500) + '...' 
            : response.body;
        print(preview);
        
        try {
          final jsonData = json.decode(response.body);
          print('\n🔍 Tipo da resposta: ${jsonData.runtimeType}');
          
          // Processar resposta conforme estrutura fornecida
          final serviceResponse = ServiceResponse.fromJson(jsonData);
          
          print('\n✅ ${serviceResponse.data.length} serviço(s) encontrado(s)');
          if (serviceResponse.pagination != null) {
            print('📄 Paginação:');
            print('   Total: ${serviceResponse.pagination!.total}');
            print('   Página atual: ${serviceResponse.pagination!.currentPage}');
            print('   Última página: ${serviceResponse.pagination!.lastPage}');
          }
          
          // Log detalhado de cada serviço
          if (serviceResponse.data.isNotEmpty) {
            print('\n📋 DETALHES DOS SERVIÇOS CARREGADOS:');
            for (int i = 0; i < serviceResponse.data.length; i++) {
              final service = serviceResponse.data[i];
              print('\n   ┌─ Serviço ${i + 1} ──────────────────────────────');
              print('   │ ID: ${service.id}');
              print('   │ Nome: ${service.name ?? "❌ Não informado"}');
              print('   │ Descrição: ${service.description ?? "❌ Não informado"}');
              print('   │ Status: ${service.status}');
              print('   │ Expira em: ${service.formattedExpiresDate ?? "❌ Não informado"}');
              print('   │ Último serviço: ${service.formattedLastService ?? "❌ Não informado"}');
              print('   │ Expirado: ${service.isExpired ? "Sim" : "Não"}');
              print('   │ Expirando em breve: ${service.isExpiringSoon ? "Sim" : "Não"}');
              print('   └─────────────────────────────────────────────');
            }
          }
          
          print('=' * 60);
          return serviceResponse;
        } catch (jsonError) {
          print('\n❌ ERRO ao processar JSON:');
          print('   Erro: $jsonError');
          print('   Resposta bruta:');
          print(response.body);
          print('=' * 60);
          return null;
        }
      } else {
        print('\n❌ ERRO na resposta da API');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('=' * 60);
        return null;
      }
    } catch (e, stackTrace) {
      print('\n❌ ========== EXCEÇÃO NA CHAMADA DA API ==========');
      print('❌ Erro: $e');
      print('📚 Stack Trace:');
      print(stackTrace);
      print('=' * 60);
      return null;
    }
  }

  ////////////////Admin Client APIs//////////////
  /// Criar novo cliente
  /// Endpoint: POST /api/admin/client
  static Future<ClientResponse?> createClient(CreateClientRequest request) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/client?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== CRIAR CLIENTE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final clientResponse = ClientResponse.fromJson(jsonData as Map<String, dynamic>);
        print('✅ Cliente criado com sucesso! ID: ${clientResponse.item?.id}');
        return clientResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Atualizar cliente
  /// Endpoint: PUT /api/admin/client
  static Future<Map<String, dynamic>?> updateClient(CreateClientRequest request) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/client?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== ATUALIZAR CLIENTE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Cliente atualizado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Deletar cliente
  /// Endpoint: DELETE /api/admin/client/{id}
  static Future<Map<String, dynamic>?> deleteClient(int clientId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/client/$clientId?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== DELETAR CLIENTE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('🗑️ Client ID: $clientId');
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Cliente deletado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Atualizar status ativo do cliente
  /// Endpoint: POST /api/admin/client/status
  static Future<Map<String, dynamic>?> updateClientStatus(UpdateClientStatusRequest request) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/client/status?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== ATUALIZAR STATUS CLIENTE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Status do cliente atualizado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Listar clientes
  /// Endpoint: GET /api/admin/clients
  static Future<ClientListResponse?> getClientsList({int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    var url = "${UserRepository.getServerURL()}/api/admin/clients?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    if (page != null) {
      url += "&page=$page";
    }
    
    print('\n📡 ========== LISTAR CLIENTES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    if (page != null) {
      print('📄 Página: $page');
    }
    
    try {
      final startTime = DateTime.now();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      final duration = DateTime.now().difference(startTime);
      
      print('⏱️ Tempo de resposta: ${duration.inMilliseconds}ms');
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final clientsList = ClientListResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Clientes carregados:');
        print('   Total: ${clientsList.total}');
        print('   Por página: ${clientsList.perPage}');
        print('   Página atual: ${clientsList.currentPage}');
        print('   Última página: ${clientsList.lastPage}');
        print('   Clientes nesta página: ${clientsList.data.length}');
        
        return clientsList;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Deletar múltiplos clientes
  /// Endpoint: DELETE /api/admin/clients
  static Future<Map<String, dynamic>?> deleteClients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/clients?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== DELETAR MÚLTIPLOS CLIENTES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Clientes deletados com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Listar dispositivos do cliente
  /// Endpoint: GET /api/admin/client/{id}/devices
  static Future<ClientDeviceResponse?> getClientDevices(int clientId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/client/$clientId/devices?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== LISTAR DISPOSITIVOS DO CLIENTE ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('👤 Client ID: $clientId');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final devicesResponse = ClientDeviceResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Dispositivos carregados:');
        print('   Total: ${devicesResponse.pagination.total}');
        print('   Dispositivos: ${devicesResponse.data.length}');
        
        return devicesResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Obter dados do cliente do usuário
  /// Endpoint: GET /api/admin/users/{id}/client
  static Future<UserClientResponse?> getUserClient(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/users/$userId/client?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== OBTER CLIENTE DO USUÁRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('👤 User ID: $userId');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final userClientResponse = UserClientResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Dados do cliente obtidos com sucesso!');
        
        return userClientResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Definir dados do cliente do usuário
  /// Endpoint: POST /api/admin/users/{id}/client
  static Future<UserClientResponse?> setUserClient(int userId, UserClientData clientData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/users/$userId/client?user_api_hash=${StaticVarMethod.user_api_hash!}&lang=br";
    
    print('\n📡 ========== DEFINIR CLIENTE DO USUÁRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('👤 User ID: $userId');
    print('📤 Request: ${json.encode(clientData.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(clientData.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final userClientResponse = UserClientResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Dados do cliente definidos com sucesso!');
        
        return userClientResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  ////////////////Admin Device APIs//////////////

  /// Listar dispositivos
  /// Endpoint: GET /api/admin/devices
  static Future<DeviceListResponse?> getAdminDevicesList({int? page, String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    var url = "${UserRepository.getServerURL()}/api/admin/devices?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    if (page != null) {
      url += "&page=$page";
    }
    
    print('\n📡 ========== LISTAR DISPOSITIVOS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final devicesResponse = DeviceListResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Dispositivos carregados:');
        print('   Total: ${devicesResponse.pagination.total}');
        print('   Dispositivos: ${devicesResponse.data.length}');
        
        return devicesResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Obter dispositivo específico
  /// Endpoint: GET /api/admin/device/{device}
  static Future<DeviceResponse?> getDevice(int deviceId, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== OBTER DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final deviceResponse = DeviceResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Dispositivo carregado com sucesso!');
        
        return deviceResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Criar dispositivo
  /// Endpoint: POST /api/admin/device
  static Future<Map<String, dynamic>?> createDevice(CreateDeviceRequest request, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== CRIAR DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Dispositivo criado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Atualizar dispositivo
  /// Endpoint: PUT /api/admin/device/{device}
  static Future<Map<String, dynamic>?> updateDevice(int deviceId, CreateDeviceRequest request, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== ATUALIZAR DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Dispositivo atualizado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Deletar dispositivo
  /// Endpoint: DELETE /api/admin/device/{device}
  static Future<Map<String, dynamic>?> deleteDevice(int deviceId, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== DELETAR DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Dispositivo deletado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Atribuir usuário ao dispositivo
  /// Endpoint: POST /api/admin/device/{device}/user
  static Future<Map<String, dynamic>?> assignUserToDevice(int deviceId, AssignUserToDeviceRequest request, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId/user?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== ATRIBUIR USUÁRIO AO DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Usuário atribuído com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Revogar usuário do dispositivo
  /// Endpoint: DELETE /api/admin/device/{device}/user
  static Future<Map<String, dynamic>?> revokeUserFromDevice(int deviceId, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId/user?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== REVOGAR USUÁRIO DO DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Usuário revogado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Alterar status ativo do dispositivo
  /// Endpoint: POST /api/admin/device/{device}/status
  static Future<Map<String, dynamic>?> changeDeviceStatus(int deviceId, UpdateDeviceStatusRequest request, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId/status?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== ALTERAR STATUS DO DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Status alterado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Alterar data de expiração do dispositivo
  /// Endpoint: POST /api/admin/device/{device}/expiration
  static Future<Map<String, dynamic>?> changeDeviceExpiration(int deviceId, UpdateDeviceExpirationRequest request, {String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId/expiration?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== ALTERAR EXPIRAÇÃO DO DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    print('📤 Request: ${json.encode(request.toJson())}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(request.toJson()),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Data de expiração alterada com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Listar usuários do dispositivo
  /// Endpoint: GET /api/admin/device/{device}/users
  static Future<DeviceUsersResponse?> getDeviceUsers(int deviceId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/admin/device/$deviceId/users?user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== LISTAR USUÁRIOS DO DISPOSITIVO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📅 Data/Hora: ${DateTime.now()}');
    print('📱 Device ID: $deviceId');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final usersResponse = DeviceUsersResponse.fromJson(jsonData as Map<String, dynamic>);
        
        print('✅ Usuários carregados:');
        print('   Total: ${usersResponse.pagination.total}');
        print('   Usuários: ${usersResponse.data.length}');
        
        return usersResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro: $e');
      print(stackTrace);
      return null;
    }
  }

  static Future<RouteResponse?> getRoutes({int? page}) async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ getRoutes: user_api_hash não disponível');
        return null;
      }

      String url = "${UserRepository.getServerURL()}/api/get_routes?lang=br&user_api_hash=$userApiHash";
      if (page != null) {
        url += "&page=$page";
      }

      print('📡 getRoutes: Fazendo requisição para $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('📡 getRoutes: Status code: ${response.statusCode}');
      print('📡 getRoutes: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Verificar se a resposta tem a estrutura esperada
        if (jsonData is Map<String, dynamic>) {
          return RouteResponse.fromJson(jsonData);
        } else if (jsonData is List) {
          // Se retornar uma lista direta, criar estrutura de paginação vazia
          return RouteResponse(
            data: (jsonData as List<dynamic>)
                .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
                .toList(),
            pagination: RoutePagination(
              total: jsonData.length,
              perPage: jsonData.length,
              currentPage: 1,
              lastPage: 1,
              url: url,
            ),
          );
        }
      } else {
        print('❌ getRoutes: Erro na requisição - Status: ${response.statusCode}');
        print('❌ getRoutes: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ getRoutes: Erro ao buscar rotas: $e');
      print('❌ getRoutes: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Obter dados para criar motorista
  /// GET /api/add_user_driver_data
  static Future<AddDriverDataResponse?> getAddDriverData() async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ getAddDriverData: user_api_hash não disponível');
        return null;
      }

      final url = Uri.parse('${UserRepository.getServerURL()}/api/add_user_driver_data');
      
      final headers = {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
      };
      
      print('📡 getAddDriverData: Fazendo requisição GET para $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print('📡 getAddDriverData: Status code: ${response.statusCode}');
      print('📡 getAddDriverData: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AddDriverDataResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ getAddDriverData: Erro na requisição - Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ getAddDriverData: Erro: $e');
      print('❌ getAddDriverData: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Criar novo motorista
  /// POST /api/add_user_driver
  static Future<AddDriverResponse?> addUserDriver(DriverFormData driverData) async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ addUserDriver: user_api_hash não disponível');
        return null;
      }

      final url = Uri.parse('${UserRepository.getServerURL()}/api/add_user_driver');
      final body = jsonEncode(driverData.toJson());
      
      final headers = {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      print('📡 addUserDriver: Fazendo requisição POST para $url');
      print('📡 addUserDriver: Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 30));

      print('📡 addUserDriver: Status code: ${response.statusCode}');
      print('📡 addUserDriver: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AddDriverResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ addUserDriver: Erro na requisição - Status: ${response.statusCode}');
        print('❌ addUserDriver: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ addUserDriver: Erro: $e');
      print('❌ addUserDriver: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Obter dados para editar motorista
  /// GET /api/edit_user_driver_data
  static Future<EditDriverDataResponse?> getEditDriverData(int driverId) async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ getEditDriverData: user_api_hash não disponível');
        return null;
      }

      final url = Uri.parse('${UserRepository.getServerURL()}/api/edit_user_driver_data?id=$driverId');
      
      final headers = {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
      };
      
      print('📡 getEditDriverData: Fazendo requisição GET para $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(Duration(seconds: 30));

      print('📡 getEditDriverData: Status code: ${response.statusCode}');
      print('📡 getEditDriverData: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EditDriverDataResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ getEditDriverData: Erro na requisição - Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ getEditDriverData: Erro: $e');
      print('❌ getEditDriverData: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Editar motorista
  /// POST /api/edit_user_driver
  static Future<EditDriverResponse?> editUserDriver(DriverFormData driverData) async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ editUserDriver: user_api_hash não disponível');
        return null;
      }

      final url = Uri.parse('${UserRepository.getServerURL()}/api/edit_user_driver');
      final body = jsonEncode(driverData.toJson());
      
      final headers = {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      print('📡 editUserDriver: Fazendo requisição POST para $url');
      print('📡 editUserDriver: Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 30));

      print('📡 editUserDriver: Status code: ${response.statusCode}');
      print('📡 editUserDriver: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EditDriverResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ editUserDriver: Erro na requisição - Status: ${response.statusCode}');
        print('❌ editUserDriver: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ editUserDriver: Erro: $e');
      print('❌ editUserDriver: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Excluir motorista
  /// POST /api/destroy_user_driver
  static Future<DestroyDriverResponse?> destroyUserDriver(int driverId) async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ destroyUserDriver: user_api_hash não disponível');
        return null;
      }

      final url = Uri.parse('${UserRepository.getServerURL()}/api/destroy_user_driver');
      final body = jsonEncode({'id': driverId});
      
      final headers = {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      
      print('📡 destroyUserDriver: Fazendo requisição POST para $url');
      print('📡 destroyUserDriver: Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 30));

      print('📡 destroyUserDriver: Status code: ${response.statusCode}');
      print('📡 destroyUserDriver: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DestroyDriverResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ destroyUserDriver: Erro na requisição - Status: ${response.statusCode}');
        print('❌ destroyUserDriver: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ destroyUserDriver: Erro: $e');
      print('❌ destroyUserDriver: Stack trace: $stackTrace');
    }
    return null;
  }

  /// Obter dispositivos mais recentes com dados completos
  /// GET /api/get_devices_latest
  static Future<DeviceLatestResponse?> getDevicesLatest() async {
    try {
      final userApiHash = StaticVarMethod.user_api_hash;
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ getDevicesLatest: user_api_hash não disponível');
        return null;
      }

      final url = "${UserRepository.getServerURL()}/api/get_devices_latest?lang=br&user_api_hash=$userApiHash";
      print('📡 getDevicesLatest: Fazendo requisição para $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('📡 getDevicesLatest: Status code: ${response.statusCode}');
      print('📡 getDevicesLatest: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DeviceLatestResponse.fromJson(jsonData as Map<String, dynamic>);
      } else {
        print('❌ getDevicesLatest: Erro na requisição - Status: ${response.statusCode}');
        print('❌ getDevicesLatest: Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ getDevicesLatest: Erro: $e');
      print('❌ getDevicesLatest: Stack trace: $stackTrace');
    }
    return null;
  }

  // ========== AVALIAÇÕES (REVIEWS) ==========
  
  /// Salvar avaliação do usuário
  /// Endpoint: POST /api/review
  static Future<Map<String, dynamic>?> saveReview({
    required int userId,
    required String userName,
    required String userEmail,
    required int rating,
    String? comment,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/review?user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    final body = {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rating': rating,
      'comment': comment ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
    
    print('\n📡 ========== SALVAR AVALIAÇÃO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Avaliação salva com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao salvar avaliação: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Buscar todas as avaliações (apenas para admin)
  /// Endpoint: GET /api/reviews
  static Future<List<Review>?> getReviews() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/reviews?user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BUSCAR AVALIAÇÕES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<Review> reviews = [];
        
        if (jsonData is List) {
          for (var item in jsonData) {
            try {
              reviews.add(Review.fromJson(item as Map<String, dynamic>));
            } catch (e) {
              print('❌ Erro ao parsear avaliação: $e');
            }
          }
        } else if (jsonData is Map && jsonData['data'] != null) {
          for (var item in jsonData['data']) {
            try {
              reviews.add(Review.fromJson(item as Map<String, dynamic>));
            } catch (e) {
              print('❌ Erro ao parsear avaliação: $e');
            }
          }
        }
        
        print('✅ ${reviews.length} avaliações encontradas');
        return reviews;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar avaliações: $e');
      print(stackTrace);
      return null;
    }
  }


  /// Verificar se um ponto está dentro de geofences e violações
  /// Endpoint: GET /api/point_in_geofences
  static Future<Map<String, dynamic>?> checkPointInGeofences({
    required double lat,
    required double lng,
    double? speed,
    int? device_id,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    String url = "${UserRepository.getServerURL()}/api/point_in_geofences?lat=$lat&lng=$lng&lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    if (speed != null) {
      url += "&speed=$speed";
    }
    if (device_id != null) {
      url += "&device_id=$device_id";
    }
    
    print('\n📡 ========== VERIFICAR PONTO EM GEOFENCES ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Verificação realizada com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao verificar ponto em geofences: $e');
      print(stackTrace);
      return null;
    }
  }


  // ========== REPORTS API ==========
  
  /// Buscar lista de relatórios
  /// GET /api/get_reports
  static Future<ReportsResponse?> getReports({String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/get_reports?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BUSCAR RELATÓRIOS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final reportsResponse = ReportsResponse.fromJson(Map<String, dynamic>.from(jsonData));
        print('✅ Relatórios carregados com sucesso');
        return reportsResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar relatórios: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Buscar tipos de relatórios
  /// GET /api/get_reports_types
  static Future<List<ReportType>?> getReportsTypes({String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/get_reports_types?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BUSCAR TIPOS DE RELATÓRIOS ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<ReportType> types = [];
        
        if (jsonData['items'] != null && jsonData['items'] is List) {
          types = (jsonData['items'] as List).map((e) => ReportType.fromJson(Map<String, dynamic>.from(e))).toList();
        } else if (jsonData is List) {
          types = jsonData.map((e) => ReportType.fromJson(Map<String, dynamic>.from(e))).toList();
        }
        
        print('✅ ${types.length} tipos de relatórios encontrados');
        return types;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar tipos de relatórios: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Buscar dados para adicionar relatório (devices, geofences, formats, etc)
  /// GET /api/add_report_data
  static Future<AddReportDataResponse?> getAddReportData({String lang = 'en'}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/add_report_data?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BUSCAR DADOS PARA ADICIONAR RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final addReportData = AddReportDataResponse.fromJson(Map<String, dynamic>.from(jsonData));
        print('✅ Dados para adicionar relatório carregados com sucesso');
        return addReportData;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar dados para adicionar relatório: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Criar novo relatório
  /// POST /api/add_report
  static Future<Map<String, dynamic>?> addReport({
    required String title,
    required int type,
    required String format,
    List<int>? devices,
    List<int>? geofences,
    String? date_from,
    String? date_to,
    String? from_time,
    String? to_time,
    int? speed_limit,
    int? stops,
    bool? show_addresses,
    bool? zones_instead,
    int? daily,
    int? weekly,
    String? send_to_email,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/add_report?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    final body = {
      'title': title,
      'type': type,
      'format': format,
      'devices': devices ?? [],
      'geofences': geofences ?? [],
      if (date_from != null) 'date_from': date_from,
      if (date_to != null) 'date_to': date_to,
      if (from_time != null) 'from_time': from_time,
      if (to_time != null) 'to_time': to_time,
      if (speed_limit != null) 'speed_limit': speed_limit,
      if (stops != null) 'stops': stops,
      if (show_addresses != null) 'show_addresses': show_addresses,
      if (zones_instead != null) 'zones_instead': zones_instead,
      if (daily != null) 'daily': daily,
      if (weekly != null) 'weekly': weekly,
      if (send_to_email != null) 'send_to_email': send_to_email,
    };
    
    print('\n📡 ========== CRIAR RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Relatório criado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao criar relatório: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Editar relatório existente
  /// POST /api/edit_report
  static Future<Map<String, dynamic>?> editReport({
    required int id,
    required String title,
    required int type,
    required String format,
    List<int>? devices,
    List<int>? geofences,
    String? date_from,
    String? date_to,
    String? from_time,
    String? to_time,
    int? speed_limit,
    int? stops,
    bool? show_addresses,
    bool? zones_instead,
    int? daily,
    int? weekly,
    String? send_to_email,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/edit_report?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    final body = {
      'id': id,
      'title': title,
      'type': type,
      'format': format,
      'devices': devices ?? [],
      'geofences': geofences ?? [],
      if (date_from != null) 'date_from': date_from,
      if (date_to != null) 'date_to': date_to,
      if (from_time != null) 'from_time': from_time,
      if (to_time != null) 'to_time': to_time,
      if (speed_limit != null) 'speed_limit': speed_limit,
      if (stops != null) 'stops': stops,
      if (show_addresses != null) 'show_addresses': show_addresses,
      if (zones_instead != null) 'zones_instead': zones_instead,
      if (daily != null) 'daily': daily,
      if (weekly != null) 'weekly': weekly,
      if (send_to_email != null) 'send_to_email': send_to_email,
    };
    
    print('\n📡 ========== EDITAR RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Relatório editado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao editar relatório: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Gerar relatório
  /// POST /api/generate_report
  static Future<GenerateReportResponse?> generateReport({
    required String title,
    required int type,
    required String format,
    List<int>? devices,
    List<int>? geofences,
    String? date_from,
    String? date_to,
    String? from_time,
    String? to_time,
    int? speed_limit,
    int? stops,
    bool? show_addresses,
    bool? zones_instead,
    int? daily,
    int? weekly,
    String? send_to_email,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    headers['Content-Type'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/generate_report?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    final body = {
      'title': title,
      'type': type,
      'format': format,
      'devices': devices ?? [],
      'geofences': geofences ?? [],
      if (date_from != null) 'date_from': date_from,
      if (date_to != null) 'date_to': date_to,
      if (from_time != null) 'from_time': from_time,
      if (to_time != null) 'to_time': to_time,
      if (speed_limit != null) 'speed_limit': speed_limit,
      if (stops != null) 'stops': stops,
      if (show_addresses != null) 'show_addresses': show_addresses,
      if (zones_instead != null) 'zones_instead': zones_instead,
      if (daily != null) 'daily': daily,
      if (weekly != null) 'weekly': weekly,
      if (send_to_email != null) 'send_to_email': send_to_email,
    };
    
    print('\n📡 ========== GERAR RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    print('📤 Body: ${json.encode(body)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final generateResponse = GenerateReportResponse.fromJson(Map<String, dynamic>.from(jsonData));
        print('✅ Relatório gerado com sucesso!');
        if (generateResponse.url != null) {
          print('📄 URL do relatório: ${generateResponse.url}');
        }
        return generateResponse;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao gerar relatório: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Deletar relatório
  /// GET /api/destroy_report
  static Future<Map<String, dynamic>?> destroyReport({
    required int id,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/destroy_report?id=$id&lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== DELETAR RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Relatório deletado com sucesso!');
        return jsonData as Map<String, dynamic>;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao deletar relatório: $e');
      print(stackTrace);
      return null;
    }
  }

  /// Download log de relatório
  /// GET /api/reports/logs/{id}/download
  static Future<http.Response?> downloadReportLog({
    required int id,
    String lang = 'en',
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    headers['Accept'] = "application/json";
    
    final url = "${UserRepository.getServerURL()}/api/reports/logs/$id/download?lang=$lang&user_api_hash=${StaticVarMethod.user_api_hash!}";
    
    print('\n📡 ========== BAIXAR LOG DE RELATÓRIO ==========');
    print('🌐 URL: ${url.replaceAll(StaticVarMethod.user_api_hash!, '***')}');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 30));
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Log de relatório baixado com sucesso!');
        return response;
      } else {
        print('❌ Erro: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Erro ao baixar log de relatório: $e');
      print(stackTrace);
      return null;
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
