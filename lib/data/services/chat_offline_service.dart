import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/data/model/internal_chat_message.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço para gerenciar cache offline do chat
class ChatOfflineService {
  static final ChatOfflineService _instance = ChatOfflineService._internal();
  factory ChatOfflineService() => _instance;
  ChatOfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  /// Verificar se está online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);
      return _isOnline;
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Inicializar listener de conectividade
  void initializeConnectivityListener(Function(bool) onConnectivityChanged) {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      _isOnline = isOnline;
      onConnectivityChanged(isOnline);
    });
  }

  /// Salvar mensagens localmente
  Future<void> saveMessages(int receiverId, List<InternalChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_messages_$receiverId';
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(messagesJson));
      await prefs.setString('${key}_last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('Erro ao salvar mensagens offline: $e');
    }
  }

  /// Carregar mensagens do cache
  Future<List<InternalChatMessage>> loadCachedMessages(int receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_messages_$receiverId';
      final messagesJson = prefs.getString(key);
      
      if (messagesJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(messagesJson);
      return decoded.map((json) => InternalChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao carregar mensagens do cache: $e');
      return [];
    }
  }

  /// Salvar mensagem pendente para envio
  Future<void> savePendingMessage(int receiverId, Map<String, dynamic> messageData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_pending_$receiverId';
      final pending = prefs.getStringList(key) ?? [];
      pending.add(jsonEncode(messageData));
      await prefs.setStringList(key, pending);
    } catch (e) {
      print('Erro ao salvar mensagem pendente: $e');
    }
  }

  /// Carregar mensagens pendentes
  Future<List<Map<String, dynamic>>> loadPendingMessages(int receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_pending_$receiverId';
      final pending = prefs.getStringList(key) ?? [];
      return pending.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
    } catch (e) {
      print('Erro ao carregar mensagens pendentes: $e');
      return [];
    }
  }

  /// Remover mensagem pendente após envio bem-sucedido
  Future<void> removePendingMessage(int receiverId, String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_pending_$receiverId';
      final pending = prefs.getStringList(key) ?? [];
      pending.removeWhere((json) {
        try {
          final data = jsonDecode(json) as Map<String, dynamic>;
          return data['temp_id'] == messageId;
        } catch (e) {
          return false;
        }
      });
      await prefs.setStringList(key, pending);
    } catch (e) {
      print('Erro ao remover mensagem pendente: $e');
    }
  }

  /// Limpar todas as mensagens pendentes
  Future<void> clearPendingMessages(int receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_pending_$receiverId';
      await prefs.remove(key);
    } catch (e) {
      print('Erro ao limpar mensagens pendentes: $e');
    }
  }

  /// Obter última data de sincronização
  Future<DateTime?> getLastSyncTime(int receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'chat_messages_${receiverId}_last_sync';
      final lastSync = prefs.getString(key);
      if (lastSync == null) return null;
      return DateTime.parse(lastSync);
    } catch (e) {
      print('Erro ao obter última sincronização: $e');
      return null;
    }
  }

  /// Limpar cache de um chat específico
  Future<void> clearCache(int receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages_$receiverId');
      await prefs.remove('chat_messages_${receiverId}_last_sync');
      await prefs.remove('chat_pending_$receiverId');
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }
}
