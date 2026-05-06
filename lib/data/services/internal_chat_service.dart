import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/data/model/internal_chat_contact.dart';
import 'package:uconnect/data/model/internal_chat_message.dart';
import 'package:uconnect/data/model/internal_chat_responses.dart';
import 'package:uconnect/utils/Session.dart' as SessionUtils;

class InternalChatService {
  final String baseUrl;
  final HttpClient _httpClient;

  InternalChatService({String? baseUrl})
      : baseUrl = baseUrl ?? UserRepository.getServerURL(),
        _httpClient = _createHttpClient();

  static HttpClient _createHttpClient() {
    return HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
  }

  // Helper para configurar headers e cookies
  Future<void> _setHeadersCookies(HttpClientRequest request, String url) async {
    final token = StaticVarMethod.user_api_hash ?? '';
    
    request.headers.set('content-type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Connection', 'close');
    
    // Adicionar cookies
    final cookies = await SessionUtils.cj.loadForRequest(Uri.parse(url));
    request.cookies.addAll(cookies);
  }

  // Helper para atualizar cookies da resposta
  void _updateCookies(HttpClientResponse response, String url) {
    SessionUtils.cj.saveFromResponse(Uri.parse(url), response.cookies);
  }

  // Helper para fazer requisição GET
  Future<String> _httpGet(String url) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.getUrl(uri);
    await _setHeadersCookies(request, url);
    
