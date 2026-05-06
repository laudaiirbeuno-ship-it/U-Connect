import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';

/// Helper para criar o FluidNavBar reutilizável
class FluidNavHelper {
  static Widget buildFluidNavBar({
    required BuildContext context,
    required GlobalKey<ScaffoldState> scaffoldKey,
    int defaultIndex = -1,
  }) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: true);

    void handleNavigationChange(int index) {
      if (index == 4) {
        scaffoldKey.currentState?.openDrawer();
      } else if (index == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VideoTelemetryScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BottomNavigation_01(initialIndex: index),
          ),
        );
      }
    }

    return FluidNavBar(
      icons: [
        FluidNavBarIcon(
          icon: Icons.directions_car,
          backgroundColor: colorProvider.primaryColor,
          extras: {"label": "Veículos", "index": 0},
        ),
        FluidNavBarIcon(
          icon: Icons.map,
          backgroundColor: colorProvider.primaryColor,
          extras: {"label": "Mapa", "index": 1},
        ),
        FluidNavBarIcon(
          icon: Icons.dashboard_outlined,
          backgroundColor: colorProvider.primaryColor,
          extras: {"label": "Dashboard", "index": 2},
        ),
        FluidNavBarIcon(
          icon: Icons.videocam,
          backgroundColor: colorProvider.primaryColor,
          extras: {"label": "Câmera", "index": 3},
        ),
        FluidNavBarIcon(
          icon: Icons.menu,
          backgroundColor: colorProvider.primaryColor,
          extras: {"label": "Menu", "index": 4},
        ),
      ],
      onChange: handleNavigationChange,
      style: FluidNavBarStyle(
        barBackgroundColor: colorProvider.primaryColor,
        iconBackgroundColor: colorProvider.primaryColor,
        iconSelectedForegroundColor: Colors.white,
        iconUnselectedForegroundColor: Colors.white.withOpacity(0.7),
      ),
      scaleFactor: 1.5,
      defaultIndex: defaultIndex,
      itemBuilder: (icon, item) => Semantics(
        label: icon.extras!["label"],
        child: item,
      ),
    );
  }
}













