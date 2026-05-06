import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapSettingsService {
  /// Obter userHash do usuário atual (isolamento por usuário)
  static Future<String> _getCurrentUserHash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = prefs.getString('user_api_hash');
      if (userHash != null && userHash.isNotEmpty) {
        return userHash;
      }
      // Fallback para user ID se userHash não estiver disponível
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        return userData['id']?.toString() ?? 'default';
      }
      return 'default';
    } catch (e) {
      print('❌ Erro ao obter userHash: $e');
      return 'default';
    }
  }

  /// Carregar todas as configurações do mapa (isoladas por usuário)
  static Future<MapSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = await _getCurrentUserHash();
      final settingsKey = 'map_settings_$userHash';
      final settingsJson = prefs.getString(settingsKey);
      
      if (settingsJson == null) {
        // Retornar configurações padrão
        return MapSettings(
          animationEnabled: true,
          animationType: AnimationType.slide,
          updateInterval: 5, // segundos
          markerSize: MarkerSize.medium,
        );
      }
      
      final Map<String, dynamic> settings = jsonDecode(settingsJson);
      
      return MapSettings(
        animationEnabled: settings['animationEnabled'] ?? true,
        animationType: AnimationType.values.firstWhere(
          (e) => e.toString() == settings['animationType'],
          orElse: () => AnimationType.slide,
        ),
        updateInterval: settings['updateInterval'] ?? 5,
        markerSize: MarkerSize.values.firstWhere(
          (e) => e.toString() == settings['markerSize'],
          orElse: () => MarkerSize.medium,
        ),
      );
    } catch (e) {
      print('❌ Erro ao carregar configurações do mapa: $e');
      return MapSettings(
        animationEnabled: true,
        animationType: AnimationType.slide,
        updateInterval: 5,
        markerSize: MarkerSize.medium,
      );
    }
  }

  /// Salvar configurações do mapa (isoladas por usuário)
  static Future<void> saveSettings(MapSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = await _getCurrentUserHash();
      final settingsKey = 'map_settings_$userHash';
      final settingsMap = {
        'animationEnabled': settings.animationEnabled,
        'animationType': settings.animationType.toString(),
        'updateInterval': settings.updateInterval,
        'markerSize': settings.markerSize.toString(),
      };
      
      await prefs.setString(settingsKey, jsonEncode(settingsMap));
      print('✅ Configurações do mapa salvas para userHash: ${userHash.substring(0, 10)}...');
    } catch (e) {
      print('❌ Erro ao salvar configurações do mapa: $e');
    }
  }
}

class MapSettings {
  final bool animationEnabled;
  final AnimationType animationType;
  final int updateInterval; // em segundos
  final MarkerSize markerSize;

  MapSettings({
    required this.animationEnabled,
    required this.animationType,
    required this.updateInterval,
    required this.markerSize,
  });
}

enum AnimationType {
  slide,      // Deslizar suavemente
  bounce,     // Bounce/rebote
  fade,       // Fade in/out
  rotate,     // Rotação
  pulse,      // Pulsação
  elastic,    // Elástico
  none,       // Sem animação
}

enum MarkerSize {
  small,      // 48px
  medium,     // 64px
  large,      // 80px
  extraLarge, // 96px
}

extension MarkerSizeExtension on MarkerSize {
  double get scale {
    switch (this) {
      case MarkerSize.small:
        return 0.75;
      case MarkerSize.medium:
        return 1.0;
      case MarkerSize.large:
        return 1.25;
      case MarkerSize.extraLarge:
        return 1.5;
    }
  }
  
  String get label {
    switch (this) {
      case MarkerSize.small:
        return 'Pequeno';
      case MarkerSize.medium:
        return 'Médio';
      case MarkerSize.large:
        return 'Grande';
      case MarkerSize.extraLarge:
        return 'Extra Grande';
    }
  }
}

extension AnimationTypeExtension on AnimationType {
  String get label {
    switch (this) {
      case AnimationType.slide:
        return 'Deslizar';
      case AnimationType.bounce:
        return 'Rebote';
      case AnimationType.fade:
        return 'Fade';
      case AnimationType.rotate:
        return 'Rotação';
      case AnimationType.pulse:
        return 'Pulsação';
      case AnimationType.elastic:
        return 'Elástico';
      case AnimationType.none:
        return 'Sem Animação';
    }
  }
  
  String get description {
    switch (this) {
      case AnimationType.slide:
        return 'Veículos deslizam suavemente para nova posição';
      case AnimationType.bounce:
        return 'Veículos fazem um pequeno rebote ao se mover';
      case AnimationType.fade:
        return 'Veículos aparecem/desaparecem suavemente';
      case AnimationType.rotate:
        return 'Veículos rotacionam ao mudar de direção';
      case AnimationType.pulse:
        return 'Veículos pulsam ao se mover';
      case AnimationType.elastic:
        return 'Movimento elástico e suave';
      case AnimationType.none:
        return 'Sem animação - atualização instantânea';
    }
  }
  
  IconData get icon {
    switch (this) {
      case AnimationType.slide:
        return Icons.swipe;
      case AnimationType.bounce:
        return Icons.animation;
      case AnimationType.fade:
        return Icons.opacity;
      case AnimationType.rotate:
        return Icons.rotate_right;
      case AnimationType.pulse:
        return Icons.favorite;
      case AnimationType.elastic:
        return Icons.tune;
      case AnimationType.none:
        return Icons.block;
    }
  }
}
