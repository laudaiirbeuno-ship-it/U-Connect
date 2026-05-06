import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';

/// Widget reutilizável da barra de navegação inferior FluidNavBar
/// para usar em páginas individuais
class ReusableFluidBottomNav extends StatelessWidget {
  final int currentIndex;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const ReusableFluidBottomNav({
    Key? key,
    this.currentIndex = 2, // Dashboard por padrão (índice 2)
    this.scaffoldKey,
  }) : super(key: key);

  void _handleNavigationChange(BuildContext context, int index) {
    // Mapeamento dos índices:
    // 0: Veículos -> listscreen (via BottomNavigation_01)
    // 1: Mapa Principal -> MainMapScreen (via BottomNavigation_01)
    // 2: Dashboard -> FleetOverviewScreen (via BottomNavigation_01)
    // 3: Video Telemetria -> VideoTelemetryScreen
    // 4: Hambúrguer -> abrir drawer

    if (index == 4) {
      // Menu hambúrguer - abrir drawer
      if (scaffoldKey?.currentState != null) {
        scaffoldKey!.currentState!.openDrawer();
      } else {
        // Se não tiver scaffoldKey, tentar encontrar o BottomNavigation_01
        final bottomNavState = BottomNavigation_01.of(context);
        bottomNavState?.openDrawer();
      }
    } else if (index == 3) {
      // Video Telemetria - navegar para a página
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VideoTelemetryScreen()),
      );
    } else {
      // Navegar para as páginas principais via BottomNavigation_01
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavigation_01(initialIndex: index),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: true);

    return Container(
      height: 80, // Altura aumentada do bottom navigation
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorProvider.primaryColor, // Cor primária no fundo
      ),
      child: FluidNavBar(
      icons: [
        FluidNavBarIcon(
          icon: Icons.directions_car,
          backgroundColor: colorProvider.primaryColor, // Cor primária no fundo
          extras: {"label": "Veículos", "index": 0},
        ),
        FluidNavBarIcon(
          icon: Icons.map,
          backgroundColor: colorProvider.primaryColor, // Cor primária no fundo
          extras: {"label": "Mapa", "index": 1},
        ),
        FluidNavBarIcon(
          icon: Icons.dashboard_outlined,
          backgroundColor: colorProvider.primaryColor, // Cor primária no fundo
          extras: {"label": "Dashboard", "index": 2},
        ),
        FluidNavBarIcon(
          icon: Icons.videocam,
          backgroundColor: colorProvider.primaryColor, // Cor primária no fundo
          extras: {"label": "Câmera", "index": 3},
        ),
        FluidNavBarIcon(
          icon: Icons.menu,
          backgroundColor: colorProvider.primaryColor, // Cor primária no fundo
          extras: {"label": "Menu", "index": 4},
        ),
      ],
      onChange: (index) => _handleNavigationChange(context, index),
      style: FluidNavBarStyle(
        barBackgroundColor: colorProvider.primaryColor, // Cor primária no fundo
        iconBackgroundColor: colorProvider.primaryColor, // Cor primária no fundo
        iconSelectedForegroundColor: Colors.white, // Ícones ativos: branco
        iconUnselectedForegroundColor: Colors.white.withOpacity(0.7), // Ícones inativos: branco com opacidade
      ),
      scaleFactor: 1.0,
      defaultIndex: currentIndex >= 0 && currentIndex < 5 ? currentIndex : -1,
      itemBuilder: (icon, item) => Semantics(
        label: icon.extras!["label"],
        child: item,
      ),
      ),
    );
  }
}




