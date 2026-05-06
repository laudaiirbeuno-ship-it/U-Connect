import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/drivers/controllers/drivers_controller.dart';
import 'package:uconnect/data/screens/drivers/widgets/drivers_filter_widget.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:uconnect/data/screens/drivers/widgets/driver_form_dialog.dart';
import 'package:uconnect/data/screens/drivers/widgets/driver_details_modal.dart';
import 'package:uconnect/data/model/driver_form_data.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uconnect/data/screens/drivers/widgets/driver_qr_scanner_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:uconnect/storage/user_repository.dart';

class DriversScreen extends StatefulWidget {
  @override
  _DriversScreenState createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFilterSticky = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DriversController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Criar controller uma única vez
    _controller = DriversController();
    
    // Carregar motoristas ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDrivers();
    });
  }
  
  bool _hasLoadedOnce = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar motoristas quando a página é reaberta pela primeira vez
    // ou se a lista estiver vazia (pode ter sido limpa)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_controller.isLoading) {
        // Se nunca carregou ou se a lista está vazia, recarregar
        if (!_hasLoadedOnce || _controller.allDrivers.isEmpty) {
          _hasLoadedOnce = true;
          _controller.loadDrivers();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Não dispose o controller aqui, pois pode ser usado por outros widgets
    super.dispose();
  }




  void _onScroll() {
    setState(() {
      _isFilterSticky = _scrollController.offset > 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Meus Motoristas', 'My Drivers'),
          icon: Icons.people_outline,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            // Fundo animado
            AnimatedBackground(opacity: 0.03),
            // Conteúdo
            Consumer2<DriversController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                if (controller.isLoading && controller.allDrivers.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorProvider.primaryColor,
                      ),
                    ),
                  );
                }

                if (controller.error != null && controller.allDrivers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          controller.error!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => controller.loadDrivers(),
                          child: Text(TranslationHelper.translateSync(context, 'Tentar novamente', 'Try again')),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Filtro fixo
                    DriversFilterWidget(isSticky: _isFilterSticky),
                    // Conteúdo
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => controller.loadDrivers(),
                        color: colorProvider.primaryColor,
                        child: controller.filteredDrivers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      controller.allDrivers.isEmpty
                                          ? TranslationHelper.translateSync(context, 'Nenhum motorista cadastrado', 'No drivers registered')
                                          : TranslationHelper.translateSync(context, 'Nenhum motorista encontrado com os filtros aplicados', 'No drivers found with applied filters'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                physics: AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  top: 16,
                                  bottom: 80,
                                  left: 16,
                                  right: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Contador de resultados
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        TranslationHelper.translateSync(context, 
                                          '${controller.filteredDrivers.length} motorista(s) encontrado(s)', 
                                          '${controller.filteredDrivers.length} driver(s) found'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Lista de cards
                                    ...controller.filteredDrivers.map((driver) {
                                      return _buildDriverCard(
                                        context,
                                        driver,
                                        controller,
                                        colorProvider,
                                      );
                                    }).toList(),
                                    SizedBox(height: 16),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Botão flutuante para criar novo motorista
            Consumer<ColorProvider>(
              builder: (context, colorProvider, child) {
                return Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showCreateDriverDialog(context, _controller),
                    backgroundColor: colorProvider.primaryColor,
                    child: Icon(Icons.person_add, color: Colors.white),
                    tooltip: TranslationHelper.translateSync(context, 'Criar Novo Motorista', 'Create New Driver'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAvatar(DriverData driver, ColorProvider colorProvider) {
    final String baseUrl = UserRepository.getServerURL() + "/";
    String? photoUrl = driver.photo;
    
    // Se a foto não começar com http, adicionar baseUrl
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = "$baseUrl$photoUrl";
    }
    
    return CircleAvatar(
      radius: 28,
      backgroundColor: colorProvider.primaryColor,
      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty && photoUrl.startsWith('http'))
          ? NetworkImage(photoUrl)
          : null,
      onBackgroundImageError: (exception, stackTrace) {
        // Se a imagem falhar, não fazer nada (vai mostrar o fallback)
      },
      child: (photoUrl == null || photoUrl.isEmpty || !photoUrl.startsWith('http'))
          ? Text(
              (driver.name ?? '?')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  void _showCreateDriverDialog(BuildContext context, DriversController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: DriverFormDialog(),
      ),
    ).then((result) {
      if (result == true) {
        // Motorista criado/atualizado com sucesso - recarregar lista
        print('🔄 [DriversScreen] Recarregando lista de motoristas após cadastro...');
        controller.loadDrivers();
      }
    });
  }

  void _showEditDriverDialog(BuildContext context, DriverData driver, DriversController controller) {
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
        // Motorista atualizado com sucesso - recarregar lista
        print('🔄 [DriversScreen] Recarregando lista de motoristas após atualização...');
        controller.loadDrivers();
      }
    });
  }

  void _showDriverDetailsModal(
    BuildContext context,
    DriverData driver,
    DriversController controller,
    ColorProvider colorProvider,
  ) {
    // Buscar veículo associado
    final objectStore = Provider.of<ObjectStore>(context, listen: false);
    final vehicle = controller.getVehicleForDriver(driver, objectStore.objects);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: DriverDetailsModal(
          driver: driver,
          vehicle: vehicle,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DriverData driver, DriversController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(context, 'Excluir Motorista', 'Delete Driver')),
        content: Text(TranslationHelper.translateSync(context, 
          'Tem certeza que deseja excluir o motorista "${driver.name ?? 'Sem nome'}"?',
          'Are you sure you want to delete driver "${driver.name ?? 'No name'}"?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              EasyLoading.show(status: TranslationHelper.translateSync(context, 'Excluindo...', 'Deleting...'));
              
              final success = await controller.deleteDriver(driver.id);
              
              EasyLoading.dismiss();
              
              if (success) {
                EasyLoading.showSuccess(TranslationHelper.translateSync(context, 'Motorista excluído com sucesso!', 'Driver deleted successfully!'));
              } else {
                EasyLoading.showError(
                  controller.error ?? TranslationHelper.translateSync(context, 'Erro ao excluir motorista', 'Error deleting driver'),
                );
              }
            },
            child: Text(
              TranslationHelper.translateSync(context, 'Excluir', 'Delete'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(
    BuildContext context,
    DriverData driver,
    DriversController controller,
    ColorProvider colorProvider,
  ) {
    return InkWell(
      onTap: () => _showDriverDetailsModal(context, driver, controller, colorProvider),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto/Avatar do motorista
            _buildDriverAvatar(driver, colorProvider),
            SizedBox(width: 16),
            // Informações básicas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    driver.name ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  // Telefone
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            driver.phone.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (driver.phone != null && driver.phone.toString().isNotEmpty)
                    SizedBox(height: 4),
                  // Email
                  if (driver.email != null && driver.email.toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            driver.email.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Ícone de seta
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
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
                SizedBox(height: 2),
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
    );
  }

  Widget _buildVehicleInfo(deviceItems vehicle, ColorProvider colorProvider) {
    final speed = vehicle.speed != null ? (vehicle.speed as num).toDouble() : 0.0;
    final isOnline = vehicle.online?.toString().toLowerCase() == 'ack';
    
    return Container(
      padding: EdgeInsets.all(12),
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
              Icon(
                Icons.directions_car,
                size: 20,
                color: colorProvider.primaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo sem nome', 'Unnamed vehicle'),
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
                  isOnline ? TranslationHelper.translateSync(context, 'Online', 'Online') : TranslationHelper.translateSync(context, 'Offline', 'Offline'),
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
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  TranslationHelper.translateSync(context, 'Placa: ${vehicle.plateNumber}', 'Plate: ${vehicle.plateNumber}'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
          if (speed > 0) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  TranslationHelper.translateSync(context, 'Velocidade: ${speed.toStringAsFixed(0)} km/h', 'Speed: ${speed.toStringAsFixed(0)} km/h'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationHelper.translateSync(context, 'Não foi possível fazer a ligação', 'Could not make the call'))),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationHelper.translateSync(context, 'Não foi possível abrir o email', 'Could not open email'))),
      );
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    try {
      // Remover caracteres não numéricos
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      final link = WhatsAppUnilink(
        phoneNumber: cleanPhone,
        text: TranslationHelper.translateSync(context, 'Olá!', 'Hello!'),
      );
      
      final uri = link.asUri();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationHelper.translateSync(context, 'WhatsApp não está instalado', 'WhatsApp is not installed'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationHelper.translateSync(context, 'Erro ao abrir WhatsApp: $e', 'Error opening WhatsApp: $e'))),
      );
    }
  }

  /// Gerar dados do QR Code para o motorista
  String _generateQrCodeData(DriverData driver) {
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

  /// Exibir modal com QR Code do motorista
  void _showQrCodeModal(BuildContext context, DriverData driver, ColorProvider colorProvider) {
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
              // Header
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: colorProvider.primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      TranslationHelper.translateSync(context, 'QR Code de Identificação', 'Identification QR Code'),
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
                driver.name ?? TranslationHelper.translateSync(context, 'Motorista', 'Driver'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorProvider.primaryColor,
                ),
              ),
              SizedBox(height: 24),
              // QR Code
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorProvider.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: colorProvider.primaryColor,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              SizedBox(height: 24),
              // Informações
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translateSync(context, 'Como usar:', 'How to use:'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorProvider.primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      TranslationHelper.translateSync(context,
                        '1. Escaneie este QR Code com o aplicativo\n'
                        '2. O motorista será identificado automaticamente\n'
                        '3. O sistema registrará qual motorista está dirigindo',
                        '1. Scan this QR Code with the app\n'
                        '2. The driver will be identified automatically\n'
                        '3. The system will record which driver is driving'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Botão Compartilhar Scanner
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareScanner(context, driver, colorProvider),
                  icon: Icon(Icons.share),
                  label: Text(TranslationHelper.translateSync(context, 'Compartilhar Scanner de Identificação', 'Share Identification Scanner')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorProvider.primaryColor,
                    side: BorderSide(color: colorProvider.primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Botão fechar
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
                  child: Text(TranslationHelper.translateSync(context, 'Fechar', 'Close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abrir scanner de QR Code para identificar motorista
  void _openQrScanner(BuildContext context, DriversController controller, ColorProvider colorProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DriverQrScannerScreen(),
      ),
    );
  }

  /// Compartilhar scanner de identificação com motorista (incluindo QR Code)
  Future<void> _shareScanner(BuildContext context, DriverData driver, ColorProvider colorProvider) async {
    final driverName = driver.name ?? TranslationHelper.translateSync(context, 'Motorista', 'Driver');
    final driverId = driver.id?.toString() ?? '';
    final qrData = _generateQrCodeData(driver);
    
    try {
      // Criar mensagem para compartilhar
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      final message = isEnglish
        ? '''🚗 *Identification QR Code - $driverName*

Hello! This is your identification QR Code. *PRINT THIS QR CODE* and always carry it with you.

*How to use:*
1. *PRINT* this QR Code
2. When starting a trip, scan your QR Code
3. Wait for system confirmation
4. After confirmation, you can start the vehicle

*Your ID:* $driverId
*Name:* $driverName

*IMPORTANT:*
- Always keep this QR Code with you
- Scan BEFORE starting the vehicle
- Without the QR Code, it will not be possible to start trips

_Shared via U-Connect_'''
        : '''🚗 *QR Code de Identificação - $driverName*

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

      // Compartilhar mensagem (o QR Code será gerado pelo motorista no app)
      await Share.share(
        message,
        subject: isEnglish ? 'Identification QR Code - $driverName' : 'QR Code de Identificação - $driverName',
      );
    } catch (e) {
      print('❌ Erro ao compartilhar QR Code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao compartilhar: $e', 'Error sharing: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  /// Compartilhar scanner geral (sem motorista específico)
  void _shareGeneralScanner(BuildContext context, ColorProvider colorProvider) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final message = isEnglish
      ? '''🚗 *Driver Identification Scanner*

Use this app to scan driver identification QR Codes.

*How to use:*
1. Open the U-Connect app
2. Go to Drivers → Scan QR Code
3. Scan the driver's QR Code
4. The driver will be identified automatically

*Available at:*
Drivers → Scan QR Code button

_Shared via U-Connect_'''
      : '''🚗 *Scanner de Identificação de Motoristas*

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
      subject: isEnglish ? 'Driver Identification Scanner' : 'Scanner de Identificação de Motoristas',
    );
  }

  /// Exibir diálogo quando motorista for identificado
  void _showDriverIdentifiedDialog(BuildContext context, String driverId, String driverName, ColorProvider colorProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                TranslationHelper.translateSync(context, 'Motorista Identificado', 'Driver Identified'),
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
              TranslationHelper.translateSync(context, 'QR Code escaneado com sucesso!', 'QR Code scanned successfully!'),
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          TranslationHelper.translateSync(context, 'ID:', 'ID:'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorProvider.primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          driverId,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          TranslationHelper.translateSync(context, 'Nome:', 'Name:'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorProvider.primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          driverName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'O motorista foi identificado e registrado no sistema.', 'The driver has been identified and registered in the system.'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationHelper.translateSync(context, 'OK', 'OK')),
          ),
        ],
      ),
    );
  }

}

/// Tela de scanner de QR Code
class _QrScannerScreen extends StatefulWidget {
  final Function(String driverId, String driverName) onDriverIdentified;

  const _QrScannerScreen({
    required this.onDriverIdentified,
  });

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

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

    setState(() {
      _isProcessing = true;
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
          final driverName = data['name']?.toString() ?? TranslationHelper.translateSync(context, 'Motorista Desconhecido', 'Unknown Driver');
          
          // Parar o scanner
          _scannerController.stop();
          
          // Chamar callback
          widget.onDriverIdentified(driverId, driverName);
          return;
        }
      }
      
      // Se não for JSON válido, tentar como ID direto
      final driverId = qrData.trim();
      if (driverId.isNotEmpty) {
        _scannerController.stop();
        widget.onDriverIdentified(driverId, TranslationHelper.translateSync(context, 'Motorista ID: $driverId', 'Driver ID: $driverId'));
        return;
      }
    } catch (e) {
      // Se não for JSON, tratar como ID simples
      final driverId = qrData.trim();
      if (driverId.isNotEmpty) {
        _scannerController.stop();
        widget.onDriverIdentified(driverId, TranslationHelper.translateSync(context, 'Motorista ID: $driverId', 'Driver ID: $driverId'));
        return;
      }
    }

    // Se chegou aqui, QR Code inválido
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translateSync(context, 'QR Code inválido. Escaneie um QR Code de motorista válido.', 'Invalid QR Code. Scan a valid driver QR Code.')),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationHelper.translateSync(context, 'Escanear QR Code', 'Scan QR Code')),
        backgroundColor: colorProvider.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          
          // Overlay com instruções
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Posicione o QR Code do motorista dentro da área de leitura', 'Position the driver QR Code within the reading area'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    TranslationHelper.translateSync(context, 'A identificação será feita automaticamente', 'Identification will be done automatically'),
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
          
          // Overlay com moldura de leitura
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colorProvider.primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
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
                      TranslationHelper.translateSync(context, 'Processando...', 'Processing...'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

