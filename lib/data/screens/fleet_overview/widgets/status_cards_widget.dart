import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatusCardsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    final statusData = [
      _ChartData('Online', controller.onlineCount, colorProvider.primaryColor),
      _ChartData('Offline', controller.offlineCount, Colors.red),
      _ChartData('Em Movimento', controller.movingCount, Colors.blue),
      _ChartData('Parados', controller.stoppedCount, Colors.orange),
    ];
    
    final maxValue = statusData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
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
                  Icons.directions_car,
                  color: colorProvider.primaryColor,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Status dos Veículos',
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
                maximum: maxValue > 0 ? maxValue.toDouble() + 2 : 5,
                interval: maxValue > 0 ? (maxValue / 5).ceil().toDouble() : 1,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: statusData,
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
                      fontSize: 12,
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
  final int value;
  final Color color;

  _ChartData(this.category, this.value, this.color);
}


