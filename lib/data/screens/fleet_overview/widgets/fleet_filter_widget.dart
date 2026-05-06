import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';

class FleetFilterWidget extends StatefulWidget {
  final bool isSticky;

  const FleetFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _FleetFilterWidgetState createState() => _FleetFilterWidgetState();
}

class _FleetFilterWidgetState extends State<FleetFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    final objectStore = Provider.of<ObjectStore>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: widget.isSticky
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A), // Preto fosco
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Dropdown de veículo
          _buildDropdown(
            context: context,
            label: 'Veículo',
            value: controller.selectedVehicleId,
            items: objectStore.objects.map((device) {
              return DropdownMenuItem<String>(
                value: device.id?.toString(),
                child: Text(device.name ?? 'Sem nome'),
              );
            }).toList(),
            onChanged: (value) {
              controller.setDeviceId(value);
            },
            colorProvider: colorProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required ColorProvider colorProvider,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(color: colorProvider.primaryColor),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

}
