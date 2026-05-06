import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';

class NotificationFilterWidget extends StatefulWidget {
  final String? selectedVehicleId;
  final String? selectedEventType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(String?) onVehicleChanged;
  final Function(String?) onEventTypeChanged;
  final Function(DateTime?) onFromDateChanged;
  final Function(DateTime?) onToDateChanged;

  const NotificationFilterWidget({
    Key? key,
    this.selectedVehicleId,
    this.selectedEventType,
    this.fromDate,
    this.toDate,
    required this.onVehicleChanged,
    required this.onEventTypeChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
  }) : super(key: key);

  @override
  _NotificationFilterWidgetState createState() => _NotificationFilterWidgetState();
}

class _NotificationFilterWidgetState extends State<NotificationFilterWidget> {
  List<String> get eventTypes {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      return [
        'All',
        'Speed',
        'Custom',
        'Ignition Off',
        'Ignition On',
        'Anchor Active',
        'Anchor Deactivated',
        'Lock',
        'Unlock',
        'Offline',
      ];
    } else {
      return [
        'Todos',
        'Velocidade',
        'Custom',
        'Ignição Desligada',
        'Ignição Ligada',
        'Âncora Ativa',
        'Âncora Desativada',
        'Bloqueio',
        'Desbloqueio',
        'Offline',
      ];
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final objectStore = Provider.of<ObjectStore>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          
          // Filtro de Veículo
          _buildDropdown(
            context: context,
            label: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
            value: widget.selectedVehicleId,
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles')),
              ),
              ...objectStore.objects.map((device) {
                return DropdownMenuItem<String>(
                  value: device.id?.toString(),
                  child: Text(device.name ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name')),
                );
              }).toList(),
            ],
            onChanged: widget.onVehicleChanged,
            colorProvider: colorProvider,
          ),
          SizedBox(height: 12),
          
          // Filtro de Tipo de Evento
          _buildDropdown(
            context: context,
            label: TranslationHelper.translateSync(context, 'Tipo de Evento', 'Event Type'),
            value: widget.selectedEventType,
            items: eventTypes.map((type) {
              final displayType = type == (Localizations.localeOf(context).languageCode == 'en' ? 'All' : 'Todos') 
                  ? TranslationHelper.translateSync(context, 'Todos', 'All')
                  : type;
              return DropdownMenuItem<String>(
                value: type == (Localizations.localeOf(context).languageCode == 'en' ? 'All' : 'Todos') ? null : type,
                child: Text(displayType),
              );
            }).toList(),
            onChanged: widget.onEventTypeChanged,
            colorProvider: colorProvider,
          ),
          SizedBox(height: 12),
          
          // Filtro de Data Inicial
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: TranslationHelper.translateSync(context, 'Data Inicial', 'Start Date'),
                  value: widget.fromDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.fromDate ?? DateTime.now().subtract(Duration(days: 7)),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      widget.onFromDateChanged(date);
                    }
                  },
                  colorProvider: colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: TranslationHelper.translateSync(context, 'Data Final', 'End Date'),
                  value: widget.toDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.toDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      widget.onToDateChanged(date);
                    }
                  },
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

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required ColorProvider colorProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: colorProvider.primaryColor, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null
                    ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
                    : label,
                style: TextStyle(
                  color: value != null ? Colors.grey.shade800 : Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
