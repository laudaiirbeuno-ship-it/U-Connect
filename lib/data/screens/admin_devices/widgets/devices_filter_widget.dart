import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/admin_devices/controllers/devices_controller.dart';

class DevicesFilterWidget extends StatefulWidget {
  final bool isSticky;

  const DevicesFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _DevicesFilterWidgetState createState() => _DevicesFilterWidgetState();
}

class _DevicesFilterWidgetState extends State<DevicesFilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<DevicesController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);

    // Atualizar o texto do campo de busca quando o controller mudar
    if (_searchController.text != controller.searchQuery) {
      _searchController.text = controller.searchQuery;
    }

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
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Campo de busca
          _buildSearchField(
            context: context,
            controller: _searchController,
            onChanged: (value) {
              controller.setSearchQuery(value);
            },
            colorProvider: colorProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required BuildContext context,
    required TextEditingController controller,
    required Function(String) onChanged,
    required ColorProvider colorProvider,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Buscar (Nome, IMEI, Placa, SIM)',
          border: InputBorder.none,
          labelStyle: TextStyle(color: colorProvider.primaryColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : Icon(Icons.search, color: Colors.grey),
        ),
        onChanged: onChanged,
      ),
    );
  }
}





































