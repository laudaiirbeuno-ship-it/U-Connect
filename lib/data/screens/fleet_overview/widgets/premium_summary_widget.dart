import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';

class PremiumSummaryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard, color: colorProvider.primaryColor, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo da Frota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '${controller.totalVehicles} veículos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Grid de métricas - 2 cards por linha
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total de Veículos',
                      controller.totalVehicles.toString(),
                      Icons.directions_car,
                      colorProvider.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Ignição Ligada',
                      controller.ignitionOnCount.toString(),
                      Icons.power,
                      colorProvider.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Ignição Ligada e Parado',
                      controller.ignitionOnStoppedCount.toString(),
                      Icons.power_off,
                      colorProvider.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Parados',
                      controller.stoppedCount.toString(),
                      Icons.stop_circle,
                      colorProvider.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Offline',
                      controller.offlineCount.toString(),
                      Icons.signal_wifi_off,
                      colorProvider.primaryColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Em Movimento',
                      controller.movingCount.toString(),
                      Icons.speed,
                      colorProvider.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricCard(String label, String value, IconData icon, Color iconColor) {
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
          Icon(icon, color: iconColor, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

