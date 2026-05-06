import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:async';

class MarkerUtils {
  // === FUNÇÃO PARA CRIAR ÍCONES DE MARCADORES (IDÊNTICA AO CÓDIGO FORNECIDO) ===
  static Future<BitmapDescriptor> getMarkerIcon(
    String imagePath,
    String infoText,
    Color color,
    double rotateDegree,
    bool showTitle,
    double scale,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Tamanho com escala
    final double s = scale.clamp(0.5, 2.0);
    Size canvasSize = Size(600.0 * s, 200.0 * s);
    Size markerSize = Size(120.0 * s, 120.0 * s);
    
    late TextPainter textPainter;
    if (showTitle) {
      // Adicionar texto de informações
      textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: infoText,
        style: TextStyle(
          fontSize: 20.0 * s,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
      textPainter.layout();
    }

    final Paint infoPaint = Paint()..color = Colors.white;
    final Paint infoStrokePaint = Paint()..color = color;
    final double infoHeight = 50.0 * s;
    final double strokeWidth = 2.0 * s;
    final double shadowWidth = 20.0 * s;
    
    canvas.translate(
      canvasSize.width / 2,
      canvasSize.height / 2 + infoHeight / 2,
    );

    // Oval para a imagem
    Rect oval = Rect.fromLTWH(
      -markerSize.width / 2 + .5 * shadowWidth,
      -markerSize.height / 2 + .5 * shadowWidth,
      markerSize.width - shadowWidth,
      markerSize.height - shadowWidth,
    );

    // Salvar canvas antes de rotacionar
    canvas.save();

    double rotateRadian = (math.pi / 180.0) * rotateDegree;

    // Rotacionar imagem
    canvas.rotate(rotateRadian);

    // Adicionar path para imagem oval
    canvas.clipPath(Path()..addOval(oval));

    ui.Image image;
    // Adicionar imagem
    image = await getImageFromPathUrl(imagePath);
    paintImage(canvas: canvas, image: image, rect: oval, fit: BoxFit.fitHeight);

    canvas.restore();

    if (showTitle) {
      // Adicionar borda da caixa de informações
      canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
            -textPainter.width / 2 - infoHeight / 2,
            -canvasSize.height / 2 - infoHeight / 2 + 1,
            textPainter.width / 2 + infoHeight / 2,
            -canvasSize.height / 2 + infoHeight / 2 + 1,
            Radius.circular(35.0),
          ))
          ..moveTo(-15, -canvasSize.height / 2 + infoHeight / 2 + 1)
          ..lineTo(0, -canvasSize.height / 2 + infoHeight / 2 + 25)
          ..lineTo(15, -canvasSize.height / 2 + infoHeight / 2 + 1),
        infoStrokePaint,
      );

