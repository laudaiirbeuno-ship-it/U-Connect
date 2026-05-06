import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';

class ChargesFilterWidget extends StatefulWidget {
  final String? selectedGateway;
  final String? selectedStatus;
  final Function(String?, String?) onFilterChanged;

  const ChargesFilterWidget({
    Key? key,
    this.selectedGateway,
    this.selectedStatus,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  _ChargesFilterWidgetState createState() => _ChargesFilterWidgetState();
}

class _ChargesFilterWidgetState extends State<ChargesFilterWidget> {
  String? _selectedGateway;
  String? _selectedStatus;

  final List<String> _gatewayOptions = [
    'Todos',
    'asaas',
    'suitpay',
  ];

  final List<String> _statusOptions = [
    'Todos',
    'PENDING',
    'PAID',
    'RECEIVED',
    'CONFIRMED',
    'EXPIRED',
    'CANCELED',
    'OVERDUE',
  ];

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Todos':
        return TranslationHelper.translateSync(context, 'Todos', 'All');
      case 'PENDING':
        return TranslationHelper.translateSync(context, 'Pendente', 'Pending');
      case 'PAID':
        return TranslationHelper.translateSync(context, 'Pago', 'Paid');
      case 'RECEIVED':
        return TranslationHelper.translateSync(context, 'Recebido', 'Received');
      case 'CONFIRMED':
        return TranslationHelper.translateSync(context, 'Confirmado', 'Confirmed');
      case 'EXPIRED':
        return TranslationHelper.translateSync(context, 'Expirado', 'Expired');
      case 'CANCELED':
      case 'CANCELLED':
        return TranslationHelper.translateSync(context, 'Cancelado', 'Cancelled');
      case 'OVERDUE':
        return TranslationHelper.translateSync(context, 'Vencido', 'Overdue');
      default:
        return status;
    }
  }

  String _getGatewayLabel(String gateway) {
    switch (gateway.toLowerCase()) {
      case 'todos':
        return TranslationHelper.translateSync(context, 'Todos', 'All');
      case 'asaas':
        return 'Asaas';
      case 'suitpay':
        return 'SuitPay';
      default:
        return gateway.toUpperCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedGateway = widget.selectedGateway;
    _selectedStatus = widget.selectedStatus;
  }

  @override
  void didUpdateWidget(ChargesFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGateway != widget.selectedGateway ||
        oldWidget.selectedStatus != widget.selectedStatus) {
      setState(() {
        _selectedGateway = widget.selectedGateway;
        _selectedStatus = widget.selectedStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);

    return Container(
      padding: EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: TranslationHelper.translateSync(context, 'Gateway', 'Gateway'),
                  value: _selectedGateway ?? 'Todos',
                  items: _gatewayOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedGateway = value == 'Todos' ? null : value;
                    });
                    widget.onFilterChanged(_selectedGateway, _selectedStatus);
                  },
                  colorProvider: colorProvider,
                  isGateway: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: TranslationHelper.translateSync(context, 'Status', 'Status'),
                  value: _selectedStatus ?? 'Todos',
                  items: _statusOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value == 'Todos' ? null : value;
                    });
                    widget.onFilterChanged(_selectedGateway, _selectedStatus);
                  },
                  colorProvider: colorProvider,
                  isStatus: true,
                  displayValue: _getStatusLabel(_selectedStatus ?? 'Todos'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required ColorProvider colorProvider,
    String? displayValue,
    bool isGateway = false,
    bool isStatus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorProvider.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorProvider.primaryColor,
            ),
            items: items.map((String item) {
              String displayText;
              if (displayValue != null && item == value) {
                // Se há um displayValue específico (para status), usar ele
                displayText = displayValue;
              } else if (item == 'Todos') {
                // Traduzir "Todos"
                displayText = TranslationHelper.translateSync(context, 'Todos', 'All');
              } else if (isStatus) {
                // Se for o dropdown de Status, traduzir o status
                displayText = _getStatusLabel(item);
              } else if (isGateway) {
                // Se for o dropdown de Gateway, traduzir o gateway
                displayText = _getGatewayLabel(item);
              } else {
                // Caso padrão, usar o item original
                displayText = item;
              }
              
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
