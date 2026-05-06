import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/map/services/marker_config_service.dart';
import 'package:uconnect/data/screens/map/services/map_settings_service.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';

class CustomMarkerService {
  // Cache de marcadores criados
  static final Map<String, BitmapDescriptor> _markerCache = {};
  
  // Cache de imagens carregadas
  static final Map<String, ui.Image> _imageCache = {};
  
  /// Limpar cache de marcadores
  /// Útil quando há problemas de cache ou quando marcadores não aparecem corretamente
  static void clearCache() {
    print('🧹 Limpando cache de marcadores...');
    _markerCache.clear();
    _imageCache.clear();
    print('✅ Cache de marcadores limpo');
  }
  
  /// Verificar se há problemas de cache
  /// Retorna true se o cache está muito grande (possível problema)
  static bool checkCacheHealth() {
    final cacheSize = _markerCache.length + _imageCache.length;
    if (cacheSize > 1000) {
      print('⚠️ Cache muito grande: $cacheSize itens - considerando limpar');
      return false;
    }
    return true;
  }

  // Mapeamento de tipos de marcadores para assets
  static final Map<String, String> _markerAssets = {
    'animal': 'assets/Iconesmarcadores/animal.png',
    'bicycle': 'assets/Iconesmarcadores/bicycle.png',
    'boat': 'assets/Iconesmarcadores/boat.png',
    'bus': 'assets/Iconesmarcadores/bus.png',
    'camper': 'assets/Iconesmarcadores/camper.png',
    'car': 'assets/Iconesmarcadores/car.png',
    'crane': 'assets/Iconesmarcadores/crane.png',
    'default': 'assets/Iconesmarcadores/default.png',
    'helicopter': 'assets/Iconesmarcadores/helicopter.png',
    'mobile': 'assets/Iconesmarcadores/mobile.png',
    'motorcycle': 'assets/Iconesmarcadores/motorcycle.png',
    'offroad': 'assets/Iconesmarcadores/offroad.png',
    'person': 'assets/Iconesmarcadores/person.png',
    'pickup': 'assets/Iconesmarcadores/pickup.png',
    'plane': 'assets/Iconesmarcadores/plane.png',
    'scooter': 'assets/Iconesmarcadores/scooter.png',
    'ship': 'assets/Iconesmarcadores/ship.png',
    'tractor': 'assets/Iconesmarcadores/tractor.png',
    'train': 'assets/Iconesmarcadores/train.png',
    'tram': 'assets/Iconesmarcadores/tram.png',
    'trolleybus': 'assets/Iconesmarcadores/trolleybus.png',
    'truck': 'assets/Iconesmarcadores/truck.png',
    'van': 'assets/Iconesmarcadores/van.png',
  };

  /// Criar marcador customizado para um veículo usando assets ou imagem customizada
  static Future<BitmapDescriptor> createCustomMarker(
    deviceItems vehicle,
    VehicleMarkerConfig config, {
    bool isSelected = false,
    double? course,
    MarkerSize markerSize = MarkerSize.medium,
  }) async {
    // Verificar se é uma imagem customizada
    if (config.customImagePath != null && config.customImagePath!.isNotEmpty) {
      final baseScale = markerSize.scale;
      final scale = isSelected ? baseScale * 1.2 : baseScale;
      final courseValue = course ?? CoordinateUtils.toDouble(vehicle.course) ?? 0.0;
      
      // Criar chave de cache única incluindo tamanho do marcador
      final cacheKey = 'custom_${config.customImagePath}_${scale}_${courseValue}_${markerSize.toString()}';
      
      // Verificar cache (com validação de saúde)
      if (_markerCache.containsKey(cacheKey)) {
        final cachedMarker = _markerCache[cacheKey]!;
        // Verificar se o marcador em cache ainda é válido
        if (cachedMarker != null) {
          return cachedMarker;
        }
      }
      
      final marker = await _createMarkerFromFile(
        filePath: config.customImagePath!,
        scale: scale,
        course: courseValue,
      );
      
      // Salvar no cache
      _markerCache[cacheKey] = marker;
      
      return marker;
    }
    
    // Usar asset padrão
    final assetPath = _markerAssets[config.markerTypeId] ?? _markerAssets['default']!;
    final baseScale = markerSize.scale;
    final scale = isSelected ? baseScale * 1.2 : baseScale;
    final courseValue = course ?? CoordinateUtils.toDouble(vehicle.course) ?? 0.0;
    
    // Criar chave de cache única incluindo tamanho do marcador
    final cacheKey = '${config.markerTypeId}_${scale}_${courseValue}_${markerSize.toString()}';
    
    // Verificar cache (com validação de saúde)
    if (_markerCache.containsKey(cacheKey)) {
      final cachedMarker = _markerCache[cacheKey]!;
      // Verificar se o marcador em cache ainda é válido
      if (cachedMarker != null) {
        return cachedMarker;
      }
    }
    
    final marker = await _createMarkerFromAsset(
      assetPath: assetPath,
      scale: scale,
      course: courseValue,
    );
    
    // Salvar no cache
    _markerCache[cacheKey] = marker;
    
    return marker;
  }

