import 'package:flutter/material.dart';
// import 'package:flutter_google_street_view/flutter_google_street_view.dart'; // Temporarily disabled due to Dart 3.0 compatibility issues
import 'package:provider/provider.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';

class VehicleLabelExpanded extends StatefulWidget {
  final deviceItems vehicle;
  final bool isSelected;
  final VoidCallback onClose;

  const VehicleLabelExpanded({
    Key? key,
    required this.vehicle,
    this.isSelected = false,
    required this.onClose,
  }) : super(key: key);

  @override
  _VehicleLabelExpandedState createState() => _VehicleLabelExpandedState();
}

class _VehicleLabelExpandedState extends State<VehicleLabelExpanded> {
  bool _isStreetViewLoading = true;

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    final name = widget.vehicle.name ?? 'Veículo ${widget.vehicle.id}';
    final plate = _getPlateNumber(widget.vehicle);
    final speed = CoordinateUtils.toDouble(widget.vehicle.speed) ?? 0.0;
    final ignitionStatus = _isIgnitionOn(widget.vehicle);
    final isOffline = _isOffline(widget.vehicle);
    final address = widget.vehicle.address ?? 'Endereço não disponível';
    final lastUpdate = _getLastUpdate(widget.vehicle);
    final distance = _getDistance(widget.vehicle);
    final movement = _getMovement(widget.vehicle);
    
    // Determinar cor do status
    final statusColor = _getStatusColor(widget.vehicle, ignitionStatus, isOffline);
    final backgroundColor = _getLightStatusColor(statusColor);
    
    // Coordenadas para Street View
    final lat = widget.vehicle.lat;
    final lng = widget.vehicle.lng;
    final hasValidCoordinates = lat != null && lng != null && lat != 0 && lng != 0;

    return Container(
      width: 380, // Aumentado de 320 para 380
      constraints: BoxConstraints(
        maxHeight: 500,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho com informações principais
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.confirmation_number, size: 14, color: colorProvider.primaryColor),
                              SizedBox(width: 4),
                              Text(
                                plate,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      icon: Icons.speed,
                      label: '${speed.toStringAsFixed(0)} km/h',
                      color: _getSpeedColor(speed),
                    ),
                    _buildInfoChip(
                      icon: ignitionStatus ? Icons.power : Icons.power_off,
                      label: ignitionStatus ? 'ON' : 'OFF',
                      color: statusColor,
                    ),
                    _buildInfoChip(
                      icon: Icons.directions_car,
                      label: movement,
                      color: movement == 'Em Movimento' ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Conteúdo expandido
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Informações detalhadas
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.location_on, 'Endereço', address),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.access_time, 'Última Atualização', lastUpdate),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.straighten, 'Distância Total', distance),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.sim_card, 'IMEI', _getImei(widget.vehicle)),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.devices, 'Modelo', _getDeviceModel(widget.vehicle)),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.settings_ethernet, 'Protocolo', _getProtocol(widget.vehicle)),
                      ],
                    ),
                  ),
                  
                  // Street View - Temporarily disabled due to Dart 3.0 compatibility issues
                  if (hasValidCoordinates)
                    Container(
                      height: 200,
                      margin: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.streetview, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Street View temporariamente indisponível',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      margin: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Coordenadas não disponíveis',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isIgnitionOn(deviceItems vehicle) {
    final String xmlData = vehicle.deviceData?.traccar?.other ?? '';
    return xmlData.contains("<ignition>true</ignition>");
  }

  bool _isOffline(deviceItems vehicle) {
    final online = vehicle.online?.toString().toLowerCase() ?? '';
    return online == 'nack' || online == 'offline' || online == 'inactive';
  }

  Color _getStatusColor(deviceItems vehicle, bool ignitionOn, bool isOffline) {
    if (isOffline) {
      return Colors.red;
    } else if (ignitionOn) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  Color _getLightStatusColor(Color statusColor) {
    if (statusColor == Colors.red) {
      return Color(0xFFFFCDD2);
    } else if (statusColor == Colors.green) {
      return Color(0xFFC8E6C9);
    } else if (statusColor == Colors.orange) {
      return Color(0xFFFFE0B2);
    } else {
      return Color(0xFFE0E0E0);
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

  String _getLastUpdate(deviceItems vehicle) {
    if (vehicle.time != null && vehicle.time!.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(vehicle.time!);
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        if (difference.inMinutes < 1) {
          return 'Agora';
        } else if (difference.inMinutes < 60) {
          return '${difference.inMinutes} min atrás';
        } else if (difference.inHours < 24) {
          return '${difference.inHours} h atrás';
        } else {
          return '${difference.inDays} dias atrás';
        }
      } catch (e) {
        return vehicle.time!;
      }
    }
    return 'N/A';
  }

  String _getDistance(deviceItems vehicle) {
    if (vehicle.totalDistance != null) {
      final distance = vehicle.totalDistance!.toDouble();
      if (distance >= 1000) {
        return '${(distance / 1000).toStringAsFixed(1)} km';
      } else {
        return '${distance.toStringAsFixed(0)} m';
      }
    }
    return '0 km';
  }

  String _getMovement(deviceItems vehicle) {
    final speed = CoordinateUtils.toDouble(vehicle.speed) ?? 0.0;
    if (speed > 0) {
      return 'Em Movimento';
    }
    return 'Parado';
  }

  String _getImei(deviceItems vehicle) {
    // Tentar obter IMEI de deviceData primeiro
    if (vehicle.deviceData?.imei != null && vehicle.deviceData!.imei!.isNotEmpty) {
      return vehicle.deviceData!.imei!;
    }
    return 'N/A';
  }

  String _getDeviceModel(deviceItems vehicle) {
    // Tentar obter modelo de deviceData primeiro
    if (vehicle.deviceData?.deviceModel != null && vehicle.deviceData!.deviceModel!.isNotEmpty) {
      return vehicle.deviceData!.deviceModel!;
    }
    return 'N/A';
  }

  String _getProtocol(deviceItems vehicle) {
    // Protocolo está diretamente em deviceItems
    if (vehicle.protocol != null && vehicle.protocol!.isNotEmpty) {
      return vehicle.protocol!;
    }
    return 'N/A';
  }
}

