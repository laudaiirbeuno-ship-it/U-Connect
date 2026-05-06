import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';

class InvoicesScreen extends StatefulWidget {
  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _invoices = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }


  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    // Carregar faturas da API
    // TODO: Implementar chamada à API quando disponível
    setState(() {
      _invoices = [];
      // Em produção, isso viria da API:
      // final response = await gpsapis.getInvoices(...);
      // if (response != null) {
      //   _invoices = response;
      // }
    });
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: 'Minhas Faturas',
        icon: Icons.receipt_long,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          // Fundo animado
          AnimatedBackground(opacity: 0.03),
          // Conteúdo
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              if (_isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorProvider.primaryColor,
                    ),
                  ),
                );
              }

              if (_invoices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma fatura encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadInvoices,
                color: colorProvider.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = _invoices[index];
                    return _buildInvoiceCard(invoice, colorProvider);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    if (invoice['status'] == 'Pendente') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (invoice['status'] == 'Vencida') {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showInvoiceDetails(invoice, colorProvider);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice['number'] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            invoice['month'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            invoice['status'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today,
                      'Vencimento',
                      dateFormat.format(DateTime.parse(invoice['dueDate'] as String)),
                      colorProvider,
                    ),
                    if (invoice['paidDate'] != null)
                      _buildInfoItem(
                        Icons.check_circle,
                        'Pago em',
                        dateFormat.format(DateTime.parse(invoice['paidDate'] as String)),
                        colorProvider,
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: colorProvider.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Valor: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            currencyFormat.format(invoice['value'] as double),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (invoice['status'] == 'Pendente')
                        ElevatedButton.icon(
                          onPressed: () {
                            _payInvoice(invoice);
                          },
                          icon: Icon(Icons.payment, size: 18),
                          label: Text('Pagar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorProvider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, ColorProvider colorProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorProvider.primaryColor,
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _payInvoice(Map<String, dynamic> invoice) {
    // Implementar lógica de pagamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidade de pagamento em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalhes da Fatura',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Número', invoice['number'] as String, colorProvider),
                    _buildDetailRow('Período', invoice['month'] as String, colorProvider),
                    _buildDetailRow('Status', invoice['status'] as String, colorProvider),
                    _buildDetailRow('Vencimento', dateFormat.format(DateTime.parse(invoice['dueDate'] as String)), colorProvider),
                    if (invoice['paidDate'] != null)
                      _buildDetailRow('Data de Pagamento', dateFormat.format(DateTime.parse(invoice['paidDate'] as String)), colorProvider),
                    _buildDetailRow('Valor', currencyFormat.format(invoice['value'] as double), colorProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorProvider colorProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}


