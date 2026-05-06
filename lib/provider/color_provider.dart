import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/config/static.dart';

class ColorProvider extends ChangeNotifier {
  static const String _primaryColorKeyPrefix = 'primary_color_';
  static const String _secondaryColorKeyPrefix = 'secondary_color_';
  static const String _accentColorKeyPrefix = 'accent_color_';
  static const String _lastSyncKeyPrefix = 'last_sync_colors_';
  static const String _templateColorKeyPrefix = 'template_color_';
  
  // Cores padrão baseadas em templates comuns
  static const Map<String, Color> _templateColors = {
    'blue': Color(0xFF3b82f6),
    'light-blue': Color(0xFF3b82f6),
    'green': Color(0xFF10b981),
    'purple': Color(0xFF8b5cf6),
    'red': Color(0xFFef4444),
    'orange': Color(0xFFf97316),
    'indigo': Color(0xFF6366f1),
  };
  
  Color _primaryColor = const Color(0xFF3b82f6); // Azul padrão
  Color _secondaryColor = const Color(0xFF6b7280); // Cinza padrão
  Color? _accentColor;
  
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  Color? get accentColor => _accentColor;
  
  ColorProvider() {
    _loadColors();
  }
  
  /// Sincroniza cores do servidor automaticamente
  Future<void> syncColorsFromServer() async {
    try {
      final userHash = await _getUserHash();
      if (userHash == 'default' || userHash.isEmpty) {
        print('⚠️ ColorProvider: Nenhum usuário logado, pulando sincronização');
        return;
      }
      
      final baseUrl = UserRepository.getServerURL();
      final url = Uri.parse('$baseUrl/api/mobile/config?user_api_hash=$userHash');
      
      print('🔄 ColorProvider: Sincronizando cores do servidor...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'user-api-hash': userHash,
          'Authorization': 'Bearer $userHash',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ ColorProvider: Timeout ao buscar cores do servidor');
          return http.Response('Timeout', 408);
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await _updateColorsFromServerData(data, userHash);
        print('✅ ColorProvider: Cores sincronizadas com sucesso');
      } else {
        print('⚠️ ColorProvider: Erro ao buscar cores: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ColorProvider: Erro ao sincronizar cores: $e');
    }
  }
  
  /// Atualiza cores a partir dos dados do servidor
  Future<void> _updateColorsFromServerData(
    Map<String, dynamic> data,
    String userHash,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Processar primary_color
    if (data.containsKey('primary_color') && data['primary_color'] != null) {
      final primaryColorHex = data['primary_color'] as String;
      final primaryColor = _hexToColor(primaryColorHex);
      _primaryColor = primaryColor;
      final primaryKey = '${_primaryColorKeyPrefix}$userHash';
      await prefs.setInt(primaryKey, primaryColor.value);
    }
    
    // Processar secondary_color
    if (data.containsKey('secondary_color') && data['secondary_color'] != null) {
      final secondaryColorHex = data['secondary_color'] as String;
      final secondaryColor = _hexToColor(secondaryColorHex);
      _secondaryColor = secondaryColor;
      final secondaryKey = '${_secondaryColorKeyPrefix}$userHash';
      await prefs.setInt(secondaryKey, secondaryColor.value);
    }
    
    // Processar accent_color
    if (data.containsKey('accent_color') && data['accent_color'] != null) {
      final accentColorHex = data['accent_color'] as String;
      final accentColor = _hexToColor(accentColorHex);
      _accentColor = accentColor;
      final accentKey = '${_accentColorKeyPrefix}$userHash';
      await prefs.setInt(accentKey, accentColor.value);
    }
    
    // Processar template_color (fallback)
    if (data.containsKey('template_color') && data['template_color'] != null) {
      final templateColor = data['template_color'] as String;
      await prefs.setString('${_templateColorKeyPrefix}$userHash', templateColor);
      
      // Se não houver primary_color, usar template_color
      if (!data.containsKey('primary_color') || data['primary_color'] == null) {
        final templatePrimaryColor = _getTemplateColor(templateColor);
        _primaryColor = templatePrimaryColor;
        final primaryKey = '${_primaryColorKeyPrefix}$userHash';
        await prefs.setInt(primaryKey, templatePrimaryColor.value);
      }
    }
    
    // Salvar timestamp da última sincronização
    final lastSyncKey = '${_lastSyncKeyPrefix}$userHash';
    await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    
    notifyListeners();
  }
  
  /// Converte hexadecimal para Color
  Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Adiciona alpha se não tiver
      }
      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (e) {
      print('⚠️ ColorProvider: Erro ao converter cor hex $hex: $e');
      return const Color(0xFF3b82f6); // Fallback
    }
  }
  
  /// Obtém cor baseada no template
  Color _getTemplateColor(String template) {
    return _templateColors[template.toLowerCase()] ?? 
           _templateColors['blue']!;
  }
  
  /// Verifica se precisa sincronizar (última sync há mais de 1 hora)
  Future<bool> shouldSync() async {
    try {
      final userHash = await _getUserHash();
      if (userHash == 'default' || userHash.isEmpty) {
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lastSyncKey = '${_lastSyncKeyPrefix}$userHash';
      final lastSync = prefs.getInt(lastSyncKey);
      
      if (lastSync == null) {
        return true; // Nunca sincronizou
      }
      
      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final now = DateTime.now();
      final difference = now.difference(lastSyncTime);
      
      // Sincronizar se passou mais de 1 hora
      return difference.inHours >= 1;
    } catch (e) {
      print('⚠️ ColorProvider: Erro ao verificar se precisa sincronizar: $e');
      return false;
    }
  }
  
  /// Força sincronização imediata (ignora cache)
  Future<bool> forceSync() async {
    try {
      final userHash = await _getUserHash();
      if (userHash == 'default' || userHash.isEmpty) {
        return false;
      }
      
      // Remover timestamp da última sincronização para forçar
      final prefs = await SharedPreferences.getInstance();
      final lastSyncKey = '${_lastSyncKeyPrefix}$userHash';
      await prefs.remove(lastSyncKey);
      
      await syncColorsFromServer();
      return true;
    } catch (e) {
      print('❌ ColorProvider: Erro ao forçar sincronização: $e');
      return false;
    }
  }
  
  // Método auxiliar para obter o userHash do usuário logado (isolamento por usuário)
  Future<String> _getUserHash() async {
    // Tentar primeiro do StaticVarMethod (mais atualizado)
    final staticHash = StaticVarMethod.user_api_hash;
    if (staticHash != null && 
        staticHash.isNotEmpty && 
        staticHash != "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G") {
      return staticHash;
    }
    
    // Fallback para SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userHash = prefs.getString('user_api_hash');
    if (userHash != null && 
        userHash.isNotEmpty && 
        userHash != "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G") {
      return userHash;
    }
    
    // Fallback para email se userHash não estiver disponível
    final email = prefs.getString('email');
    return email ?? 'default';
  }
  
  // Método auxiliar para criar chave única por usuário usando userHash
  Future<String> _getPrimaryColorKey() async {
    final userHash = await _getUserHash();
    return '${_primaryColorKeyPrefix}$userHash';
  }
  
  Future<String> _getSecondaryColorKey() async {
    final userHash = await _getUserHash();
    return '${_secondaryColorKeyPrefix}$userHash';
  }
  
  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    
    final primaryKey = '${_primaryColorKeyPrefix}$userHash';
    final secondaryKey = '${_secondaryColorKeyPrefix}$userHash';
    final accentKey = '${_accentColorKeyPrefix}$userHash';
    
    final primaryColorValue = prefs.getInt(primaryKey);
    final secondaryColorValue = prefs.getInt(secondaryKey);
    final accentColorValue = prefs.getInt(accentKey);
    
    if (primaryColorValue != null) {
      _primaryColor = Color(primaryColorValue);
    }
    if (secondaryColorValue != null) {
      _secondaryColor = Color(secondaryColorValue);
    }
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    
    notifyListeners();
    
    // Verificar se precisa sincronizar após carregar cores
    if (await shouldSync()) {
      syncColorsFromServer();
    }
  }
  
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    final key = '${_primaryColorKeyPrefix}$userHash';
    await prefs.setInt(key, color.value);
    notifyListeners();
  }
  
  Future<void> setSecondaryColor(Color color) async {
    _secondaryColor = color;
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    final key = '${_secondaryColorKeyPrefix}$userHash';
    await prefs.setInt(key, color.value);
    notifyListeners();
  }
  
  Future<void> setAccentColor(Color? color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    final key = '${_accentColorKeyPrefix}$userHash';
    if (color != null) {
      await prefs.setInt(key, color.value);
    } else {
      await prefs.remove(key);
    }
    notifyListeners();
  }
  
  Future<void> resetColors() async {
    _primaryColor = const Color(0xFF3b82f6);
    _secondaryColor = const Color(0xFF6b7280);
    _accentColor = null;
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    final primaryKey = '${_primaryColorKeyPrefix}$userHash';
    final secondaryKey = '${_secondaryColorKeyPrefix}$userHash';
    final accentKey = '${_accentColorKeyPrefix}$userHash';
    await prefs.remove(primaryKey);
    await prefs.remove(secondaryKey);
    await prefs.remove(accentKey);
    notifyListeners();
  }
}