  /// Criar marcador a partir de asset mantendo proporção original
  static Future<BitmapDescriptor> _createMarkerFromAsset({
    required String assetPath,
    double scale = 1.0,
    double course = 0.0,
  }) async {
    try {
      // Carregar imagem do asset
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Calcular tamanho baseado no scale, mas manter proporção original
      final baseSize = 64.0 * scale;
      
      // Obter dimensões originais da imagem
      final originalWidth = image.width.toDouble();
      final originalHeight = image.height.toDouble();
      
      // Calcular proporção para manter aspecto original
      final aspectRatio = originalWidth / originalHeight;
      
      // Calcular tamanhos mantendo proporção (usar o maior lado como base)
      double targetWidth, targetHeight;
      if (aspectRatio >= 1.0) {
        // Largura maior ou igual à altura
        targetWidth = baseSize;
        targetHeight = baseSize / aspectRatio;
      } else {
        // Altura maior que largura
        targetHeight = baseSize;
        targetWidth = baseSize * aspectRatio;
      }
      
      // Criar canvas com tamanho suficiente para a imagem (transparente por padrão)
      // Usar tamanho baseado no maior lado para garantir espaço suficiente após rotação
      final maxDimension = targetWidth > targetHeight ? targetWidth : targetHeight;
      final canvasSize = (maxDimension * 1.5).toInt(); // Espaço extra para rotação
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder, Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()));
      
      // Calcular centro exato do canvas para melhor centralização
      final center = Offset(canvasSize / 2.0, canvasSize / 2.0);
      
      // Rotacionar para a esquerda (-45 graus) + course do veículo
      final rotationAngle = (-45.0 + course) * 3.14159 / 180;
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(-center.dx, -center.dy);
      
      // Desenhar imagem mantendo proporção original (centrada)
      final srcRect = Rect.fromLTWH(0, 0, originalWidth, originalHeight);
      final dstRect = Rect.fromCenter(
        center: center,
        width: targetWidth,
        height: targetHeight,
      );
      
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true
        ..blendMode = BlendMode.srcOver; // Preservar transparência
      
      canvas.drawImageRect(image, srcRect, dstRect, paint);
      canvas.restore();
      
      final picture = pictureRecorder.endRecording();
      // Criar imagem com canal alpha para transparência (PNG preserva transparência)
      final finalImage = await picture.toImage(canvasSize, canvasSize);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
      
