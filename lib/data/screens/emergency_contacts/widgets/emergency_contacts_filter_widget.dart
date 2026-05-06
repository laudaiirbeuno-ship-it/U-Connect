import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/emergency_contacts/controllers/emergency_contacts_controller.dart';

class EmergencyContactsFilterWidget extends StatefulWidget {
  final bool isSticky;

  const EmergencyContactsFilterWidget({Key? key, this.isSticky = false}) : super(key: key);

  @override
  _EmergencyContactsFilterWidgetState createState() => _EmergencyContactsFilterWidgetState();
}

class _EmergencyContactsFilterWidgetState extends State<EmergencyContactsFilterWidget> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<EmergencyContactsController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);

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
                TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Dropdown de categoria
          _buildDropdown(
            context: context,
            label: TranslationHelper.translateSync(context, 'Categoria', 'Category'),
            value: controller.selectedCategory ?? 'Todas',
            items: [
              DropdownMenuItem<String>(
                value: 'Todas',
                child: Text(TranslationHelper.translateSync(context, 'Todas', 'All')),
              ),
              ...controller.categories.where((c) => c != 'Todas').map((cat) {
                final translatedCategory = _translateCategory(cat);
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(translatedCategory),
                );
              }).toList(),
            ],
            onChanged: (value) {
              if (value == 'Todas') {
                controller.setCategory(null);
              } else {
                controller.setCategory(value);
              }
            },
            colorProvider: colorProvider,
          ),
          SizedBox(height: 12),
          // Dropdown de estado
          _buildDropdown(
            context: context,
            label: TranslationHelper.translateSync(context, 'Estado', 'State'),
            value: controller.selectedState ?? 'Todos',
            items: [
              DropdownMenuItem<String>(
                value: 'Todos',
                child: Text(TranslationHelper.translateSync(context, 'Todos', 'All')),
              ),
              ...controller.states.where((s) => s != 'Todos').map((state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
            ],
            onChanged: (value) {
              if (value == 'Todos') {
                controller.setState(null);
              } else {
                controller.setState(value);
              }
            },
            colorProvider: colorProvider,
          ),
        ],
      ),
    );
  }

  String _translateCategory(String category) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isEnglish) {
      switch (category) {
        case 'Bombeiros':
          return 'Fire Department';
        case 'Polícia Militar':
          return 'Military Police';
        case 'Polícia Civil':
          return 'Civil Police';
        case 'Polícia Rodoviária Federal':
          return 'Federal Highway Police';
        case 'Polícia Federal':
          return 'Federal Police';
        case 'SAMU':
          return 'SAMU (Emergency Medical Service)';
        default:
          return category;
      }
    } else {
      return category;
    }
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
