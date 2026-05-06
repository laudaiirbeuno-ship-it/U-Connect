import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/drivers/controllers/drivers_controller.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/utils/translation_helper.dart';

class DriversFilterWidget extends StatefulWidget {
  final bool isSticky;

  const DriversFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _DriversFilterWidgetState createState() => _DriversFilterWidgetState();
}

class _DriversFilterWidgetState extends State<DriversFilterWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<DriversController>(context);
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
        ],
      ),
    );
  }

  Widget _buildSearchField(DriversController controller, ColorProvider colorProvider) {
    return Container(
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: TranslationHelper.translateSync(context, 'Buscar por nome, telefone ou email...', 'Search by name, phone or email...'),
          prefixIcon: Icon(Icons.search, color: colorProvider.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    controller.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: (value) {
          controller.setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildDeviceSelector(DriversController controller, ColorProvider colorProvider, ObjectStore objectStore) {
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

  Future<void> _selectDevice(DriversController controller, ColorProvider colorProvider, ObjectStore objectStore) async {
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
                  itemCount: devices.length + 1, // +1 para "Todos os veículos"
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
                            TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles'),
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

      controller.setSelectedVehicle(selected);
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





































