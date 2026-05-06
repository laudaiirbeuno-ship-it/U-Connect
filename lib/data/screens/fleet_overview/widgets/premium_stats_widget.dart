import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';

class PremiumStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
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
              Icon(Icons.analytics, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'Estatísticas Gerais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Grid de estatísticas - 2 cards por linha
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Velocidade Máxima',
                      '${controller.topSpeed.toStringAsFixed(0)} km/h',
                      Icons.speed,
                      colorProvider.primaryColor,
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Tempo em Movimento',
                      controller.moveDuration,
                      Icons.directions_run,
                      colorProvider.primaryColor,
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Tempo Parado',
                      controller.stopDuration,
                      Icons.pause_circle,
                      colorProvider.primaryColor,
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Tempo Offline',
                      controller.offlineDuration,
                      Icons.offline_bolt,
                      colorProvider.primaryColor,
                      context,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Ignição Ligou',
                      controller.ignitionOnEvents.toString(),
                      Icons.power_settings_new,
                      colorProvider.primaryColor,
                      context,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      'Ignição Desligou',
                      controller.ignitionOffEvents.toString(),
                      Icons.power_off,
                      colorProvider.primaryColor,
                      context,
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
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

