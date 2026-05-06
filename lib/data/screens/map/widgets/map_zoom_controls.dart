import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/provider/color_provider.dart';

class MapZoomControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final mapController = context.watch<MapController>();

    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height / 2 - 80, // Puxado um pouco para cima
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildZoomButton(
            context: context,
            icon: Icons.add,
            onTap: () {
              mapController.zoomIn();
            },
            colorProvider: colorProvider,
          ),
          SizedBox(height: 12), // Maior distância entre botões
          _buildZoomButton(
            context: context,
            icon: Icons.remove,
            onTap: () {
              mapController.zoomOut();
            },
            colorProvider: colorProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required ColorProvider colorProvider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorProvider.primaryColor, // Cor principal como fundo
            shape: BoxShape.circle, // Circular
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Sombra leve premium
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white, // Ícone branco
            size: 22,
          ),
        ),
      ),
    );
  }
}


