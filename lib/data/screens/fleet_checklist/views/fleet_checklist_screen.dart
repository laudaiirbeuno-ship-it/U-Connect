import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/fleet_checklist/controllers/fleet_checklist_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:intl/intl.dart';

class FleetChecklistScreen extends StatefulWidget {
  @override
  _FleetChecklistScreenState createState() => _FleetChecklistScreenState();
}

class _FleetChecklistScreenState extends State<FleetChecklistScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FleetChecklistController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Checklist da Frota', 'Fleet Checklist'),
          icon: Icons.checklist,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer<FleetChecklistController>(
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
                        // Resumo
                        _buildSummarySection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Filtros
                        _buildFiltersSection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Lista de checklists
                        _buildChecklistsList(context, controller),
                        
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Botão flutuante para criar novo checklist
            Consumer<ColorProvider>(
              builder: (context, colorProvider, child) {
                return Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showAddChecklistDialog(context),
                    backgroundColor: colorProvider.primaryColor,
                    child: Icon(Icons.add, color: Colors.white),
                    tooltip: TranslationHelper.translateSync(context, 'Criar Novo Checklist', 'Create New Checklist'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, FleetChecklistController controller) {
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
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: colorProvider.primaryColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Resumo de Checklists', 'Checklist Summary'),
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
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.list,
                  '${controller.totalChecklists}',
                  TranslationHelper.translateSync(context, 'Total', 'Total'),
                  colorProvider.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.check_circle,
                  '${controller.completedChecklists}',
                  TranslationHelper.translateSync(context, 'Concluídos', 'Completed'),
                  colorProvider.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.pending,
                  '${controller.pendingChecklists}',
                  TranslationHelper.translateSync(context, 'Pendentes', 'Pending'),
                  colorProvider.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String value, String label, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, FleetChecklistController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: colorProvider.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: controller.selectedVehicleId,
            decoration: InputDecoration(
              labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.fromDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.setDateRange(date, controller.toDate);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'De', 'From'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(controller.fromDate)),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.toDate,
                      firstDate: controller.fromDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.setDateRange(controller.fromDate, date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'Até', 'To'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(controller.toDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistsList(BuildContext context, FleetChecklistController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.checklistRecords.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.checklist_outlined, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Nenhum checklist encontrado', 'No checklists found'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
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
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.history, color: colorProvider.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Histórico de Checklists', 'Checklist History'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          ...controller.checklistRecords.map((record) => _buildChecklistCard(context, record, controller)),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context, ChecklistRecord record, FleetChecklistController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.completed ? Colors.green.shade300 : Colors.orange.shade300,
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
              Builder(
                builder: (context) {
                  final colorProvider = Provider.of<ColorProvider>(context);
                  return Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  record.completed ? Icons.check_circle : Icons.pending,
                      color: colorProvider.primaryColor,
                  size: 24,
                ),
                  );
                },
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.vehicleName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      record.templateName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: record.completed ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.completed 
                      ? TranslationHelper.translateSync(context, 'Concluído', 'Completed')
                      : TranslationHelper.translateSync(context, 'Pendente', 'Pending'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: record.completed ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                record.inspectorName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (record.deviceName != null) ...[
                SizedBox(width: 12),
                Icon(Icons.devices, size: 14, color: Colors.grey.shade500),
                SizedBox(width: 4),
                Text(
                  record.deviceName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              if (record.driverName != null) ...[
                SizedBox(width: 12),
                Icon(Icons.drive_eta, size: 14, color: Colors.grey.shade500),
                SizedBox(width: 4),
                Text(
                  record.driverName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              Spacer(),
              Text(
                '${record.items.where((i) => i.checked).length}/${record.items.length} ${TranslationHelper.translateSync(context, 'itens', 'items')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showChecklistDetails(context, record),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text(TranslationHelper.translateSync(context, 'Ver Detalhes', 'View Details')),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(TranslationHelper.translateSync(context, 'Excluir Checklist', 'Delete Checklist')),
                      content: Text(TranslationHelper.translateSync(context, 'Deseja realmente excluir este checklist?', 'Do you really want to delete this checklist?')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.deleteChecklistRecord(record.id);
                            Navigator.pop(context);
                          },
                          child: Text(TranslationHelper.translateSync(context, 'Excluir', 'Delete'), style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChecklistDetails(BuildContext context, ChecklistRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.templateName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${record.vehicleName} - ${DateFormat('dd/MM/yyyy HH:mm').format(record.date)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 20),
            ...record.items.map((item) => CheckboxListTile(
              title: Text(item.itemName),
              value: item.checked,
              onChanged: null,
              secondary: Icon(
                item.checked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: item.checked ? Colors.green : Colors.grey,
              ),
            )),
            if (record.notes != null) ...[
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Observações', 'Notes'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(record.notes!),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddChecklistDialog(BuildContext context) {
    final controller = Provider.of<FleetChecklistController>(context, listen: false);
    
    String? selectedVehicleId;
    String? selectedDeviceId;
    String? selectedDriverId;
    ChecklistTemplate? selectedTemplate;
    DateTime selectedDate = DateTime.now();
    String inspectorName = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Novo Checklist', 'New Checklist'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003087),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: controller.vehicles.map((vehicle) => DropdownMenuItem(
                    value: vehicle.id.toString(),
                    child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
                  )).toList(),
                  onChanged: (value) => setState(() {
                    selectedVehicleId = value;
                    // Auto-selecionar o dispositivo quando selecionar o veículo
                    if (value != null) {
                      selectedDeviceId = value;
                    }
                  }),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Dispositivo', 'Device'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.devices),
                    helperText: TranslationHelper.translateSync(context, 'Dispositivo GPS vinculado', 'Linked GPS device'),
                  ),
                  value: selectedDeviceId,
                  items: controller.vehicles.map((vehicle) => DropdownMenuItem(
                    value: vehicle.id.toString(),
                    child: Text('${vehicle.name ?? 'Veículo ${vehicle.id}'} (${vehicle.id})'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedDeviceId = value),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Motorista (Opcional)', 'Driver (Optional)'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  value: selectedDriverId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(TranslationHelper.translateSync(context, 'Nenhum motorista', 'No driver')),
                    ),
                    ...controller.drivers.map((driver) => DropdownMenuItem(
                      value: driver.id.toString(),
                      child: Text(driver.name ?? 'Motorista ${driver.id}'),
                    )),
                  ],
                  onChanged: (value) => setState(() => selectedDriverId = value),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<ChecklistTemplate>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Template', 'Template'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: controller.templates.map((template) => DropdownMenuItem(
                    value: template,
                    child: Text(template.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedTemplate = value),
                ),
                SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'Data', 'Date'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Inspetor', 'Inspector'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: (value) => inspectorName = value,
                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF003087), Color(0xFF0077D7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedVehicleId != null && selectedDeviceId != null && selectedTemplate != null) {
                              final vehicle = controller.vehicles.firstWhere((v) => v.id.toString() == selectedVehicleId);
                              final device = controller.vehicles.firstWhere((v) => v.id.toString() == selectedDeviceId);
                              
                              DriverData? driver;
                              if (selectedDriverId != null) {
                                driver = controller.drivers.firstWhere((d) => d.id.toString() == selectedDriverId);
                              }
                              
                              final record = ChecklistRecord(
                                id: '${DateTime.now().millisecondsSinceEpoch}',
                                vehicleId: vehicle.id,
                                vehicleName: vehicle.name ?? 'Veículo',
                                deviceId: device.id,
                                deviceName: device.name ?? 'Dispositivo',
                                driverId: driver?.id,
                                driverName: driver?.name,
                                templateId: selectedTemplate!.id,
                                templateName: selectedTemplate!.name,
                                date: selectedDate,
                                completed: false,
                                items: selectedTemplate!.items.map((item) => ChecklistItemResult(
                                  itemId: item.id,
                                  itemName: item.name,
                                  checked: false,
                                )).toList(),
                                inspectorName: inspectorName.isNotEmpty ? inspectorName : 'Inspetor',
                              );
                              
                              controller.addChecklistRecord(record);
                              Navigator.pop(context);
                              _showChecklistDetails(context, record);
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          TranslationHelper.translateSync(context, 'Criar', 'Create'),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
