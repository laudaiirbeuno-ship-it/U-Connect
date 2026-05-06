import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class PremiumKmSectionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    final kmData = [
      _ChartData('Hoje', controller.kmToday, colorProvider.primaryColor),
      _ChartData('Semana', controller.kmWeek, colorProvider.primaryColor.withOpacity(0.8)),
      _ChartData('Mês', controller.kmMonth, colorProvider.primaryColor.withOpacity(0.6)),
      _ChartData('Total', controller.kmTotal, colorProvider.primaryColor.withOpacity(0.4)),
    ];
    
    final maxValue = kmData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(Icons.straighten, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'Quilometragem',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Cards de resumo
          Row(
            children: [
              Expanded(
                child: _buildKmCard(
                  'Hoje',
                  controller.kmToday,
                  'km',
                  Icons.today,
                  colorProvider.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildKmCard(
                  'Semana',
                  controller.kmWeek,
                  'km',
                  Icons.date_range,
                  colorProvider.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKmCard(
                  'Mês',
                  controller.kmMonth,
                  'km',
                  Icons.calendar_month,
                  colorProvider.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildKmCard(
                  'Total',
                  controller.kmTotal,
                  'km',
                  Icons.all_inclusive,
                  colorProvider.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Gráfico
          Container(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: maxValue > 0 ? maxValue * 1.2 : 100,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
                numberFormat: NumberFormat.compact(locale: 'pt_BR'),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: kmData,
                  xValueMapper: (_ChartData data, _) => data.category,
                  yValueMapper: (_ChartData data, _) => data.value,
                  pointColorMapper: (_ChartData data, _) => data.color,
                  borderRadius: BorderRadius.circular(8),
                  width: 0.6,
                  spacing: 0.2,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKmCard(String label, double value, String unit, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
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
              Icon(icon, color: color, size: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 20,
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
  final String category;
  final double value;
  final Color color;

  _ChartData(this.category, this.value, this.color);
}





































