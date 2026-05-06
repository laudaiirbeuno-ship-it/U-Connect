import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/config/static.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LogoProvider extends ChangeNotifier {
  static const String _mainLogoUrlKeyPrefix = 'main_logo_url_';
  static const String _appLogoUrlKeyPrefix = 'app_logo_url_';
  static const String _splashLogoUrlKeyPrefix = 'splash_logo_url_';
  static const String _loginLogoUrlKeyPrefix = 'login_logo_url_';
  static const String _lastSyncKeyPrefix = 'last_sync_logos_';
  
  String? _mainLogoUrl;
  String? _appLogoUrl;
  String? _splashLogoUrl;
  String? _loginLogoUrl;
  
  String? get mainLogoUrl => _mainLogoUrl;
  String? get appLogoUrl => _appLogoUrl;
  String? get splashLogoUrl => _splashLogoUrl;
  String? get loginLogoUrl => _loginLogoUrl;
  
  // URLs finais (app_logo tem prioridade sobre main_logo)
  String? get finalMainLogoUrl => _appLogoUrl ?? _mainLogoUrl;
  String? get finalLoginLogoUrl => _loginLogoUrl ?? _mainLogoUrl ?? _appLogoUrl;
  
  // Getters booleanos para verificar se há logos disponíveis
  bool get hasMainLogo => finalMainLogoUrl != null && finalMainLogoUrl!.isNotEmpty;
  bool get hasAppLogo => _appLogoUrl != null && _appLogoUrl!.isNotEmpty;
  bool get hasSplashLogo => _splashLogoUrl != null && _splashLogoUrl!.isNotEmpty;
  bool get hasLoginLogo => finalLoginLogoUrl != null && finalLoginLogoUrl!.isNotEmpty;
  
  LogoProvider() {
    _loadLogos();
  }
  
  /// Sincroniza logos do servidor automaticamente
  Future<void> syncLogosFromServer() async {
    try {
      final userHash = await _getUserHash();
      if (userHash == 'default' || userHash.isEmpty) {
        print('⚠️ LogoProvider: Nenhum usuário logado, pulando sincronização');
        return;
      }
      
      final baseUrl = UserRepository.getServerURL();
      final url = Uri.parse('$baseUrl/api/mobile/config?user_api_hash=$userHash');
      
      print('🔄 LogoProvider: Sincronizando logos do servidor...');
      
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
          print('⏱️ LogoProvider: Timeout ao buscar logos do servidor');
          return http.Response('Timeout', 408);
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await _updateLogosFromServerData(data, userHash);
        
        // Fazer download e cache das imagens
        await _downloadAndCacheLogos(userHash);
        
        print('✅ LogoProvider: Logos sincronizados com sucesso');
      } else {
        print('⚠️ LogoProvider: Erro ao buscar logos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ LogoProvider: Erro ao sincronizar logos: $e');
    }
  }
  
  /// Atualiza URLs dos logos a partir dos dados do servidor
  Future<void> _updateLogosFromServerData(
    Map<String, dynamic> data,
    String userHash,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Processar main_logo
    if (data.containsKey('main_logo') && data['main_logo'] != null) {
      final mainLogoUrl = data['main_logo'] as String;
      if (mainLogoUrl.isNotEmpty) {
        _mainLogoUrl = mainLogoUrl;
        await prefs.setString('${_mainLogoUrlKeyPrefix}$userHash', mainLogoUrl);
      }
    }
    
    // Processar app_logo (tem prioridade sobre main_logo)
    if (data.containsKey('app_logo') && data['app_logo'] != null) {
      final appLogoUrl = data['app_logo'] as String;
      if (appLogoUrl.isNotEmpty) {
        _appLogoUrl = appLogoUrl;
        await prefs.setString('${_appLogoUrlKeyPrefix}$userHash', appLogoUrl);
      }
    }
    
    // Processar splash_logo
    if (data.containsKey('splash_logo') && data['splash_logo'] != null) {
      final splashLogoUrl = data['splash_logo'] as String;
      if (splashLogoUrl.isNotEmpty) {
        _splashLogoUrl = splashLogoUrl;
        await prefs.setString('${_splashLogoUrlKeyPrefix}$userHash', splashLogoUrl);
      }
    }
    
    // Processar login_logo
    if (data.containsKey('login_logo') && data['login_logo'] != null) {
      final loginLogoUrl = data['login_logo'] as String;
      if (loginLogoUrl.isNotEmpty) {
        _loginLogoUrl = loginLogoUrl;
        await prefs.setString('${_loginLogoUrlKeyPrefix}$userHash', loginLogoUrl);
      }
    }
    
    // Salvar timestamp da última sincronização
    final lastSyncKey = '${_lastSyncKeyPrefix}$userHash';
    await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    
    notifyListeners();
  }
  
  /// Faz download e cache das imagens dos logos
  Future<void> _downloadAndCacheLogos(String userHash) async {
    final cacheManager = DefaultCacheManager();
    
    try {
      // Cache main_logo
      if (_mainLogoUrl != null && _mainLogoUrl!.isNotEmpty) {
        try {
          await cacheManager.getSingleFile(_mainLogoUrl!);
          print('✅ LogoProvider: main_logo em cache');
        } catch (e) {
          print('⚠️ LogoProvider: Erro ao fazer cache do main_logo: $e');
        }
      }
      
      // Cache app_logo
      if (_appLogoUrl != null && _appLogoUrl!.isNotEmpty) {
        try {
          await cacheManager.getSingleFile(_appLogoUrl!);
          print('✅ LogoProvider: app_logo em cache');
        } catch (e) {
          print('⚠️ LogoProvider: Erro ao fazer cache do app_logo: $e');
        }
      }
      
      // Cache splash_logo
      if (_splashLogoUrl != null && _splashLogoUrl!.isNotEmpty) {
        try {
          await cacheManager.getSingleFile(_splashLogoUrl!);
          print('✅ LogoProvider: splash_logo em cache');
        } catch (e) {
          print('⚠️ LogoProvider: Erro ao fazer cache do splash_logo: $e');
        }
      }
      
      // Cache login_logo
      if (_loginLogoUrl != null && _loginLogoUrl!.isNotEmpty) {
        try {
          await cacheManager.getSingleFile(_loginLogoUrl!);
          print('✅ LogoProvider: login_logo em cache');
        } catch (e) {
          print('⚠️ LogoProvider: Erro ao fazer cache do login_logo: $e');
        }
      }
    } catch (e) {
      print('❌ LogoProvider: Erro geral ao fazer cache dos logos: $e');
    }
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
      print('⚠️ LogoProvider: Erro ao verificar se precisa sincronizar: $e');
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
      
      await syncLogosFromServer();
      return true;
    } catch (e) {
      print('❌ LogoProvider: Erro ao forçar sincronização: $e');
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
  
  /// Carrega URLs dos logos salvos localmente
  Future<void> _loadLogos() async {
    final prefs = await SharedPreferences.getInstance();
    final userHash = await _getUserHash();
    
    final mainLogoKey = '${_mainLogoUrlKeyPrefix}$userHash';
    final appLogoKey = '${_appLogoUrlKeyPrefix}$userHash';
    final splashLogoKey = '${_splashLogoUrlKeyPrefix}$userHash';
    final loginLogoKey = '${_loginLogoUrlKeyPrefix}$userHash';
    
    _mainLogoUrl = prefs.getString(mainLogoKey);
    _appLogoUrl = prefs.getString(appLogoKey);
    _splashLogoUrl = prefs.getString(splashLogoKey);
    _loginLogoUrl = prefs.getString(loginLogoKey);
    
    notifyListeners();
    
    // Verificar se precisa sincronizar após carregar logos
    if (await shouldSync()) {
      syncLogosFromServer();
    }
  }
  
  /// Widget helper para exibir o logo principal
  Widget getMainLogoWidget({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (!hasMainLogo) {
      return errorWidget ?? 
             Icon(Icons.business, size: height ?? width ?? 80, color: Colors.grey);
    }
    
    return CachedNetworkImage(
      imageUrl: finalMainLogoUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => 
          placeholder ?? CircularProgressIndicator(strokeWidth: 2),
      errorWidget: (context, url, error) => 
          errorWidget ?? 
          Icon(Icons.image_not_supported, 
               size: height ?? width ?? 80, 
               color: Colors.grey),
      cacheManager: DefaultCacheManager(),
    );
  }
  
  /// Widget helper para exibir o logo de login
  Widget getLoginLogoWidget({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (!hasLoginLogo) {
      return errorWidget ?? 
             Icon(Icons.account_circle, size: height ?? width ?? 60, color: Colors.grey);
    }
    
    return CachedNetworkImage(
      imageUrl: finalLoginLogoUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => 
          placeholder ?? CircularProgressIndicator(strokeWidth: 2),
      errorWidget: (context, url, error) => 
          errorWidget ?? 
          Icon(Icons.account_circle, 
               size: height ?? width ?? 60, 
               color: Colors.grey),
      cacheManager: DefaultCacheManager(),
    );
  }
  
  /// Widget helper para exibir o logo do splash screen
  Widget getSplashLogoWidget({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (!hasSplashLogo) {
      return errorWidget ?? 
             Icon(Icons.mobile_screen_share, size: height ?? width ?? 100, color: Colors.grey);
    }
    
    return CachedNetworkImage(
      imageUrl: _splashLogoUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => 
          placeholder ?? CircularProgressIndicator(strokeWidth: 2),
      errorWidget: (context, url, error) => 
          errorWidget ?? 
          Icon(Icons.mobile_screen_share, 
               size: height ?? width ?? 100, 
               color: Colors.grey),
      cacheManager: DefaultCacheManager(),
    );
  }
  
  /// Limpa cache dos logos
  Future<void> clearLogoCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      print('✅ LogoProvider: Cache de logos limpo');
    } catch (e) {
      print('❌ LogoProvider: Erro ao limpar cache: $e');
    }
  }
}






