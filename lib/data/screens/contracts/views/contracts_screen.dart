import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class ContractsScreen extends StatefulWidget {
  @override
  _ContractsScreenState createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _contracts = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }


  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
    });

    // Carregar contratos da API
    // TODO: Implementar chamada à API quando disponível
    if (mounted) {
      setState(() {
        _contracts = [];
        // Em produção, isso viria da API:
        // final response = await gpsapis.getContracts(...);
        // if (response != null) {
        //   _contracts = response;
        // }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Meus Contratos', 'My Contracts'),
        icon: Icons.description,
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

              if (_contracts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translateSync(context, 'Nenhum contrato encontrado', 'No contracts found'),
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
                onRefresh: _loadContracts,
                color: colorProvider.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _contracts.length,
                  itemBuilder: (context, index) {
                    final contract = _contracts[index];
                    return _buildContractCard(contract, colorProvider);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    final status = contract['status'] as String;
    Color statusColor = Colors.green;
    if (status.toLowerCase().contains('expirado') || status.toLowerCase().contains('expired')) {
      statusColor = Colors.red;
    } else if (status.toLowerCase().contains('pendente') || status.toLowerCase().contains('pending')) {
      statusColor = Colors.orange;
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
            _showContractDetails(contract, colorProvider);
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
                            TranslationHelper.translateSync(context, contract['title'] as String, contract['title'] as String),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            TranslationHelper.translateSync(context, contract['type'] as String, contract['type'] as String),
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
                      child: Text(
                        TranslationHelper.translateSync(context, contract['status'] as String, contract['status'] as String),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
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
                      TranslationHelper.translateSync(context, 'Início', 'Start'),
                      dateFormat.format(DateTime.parse(contract['startDate'] as String)),
                      colorProvider,
                    ),
                    _buildInfoItem(
                      Icons.event,
                      TranslationHelper.translateSync(context, 'Término', 'End'),
                      dateFormat.format(DateTime.parse(contract['endDate'] as String)),
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
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: colorProvider.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        TranslationHelper.translateSync(context, 'Valor: ', 'Amount: '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        currencyFormat.format(contract['value'] as double),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor,
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

  void _showContractDetails(Map<String, dynamic> contract, ColorProvider colorProvider) {
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
                    TranslationHelper.translateSync(context, 'Detalhes do Contrato', 'Contract Details'),
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
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Título', 'Title'), TranslationHelper.translateSync(context, contract['title'] as String, contract['title'] as String), colorProvider),
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Tipo', 'Type'), TranslationHelper.translateSync(context, contract['type'] as String, contract['type'] as String), colorProvider),
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Status', 'Status'), TranslationHelper.translateSync(context, contract['status'] as String, contract['status'] as String), colorProvider),
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Data de Início', 'Start Date'), dateFormat.format(DateTime.parse(contract['startDate'] as String)), colorProvider),
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Data de Término', 'End Date'), dateFormat.format(DateTime.parse(contract['endDate'] as String)), colorProvider),
                    _buildDetailRow(TranslationHelper.translateSync(context, 'Valor', 'Amount'), currencyFormat.format(contract['value'] as double), colorProvider),
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