      final uint8List = byteData.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      print('❌ Erro ao criar marcador do asset: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  /// Criar marcador a partir de arquivo de imagem customizada
  static Future<BitmapDescriptor> _createMarkerFromFile({
    required String filePath,
    double scale = 1.0,
    double course = 0.0,
  }) async {
    try {
      // Carregar imagem do arquivo
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Arquivo de imagem não encontrado: $filePath');
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
      
      final bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Calcular tamanho baseado no scale, mas manter proporção original
      final baseSize = 64.0 * scale;
      
      // Obter dimensões originais da imagem
      final originalWidth = image.width.toDouble();
      final originalHeight = image.height.toDouble();
      
      // Calcular proporção para manter aspecto original
      final aspectRatio = originalWidth / originalHeight;
      
      // Calcular tamanhos mantendo proporção
      double targetWidth, targetHeight;
      if (aspectRatio >= 1.0) {
        targetWidth = baseSize;
        targetHeight = baseSize / aspectRatio;
      } else {
        targetHeight = baseSize;
        targetWidth = baseSize * aspectRatio;
      }
      
      // Criar canvas transparente
      // Usar tamanho baseado no maior lado para garantir espaço suficiente após rotação
      final maxDimension = targetWidth > targetHeight ? targetWidth : targetHeight;
      final canvasSize = (maxDimension * 1.5).toInt(); // Espaço extra para rotação
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder, Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()));
      
      // Calcular centro exato do canvas para melhor centralização
      final center = Offset(canvasSize / 2.0, canvasSize / 2.0);
      
      // Rotacionar para a esquerda (-45 graus) + course do veículo
      final rotationAngle = (-45.0 + course) * 3.14159 / 180;
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(-center.dx, -center.dy);
      
      // Desenhar imagem mantendo proporção original (centrada)
      final srcRect = Rect.fromLTWH(0, 0, originalWidth, originalHeight);
      final dstRect = Rect.fromCenter(
        center: center,
        width: targetWidth,
        height: targetHeight,
      );
      
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true
        ..blendMode = BlendMode.srcOver; // Preservar transparência
      
      canvas.drawImageRect(image, srcRect, dstRect, paint);
      canvas.restore();
      
      final picture = pictureRecorder.endRecording();
      // Criar imagem com canal alpha para transparência (PNG preserva transparência)
      final finalImage = await picture.toImage(canvasSize, canvasSize);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
      
      final uint8List = byteData.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      print('❌ Erro ao criar marcador do arquivo: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

/// Criar marcadores para todos os veículos
  static Future<Set<Marker>> createMarkersForVehicles(
    List<deviceItems> vehicles,
    Map<int, VehicleMarkerConfig> configs,
    deviceItems? selectedVehicle,
    Function(deviceItems) onTap, {
    MarkerSize markerSize = MarkerSize.medium,
  }) async {
    final Set<Marker> markers = {};
    
    for (final vehicle in vehicles) {
      // Verificar se as coordenadas são válidas usando a função utilitária
      if (!CoordinateUtils.isValidCoordinate(vehicle.lat, vehicle.lng)) {
        continue;
      }
      
      // Obter configuração do veículo ou usar padrão
      final config = configs[vehicle.id] ?? VehicleMarkerConfig(
        markerTypeId: 'default',
      );
      
      final isSelected = selectedVehicle?.id == vehicle.id;
      
      // Criar marcador customizado
      final customIcon = await createCustomMarker(
        vehicle,
        config,
        isSelected: isSelected,
        markerSize: markerSize,
      );
      
      // Converter coordenadas de forma segura
      final position = CoordinateUtils.toLatLng(vehicle.lat, vehicle.lng);
      if (position == null) continue;
      
      // Calcular anchor baseado no tamanho do ícone
      // Anchor (0.5, 0.5) = centro exato do marcador
      // Isso garante que o marcador fique perfeitamente centralizado na posição
      final anchorX = 0.5; // Centro horizontal exato
      final anchorY = 0.5; // Centro vertical exato
      
      final marker = Marker(
        markerId: MarkerId('vehicle_${vehicle.id}'),
        position: position,
        icon: customIcon,
        rotation: 0.0, // Rotação já aplicada no canvas (-45 graus + course)
        anchor: Offset(anchorX, anchorY), // Centro exato do marcador para melhor centralização
        onTap: () => onTap(vehicle),
        // InfoWindow removido - usando apenas labels customizados e VehicleCard
      );
      
      markers.add(marker);
    }
    
    return markers;
  }
}
