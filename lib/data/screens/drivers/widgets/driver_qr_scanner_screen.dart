import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'dart:convert';

/// Tela standalone de scanner de QR Code para identificação de motoristas
/// Pode ser compartilhada com motoristas para identificação independente
class DriverQrScannerScreen extends StatefulWidget {
  final String? driverId; // ID do motorista esperado (opcional, para validação)
  final Function(String, String)? onDriverIdentified; // Callback opcional
  
  const DriverQrScannerScreen({
    Key? key,
    this.driverId,
    this.onDriverIdentified,
  }) : super(key: key);

  @override
  _DriverQrScannerScreenState createState() => _DriverQrScannerScreenState();
}

class _DriverQrScannerScreenState extends State<DriverQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedId;
  DateTime? _lastScanTime;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    // Evitar processar o mesmo QR Code múltiplas vezes
    if (_lastScannedId == rawValue && 
        _lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!) < Duration(seconds: 2)) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedId = rawValue;
      _lastScanTime = DateTime.now();
    });

    // Processar QR Code
    _processQrCode(rawValue);
  }

  void _processQrCode(String qrData) {
    try {
      // Tentar parsear como JSON
      final data = jsonDecode(qrData);
      
      if (data is Map) {
        // Verificar se é um QR Code de identificação de motorista
        if (data['type'] == 'driver_identification' && data['driver_id'] != null) {
          final driverId = data['driver_id'].toString();
          final driverName = data['name']?.toString() ?? 'Motorista Desconhecido';
          
          // Se foi especificado um driverId esperado, validar
          if (widget.driverId != null && driverId != widget.driverId) {
            _showError('QR Code não corresponde ao motorista esperado');
            return;
          }
          
          // Parar o scanner temporariamente
          _scannerController.stop();
          
          // Retornar dados para quem chamou (se for chamado de um Navigator.push)
          if (widget.onDriverIdentified != null) {
            // Se há callback, chamar e fechar
            widget.onDriverIdentified!(driverId, driverName);
            Navigator.of(context).pop({
              'driver_id': driverId,
              'driver_name': driverName,
            });
          } else {
            // Se não há callback, mostrar diálogo
            _showSuccessDialog(driverId, driverName);
          }
          return;
        }
      }
      
        // Se não for JSON válido, tratar como ID simples
        final driverId = qrData.trim();
        if (driverId.isNotEmpty) {
          if (widget.driverId != null && driverId != widget.driverId) {
            _showError('QR Code não corresponde ao motorista esperado');
            return;
          }
          
          _scannerController.stop();
          
          // Retornar dados para quem chamou (se for chamado de um Navigator.push)
          if (widget.onDriverIdentified != null) {
            widget.onDriverIdentified!(driverId, 'Motorista ID: $driverId');
            Navigator.of(context).pop({
              'driver_id': driverId,
              'driver_name': 'Motorista ID: $driverId',
            });
          } else {
            _showSuccessDialog(driverId, 'Motorista ID: $driverId');
          }
          return;
        }
    } catch (e) {
      // Se não for JSON, tratar como ID simples
      final driverId = qrData.trim();
      if (driverId.isNotEmpty) {
        if (widget.driverId != null && driverId != widget.driverId) {
          _showError('QR Code não corresponde ao motorista esperado');
          return;
        }
        
        _scannerController.stop();
        
        // Retornar dados para quem chamou (se for chamado de um Navigator.push)
        if (widget.onDriverIdentified != null) {
          widget.onDriverIdentified!(driverId, 'Motorista ID: $driverId');
          Navigator.of(context).pop({
            'driver_id': driverId,
            'driver_name': 'Motorista ID: $driverId',
          });
        } else {
          _showSuccessDialog(driverId, 'Motorista ID: $driverId');
        }
        return;
      }
    }

    // Se chegou aqui, QR Code inválido
    _showError('QR Code inválido. Escaneie um QR Code de motorista válido.');
  }

  void _showSuccessDialog(String driverId, String driverName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Identificação Confirmada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motorista identificado com sucesso!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoText('Nome', driverName),
                  SizedBox(height: 8),
                  _buildInfoText('ID', driverId),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Você foi identificado no sistema.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reiniciar scanner após 1 segundo
              Future.delayed(Duration(seconds: 1), () {
                if (mounted) {
                  _scannerController.start();
                  setState(() {
                    _isProcessing = false;
                  });
                }
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // Reiniciar scanner após erro
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Identificação de Motorista'),
        backgroundColor: colorProvider.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) => _handleBarcode(capture),
          ),
          
          // Overlay com instruções
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Escaneie seu QR Code de Identificação',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Posicione o QR Code dentro da área de leitura',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Overlay com moldura de leitura
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorProvider.primaryColor,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Cantos decorativos
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colorProvider.primaryColor, width: 6),
                          left: BorderSide(color: colorProvider.primaryColor, width: 6),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: colorProvider.primaryColor, width: 6),
                          right: BorderSide(color: colorProvider.primaryColor, width: 6),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colorProvider.primaryColor, width: 6),
                          left: BorderSide(color: colorProvider.primaryColor, width: 6),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colorProvider.primaryColor, width: 6),
                          right: BorderSide(color: colorProvider.primaryColor, width: 6),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicador de processamento
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processando identificação...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
