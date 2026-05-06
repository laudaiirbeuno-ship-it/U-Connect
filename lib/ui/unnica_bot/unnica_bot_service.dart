import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uconnect/storage/user_repository.dart';

/// Status do bot UnnicaBot
class BotStatus {
  final bool botEnabled;
  final bool geminiConfigured;
  final int usageLimit;
  final int usageCurrent;
  final int usageRemaining;
  final bool isAdmin;
  final bool isManager;

  BotStatus({
    required this.botEnabled,
    required this.geminiConfigured,
    required this.usageLimit,
    required this.usageCurrent,
    required this.usageRemaining,
    required this.isAdmin,
    required this.isManager,
  });

  factory BotStatus.fromJson(Map<String, dynamic> json) {
    return BotStatus(
      botEnabled: json['bot_enabled'] ?? false,
      geminiConfigured: json['gemini_configured'] ?? false,
      usageLimit: json['usage_limit'] ?? 100,
      usageCurrent: json['usage_current'] ?? 0,
      usageRemaining: json['usage_remaining'] ?? 100,
      isAdmin: json['is_admin'] ?? false,
      isManager: json['is_manager'] ?? false,
    );
  }
}

/// Resposta do chat
class ChatResponse {
  final int status;
  final String? response;
  final String? message;
  final String type;
  final List<dynamic>? buttons;
  final String mode;
  final Map<String, dynamic> payload;
  final List<dynamic>? devices;
  final List<dynamic>? reportTypes;
  final String? url;
  final Map<String, dynamic>? table;
  final Map<String, dynamic>? totals;
  final Map<String, dynamic>? detailedSummary;
  final Map<String, dynamic>? data;

  ChatResponse({
    required this.status,
    this.response,
    this.message,
    this.type = 'text',
    this.buttons,
    this.mode = 'default',
    this.payload = const {},
    this.devices,
    this.reportTypes,
    this.url,
    this.table,
    this.totals,
    this.detailedSummary,
    this.data,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      status: json['status'] ?? 0,
      response: json['response'],
      message: json['message'],
      type: json['type'] ?? 'text',
      buttons: json['buttons'],
      mode: json['mode'] ?? 'default',
      payload: json['payload'] ?? {},
      devices: json['devices'],
      reportTypes: json['report_types'],
      url: json['url'],
      table: json['table'],
      totals: json['totals'],
      detailedSummary: json['detailed_summary'],
      data: json['data'],
    );
  }
}

/// Serviço para comunicação com a API do UnnicaBot
class UnnicaBotService {
  String? token;
  final String baseUrl;

  UnnicaBotService({this.token, String? baseUrl})
      : baseUrl = baseUrl ?? UserRepository.getServerURL();

  /// Obtém o status do bot
  Future<BotStatus?> getStatus() async {
    if (token == null || token!.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse('$baseUrl/api/tracker-bot/status?user_api_hash=$token');

      final response = await http.get(
        url,
        headers: {
          'user-api-hash': token!,
          'Authorization': 'Bearer $token!',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1) {
          return BotStatus.fromJson(data);
        }
      }
    } catch (e) {
      print('❌ Erro ao obter status do bot: $e');
    }

    return null;
  }

  /// Envia mensagem ao bot
  Future<ChatResponse> sendMessage({
    required String message,
    required List<Map<String, String>> history,
    String mode = 'default',
    Map<String, dynamic> payload = const {},
  }) async {
    if (token == null || token!.isEmpty) {
      return ChatResponse(
        status: 0,
        message: 'Token de autenticação não encontrado',
      );
    }

    try {
      final url = Uri.parse('$baseUrl/api/tracker-bot/chat?user_api_hash=$token');

      final body = json.encode({
        'message': message,
        'history': history,
        'mode': mode,
        'payload': payload,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'user-api-hash': token!,
          'Authorization': 'Bearer $token!',
        },
        body: body,
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ChatResponse.fromJson(data);
      } else {
        return ChatResponse(
          status: 0,
          message: 'Erro ao comunicar com o servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e');
      return ChatResponse(
        status: 0,
        message: 'Erro de conexão: $e',
      );
    }
  }

  /// Obtém alertas recentes
  Future<List<Map<String, dynamic>>> getAlerts() async {
    if (token == null || token!.isEmpty) {
      return [];
    }

    try {
      final url = Uri.parse('$baseUrl/api/tracker-bot/alerts?user_api_hash=$token');

      final response = await http.get(
        url,
        headers: {
          'user-api-hash': token!,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
    } catch (e) {
      print('❌ Erro ao obter alertas: $e');
    }

    return [];
  }
}





