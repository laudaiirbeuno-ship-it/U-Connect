import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class KmCardsWidget extends StatelessWidget {
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
      padding: EdgeInsets.all(16),
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
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              children: [
                Icon(
                  Icons.straighten,
                  color: colorProvider.primaryColor,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Quilometragem Percorrida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
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
}

class _ChartData {
  final String category;
  final double value;
  final Color color;

  _ChartData(this.category, this.value, this.color);
}