    final response = await request.close();
    _updateCookies(response, uri.toString());
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw HttpException('Erro HTTP ${response.statusCode}: $responseBody');
    }
  }

  // Helper para fazer requisição POST JSON
  Future<String> _httpPost(String url, Map<String, dynamic> data) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.postUrl(uri);
    await _setHeadersCookies(request, url);
    
    // Nota: Rotas de API (/api/internal-chat/*) não precisam de CSRF token
    // Apenas rotas /admin/* precisam
    
    request.add(utf8.encode(jsonEncode(data)));
    final response = await request.close();
    _updateCookies(response, uri.toString());
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseBody;
    } else {
      throw HttpException('Erro HTTP ${response.statusCode}: $responseBody');
    }
  }

  // Helper para fazer requisição DELETE
  Future<String> _httpDelete(String url, {Map<String, dynamic>? data}) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.deleteUrl(uri);
    await _setHeadersCookies(request, url);
    
    // Nota: Rotas de API (/api/internal-chat/*) não precisam de CSRF token
    
    if (data != null) {
      request.add(utf8.encode(jsonEncode(data)));
    }
    
    final response = await request.close();
    _updateCookies(response, uri.toString());
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw HttpException('Erro HTTP ${response.statusCode}: $responseBody');
    }
  }

  // Helper para fazer requisição POST Multipart (para arquivos)
  Future<String> _httpPostMultipart(
    String url,
    Map<String, String> fields,
    List<File> files,
  ) async {
    final uri = Uri.parse(url);
    final request = await _httpClient.postUrl(uri);
    
    final token = StaticVarMethod.user_api_hash ?? '';
    request.headers.set('Accept', 'application/json');
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Connection', 'close');
    
    // Adicionar cookies
    final cookies = await SessionUtils.cj.loadForRequest(uri);
    request.cookies.addAll(cookies);
    
    // Nota: Rotas de API (/api/internal-chat/*) não precisam de CSRF token
    
    // Criar boundary para multipart
    final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
    
    final buffer = StringBuffer();
    
    // Adicionar campos
    fields.forEach((key, value) {
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Disposition: form-data; name="$key"');
      buffer.writeln();
      buffer.writeln(value);
    });
    
    // Adicionar arquivos
    for (var file in files) {
      final fileName = file.path.split('/').last;
      buffer.writeln('--$boundary');
      buffer.writeln('Content-Disposition: form-data; name="file"; filename="$fileName"');
      buffer.writeln('Content-Type: application/octet-stream');
      buffer.writeln();
      
      final fileBytes = await file.readAsBytes();
      request.add(utf8.encode(buffer.toString()));
      request.add(fileBytes);
      buffer.clear();
    }
    
    buffer.writeln('--$boundary--');
    request.add(utf8.encode(buffer.toString()));
    
    final response = await request.close();
    _updateCookies(response, uri.toString());
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseBody;
    } else {
      throw HttpException('Erro HTTP ${response.statusCode}: $responseBody');
    }
  }


  // 1. Listar contatos
  Future<List<InternalChatContact>> getContacts() async {
    try {
      final responseBody = await _httpGet('$baseUrl/api/internal-chat/contacts');
      final List<dynamic> data = jsonDecode(responseBody);
      return data.map((c) => InternalChatContact.fromJson(c)).toList();
    } catch (e) {
      throw Exception('Erro ao carregar contatos: $e');
    }
  }

  // 2. Buscar mensagens
  Future<MessagesResponse> getMessages(int receiverId) async {
    try {
      final responseBody = await _httpGet('$baseUrl/api/internal-chat/messages/$receiverId');
      return MessagesResponse.fromJson(jsonDecode(responseBody));
    } catch (e) {
      throw Exception('Erro ao carregar mensagens: $e');
    }
  }

  // 3. Enviar mensagem
  Future<InternalChatMessage> sendMessage({
    required int receiverId,
    String? message,
    File? file,
    int? replyToId,
    bool isRequest = false,
  }) async {
    try {
      final fields = <String, String>{
        'receiver_id': receiverId.toString(),
      };

      if (message != null && message.isNotEmpty) {
        fields['message'] = message;
      }

      if (replyToId != null) {
        fields['reply_to_id'] = replyToId.toString();
      }

      if (isRequest) {
        fields['is_request'] = '1';
      }

      String responseBody;
      
      if (file != null) {
        // Enviar com arquivo (multipart)
        if (message == null || message.isEmpty) {
          fields['message'] = file.path.split('/').last;
        }
        responseBody = await _httpPostMultipart(
          '$baseUrl/api/internal-chat/send',
          fields,
          [file],
        );
      } else {
        // Enviar apenas texto (JSON)
        responseBody = await _httpPost(
          '$baseUrl/api/internal-chat/send',
          fields,
        );
      }

      return InternalChatMessage.fromJson(jsonDecode(responseBody));
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  // 4. Verificar novas mensagens
  Future<CheckMessagesResponse> checkNewMessages() async {
    try {
      final responseBody = await _httpGet('$baseUrl/api/internal-chat/check');
      return CheckMessagesResponse.fromJson(jsonDecode(responseBody));
    } catch (e) {
      throw Exception('Erro ao verificar mensagens: $e');
    }
  }

  // 5. Marcar todas como lidas
  Future<void> markAllAsRead() async {
    try {
      await _httpPost('$baseUrl/api/internal-chat/read-all', {});
    } catch (e) {
      throw Exception('Erro ao marcar como lido: $e');
    }
  }

  // 6. Indicar digitação
  Future<void> setTyping(int receiverId) async {
    try {
      await _httpPost('$baseUrl/api/internal-chat/typing', {
        'receiver_id': receiverId.toString(),
      });
    } catch (e) {
      throw Exception('Erro ao enviar status de digitação: $e');
    }
  }

  // 7. Excluir mensagem
  Future<void> deleteMessage(int messageId) async {
    try {
      await _httpDelete('$baseUrl/api/internal-chat/message/$messageId', data: {});
    } catch (e) {
      throw Exception('Erro ao excluir mensagem: $e');
    }
  }

  // 8. Fixar/desfixar mensagem
  Future<bool> togglePin(int messageId) async {
    try {
      final responseBody = await _httpPost('$baseUrl/api/internal-chat/message/$messageId/pin', {});
      final data = jsonDecode(responseBody);
      return data['is_pinned'] ?? false;
    } catch (e) {
      throw Exception('Erro ao fixar mensagem: $e');
    }
  }

  // 9. Reagir à mensagem
  Future<Map<String, dynamic>> reactToMessage(int messageId, String emoji) async {
    try {
      final responseBody = await _httpPost('$baseUrl/api/internal-chat/message/$messageId/react', {
        'emoji': emoji,
      });
      return jsonDecode(responseBody);
    } catch (e) {
      throw Exception('Erro ao reagir à mensagem: $e');
    }
  }

  // 10. Baixar histórico
  Future<Uint8List> downloadHistory(int userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/internal-chat/history/$userId');
      final request = await _httpClient.getUrl(uri);
      await _setHeadersCookies(request, uri.toString());
      
      final response = await request.close();
      _updateCookies(response, uri.toString());
      
      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (var chunk in response) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      } else {
        throw HttpException('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao baixar histórico: $e');
    }
  }

  // 11. Listar dispositivos
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final responseBody = await _httpGet('$baseUrl/api/internal-chat/devices');
      return List<Map<String, dynamic>>.from(jsonDecode(responseBody));
    } catch (e) {
      throw Exception('Erro ao carregar dispositivos: $e');
    }
  }

  // 12. Ação de pânico
  Future<void> triggerPanicAction(int deviceId) async {
    try {
      await _httpPost('$baseUrl/api/internal-chat/panic-action', {
        'device_id': deviceId.toString(),
        'type': 'engineStop',
      });
    } catch (e) {
      throw Exception('Erro ao disparar ação de pânico: $e');
    }
  }

  // 13. Salvar configurações
  Future<void> saveSettings({
    String? btnColor,
    String? headerColor,
    String? chatName,
    String? chatAvatar,
    String? floatingBtnColor,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (btnColor != null) data['chat_btn_color'] = btnColor;
      if (headerColor != null) data['chat_header_color'] = headerColor;
      if (chatName != null) data['chat_name'] = chatName;
      if (chatAvatar != null) data['chat_avatar'] = chatAvatar;
      if (floatingBtnColor != null) data['floating_btn_color'] = floatingBtnColor;
      
      await _httpPost('$baseUrl/api/internal-chat/settings', data);
    } catch (e) {
      throw Exception('Erro ao salvar configurações: $e');
    }
  }

  // 14. Buscar configurações do usuário
  Future<Map<String, dynamic>> getSettings() async {
    try {
      // Buscar settings via getContacts que retorna user settings
      final contacts = await getContacts();
      if (contacts.isNotEmpty) {
        // Tentar buscar de um contato específico para pegar user settings
        // Por enquanto, vamos usar getMessages que retorna user settings
        final firstContact = contacts.first;
        final response = await getMessages(firstContact.id);
        return response.user;
      }
      return {};
    } catch (e) {
      print('Erro ao buscar configurações: $e');
      return {};
    }
  }

  // Fechar cliente HTTP quando não precisar mais
  void dispose() {
    _httpClient.close(force: true);
  }
}