      // Caixa de informações
      canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
            -textPainter.width / 2 - infoHeight / 2 + strokeWidth,
            -canvasSize.height / 2 - infoHeight / 2 + 1 + strokeWidth,
            textPainter.width / 2 + infoHeight / 2 - strokeWidth,
            -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth,
            Radius.circular(32.0),
          ))
          ..moveTo(
            -15 + strokeWidth / 2,
            -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth,
          )
          ..lineTo(
            0,
            -canvasSize.height / 2 + infoHeight / 2 + 25 - strokeWidth * 2,
          )
          ..lineTo(
            15 - strokeWidth / 2,
            -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth,
          ),
        infoPaint,
      );

      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -canvasSize.height / 2 -
              infoHeight / 2 +
              infoHeight / 2 -
              textPainter.height / 2,
        ),
      );

      canvas.restore();
    }

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());

    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? uint8List = byteData?.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List!);
  }

  // === CARREGAMENTO DE IMAGENS DE ASSETS ===
  static Future<ui.Image> getImageFromPath(String imagePath) async {
    var bd = await rootBundle.load(imagePath);
    Uint8List imageBytes = Uint8List.view(bd.buffer);

    final Completer<ui.Image> completer = Completer();

    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      return completer.complete(img);
    });

    return completer.future;
  }

  // === CARREGAMENTO DE IMAGENS DE URL ===
  static Future<ui.Image> getImageFromPathUrl(String imagePath) async {
    print('🖼️ Carregando ícone da URL: $imagePath');

    // Se a URL estiver vazia, retornar imagem padrão
    if (imagePath.isEmpty) {
      print('⚠️ URL do ícone vazia, usando ícone padrão');
      return getImageFromPath('assets/icon/car.png');
    }

    try {
      final response = await http.Client().get(Uri.parse(imagePath));
      final bytes = response.bodyBytes;
      print('✅ Ícone carregado da API: ${bytes.length} bytes');

      final Completer<ui.Image> completer = Completer();

      ui.decodeImageFromList(bytes, (ui.Image img) {
        print('✅ Ícone decodificado com sucesso');
        return completer.complete(img);
      });

      return completer.future;
    } catch (e) {
      print('❌ Erro ao carregar ícone da URL: $e');
      print('🔄 Tentando usar ícone padrão...');
      // Retornar imagem padrão em caso de erro
      return getImageFromPath('assets/icon/car.png');
    }
  }

  // === FUNÇÃO PARA CRIAR ÍCONE ORIGINAL DO SERVIDOR (SEM TRANSFORMAÇÕES) ===
  static Future<BitmapDescriptor> getOriginalMarkerIcon(
    String imagePath,
    double rotateDegree,
    double scale,
  ) async {
    print('🖼️ Criando ícone original do servidor: $imagePath');
    
    try {
      // Carregar imagem diretamente da URL
      final response = await http.Client().get(Uri.parse(imagePath));
      final bytes = response.bodyBytes;
      
      if (bytes.isEmpty) {
        print('⚠️ Imagem vazia, usando ícone padrão');
        final defaultImage = await getImageFromPath('assets/icon/car.png');
        return await _imageToBitmapDescriptor(defaultImage, rotateDegree, scale);
      }

      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        print('✅ Ícone original decodificado: ${img.width}x${img.height}');
        return completer.complete(img);
      });

      final image = await completer.future;
      
      // Converter imagem diretamente para BitmapDescriptor sem transformações
      return await _imageToBitmapDescriptor(image, rotateDegree, scale);
    } catch (e) {
      print('❌ Erro ao carregar ícone original: $e');
      print('🔄 Usando ícone padrão...');
      final defaultImage = await getImageFromPath('assets/icon/car.png');
      return await _imageToBitmapDescriptor(defaultImage, rotateDegree, scale);
    }
  }

  // === CONVERTER IMAGEM PARA BITMAPDESCRIPTOR (SEM TRANSFORMAÇÕES) ===
  static Future<BitmapDescriptor> _imageToBitmapDescriptor(
    ui.Image image,
    double rotateDegree,
    double scale,
  ) async {
    // Aplicar escala se necessário
    final double s = scale.clamp(0.5, 2.0);
    final int scaledWidth = (image.width * s).toInt();
    final int scaledHeight = (image.height * s).toInt();

    // Se não precisa de escala ou rotação, usar imagem diretamente
    if (s == 1.0 && rotateDegree == 0.0) {
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? uint8List = byteData?.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(uint8List!);
    }

    // Se precisa de escala ou rotação, criar canvas mínimo
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Size canvasSize = Size(scaledWidth.toDouble(), scaledHeight.toDouble());
    
    // Aplicar rotação se necessário
    if (rotateDegree != 0.0) {
      canvas.translate(canvasSize.width / 2, canvasSize.height / 2);
      canvas.rotate((math.pi / 180.0) * rotateDegree);
      canvas.translate(-canvasSize.width / 2, -canvasSize.height / 2);
    }

    // Desenhar imagem original sem transformações (sem oval, sem texto, sem bordas)
    paintImage(
      canvas: canvas,
      image: image,
      rect: Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
      fit: BoxFit.contain,
    );

    final ui.Image finalImage = await pictureRecorder
        .endRecording()
        .toImage(scaledWidth, scaledHeight);

    final ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? uint8List = byteData?.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List!);
  }

  // === CRIAÇÃO DE MARCADORES (USANDO A MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
  static Future<Set<Marker>> createMarkers(
    List<deviceItems> vehicles,
    ColorProvider colorProvider,
    Function(deviceItems) onMarkerTap,
    deviceItems? selectedVehicle,
  ) async {
    final Set<Marker> markers = {};
    const String baseUrl = "https://web.unnicatelemetria.com.br/";

    for (var vehicle in vehicles) {
      if (vehicle.lat == null ||
          vehicle.lng == null ||
          vehicle.lat == 0 ||
          vehicle.lng == 0) {
        continue;
      }

      // Nota: Informações de ignição, cor e label removidas pois agora usamos ícones originais do servidor
      // sem adicionar texto ou cores customizadas

      // Converter para double caso venha como int
      double lat = vehicle.lat is double
          ? vehicle.lat as double
          : (vehicle.lat as num).toDouble();

      double lng = vehicle.lng is double
          ? vehicle.lng as double
          : (vehicle.lng as num).toDouble();

      // Usar vehicle.icon?.path em vez de vehicle.image
      String? deviceIconPath = vehicle.icon?.path;
      String deviceIconFullPath = (deviceIconPath != null && deviceIconPath.isNotEmpty)
          ? "$baseUrl$deviceIconPath"
          : "$baseUrl/images/device_icons/rotating/1.png";

      print('🖼️ Criando marcador para ${vehicle.name}:');
      print('   📦 deviceIconPath: $deviceIconPath');
      print('   🌐 deviceIconFullPath: $deviceIconFullPath');

      // Aplicar escala apenas no veículo selecionado - MARCADORES MAIORES
      final bool isSelectedMarker =
          (vehicle.deviceData?.imei?.toString() ?? '') ==
              (selectedVehicle?.deviceData?.imei?.toString() ?? '') ||
          vehicle.id == selectedVehicle?.id;
      
      final double markerScale = isSelectedMarker ? 2.2 : 1.8; // Marcadores ainda maiores

      // Usar ícone original do servidor sem transformações
      BitmapDescriptor customIcon = await getOriginalMarkerIcon(
        deviceIconFullPath,
        vehicle.course.toDouble(),
        markerScale,
      );

      final marker = Marker(
        markerId: MarkerId(vehicle.id.toString()),
        position: LatLng(lat, lng),
        onTap: () {
          onMarkerTap(vehicle);
        },
        anchor: const Offset(0.5, 0.5),
        icon: customIcon,
        rotation: vehicle.course.toDouble(),
      );

      markers.add(marker);
    }

    return markers;
  }
}
