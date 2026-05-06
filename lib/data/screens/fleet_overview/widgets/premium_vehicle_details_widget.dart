import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';

class PremiumVehicleDetailsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.vehicleDetailedData.isEmpty) {
      return SizedBox.shrink();
    }
    
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
              Icon(Icons.directions_car, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'Detalhes por Veículo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.vehicleDetailedData.length,
            itemBuilder: (context, index) {
              final data = controller.vehicleDetailedData[index];
              return _buildVehicleDetailCard(data, colorProvider);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildVehicleDetailCard(VehicleDetailedData data, ColorProvider colorProvider) {
    final vehicle = data.vehicle;
    final imageUrl = vehicle.image != null && vehicle.image!.isNotEmpty
        ? "https://web.unnicatelemetria.com.br/${vehicle.image}"
        : "https://web.unnicatelemetria.com.br/images/device_icons/rotating/1.png";
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: colorProvider.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.directions_car,
                  color: colorProvider.primaryColor,
                ),
              );
            },
          ),
        ),
        title: Text(
          vehicle.name ?? 'Veículo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Motorista: ${data.driverName}'),
            Text('IMEI: ${data.imei}'),
          ],
        ),
        children: [
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Velocidade Máxima', data.topSpeed, Icons.speed, Colors.red),
                SizedBox(height: 8),
                _buildDetailRow('Tempo em Movimento', data.moveDuration, Icons.directions_run, Colors.green),
                SizedBox(height: 8),
                _buildDetailRow('Tempo Parado', data.stopDuration, Icons.pause_circle, Colors.orange),
                SizedBox(height: 8),
                _buildDetailRow('Consumo de Combustível', data.fuelConsumption, Icons.local_gas_station, Colors.blue),
                SizedBox(height: 8),
                _buildDetailRow('Distância Total', data.distanceSum, Icons.straighten, Colors.purple),
                SizedBox(height: 8),
                _buildDetailRow('Ignição Ligou', data.ignitionOnCount.toString(), Icons.power_settings_new, Colors.green),
                SizedBox(height: 8),
                _buildDetailRow('Ignição Desligou', data.ignitionOffCount.toString(), Icons.power_off, Colors.red),
                SizedBox(height: 8),
                _buildDetailRow('Tempo Offline', data.offlineDuration, Icons.offline_bolt, Colors.grey),
                SizedBox(height: 8),
                _buildDetailRow('Itens no Histórico', data.historyItems.length.toString(), Icons.history, Colors.indigo),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 12),
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
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}





































