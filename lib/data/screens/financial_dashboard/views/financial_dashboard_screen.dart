import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:uconnect/data/model/charge.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class FinancialDashboardScreen extends StatefulWidget {
  @override
  _FinancialDashboardScreenState createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  ChargesStatistics? _statistics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await gpsapis.getFinancialChargesStatistics();
      
      if (response != null && response['status'] == 1 && response['data'] != null) {
        setState(() {
          _statistics = ChargesStatistics.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response?['message'] ?? TranslationHelper.translateSync(context, 'Erro ao carregar estatísticas', 'Error loading statistics');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar estatísticas: $e');
      setState(() {
        _error = TranslationHelper.translateSync(context, 'Erro ao carregar estatísticas', 'Error loading statistics');
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
        title: TranslationHelper.translateSync(context, 'Dashboard Financeiro', 'Financial Dashboard'),
        icon: Icons.dashboard,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              if (_isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                  ),
                );
              }

              if (_error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadStatistics,
                        icon: Icon(Icons.refresh),
                        label: Text(TranslationHelper.translateSync(context, 'Tentar novamente', 'Try again')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (_statistics == null) {
                return Center(
                  child: Text(
                    TranslationHelper.translateSync(context, 'Nenhum dado disponível', 'No data available'),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadStatistics,
                color: colorProvider.primaryColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cards de resumo
                      _buildSummaryCards(colorProvider),
                      
                      SizedBox(height: 24),
                      
                      // Gráfico de status
                      _buildStatusChart(colorProvider),
                      
                      SizedBox(height: 24),
                      
                      // Gráfico de valores
                      _buildValuesChart(colorProvider),
                      
                      SizedBox(height: 24),
                      
                      // Detalhes por status
                      _buildStatusDetails(colorProvider),
                      
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ColorProvider colorProvider) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                TranslationHelper.translateSync(context, 'Total', 'Total'),
                '${_statistics!.total}',
                currencyFormat.format(_statistics!.values.total),
                Icons.attach_money,
                colorProvider.primaryColor,
                colorProvider,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                TranslationHelper.translateSync(context, 'Pendentes', 'Pending'),
                '${_statistics!.pending}',
                currencyFormat.format(_statistics!.values.pending),
                Icons.pending,
                colorProvider.primaryColor,
                colorProvider,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                TranslationHelper.translateSync(context, 'Pagas', 'Paid'),
                '${_statistics!.paid}',
                currencyFormat.format(_statistics!.values.paid),
                Icons.check_circle,
                colorProvider.primaryColor,
                colorProvider,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                TranslationHelper.translateSync(context, 'Vencidas', 'Overdue'),
                '${_statistics!.overdue}',
                currencyFormat.format(_statistics!.values.overdue),
                Icons.warning,
                colorProvider.primaryColor,
                colorProvider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, String value, IconData icon, Color color, ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(ColorProvider colorProvider) {
    final data = [
      _ChartData(
        TranslationHelper.translateSync(context, 'Pendentes', 'Pending'),
        _statistics!.pending.toDouble(),
        Colors.orange,
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Pagas', 'Paid'),
        _statistics!.paid.toDouble(),
        Colors.green,
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Vencidas', 'Overdue'),
        _statistics!.overdue.toDouble(),
        Colors.red,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Distribuição por Status', 'Status Distribution'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <CartesianSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData data, _) => data.label,
                  yValueMapper: (_ChartData data, _) => data.value,
                  pointColorMapper: (_ChartData data, _) => data.color,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesChart(ColorProvider colorProvider) {
    final data = [
      _ChartData(
        TranslationHelper.translateSync(context, 'Pendentes', 'Pending'),
        _statistics!.values.pending,
        Colors.orange,
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Pagas', 'Paid'),
        _statistics!.values.paid,
        Colors.green,
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Vencidas', 'Overdue'),
        _statistics!.values.overdue,
        Colors.red,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Valores por Status', 'Values by Status'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <CartesianSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData data, _) => data.label,
                  yValueMapper: (_ChartData data, _) => data.value,
                  pointColorMapper: (_ChartData data, _) => data.color,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetails(ColorProvider colorProvider) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Detalhes', 'Details'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            TranslationHelper.translateSync(context, 'Total de Cobranças', 'Total Charges'),
            '${_statistics!.total}',
            currencyFormat.format(_statistics!.values.total),
            colorProvider,
          ),
          Divider(),
          _buildDetailRow(
            TranslationHelper.translateSync(context, 'Pendentes', 'Pending'),
            '${_statistics!.pending}',
            currencyFormat.format(_statistics!.values.pending),
            colorProvider,
            Colors.orange,
          ),
          Divider(),
          _buildDetailRow(
            TranslationHelper.translateSync(context, 'Pagas', 'Paid'),
            '${_statistics!.paid}',
            currencyFormat.format(_statistics!.values.paid),
            colorProvider,
            Colors.green,
          ),
          Divider(),
          _buildDetailRow(
            TranslationHelper.translateSync(context, 'Vencidas', 'Overdue'),
            '${_statistics!.overdue}',
            currencyFormat.format(_statistics!.values.overdue),
            colorProvider,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String count, String value, ColorProvider colorProvider, [Color? color]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? colorProvider.primaryColor,
            ),
          ),
          SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
