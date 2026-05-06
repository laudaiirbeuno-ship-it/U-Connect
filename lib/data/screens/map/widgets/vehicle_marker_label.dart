import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';

class VehicleMarkerLabel extends StatelessWidget {
  final deviceItems vehicle;
  final bool isSelected;
  final VoidCallback? onTap;

  const VehicleMarkerLabel({
    Key? key,
    required this.vehicle,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    final name = vehicle.name ?? 'Veículo ${vehicle.id}';
    final plate = _getPlateNumber(vehicle);
    final speed = CoordinateUtils.toDouble(vehicle.speed) ?? 0.0;
    final ignitionStatus = _isIgnitionOn(vehicle);
    final isOffline = _isOffline(vehicle);
    
    // Determinar cor do status
    final statusColor = _getStatusColor(vehicle, ignitionStatus, isOffline);
    // Cor de fundo bem clara (light) baseada na cor da ignição
    final backgroundColor = _getLightStatusColor(statusColor);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduzido padding vertical
        constraints: BoxConstraints(
          maxWidth: 200, // Largura máxima reduzida
          maxHeight: 65, // Altura máxima reduzida (era 80)
        ),
        decoration: BoxDecoration(
          color: backgroundColor, // Fundo bem claro baseado na cor da ignição
          borderRadius: BorderRadius.circular(20), // Mais redondo (era 14)
          border: Border.all(
            color: statusColor.withOpacity(0.5), // Borda com cor do status semi-transparente
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Centralizado
          children: [
            // Nome do veículo
            Text(
              name,
              style: TextStyle(
                fontSize: 11, // Reduzido de 12 para 11
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Preto fosco
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 3), // Reduzido de 4 para 3
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Placa com ícone
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Reduzido
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Reduzido
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      size: 10, // Reduzido de 12 para 10
                      color: colorProvider.primaryColor,
                    ),
                    SizedBox(width: 3), // Reduzido
                    Text(
                      plate,
                      style: TextStyle(
                        fontSize: 9, // Reduzido de 10 para 9
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4), // Reduzido de 6 para 4
              // Velocidade com ícone
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Reduzido
                decoration: BoxDecoration(
                  color: _getSpeedColor(speed).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Reduzido
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed,
                      size: 10, // Reduzido
                      color: _getSpeedColor(speed),
                    ),
                    SizedBox(width: 3), // Reduzido
                    Text(
                      '${speed.toStringAsFixed(0)} km/h',
                      style: TextStyle(
                        fontSize: 9, // Reduzido
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4), // Reduzido
              // Status de ignição com ícone
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2), // Reduzido
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6), // Reduzido
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ignitionStatus ? Icons.power : Icons.power_off,
                      size: 10, // Reduzido
                      color: statusColor,
                    ),
                    SizedBox(width: 3), // Reduzido
                    Text(
                      ignitionStatus ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 9, // Reduzido
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Verificar status de ignição
  bool _isIgnitionOn(deviceItems vehicle) {
    final String xmlData = vehicle.deviceData?.traccar?.other ?? '';
    return xmlData.contains("<ignition>true</ignition>");
  }

  // Verificar se veículo está offline
  bool _isOffline(deviceItems vehicle) {
    final online = vehicle.online?.toString().toLowerCase() ?? '';
    return online == 'nack' || online == 'offline' || online == 'inactive';
  }

  // Obter cor do status do veículo
  Color _getStatusColor(deviceItems vehicle, bool ignitionOn, bool isOffline) {
    if (isOffline) {
      return Colors.red; // Offline = vermelho
    } else if (ignitionOn) {
      return Colors.green; // Ignition ON = verde
    } else {
      return Colors.orange; // Ignition OFF mas online = laranja
    }
  }

  // Obter cor de fundo mais forte baseada na cor do status
  Color _getLightStatusColor(Color statusColor) {
    if (statusColor == Colors.red) {
      return Color(0xFFFFCDD2); // Vermelho mais forte (era 0xFFFFEBEE)
    } else if (statusColor == Colors.green) {
      return Color(0xFFC8E6C9); // Verde mais forte (era 0xFFE8F5E9)
    } else if (statusColor == Colors.orange) {
      return Color(0xFFFFE0B2); // Laranja mais forte (era 0xFFFFF3E0)
    } else {
      return Color(0xFFE0E0E0); // Cinza mais forte (era 0xFFF5F5F5)
    }
  }

  Color _getSpeedColor(double speed) {
    if (speed == 0) {
      return Colors.grey;
    } else if (speed < 30) {
      return Colors.green;
    } else if (speed < 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getPlateNumber(deviceItems vehicle) {
    if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty) {
      return vehicle.plateNumber!;
    } else if (vehicle.deviceData?.plateNumber != null &&
        vehicle.deviceData!.plateNumber!.isNotEmpty) {
      return vehicle.deviceData!.plateNumber!;
    } else if (vehicle.deviceData?.registrationNumber != null &&
        vehicle.deviceData!.registrationNumber!.isNotEmpty) {
      return vehicle.deviceData!.registrationNumber!;
    } else if (vehicle.name != null && vehicle.name!.contains(' ')) {
      final nameParts = vehicle.name!.split(' ');
      if (nameParts.length >= 2) {
        final possiblePlate = nameParts[1];
        if (RegExp(r'[A-Za-z].*\d|\d.*[A-Za-z]').hasMatch(possiblePlate)) {
          return possiblePlate;
        }
      }
    }
    return 'Sem placa';
  }
}
