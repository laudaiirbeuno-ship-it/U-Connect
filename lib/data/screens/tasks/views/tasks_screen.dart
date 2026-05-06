import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/tasks/controllers/tasks_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TasksController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Manutenção', 'Maintenance'),
          icon: Icons.task,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            // Fundo animado
            AnimatedBackground(opacity: 0.03),
            // Conteúdo
            Consumer2<TasksController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                return Column(
              children: [
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: colorProvider.primaryColor,
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: colorProvider.primaryColor,
                    tabs: [
                      Tab(text: TranslationHelper.translateSync(context, 'Criar Tarefa', 'Create Task'), icon: Icon(Icons.add_task)),
                      Tab(text: TranslationHelper.translateSync(context, 'Minhas Tarefas', 'My Tasks'), icon: Icon(Icons.list)),
                    ],
                  ),
                ),
                // Conteúdo
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCreateTaskTab(controller, colorProvider),
                      _buildTasksListTab(controller, colorProvider),
                    ],
                  ),
                ),
                ],
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTaskTab(TasksController controller, ColorProvider colorProvider) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Veículo
          _buildDeviceSelector(controller, colorProvider),
          ResponsiveHelper.verticalSpace(24),
          // Título
          Text(
            TranslationHelper.translateSync(context, 'Título da Tarefa *', 'Task Title *'),
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(14),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          ResponsiveHelper.verticalSpace(8),
          TextField(
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(context, 'Ex: Entrega de documentos', 'E.g.: Document delivery'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.title, color: colorProvider.primaryColor),
            ),
            onChanged: (value) => controller.setTitle(value),
          ),
          ResponsiveHelper.verticalSpace(24),
          // Comentário
          Text(
            TranslationHelper.translateSync(context, 'Descrição/Comentário', 'Description/Comment'),
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(14),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          ResponsiveHelper.verticalSpace(8),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(context, 'Descreva a tarefa...', 'Describe the task...'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Padding(
                padding: ResponsiveHelper.padding(bottom: 60),
                child: Icon(Icons.description, color: colorProvider.primaryColor),
              ),
            ),
            onChanged: (value) => controller.setComment(value),
          ),
          ResponsiveHelper.verticalSpace(24),
          // Endereço
          Text(
            TranslationHelper.translateSync(context, 'Endereço de Coleta', 'Pickup Address'),
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(14),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          ResponsiveHelper.verticalSpace(8),
          TextField(
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(context, 'Ex: Rua das Flores, 123', 'E.g.: Main Street, 123'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.location_on, color: colorProvider.primaryColor),
            ),
            onChanged: (value) => controller.setPickupAddress(value),
          ),
          ResponsiveHelper.verticalSpace(24),
          // Erro
          if (controller.error != null)
            Container(
              padding: ResponsiveHelper.padding(all: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  ResponsiveHelper.horizontalSpace(8),
                  Expanded(
                    child: Text(
                      controller.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ResponsiveHelper.verticalSpace(16),
          // Botão criar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading ? null : () async {
                final success = await controller.createTask();
                if (success) {
                  Fluttertoast.showToast(
                    msg: TranslationHelper.translateSync(context, 'Tarefa criada com sucesso!', 'Task created successfully!'),
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                  _tabController.animateTo(1);
                }
              },
              icon: controller.isLoading
                  ? SizedBox(
                      width: ResponsiveHelper.width(20),
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.add),
              label: Text(TranslationHelper.translateSync(context, 'Criar Tarefa', 'Create Task')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksListTab(TasksController controller, ColorProvider colorProvider) {
    if (controller.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey.shade400),
            ResponsiveHelper.verticalSpace(16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhuma tarefa criada', 'No tasks created'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            ResponsiveHelper.verticalSpace(8),
            Text(
              TranslationHelper.translateSync(context, 'Crie sua primeira tarefa na aba "Criar Tarefa"', 'Create your first task in the "Create Task" tab'),
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(14),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final pendingTasks = controller.tasks.where((t) => t['status'] == 1).toList();
    final completedTasks = controller.tasks.where((t) => t['status'] == 0).toList();

    return ListView(
      padding: ResponsiveHelper.padding(all: 16),
      children: [
        if (pendingTasks.isNotEmpty) ...[
          Text(
            TranslationHelper.translateSync(context, 'Pendentes (${pendingTasks.length})', 'Pending (${pendingTasks.length})'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...pendingTasks.map((task) => _buildTaskCard(task, controller, colorProvider, true)),
          ResponsiveHelper.verticalSpace(24),
        ],
        if (completedTasks.isNotEmpty) ...[
          Text(
            TranslationHelper.translateSync(context, 'Concluídas (${completedTasks.length})', 'Completed (${completedTasks.length})'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...completedTasks.map((task) => _buildTaskCard(task, controller, colorProvider, false)),
        ],
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, TasksController controller, ColorProvider colorProvider, bool isPending) {
    final device = controller.devices.firstWhere(
      (d) => d.id?.toString() == task['device_id'],
      orElse: () => controller.devices.first,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? Colors.orange.shade300 : Colors.grey.shade300,
          width: isPending ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsiveHelper.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPending ? Icons.pending : Icons.check_circle,
                    color: isPending ? Colors.orange : Colors.green,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] ?? TranslationHelper.translateSync(context, 'Sem título', 'No title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.directions_car, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            device.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPending)
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () {
                      final index = controller.tasks.indexOf(task);
                      controller.updateTaskStatus(index, 0);
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    final index = controller.tasks.indexOf(task);
                    controller.deleteTask(index);
                  },
                ),
              ],
            ),
            if (task['comment'] != null && task['comment'].toString().isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(),
              ResponsiveHelper.verticalSpace(8),
              Text(
                task['comment'],
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(14),
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            if (task['pickup_address'] != null && task['pickup_address'].toString().isNotEmpty) ...[
              ResponsiveHelper.verticalSpace(8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task['pickup_address'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (task['created_at'] != null) ...[
              ResponsiveHelper.verticalSpace(8),
              Text(
                TranslationHelper.translateSync(context, 'Criada em: ${_formatDateTime(task['created_at'])}', 'Created on: ${_formatDateTime(task['created_at'])}'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildDeviceSelector(TasksController controller, ColorProvider colorProvider) {
    final selectedDevice = controller.selectedDeviceId != null
        ? controller.devices.firstWhere(
            (device) => device.id?.toString() == controller.selectedDeviceId,
            orElse: () => deviceItems(),
          )
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDevice(controller, colorProvider),
          child: Container(
            padding: ResponsiveHelper.padding(all: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorProvider.primaryColor.withOpacity(0.1),
                  colorProvider.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorProvider.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.devices, color: colorProvider.primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.selectedDeviceId == null 
                            ? TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device')
                            : TranslationHelper.translateSync(context, 'Dispositivo Selecionado', 'Device Selected'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        controller.selectedDeviceId == null
                            ? TranslationHelper.translateSync(context, 'Toque para escolher um veículo', 'Tap to choose a vehicle')
                            : selectedDevice?.name ?? TranslationHelper.translateSync(context, 'Dispositivo', 'Device'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: colorProvider.primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDevice(TasksController controller, ColorProvider colorProvider) async {
    try {
      if (controller.devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Nenhum dispositivo disponível', 'No devices available')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: ResponsiveHelper.padding(all: 16),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.devices, color: Colors.white),
                    ResponsiveHelper.horizontalSpace(8),
                    Expanded(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
              
              // Lista de dispositivos
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: controller.devices.length,
                  itemBuilder: (context, index) {
                    final device = controller.devices[index];
                    final isSelected = controller.selectedDeviceId == device.id?.toString();
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: colorProvider.primaryColor,
                          ),
                        ),
                        title: Text(
                          device.name ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name'),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                            color: isSelected ? colorProvider.primaryColor : Colors.black87,
                          ),
                        ),
                        subtitle: device.plateNumber != null && device.plateNumber!.isNotEmpty
                            ? Text('${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${device.plateNumber}')
                            : null,
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: colorProvider.primaryColor,
                                size: 18,
                              ),
                        onTap: () => Navigator.pop(context, device.id?.toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (selected != null) {
        controller.setSelectedDevice(selected);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao carregar dispositivos: $e', 'Error loading devices: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

