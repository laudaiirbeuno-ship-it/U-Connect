import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/config/Session.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _logoPathKeyPrefix = 'custom_logo_path_';
  static const String _splashLogoPathKeyPrefix = 'custom_splash_logo_path_';
  static const String _notificationSoundKeyPrefix = 'notification_sound_';
  static const String _languageKeyPrefix = 'language_code_';
  static const String _fleetIconKeyPrefix = 'fleet_status_icon_';
  static const String _markerSizeKeyPrefix = 'marker_size_';
  static const String _markerAnimationKeyPrefix = 'marker_animation_';
  static const String _logoCustomStyleKeyPrefix = 'logo_custom_style_';
  
  File? _customLogo;
  File? _customSplashLogo;
  String _notificationSound = 'default';
  Locale _currentLocale = const Locale('pt', 'pt_BR');
  String _fleetStatusIcon = 'directions_car'; // Ícone padrão
  double _markerSize = 1.0; // Tamanho padrão do marcador (1.0 = 100%)
  bool _markerAnimation = false; // Animação do marcador desativada por padrão
  bool _logoCustomStyle = false; // Estilo personalizado da logo (preto com detalhes amarelos)
  
  File? get customLogo => _customLogo;
  File? get customSplashLogo => _customSplashLogo;
  String get notificationSound => _notificationSound;
  Locale get currentLocale => _currentLocale;
  String get fleetStatusIcon => _fleetStatusIcon;
  double get markerSize => _markerSize;
  bool get markerAnimation => _markerAnimation;
  bool get logoCustomStyle => _logoCustomStyle;
  
  AppSettingsProvider() {
    _loadSettings();
  }
  
  // Método auxiliar para obter o userHash do usuário logado (isolamento por usuário)
  Future<String> _getUserHash() async {
    final prefs = await SharedPreferences.getInstance();
    final userHash = prefs.getString('user_api_hash');
    if (userHash != null && userHash.isNotEmpty) {
      return userHash;
    }
    // Fallback para email se userHash não estiver disponível
    final email = prefs.getString('email');
    return email ?? 'default';
  }
  
  // Métodos auxiliares para criar chaves únicas por usuário usando userHash
  Future<String> _getLogoPathKey() async {
    final userHash = await _getUserHash();
    return '${_logoPathKeyPrefix}$userHash';
  }
  
  Future<String> _getNotificationSoundKey() async {
    final userHash = await _getUserHash();
    return '${_notificationSoundKeyPrefix}$userHash';
  }
  
  Future<String> _getLanguageKey() async {
    final userHash = await _getUserHash();
    return '${_languageKeyPrefix}$userHash';
  }
  
  Future<String> _getFleetIconKey() async {
    final userHash = await _getUserHash();
    return '${_fleetIconKeyPrefix}$userHash';
  }
  
  Future<String> _getSplashLogoPathKey() async {
    final userHash = await _getUserHash();
    return '${_splashLogoPathKeyPrefix}$userHash';
  }
  
  Future<String> _getMarkerSizeKey() async {
    final userHash = await _getUserHash();
    return '${_markerSizeKeyPrefix}$userHash';
  }
  
  Future<String> _getMarkerAnimationKey() async {
    final userHash = await _getUserHash();
    return '${_markerAnimationKeyPrefix}$userHash';
  }
  
  Future<String> _getLogoCustomStyleKey() async {
    final userHash = await _getUserHash();
    return '${_logoCustomStyleKeyPrefix}$userHash';
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carregar logo
    final logoKey = await _getLogoPathKey();
    final logoPath = prefs.getString(logoKey);
    if (logoPath != null && File(logoPath).existsSync()) {
      _customLogo = File(logoPath);
    }
    
    // Carregar splash logo
    final splashLogoKey = await _getSplashLogoPathKey();
    final splashLogoPath = prefs.getString(splashLogoKey);
    if (splashLogoPath != null && File(splashLogoPath).existsSync()) {
      _customSplashLogo = File(splashLogoPath);
    }
    
    // Carregar som
    final soundKey = await _getNotificationSoundKey();
    _notificationSound = prefs.getString(soundKey) ?? 'default';
    
    // Carregar idioma
    final languageKey = await _getLanguageKey();
    final languageCode = prefs.getString(languageKey);
    if (languageCode != null) {
      _currentLocale = _localeFromCode(languageCode);
    } else {
      final savedLocale = await getLocale();
      _currentLocale = savedLocale;
    }
    
    // Carregar ícone do status da frota
    final fleetIconKey = await _getFleetIconKey();
    _fleetStatusIcon = prefs.getString(fleetIconKey) ?? 'directions_car';
    
    // Carregar tamanho do marcador
    final markerSizeKey = await _getMarkerSizeKey();
    _markerSize = prefs.getDouble(markerSizeKey) ?? 1.0;
    
    // Carregar animação do marcador
    final markerAnimationKey = await _getMarkerAnimationKey();
    _markerAnimation = prefs.getBool(markerAnimationKey) ?? false;
    
    // Carregar estilo personalizado da logo
    final logoCustomStyleKey = await _getLogoCustomStyleKey();
    _logoCustomStyle = prefs.getBool(logoCustomStyleKey) ?? false;
    
    notifyListeners();
  }
  
  Future<void> setCustomLogo(File logoFile) async {
    _customLogo = logoFile;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getLogoPathKey();
    await prefs.setString(key, logoFile.path);
    notifyListeners();
  }
  
  Future<void> removeCustomLogo() async {
    if (_customLogo != null && _customLogo!.existsSync()) {
      await _customLogo!.delete();
    }
    _customLogo = null;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getLogoPathKey();
    await prefs.remove(key);
    notifyListeners();
  }
  
  Future<void> setCustomSplashLogo(File logoFile) async {
    _customSplashLogo = logoFile;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getSplashLogoPathKey();
    await prefs.setString(key, logoFile.path);
    notifyListeners();
  }
  
  Future<void> removeCustomSplashLogo() async {
    if (_customSplashLogo != null && _customSplashLogo!.existsSync()) {
      await _customSplashLogo!.delete();
    }
    _customSplashLogo = null;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getSplashLogoPathKey();
    await prefs.remove(key);
    notifyListeners();
  }
  
  Future<void> setNotificationSound(String soundName) async {
    _notificationSound = soundName;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getNotificationSoundKey();
    await prefs.setString(key, soundName);
    notifyListeners();
  }
  
  Future<void> setLanguage(Locale locale) async {
    _currentLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    String languageCode;
    
    if (locale.languageCode == 'pt') {
      languageCode = 'pt';
    } else if (locale.languageCode == 'en') {
      languageCode = 'en';
    } else if (locale.languageCode == 'es') {
      languageCode = 'es';
    } else {
      languageCode = 'pt';
    }
    
    final key = await _getLanguageKey();
    await prefs.setString(key, languageCode);
    await setLocale(languageCode);
    notifyListeners();
  }
  
  Locale _localeFromCode(String code) {
    switch (code) {
      case 'pt':
        return const Locale('pt', 'pt_BR');
      case 'en':
        return const Locale('en', 'US');
      case 'es':
        return const Locale('es', 'ES');
      default:
        return const Locale('pt', 'pt_BR');
    }
  }
  
  Future<void> setFleetStatusIcon(String iconCode) async {
    _fleetStatusIcon = iconCode;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getFleetIconKey();
    await prefs.setString(key, iconCode);
    notifyListeners();
  }
  
  Future<void> setMarkerSize(double size) async {
    _markerSize = size;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getMarkerSizeKey();
    await prefs.setDouble(key, size);
    notifyListeners();
  }
  
  Future<void> setMarkerAnimation(bool enabled) async {
    _markerAnimation = enabled;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getMarkerAnimationKey();
    await prefs.setBool(key, enabled);
    notifyListeners();
  }
  
  Future<void> setLogoCustomStyle(bool enabled) async {
    _logoCustomStyle = enabled;
    final prefs = await SharedPreferences.getInstance();
    final key = await _getLogoCustomStyleKey();
    await prefs.setBool(key, enabled);
    notifyListeners();
  }
  
  IconData getFleetStatusIconData() {
    switch (_fleetStatusIcon) {
      case 'directions_car':
        return Icons.directions_car;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'agriculture':
        return Icons.agriculture;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'fire_truck':
        return Icons.fire_truck;
      case 'rv_hookup':
        return Icons.rv_hookup;
      case 'tram':
        return Icons.tram;
      case 'directions_boat':
        return Icons.directions_boat;
      case 'flight':
        return Icons.flight;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'snowmobile':
        return Icons.snowmobile;
      case 'sailing':
        return Icons.sailing;
      case 'satellite':
        return Icons.satellite;
      case 'satellite_alt':
        return Icons.satellite_alt;
      case 'radio':
        return Icons.radio;
      case 'map':
        return Icons.map;
      default:
        return Icons.directions_car;
    }
  }
  
  List<String> get availableSounds => [
    'default',
    'ignitiononnoti',
    'notification',
    'alert',
  ];
  
  List<Map<String, dynamic>> get availableFleetIcons => [
    {'code': 'directions_car', 'icon': Icons.directions_car, 'name': 'Carro'},
    {'code': 'local_shipping', 'icon': Icons.local_shipping, 'name': 'Caminhão'},
    {'code': 'two_wheeler', 'icon': Icons.two_wheeler, 'name': 'Moto'},
    {'code': 'airport_shuttle', 'icon': Icons.airport_shuttle, 'name': 'Van'},
    {'code': 'directions_bus', 'icon': Icons.directions_bus, 'name': 'Ônibus'},
    {'code': 'agriculture', 'icon': Icons.agriculture, 'name': 'Trator'},
    {'code': 'local_taxi', 'icon': Icons.local_taxi, 'name': 'Táxi'},
    {'code': 'fire_truck', 'icon': Icons.fire_truck, 'name': 'Bombeiro'},
    {'code': 'rv_hookup', 'icon': Icons.rv_hookup, 'name': 'RV'},
    {'code': 'tram', 'icon': Icons.tram, 'name': 'Bonde'},
    {'code': 'directions_boat', 'icon': Icons.directions_boat, 'name': 'Barco'},
    {'code': 'flight', 'icon': Icons.flight, 'name': 'Avião'},
    {'code': 'motorcycle', 'icon': Icons.motorcycle, 'name': 'Motocicleta'},
    {'code': 'satellite', 'icon': Icons.satellite, 'name': 'Satélite'},
    {'code': 'satellite_alt', 'icon': Icons.satellite_alt, 'name': 'Satélite Alt'},
    {'code': 'radio', 'icon': Icons.radio, 'name': 'Antena'},
    {'code': 'map', 'icon': Icons.map, 'name': 'Mapa'},
  ];
}










