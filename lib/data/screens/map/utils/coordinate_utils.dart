import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilitário centralizado para conversão segura de coordenadas
class CoordinateUtils {
  /// Converte um valor dynamic para double de forma segura
  /// Suporta: null, double, int, num, String
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Cria um LatLng de forma segura a partir de coordenadas dynamic
  /// Retorna null se as coordenadas não puderem ser convertidas
  static LatLng? toLatLng(dynamic lat, dynamic lng) {
    final latDouble = toDouble(lat);
    final lngDouble = toDouble(lng);
    
    if (latDouble == null || lngDouble == null) {
      return null;
    }
    
    return LatLng(latDouble, lngDouble);
  }

  /// Verifica se as coordenadas são válidas (não nulas e não zero)
  static bool isValidCoordinate(dynamic lat, dynamic lng) {
    final latDouble = toDouble(lat);
    final lngDouble = toDouble(lng);
    
    if (latDouble == null || lngDouble == null) return false;
    if (latDouble == 0.0 && lngDouble == 0.0) return false;
    
    return true;
  }
}

