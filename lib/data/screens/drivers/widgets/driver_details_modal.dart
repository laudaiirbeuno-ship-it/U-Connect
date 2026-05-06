import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/screens/drivers/controllers/drivers_controller.dart';
import 'package:uconnect/data/model/driver_form_data.dart';
import 'package:uconnect/data/screens/drivers/widgets/driver_form_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class DriverDetailsModal extends StatelessWidget {
  final dynamic driver;
  final deviceItems? vehicle;

  const DriverDetailsModal({
    Key? key,
    required this.driver,
    this.vehicle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final controller = Provider.of<DriversController>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            color: colorProvider.primaryColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes do Motorista',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Botão Editar
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: DriverFormDialog(
                              driverId: driver.id,
                              initialData: DriverFormData.fromDriverData(driver),
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            controller.loadDrivers();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Conteúdo com scroll
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informações do Motorista
                  _buildSectionTitle('Informações do Motorista', colorProvider),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Nome',
                    value: driver.name ?? 'Não informado',
                    colorProvider: colorProvider,
                  ),
                  SizedBox(height: 12),
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.phone,
                      label: 'Telefone',
                      value: driver.phone.toString(),
                      colorProvider: colorProvider,
                      onTap: () => _makePhoneCall(context, driver.phone.toString()),
                    ),
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    SizedBox(height: 12),
                  if (driver.email != null && driver.email.toString().isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email',
                      value: driver.email.toString(),
                      colorProvider: colorProvider,
                      onTap: () => _sendEmail(context, driver.email.toString()),
                    ),
                  if (driver.email != null && driver.email.toString().isNotEmpty)
                    SizedBox(height: 12),
                  if (driver.rfid != null && driver.rfid.toString().isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.credit_card,
                      label: 'RFID',
                      value: driver.rfid.toString(),
                      colorProvider: colorProvider,
                    ),
                  if (driver.rfid != null && driver.rfid.toString().isNotEmpty)
                    SizedBox(height: 12),
                  if (driver.description != null && driver.description.toString().isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.description,
                      label: 'Descrição',
                      value: driver.description.toString(),
                      colorProvider: colorProvider,
                    ),
                  if (driver.description != null && driver.description.toString().isNotEmpty)
                    SizedBox(height: 12),
                  if (driver.devicePort != null && driver.devicePort.toString().isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.usb,
                      label: 'Porta do Dispositivo',
                      value: driver.devicePort.toString(),
                      colorProvider: colorProvider,
                    ),

                  // Informações do Veículo
                  if (vehicle != null) ...[
                    SizedBox(height: 24),
                    _buildSectionTitle('Veículo Associado', colorProvider),
                    SizedBox(height: 12),
                    _buildVehicleInfoCard(vehicle!, colorProvider),
                  ] else ...[
                    SizedBox(height: 24),
                    _buildSectionTitle('Veículo Associado', colorProvider),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600),
                          SizedBox(width: 12),
                          Text(
                            'Nenhum veículo associado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botões de Ação
                  SizedBox(height: 24),
                  _buildSectionTitle('Ações', colorProvider),
                  SizedBox(height: 12),
                  
                  // Botão QR Code
                  ElevatedButton.icon(
                    onPressed: () => _showQrCodeModal(context, driver, colorProvider),
                    icon: Icon(Icons.qr_code),
                    label: Text('Ver QR Code de Identificação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorProvider.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Botão Compartilhar QR Code no WhatsApp
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _shareQrCodeWhatsApp(context, driver, colorProvider),
                      icon: Icon(Icons.share),
                      label: Text('Compartilhar QR Code no WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    SizedBox(height: 12),
                  
                  // Botão Link do Scanner
                  OutlinedButton.icon(
                    onPressed: () => _shareScannerLink(context, colorProvider),
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('Compartilhar Link do Scanner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorProvider.primaryColor,
                      side: BorderSide(color: colorProvider.primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorProvider colorProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorProvider.primaryColor,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required ColorProvider colorProvider,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorProvider.primaryColor, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(deviceItems vehicle, ColorProvider colorProvider) {
    final speed = vehicle.speed != null ? (vehicle.speed as num).toDouble() : 0.0;
    final isOnline = vehicle.online?.toString().toLowerCase() == 'ack';
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle.name ?? 'Veículo sem nome',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildVehicleDetailRow('Placa', vehicle.plateNumber!),
          ],
          if (speed > 0) ...[
            SizedBox(height: 8),
            _buildVehicleDetailRow('Velocidade', '${speed.toStringAsFixed(0)} km/h'),
          ],
          if (vehicle.totalDistance != null) ...[
            SizedBox(height: 8),
            _buildVehicleDetailRow('Distância Total', '${vehicle.totalDistance?.toStringAsFixed(1) ?? '0.0'} km'),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 36),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showQrCodeModal(BuildContext context, dynamic driver, ColorProvider colorProvider) {
    final qrData = _generateQrCodeData(driver);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          constraints: BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code, color: colorProvider.primaryColor, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'QR Code de Identificação',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                driver.name ?? 'Motorista',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorProvider.primaryColor,
                ),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorProvider.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: colorProvider.primaryColor,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateQrCodeData(dynamic driver) {
    final data = {
      'driver_id': driver.id?.toString() ?? '',
      'name': driver.name?.toString() ?? '',
      'phone': driver.phone?.toString() ?? '',
      'email': driver.email?.toString() ?? '',
      'type': 'driver_identification',
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  Future<void> _shareQrCodeWhatsApp(BuildContext context, dynamic driver, ColorProvider colorProvider) async {
    final driverName = driver.name ?? 'Motorista';
    final driverId = driver.id?.toString() ?? '';
    
    try {
      final message = '''🚗 *QR Code de Identificação - $driverName*

Olá! Este é seu QR Code de identificação. *IMPRIMA ESTE QR CODE* e leve sempre com você.

*Como usar:*
1. *IMPRIMA* este QR Code
2. Ao iniciar uma viagem, escaneie seu QR Code
3. Aguarde a confirmação do sistema
4. Após confirmação, você poderá dar partida no veículo

*Seu ID:* $driverId
*Nome:* $driverName

*IMPORTANTE:*
- Mantenha este QR Code sempre com você
- Escaneie ANTES de dar partida no veículo
- Sem o QR Code, não será possível iniciar viagens

_Compartilhado via U-Connect_''';

      final cleanPhone = driver.phone.toString().replaceAll(RegExp(r'[^\d]'), '');
      final link = WhatsAppUnilink(
        phoneNumber: cleanPhone,
        text: message,
      );
      
      final uri = link.asUri();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp não está instalado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar: $e')),
      );
    }
  }

  void _shareScannerLink(BuildContext context, ColorProvider colorProvider) {
    final message = '''🚗 *Scanner de Identificação de Motoristas*

Use este aplicativo para escanear QR Codes de identificação de motoristas.

*Como usar:*
1. Abra o aplicativo U-Connect
2. Vá em Motoristas → Escanear QR Code
3. Escaneie o QR Code do motorista
4. O motorista será identificado automaticamente

*Disponível em:*
Motoristas → Botão de Escanear QR Code

_Compartilhado via U-Connect_''';

    Share.share(
      message,
      subject: 'Scanner de Identificação de Motoristas',
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível fazer a ligação')),
      );
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o email')),
      );
    }
  }
}
