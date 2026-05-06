import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';

/// Widget reutilizável da barra de navegação inferior
/// para usar nas páginas do menu flutuante
/// Sempre navega para BottomNavigation_01 quando clicado
class FloatingMenuBottomNav extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final int defaultIndex;

  const FloatingMenuBottomNav({
    Key? key,
    this.scaffoldKey,
    this.defaultIndex = 2, // Dashboard selecionado por padrão
  }) : super(key: key);

  @override
  _FloatingMenuBottomNavState createState() => _FloatingMenuBottomNavState();
}

class _FloatingMenuBottomNavState extends State<FloatingMenuBottomNav> {
  int _currentIndex = 2; // Dashboard selecionado por padrão

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.defaultIndex;
  }

  void _handleNavigationChange(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });

    // Mapeamento dos índices:
    // 0: Veículos -> listscreen (via BottomNavigation_01)
    // 1: Mapa Principal -> MainMapScreen (via BottomNavigation_01)
    // 2: Dashboard -> FleetOverviewScreen (via BottomNavigation_01)
    // 3: Video Telemetria -> VideoTelemetryScreen
    // 4: Hambúrguer -> abrir drawer

    if (index == 4) {
      // Menu hambúrguer - abrir drawer
      if (widget.scaffoldKey?.currentState != null) {
        widget.scaffoldKey!.currentState!.openDrawer();
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
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return Container(
          height: 70,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: colorProvider.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.directions_car,
                label: 'Veículos',
                index: 0,
                colorProvider: colorProvider,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.map,
                label: 'Mapa',
                index: 1,
                colorProvider: colorProvider,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                index: 2,
                colorProvider: colorProvider,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.videocam,
                label: 'Câmera',
                index: 3,
                colorProvider: colorProvider,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.menu,
                label: 'Menu',
                index: 4,
                colorProvider: colorProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required ColorProvider colorProvider,
  }) {
    final isSelected = _currentIndex == index;
    final iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.7);
    
    return Expanded(
      child: InkWell(
        onTap: () => _handleNavigationChange(context, index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

