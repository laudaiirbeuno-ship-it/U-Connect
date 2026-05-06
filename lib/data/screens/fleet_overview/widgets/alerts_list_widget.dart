import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/data/screens/map/views/main_map_screen.dart';

class AlertsListWidget extends StatelessWidget {
  final bool isCritical;

  const AlertsListWidget({required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FleetOverviewController>(context);
    final colorProvider = Provider.of<ColorProvider>(context);
    
    final alerts = isCritical ? controller.criticalAlerts : controller.recentAlerts;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(
                  isCritical ? Icons.warning : Icons.notifications_active,
                  color: isCritical ? Colors.red : colorProvider.primaryColor,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  isCritical ? 'Alertas Críticos' : 'Alertas Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          alerts.isEmpty
              ? Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isCritical 
                          ? 'Nenhum alerta crítico no momento'
                          : 'Nenhum alerta recente',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: alerts.take(10).map((alert) => _AlertCard(
                    alert: alert,
                    isCritical: isCritical,
                    colorProvider: colorProvider,
                    controller: controller,
                  )).toList(),
                ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final EventsData alert;
  final bool isCritical;
  final ColorProvider colorProvider;
  final FleetOverviewController controller;

  const _AlertCard({
    required this.alert,
    required this.isCritical,
    required this.colorProvider,
    required this.controller,
  });

  @override
  _AlertCardState createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _address;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _loadAddress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    if (widget.alert.latitude != null && widget.alert.longitude != null) {
      final address = await widget.controller.getAddress(
        widget.alert.latitude!.toDouble(),
        widget.alert.longitude!.toDouble(),
      );
      if (mounted) {
        setState(() {
          _address = address;
        });
      }
    }
  }

  IconData _getAlertIcon(String? type) {
    final typeLower = type?.toLowerCase() ?? '';
    if (typeLower.contains('overspeed')) return Icons.speed;
    if (typeLower.contains('geofence')) return Icons.fence;
    if (typeLower.contains('panic')) return Icons.warning;
    if (typeLower.contains('disconnect')) return Icons.signal_wifi_off;
    return Icons.notifications;
  }

  Color _getAlertColor(String? type) {
    if (widget.isCritical) return Colors.red;
    final typeLower = type?.toLowerCase() ?? '';
    if (typeLower.contains('overspeed') || typeLower.contains('panic')) {
      return Colors.red;
    }
    return widget.colorProvider.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: widget.isCritical
                  ? Border(
                      left: BorderSide(
                        color: Colors.red,
                        width: 4,
                      ),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: widget.isCritical
                  ? () {
                      // Navegar para o mapa
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainMapScreen(),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getAlertColor(widget.alert.type)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getAlertIcon(widget.alert.type),
                        color: _getAlertColor(widget.alert.type),
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.alert.name ?? widget.alert.message ?? 'Alerta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _address ?? 'Carregando endereço...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDateTime(widget.alert.time ?? widget.alert.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isCritical)
                      IconButton(
                        icon: Icon(Icons.map, color: widget.colorProvider.primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainMapScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Data não disponível';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
}


