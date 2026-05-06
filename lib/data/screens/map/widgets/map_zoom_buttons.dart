import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/provider/color_provider.dart';

/// Botões de zoom do mapa - arquivo leve
class MapZoomButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final mapController = context.watch<MapController>();

    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height / 2 - 80,
      child: Column(
        children: [
          _ZoomButton(
            icon: Icons.add,
            onTap: () => mapController.zoomIn(),
            colorProvider: colorProvider,
          ),
          SizedBox(height: 12),
          _ZoomButton(
            icon: Icons.remove,
            onTap: () => mapController.zoomOut(),
            colorProvider: colorProvider,
          ),
        ],
      ),
    );
  }
}

/// Botão de zoom individual
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorProvider colorProvider;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.colorProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorProvider.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}



































