import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/video_telemetry/controllers/cameras_controller.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/data/model/devices.dart';

class CamerasFilterWidget extends StatefulWidget {
  final bool isSticky;

  const CamerasFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _CamerasFilterWidgetState createState() => _CamerasFilterWidgetState();
}

class _CamerasFilterWidgetState extends State<CamerasFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CamerasController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    final objectStore = Provider.of<ObjectStore>(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildDeviceSelector(controller, colorProvider, objectStore),
          SizedBox(height: 12),
          _buildStatusSelector(controller, colorProvider),
          SizedBox(height: 12),
          _buildCategorySelector(controller, colorProvider),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(CamerasController controller, ColorProvider colorProvider, ObjectStore objectStore) {
    final selectedDevice = controller.selectedVehicleId != null
        ? objectStore.objects.firstWhere(
            (device) => device.id?.toString() == controller.selectedVehicleId,
            orElse: () => deviceItems(),
          )
        : null;
    
    return InkWell(
      onTap: () => _selectDevice(controller, colorProvider, objectStore),
      child: Container(
        padding: EdgeInsets.all(16),
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
                    controller.selectedVehicleId == null 
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
                    controller.selectedVehicleId == null
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
    );
  }

  Widget _buildStatusSelector(CamerasController controller, ColorProvider colorProvider) {
    final statusText = controller.selectedStatus == null 
        ? TranslationHelper.translateSync(context, 'Todos', 'All')
        : _translateStatus(controller.selectedStatus!);
    
    return InkWell(
      onTap: () => _selectStatus(controller, colorProvider),
      child: Container(
        padding: EdgeInsets.all(16),
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
              child: Icon(Icons.info, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Status', 'Status'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    statusText,
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
    );
  }

  Widget _buildCategorySelector(CamerasController controller, ColorProvider colorProvider) {
    final categoryText = controller.selectedCategory == null 
        ? TranslationHelper.translateSync(context, 'Todas', 'All')
        : _translateCategory(controller.selectedCategory!);
    
    return InkWell(
      onTap: () => _selectCategory(controller, colorProvider),
      child: Container(
        padding: EdgeInsets.all(16),
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
              child: Icon(Icons.category, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Categoria', 'Category'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    categoryText,
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
    );
  }

  Future<void> _selectDevice(CamerasController controller, ColorProvider colorProvider, ObjectStore objectStore) async {
    try {
      final devices = objectStore.objects.isNotEmpty 
          ? List<deviceItems>.from(objectStore.objects)
          : <deviceItems>[];
      
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
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.devices, color: Colors.white),
              SizedBox(width: 8),
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
                  itemCount: devices.length + 1, // +1 para "Todos"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = controller.selectedVehicleId == null;
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
                            TranslationHelper.translateSync(context, 'Todos', 'All'),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: isSelected ? colorProvider.primaryColor : Colors.black87,
                            ),
                          ),
                          trailing: isSelected 
                              ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  color: colorProvider.primaryColor,
                                  size: 18,
                                ),
                          onTap: () => Navigator.pop(context, null),
                        ),
                      );
                    }
                    
                    final device = devices[index - 1];
                    final isSelected = controller.selectedVehicleId == device.id?.toString();
                    
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

      controller.setVehicleId(selected);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao carregar dispositivos: $e', 'Error loading devices: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectStatus(CamerasController controller, ColorProvider colorProvider) async {
    final selected = await showModalBottomSheet<String>(
            context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TranslationHelper.translateSync(context, 'Selecionar Status', 'Select Status'),
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
            
            // Lista de status
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: controller.statuses.length,
                itemBuilder: (context, index) {
                  final status = controller.statuses[index];
                  final isSelected = controller.selectedStatus == status || (controller.selectedStatus == null && status == 'Todos');
                  
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
                          Icons.info,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                      title: Text(
                        _translateStatus(status),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isSelected ? colorProvider.primaryColor : Colors.black87,
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                          : Icon(
                              Icons.arrow_forward_ios,
                              color: colorProvider.primaryColor,
                              size: 18,
                            ),
                      onTap: () => Navigator.pop(context, status == 'Todos' ? null : status),
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
      if (selected == 'Todos') {
        controller.setStatus(null);
      } else {
        controller.setStatus(selected);
      }
    } else if (selected == null) {
      controller.setStatus(null);
    }
  }

  Future<void> _selectCategory(CamerasController controller, ColorProvider colorProvider) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TranslationHelper.translateSync(context, 'Selecionar Categoria', 'Select Category'),
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
            
            // Lista de categorias
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  final isSelected = controller.selectedCategory == category || (controller.selectedCategory == null && category == 'Todas');
                  
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
                          Icons.category,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                      title: Text(
                        _translateCategory(category),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isSelected ? colorProvider.primaryColor : Colors.black87,
                        ),
                      ),
                      trailing: isSelected 
                          ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                          : Icon(
                              Icons.arrow_forward_ios,
                              color: colorProvider.primaryColor,
                              size: 18,
                            ),
                      onTap: () => Navigator.pop(context, category == 'Todas' ? null : category),
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
      if (selected == 'Todas') {
        controller.setCategory(null);
      } else {
        controller.setCategory(selected);
      }
    } else if (selected == null) {
      controller.setCategory(null);
    }
  }

  String _translateStatus(String status) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isEnglish) {
      switch (status.toLowerCase()) {
        case 'online':
          return 'Online';
        case 'offline':
          return 'Offline';
        default:
          return status;
      }
    } else {
      switch (status.toLowerCase()) {
        case 'online':
          return 'Online';
        case 'offline':
          return 'Offline';
        default:
          return status;
      }
    }
  }

  String _translateCategory(String category) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isEnglish) {
      switch (category) {
        case 'Frontal':
          return 'Front';
        case 'Traseira':
          return 'Rear';
        case 'Interna':
          return 'Internal';
        default:
          return category;
      }
    } else {
      return category;
    }
  }

}
