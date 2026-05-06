import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:intl/intl.dart';

class TransactionsFilterWidget extends StatefulWidget {
  final String? selectedGateway;
  final String? selectedStatus;
  final String? selectedBillingType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, String?, String?, DateTime?, DateTime?) onFilterChanged;

  const TransactionsFilterWidget({
    Key? key,
    this.selectedGateway,
    this.selectedStatus,
    this.selectedBillingType,
    this.startDate,
    this.endDate,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  _TransactionsFilterWidgetState createState() => _TransactionsFilterWidgetState();
}

class _TransactionsFilterWidgetState extends State<TransactionsFilterWidget> {
  String? _selectedGateway;
  String? _selectedStatus;
  String? _selectedBillingType;
  DateTime? _startDate;
  DateTime? _endDate;

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

  final List<String> _billingTypeOptions = [
    'Todos',
    'PIX',
    'BOLETO',
    'CREDIT_CARD',
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

  String _getBillingTypeLabel(String billingType) {
    switch (billingType) {
      case 'Todos':
        return TranslationHelper.translateSync(context, 'Todos', 'All');
      case 'PIX':
        return 'PIX';
      case 'BOLETO':
        return TranslationHelper.translateSync(context, 'Boleto', 'Bank Slip');
      case 'CREDIT_CARD':
        return TranslationHelper.translateSync(context, 'Cartão de Crédito', 'Credit Card');
      default:
        return billingType;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedGateway = widget.selectedGateway;
    _selectedStatus = widget.selectedStatus;
    _selectedBillingType = widget.selectedBillingType;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(TransactionsFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGateway != widget.selectedGateway ||
        oldWidget.selectedStatus != widget.selectedStatus ||
        oldWidget.selectedBillingType != widget.selectedBillingType ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      setState(() {
        _selectedGateway = widget.selectedGateway;
        _selectedStatus = widget.selectedStatus;
        _selectedBillingType = widget.selectedBillingType;
        _startDate = widget.startDate;
        _endDate = widget.endDate;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          // Primeira linha: Gateway e Status
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
                    widget.onFilterChanged(_selectedGateway, _selectedStatus, _selectedBillingType, _startDate, _endDate);
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
                    widget.onFilterChanged(_selectedGateway, _selectedStatus, _selectedBillingType, _startDate, _endDate);
                  },
                  colorProvider: colorProvider,
                  isStatus: true,
                  displayValue: _getStatusLabel(_selectedStatus ?? 'Todos'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Segunda linha: Tipo de Pagamento e Datas
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: TranslationHelper.translateSync(context, 'Tipo de Pagamento', 'Payment Type'),
                  value: _selectedBillingType ?? 'Todos',
                  items: _billingTypeOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedBillingType = value == 'Todos' ? null : value;
                    });
                    widget.onFilterChanged(_selectedGateway, _selectedStatus, _selectedBillingType, _startDate, _endDate);
                  },
                  colorProvider: colorProvider,
                  isBillingType: true,
                  displayValue: _getBillingTypeLabel(_selectedBillingType ?? 'Todos'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Terceira linha: Datas
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: TranslationHelper.translateSync(context, 'Data Inicial', 'Start Date'),
                  date: _startDate,
                  onDateSelected: (date) {
                    setState(() {
                      _startDate = date;
                    });
                    widget.onFilterChanged(_selectedGateway, _selectedStatus, _selectedBillingType, _startDate, _endDate);
                  },
                  colorProvider: colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker(
                  label: TranslationHelper.translateSync(context, 'Data Final', 'End Date'),
                  date: _endDate,
                  onDateSelected: (date) {
                    setState(() {
                      _endDate = date;
                    });
                    widget.onFilterChanged(_selectedGateway, _selectedStatus, _selectedBillingType, _startDate, _endDate);
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
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required ColorProvider colorProvider,
    String? displayValue,
    bool isGateway = false,
    bool isStatus = false,
    bool isBillingType = false,
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
                displayText = displayValue;
              } else if (item == 'Todos') {
                displayText = TranslationHelper.translateSync(context, 'Todos', 'All');
              } else if (isStatus) {
                displayText = _getStatusLabel(item);
              } else if (isGateway) {
                displayText = _getGatewayLabel(item);
              } else if (isBillingType) {
                displayText = _getBillingTypeLabel(item);
              } else {
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
    required ColorProvider colorProvider,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
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
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            onDateSelected(selectedDate);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorProvider.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorProvider.primaryColor,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : TranslationHelper.translateSync(context, 'Selecione', 'Select'),
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? Colors.grey.shade800 : Colors.grey.shade400,
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 16),
                    onPressed: () => onDateSelected(null),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
