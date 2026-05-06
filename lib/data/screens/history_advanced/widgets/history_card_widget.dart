import 'package:flutter/material.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/history_advanced/controllers/history_advanced_controller.dart';
import 'package:uconnect/data/screens/map/views/main_map_screen.dart';
import 'package:intl/intl.dart';

class HistoryCardWidget extends StatefulWidget {
  final HistoryEventItem event;
  final ColorProvider colorProvider;
  final HistoryAdvancedController controller;

  const HistoryCardWidget({
    Key? key,
    required this.event,
    required this.colorProvider,
    required this.controller,
  }) : super(key: key);

  @override
  _HistoryCardWidgetState createState() => _HistoryCardWidgetState();
}

class _HistoryCardWidgetState extends State<HistoryCardWidget> {
  String? _address;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    double? lat, lng;

    if (widget.event.item != null) {
      lat = widget.event.item!.latitude ?? widget.event.item!.lat;
      lng = widget.event.item!.longitude ?? widget.event.item!.lng;
    } else if (widget.event.event != null) {
      lat = widget.event.event!.latitude;
      lng = widget.event.event!.longitude;
    }

    if (lat != null && lng != null) {
      setState(() {
        _isLoadingAddress = true;
      });

      final address = await widget.controller.getAddress(lat, lng);
      setState(() {
        _address = address;
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = widget.controller.getEventColor(widget.event, widget.colorProvider);
    final eventIcon = widget.controller.getEventIcon(widget.event);
    final eventType = widget.controller.getEventType(widget.event);

    String title = _getEventTitle();
    String? speed;
    String? battery;
    String? satellites;
    double? lat, lng;

    if (widget.event.item != null) {
      speed = widget.event.item!.speed?.toString();
      lat = widget.event.item!.latitude ?? widget.event.item!.lat;
      lng = widget.event.item!.longitude ?? widget.event.item!.lng;
      // Extrair bateria e satélites de otherArr se disponível
      if (widget.event.item!.otherArr != null) {
        for (var item in widget.event.item!.otherArr!) {
          if (item.toString().contains('batterylevel')) {
            battery = item.toString().split(':')[1].trim();
          }
          if (item.toString().contains('sat:')) {
            satellites = item.toString().split(':')[1].trim();
          }
        }
      }
    } else if (widget.event.event != null) {
      speed = widget.event.event!.speed?.toString();
      lat = widget.event.event!.latitude;
      lng = widget.event.event!.longitude;
    }

    DateTime? eventDateTime;
    try {
      eventDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(widget.event.time);
    } catch (e) {
      // Ignorar erro de parsing
    }

    return GestureDetector(
      onTap: () {
        // Abrir detalhes do evento
        _showEventDetails(context);
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: eventType == 'overspeed' || eventType == 'panic'
              ? Border.all(color: Colors.red, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: eventColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: eventColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      eventIcon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A), // Preto fosco
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (eventDateTime != null)
                          Text(
                            DateFormat('HH:mm:ss').format(eventDateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildBadge(eventType, eventColor),
                ],
              ),
            ),
            // Corpo
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingAddress)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.colorProvider.secondaryColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Carregando endereço...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_address != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: widget.colorProvider.primaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (speed != null)
                    _buildInfoRow(
                      icon: Icons.speed,
                      label: 'Velocidade',
                      value: '$speed km/h',
                      colorProvider: widget.colorProvider,
                    ),
                  if (battery != null)
                    _buildInfoRow(
                      icon: Icons.battery_charging_full,
                      label: 'Bateria',
                      value: '$battery%',
                      colorProvider: widget.colorProvider,
                    ),
                  if (satellites != null)
                    _buildInfoRow(
                      icon: Icons.satellite,
                      label: 'Satélites',
                      value: satellites,
                      colorProvider: widget.colorProvider,
                    ),
                  if (lat != null && lng != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map,
                            size: 16,
                            color: widget.colorProvider.secondaryColor,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MainMapScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.map,
                              size: 16,
                              color: widget.colorProvider.primaryColor,
                            ),
                            label: Text(
                              'Ver no mapa',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.colorProvider.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Rodapé
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (eventDateTime != null)
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(eventDateTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (widget.event.item?.id != null)
                    Text(
                      'ID: ${widget.event.item!.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String eventType, Color color) {
    String label;
    Color badgeColor;

    switch (eventType) {
      case 'overspeed':
      case 'panic':
        label = 'Crítico';
        badgeColor = Colors.red;
        break;
      case 'geofence':
      case 'disconnection':
        label = 'Alerta';
        badgeColor = Colors.orange;
        break;
      case 'movement':
        label = 'Movimento';
        badgeColor = widget.colorProvider.secondaryColor;
        break;
      case 'stop':
        label = 'Parada';
        badgeColor = widget.colorProvider.secondaryColor;
        break;
      default:
        label = 'Evento';
        badgeColor = widget.colorProvider.secondaryColor;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorProvider colorProvider,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorProvider.secondaryColor,
          ),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A1A), // Preto fosco
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getEventTitle() {
    if (widget.event.event != null) {
      return widget.event.event!.name ?? widget.event.event!.type ?? 'Evento';
    }
    if (widget.event.item != null) {
      if (widget.event.item!.speed != null && widget.event.item!.speed! > 0) {
        return 'Movimento Iniciado';
      }
      return 'Veículo Parado';
    }
    return 'Evento';
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalhes do Evento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.colorProvider.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Text('Detalhes completos do evento...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

