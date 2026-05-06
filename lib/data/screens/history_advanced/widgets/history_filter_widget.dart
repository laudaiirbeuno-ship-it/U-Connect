import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/history_advanced/controllers/history_advanced_controller.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:intl/intl.dart';

class HistoryFilterWidget extends StatefulWidget {
  final bool isSticky;

  const HistoryFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _HistoryFilterWidgetState createState() => _HistoryFilterWidgetState();
}

class _HistoryFilterWidgetState extends State<HistoryFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryAdvancedController>(context);
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
      padding: EdgeInsets.all(16),
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
            value: controller.selectedDeviceId,
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
          SizedBox(height: 12),
          // Período
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  context: context,
                  label: 'Data Inicial',
                  date: controller.fromDate,
                  onDateSelected: (date) {
                    controller.setFromDate(date);
                  },
                  colorProvider: colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  context: context,
                  label: 'Data Final',
                  date: controller.toDate,
                  onDateSelected: (date) {
                    controller.setToDate(date);
                  },
                  colorProvider: colorProvider,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Botões
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Buscar',
                  icon: Icons.search,
                  onTap: () => controller.loadData(),
                  isPrimary: true,
                  colorProvider: colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'Limpar',
                  icon: Icons.clear,
                  onTap: () {
                    controller.clearFilters();
                    controller.loadData();
                  },
                  isPrimary: false,
                  colorProvider: colorProvider,
                ),
              ),
            ],
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

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime date,
    required Function(DateTime) onDateSelected,
    required ColorProvider colorProvider,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: colorProvider.primaryColor,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A1A1A), // Preto fosco
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A), // Preto fosco
                  ),
                ),
              ],
            ),
            Icon(Icons.calendar_today, color: colorProvider.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
    required ColorProvider colorProvider,
  }) {
    return Material(
      color: isPrimary ? colorProvider.primaryColor : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : colorProvider.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : colorProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

