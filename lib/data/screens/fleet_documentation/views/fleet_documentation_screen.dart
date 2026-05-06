import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/fleet_documentation/controllers/fleet_documentation_controller.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:share_plus/share_plus.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';

class FleetDocumentationScreen extends StatefulWidget {
  @override
  _FleetDocumentationScreenState createState() => _FleetDocumentationScreenState();
}

class _FleetDocumentationScreenState extends State<FleetDocumentationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FleetDocumentationController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Documentação da Frota', 'Fleet Documentation'),
          icon: Icons.description,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer<FleetDocumentationController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        SizedBox(height: 16),
                        Text(
                          TranslationHelper.translateSync(context, 'Erro ao carregar dados', 'Error loading data'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(controller.error!),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => controller.loadData(),
                          icon: Icon(Icons.refresh),
                          label: Text(TranslationHelper.translateSync(context, 'Tentar novamente', 'Try again')),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadData(),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alertas de documentos próximos do vencimento
                        _buildExpiringAlerts(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Resumo
                        _buildSummarySection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Filtros
                        _buildFiltersSection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Lista de documentos
                        _buildDocumentsList(context, controller),
                        
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Botão flutuante com opções (SpeedDial) - Posicionado acima da barra de navegação
            Positioned(
              bottom: 100,
              right: 16,
              child: Consumer<ColorProvider>(
                builder: (context, colorProvider, child) {
                  return SpeedDial(
                    animatedIcon: AnimatedIcons.menu_close,
                    animatedIconTheme: IconThemeData(size: 22.0),
                    backgroundColor: colorProvider.primaryColor,
                    foregroundColor: Colors.white,
                    visible: true,
                    curve: Curves.bounceIn,
                    children: [
                      // Opção: Escanear Documento
                      SpeedDialChild(
                        child: Icon(Icons.document_scanner, color: Colors.white),
                        backgroundColor: Colors.blue,
                        label: TranslationHelper.translateSync(context, 'Escanear Documento', 'Scan Document'),
                        labelStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                        onTap: () => _scanDocument(context),
                      ),
                      // Opção: Tirar Foto
                      SpeedDialChild(
                        child: Icon(Icons.camera_alt, color: Colors.white),
                        backgroundColor: Colors.green,
                        label: TranslationHelper.translateSync(context, 'Tirar Foto', 'Take Photo'),
                        labelStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                        onTap: () => _takePhoto(context),
                      ),
                      // Opção: Adicionar Manualmente
                      SpeedDialChild(
                        child: Icon(Icons.add, color: Colors.white),
                        backgroundColor: Colors.orange,
                        label: TranslationHelper.translateSync(context, 'Adicionar Manualmente', 'Add Manually'),
                        labelStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
                        onTap: () => _showAddDocumentDialog(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringAlerts(BuildContext context, FleetDocumentationController controller) {
    final expiringDocs = controller.getExpiringDocuments();
    
    if (expiringDocs.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Documentos Próximos do Vencimento', 'Documents Expiring Soon'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...expiringDocs.take(3).map((doc) => Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '• ${doc.vehicleName} - ${doc.documentType} (${doc.daysUntilExpiry} dias)',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, FleetDocumentationController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: colorProvider.primaryColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Resumo de Documentos', 'Documents Summary'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.documentCountByType.entries.map((entry) {
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorProvider.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorProvider.primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, FleetDocumentationController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.directions_car),
            ),
            value: controller.selectedVehicleId,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles')),
              ),
              ...controller.vehicles.map((vehicle) => DropdownMenuItem(
                value: vehicle.id.toString(),
                child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
              )),
            ],
            onChanged: (value) => controller.setSelectedVehicle(value),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: TranslationHelper.translateSync(context, 'Tipo de Documento', 'Document Type'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.description),
            ),
            value: controller.selectedDocumentType,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(TranslationHelper.translateSync(context, 'Todos os tipos', 'All types')),
              ),
              DropdownMenuItem(value: 'CRLV', child: Text('CRLV')),
              DropdownMenuItem(value: 'Seguro', child: Text(TranslationHelper.translateSync(context, 'Seguro', 'Insurance'))),
              DropdownMenuItem(value: 'IPVA', child: Text('IPVA')),
              DropdownMenuItem(value: 'Licenciamento', child: Text(TranslationHelper.translateSync(context, 'Licenciamento', 'Licensing'))),
              DropdownMenuItem(value: 'Vistoria', child: Text(TranslationHelper.translateSync(context, 'Vistoria', 'Inspection'))),
            ],
            onChanged: (value) => controller.setSelectedDocumentType(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(BuildContext context, FleetDocumentationController controller) {
    if (controller.documents.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Nenhum documento encontrado', 'No documents found'),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Documentos', 'Documents'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...controller.documents.map((doc) => _buildDocumentCard(context, doc, controller)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, VehicleDocument doc, FleetDocumentationController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final isExpired = doc.isExpired;
    final isExpiringSoon = doc.isExpiringSoon;
    
    Color statusColor = Colors.green;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
    }
    
    return InkWell(
      onTap: () => _showDocumentModal(context, doc, colorProvider),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description, color: statusColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.vehicleName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        doc.documentType,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired
                        ? TranslationHelper.translateSync(context, 'Vencido', 'Expired')
                        : isExpiringSoon
                            ? '${doc.daysUntilExpiry} dias'
                            : TranslationHelper.translateSync(context, 'Válido', 'Valid'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, 'Número', 'Number'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        doc.documentNumber,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, 'Vencimento', 'Expiry'),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(doc.expiryDate),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentModal(BuildContext context, VehicleDocument doc, ColorProvider colorProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentViewModal(
        document: doc,
        colorProvider: colorProvider,
      ),
    );
  }

  Future<void> _scanDocument(BuildContext context) async {
    try {
      // Verificar permissão de câmera
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationHelper.translateSync(
                  context,
                  'Permissão de câmera necessária para escanear documentos',
                  'Camera permission required to scan documents',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final file = File(image.path);
        _showAddDocumentDialog(context, filePath: file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao escanear documento: $e',
                'Error scanning document: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      // Verificar permissão de câmera
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationHelper.translateSync(
                  context,
                  'Permissão de câmera necessária para tirar foto',
                  'Camera permission required to take photo',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final file = File(image.path);
        _showAddDocumentDialog(context, filePath: file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao tirar foto: $e',
                'Error taking photo: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDocumentDialog(BuildContext context, {String? filePath}) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    final controller = Provider.of<FleetDocumentationController>(context, listen: false);
    
    String? selectedVehicleId;
    String? selectedDocumentType;
    TextEditingController documentNumberController = TextEditingController();
    TextEditingController issuingAgencyController = TextEditingController();
    DateTime? issueDate;
    DateTime? expiryDate;
    String? selectedFilePath = filePath;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      TranslationHelper.translateSync(context, 'Novo Documento', 'New Document'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview da imagem se houver
                    if (selectedFilePath != null) ...[
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(selectedFilePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    // Veículo
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(TranslationHelper.translateSync(context, 'Selecione um veículo', 'Select a vehicle')),
                        ),
                        ...controller.vehicles.map((vehicle) => DropdownMenuItem(
                          value: vehicle.id.toString(),
                          child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
                        )),
                      ],
                      onChanged: (value) => selectedVehicleId = value,
                    ),
                    SizedBox(height: 16),
                    
                    // Tipo de Documento
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: TranslationHelper.translateSync(context, 'Tipo de Documento', 'Document Type'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.description),
                      ),
                      items: [
                        DropdownMenuItem(value: 'CRLV', child: Text('CRLV')),
                        DropdownMenuItem(value: 'Seguro', child: Text(TranslationHelper.translateSync(context, 'Seguro', 'Insurance'))),
                        DropdownMenuItem(value: 'IPVA', child: Text('IPVA')),
                        DropdownMenuItem(value: 'Licenciamento', child: Text(TranslationHelper.translateSync(context, 'Licenciamento', 'Licensing'))),
                        DropdownMenuItem(value: 'Vistoria', child: Text(TranslationHelper.translateSync(context, 'Vistoria', 'Inspection'))),
                        DropdownMenuItem(value: 'Outro', child: Text(TranslationHelper.translateSync(context, 'Outro', 'Other'))),
                      ],
                      onChanged: (value) => selectedDocumentType = value,
                    ),
                    SizedBox(height: 16),
                    
                    // Número do Documento
                    TextField(
                      controller: documentNumberController,
                      decoration: InputDecoration(
                        labelText: TranslationHelper.translateSync(context, 'Número do Documento', 'Document Number'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Órgão Emissor
                    TextField(
                      controller: issuingAgencyController,
                      decoration: InputDecoration(
                        labelText: TranslationHelper.translateSync(context, 'Órgão Emissor', 'Issuing Agency'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Data de Emissão
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          issueDate = date;
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: TranslationHelper.translateSync(context, 'Data de Emissão', 'Issue Date'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          issueDate != null
                              ? DateFormat('dd/MM/yyyy').format(issueDate!)
                              : TranslationHelper.translateSync(context, 'Selecione a data', 'Select date'),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Data de Vencimento
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          expiryDate = date;
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: TranslationHelper.translateSync(context, 'Data de Vencimento', 'Expiry Date'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          expiryDate != null
                              ? DateFormat('dd/MM/yyyy').format(expiryDate!)
                              : TranslationHelper.translateSync(context, 'Selecione a data', 'Select date'),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedVehicleId == null || selectedDocumentType == null || 
                              documentNumberController.text.isEmpty || expiryDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  TranslationHelper.translateSync(
                                    context,
                                    'Preencha todos os campos obrigatórios',
                                    'Fill all required fields',
                                  ),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          final vehicle = controller.vehicles.firstWhere(
                            (v) => v.id.toString() == selectedVehicleId,
                          );
                          
                          final document = VehicleDocument(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            vehicleId: int.tryParse(selectedVehicleId!),
                            vehicleName: vehicle.name ?? 'Veículo ${vehicle.id}',
                            documentType: selectedDocumentType!,
                            documentNumber: documentNumberController.text,
                            issueDate: issueDate ?? DateTime.now(),
                            expiryDate: expiryDate!,
                            issuingAgency: issuingAgencyController.text.isNotEmpty 
                                ? issuingAgencyController.text 
                                : 'N/A',
                            filePath: selectedFilePath,
                          );
                          
                          controller.addDocument(document);
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                TranslationHelper.translateSync(
                                  context,
                                  'Documento adicionado com sucesso!',
                                  'Document added successfully!',
                                ),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          TranslationHelper.translateSync(context, 'Salvar Documento', 'Save Document'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// MODAL DE VISUALIZAÇÃO DO DOCUMENTO
// ============================================

class _DocumentViewModal extends StatefulWidget {
  final VehicleDocument document;
  final ColorProvider colorProvider;

  const _DocumentViewModal({
    required this.document,
    required this.colorProvider,
  });

  @override
  State<_DocumentViewModal> createState() => _DocumentViewModalState();
}

class _DocumentViewModalState extends State<_DocumentViewModal> {
  bool _isSharing = false;

  Future<void> _shareOnWhatsApp() async {
    try {
      setState(() {
        _isSharing = true;
      });

      StringBuffer messageBuffer = StringBuffer();
      messageBuffer.writeln('📄 *DOCUMENTO DA FROTA*');
      messageBuffer.writeln('');
      messageBuffer.writeln('🚗 *Veículo:* ${widget.document.vehicleName}');
      messageBuffer.writeln('📋 *Tipo:* ${widget.document.documentType}');
      messageBuffer.writeln('🔢 *Número:* ${widget.document.documentNumber}');
      messageBuffer.writeln('🏢 *Órgão Emissor:* ${widget.document.issuingAgency}');
      messageBuffer.writeln('📅 *Emissão:* ${DateFormat('dd/MM/yyyy').format(widget.document.issueDate)}');
      messageBuffer.writeln('⏰ *Vencimento:* ${DateFormat('dd/MM/yyyy').format(widget.document.expiryDate)}');
      
      if (widget.document.isExpired) {
        messageBuffer.writeln('⚠️ *Status:* VENCIDO');
      } else if (widget.document.isExpiringSoon) {
        messageBuffer.writeln('⚠️ *Status:* Vence em ${widget.document.daysUntilExpiry} dias');
      } else {
        messageBuffer.writeln('✅ *Status:* Válido');
      }

      if (widget.document.notes != null && widget.document.notes!.isNotEmpty) {
        messageBuffer.writeln('');
        messageBuffer.writeln('📝 *Observações:*');
        messageBuffer.writeln(widget.document.notes!);
      }

      final message = messageBuffer.toString();
      final link = WhatsAppUnilink(
        phoneNumber: '',
        text: message,
      );

      await launchUrl(link.asUri());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao compartilhar no WhatsApp', 'Error sharing on WhatsApp')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _shareDocument() async {
    try {
      setState(() {
        _isSharing = true;
      });

      String shareText = TranslationHelper.translateSync(
        context,
        'Documento: ${widget.document.documentType}\nVeículo: ${widget.document.vehicleName}\nNúmero: ${widget.document.documentNumber}\nVencimento: ${DateFormat('dd/MM/yyyy').format(widget.document.expiryDate)}',
        'Document: ${widget.document.documentType}\nVehicle: ${widget.document.vehicleName}\nNumber: ${widget.document.documentNumber}\nExpiry: ${DateFormat('dd/MM/yyyy').format(widget.document.expiryDate)}',
      );

      if (widget.document.filePath != null && File(widget.document.filePath!).existsSync()) {
        await Share.shareXFiles(
          [XFile(widget.document.filePath!)],
          text: shareText,
        );
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao compartilhar', 'Error sharing')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _viewImage() {
    if (widget.document.filePath == null || !File(widget.document.filePath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Imagem não disponível', 'Image not available')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(widget.document.filePath!),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.document.isExpired;
    final isExpiringSoon = widget.document.isExpiringSoon;
    
    Color statusColor = Colors.green;
    if (isExpired) {
      statusColor = Colors.red;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: widget.colorProvider.primaryColor,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Ícone da página
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.documentType,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2),
                          Text(
                            widget.document.vehicleName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Botão fechar
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: TranslationHelper.translateSync(context, 'Fechar', 'Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Conteúdo com scroll
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview da imagem se houver
                  if (widget.document.filePath != null && File(widget.document.filePath!).existsSync()) ...[
                    GestureDetector(
                      onTap: _viewImage,
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.document.filePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                                    SizedBox(height: 8),
                                    Text(
                                      TranslationHelper.translateSync(context, 'Erro ao carregar imagem', 'Error loading image'),
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Toque para ampliar', 'Tap to enlarge'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Informações gerais
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.colorProvider.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.colorProvider.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Informações Gerais', 'General Information'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.colorProvider.primaryColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _buildDataCard(
                                  TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                                  widget.document.vehicleName,
                                );
                              case 1:
                                return _buildDataCard(
                                  TranslationHelper.translateSync(context, 'Tipo', 'Type'),
                                  widget.document.documentType,
                                );
                              case 2:
                                return _buildDataCard(
                                  TranslationHelper.translateSync(context, 'Número', 'Number'),
                                  widget.document.documentNumber,
                                );
                              case 3:
                                return _buildDataCard(
                                  TranslationHelper.translateSync(context, 'Status', 'Status'),
                                  isExpired
                                      ? TranslationHelper.translateSync(context, 'Vencido', 'Expired')
                                      : isExpiringSoon
                                          ? '${widget.document.daysUntilExpiry} ${TranslationHelper.translateSync(context, 'dias', 'days')}'
                                          : TranslationHelper.translateSync(context, 'Válido', 'Valid'),
                                  valueColor: statusColor,
                                );
                              default:
                                return SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Informações detalhadas
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Detalhes do Documento', 'Document Details'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildDetailRow(
                          TranslationHelper.translateSync(context, 'Órgão Emissor', 'Issuing Agency'),
                          widget.document.issuingAgency,
                          Icons.business,
                        ),
                        SizedBox(height: 12),
                        _buildDetailRow(
                          TranslationHelper.translateSync(context, 'Data de Emissão', 'Issue Date'),
                          DateFormat('dd/MM/yyyy').format(widget.document.issueDate),
                          Icons.calendar_today,
                        ),
                        SizedBox(height: 12),
                        _buildDetailRow(
                          TranslationHelper.translateSync(context, 'Data de Vencimento', 'Expiry Date'),
                          DateFormat('dd/MM/yyyy').format(widget.document.expiryDate),
                          Icons.event,
                          valueColor: statusColor,
                        ),
                        if (widget.document.notes != null && widget.document.notes!.isNotEmpty) ...[
                          SizedBox(height: 12),
                          _buildDetailRow(
                            TranslationHelper.translateSync(context, 'Observações', 'Notes'),
                            widget.document.notes!,
                            Icons.note,
                            isMultiline: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botões de ação
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (widget.document.filePath != null && File(widget.document.filePath!).existsSync())
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _viewImage,
                      icon: Icon(Icons.image, color: Colors.white),
                      label: Text(TranslationHelper.translateSync(context, 'Ver Imagem', 'View Image')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (widget.document.filePath != null && File(widget.document.filePath!).existsSync())
                  SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareOnWhatsApp,
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text(TranslationHelper.translateSync(context, 'WhatsApp', 'WhatsApp')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareDocument,
                    icon: _isSharing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.share_outlined, color: Colors.white),
                    label: Text(_isSharing 
                        ? TranslationHelper.translateSync(context, 'Compartilhando...', 'Sharing...')
                        : TranslationHelper.translateSync(context, 'Compartilhar', 'Share')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colorProvider.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, String value, {Color? valueColor}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: widget.colorProvider.primaryColor),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey[800],
                ),
                maxLines: isMultiline ? null : 2,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
