import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/history_advanced/controllers/history_advanced_controller.dart';
import 'package:shimmer/shimmer.dart';

class SummaryCardsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryAdvancedController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, size: 20, color: colorProvider.primaryColor),
              SizedBox(width: 6),
              Text(
                'Resumo do Período',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildSummaryCard(
                context: context,
                index: index,
                controller: controller,
                colorProvider: colorProvider,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required int index,
    required HistoryAdvancedController controller,
    required ColorProvider colorProvider,
  }) {
    if (controller.isLoading) {
      return _buildShimmerCard();
    }

    String title;
    IconData icon;
    int value;

    switch (index) {
      case 0:
        title = 'Total de Eventos';
        icon = Icons.event;
        value = controller.totalEvents;
        break;
      case 1:
        title = 'Movimentos';
        icon = Icons.directions_car;
        value = controller.totalMovements;
        break;
      case 2:
        title = 'Paradas';
        icon = Icons.stop_circle;
        value = controller.totalStops;
        break;
      case 3:
        title = 'Alertas Críticos';
        icon = Icons.warning;
        value = controller.criticalAlerts;
        break;
      default:
        title = '';
        icon = Icons.info;
        value = 0;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22), // mais arredondado
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07), // Leve
              blurRadius: 14, // sombra mais suave
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: colorProvider.primaryColor,
                    size: 22,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12, // menor
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 15, // aumentado em 2 pontos
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A), // Preto fosco
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}





