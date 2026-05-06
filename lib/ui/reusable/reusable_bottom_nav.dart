import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/listscreen.dart';
import 'package:uconnect/data/screens/map/views/main_map_screen.dart';
import 'package:uconnect/data/screens/notificationscreen.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';
import 'package:uconnect/data/screens/AlertList.dart';

/// Widget reutilizável de bottom navigation para páginas individuais
class ReusableBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const ReusableBottomNav({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
  }) : super(key: key);

  void _navigateToPage(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    Widget? page;
    switch (index) {
      case 0:
        page = listscreen();
        break;
      case 1:
        page = MainMapScreen();
        break;
      case 2:
        page = NotificationsPage();
        break;
      case 3:
        page = AlertListPage();
        break;
      case 4:
        page = VideoTelemetryScreen();
        break;
    }

    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);

    return Container(
      height: 50.0, // Altura reduzida em 10-15% (de 58 para 50)
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
          child: Container(
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.15), // Glassmorphism - cor primária no fundo
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.directions_car_filled,
                  label: "Veículos",
                  index: 0,
                  isActive: currentIndex == 0,
                  colorProvider: colorProvider,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.map_outlined,
                  label: "Mapa",
                  index: 1,
                  isActive: currentIndex == 1,
                  colorProvider: colorProvider,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_customize_outlined,
                  label: "Painel",
                  index: 2,
                  isActive: currentIndex == 2,
                  colorProvider: colorProvider,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.videocam, // Botão de câmera
                  label: "Câmera",
                  index: 4,
                  isActive: currentIndex == 4,
                  colorProvider: colorProvider,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  label: "Alertas",
                  index: 3,
                  isActive: currentIndex == 3,
                  colorProvider: colorProvider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required ColorProvider colorProvider,
  }) {
    return GestureDetector(
      onTap: () => _navigateToPage(context, index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.25) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22, // Ícones menores para caber melhor
              color: isActive
                  ? Colors.white // Branco para ativo
                  : Colors.white.withOpacity(0.7), // Branco com opacidade para inativo
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? Colors.white // Branco para ativo
                    : Colors.white.withOpacity(0.7), // Branco com opacidade para inativo
              ),
            ),
          ],
        ),
      ),
    );
  }
}


