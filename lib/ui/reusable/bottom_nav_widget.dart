import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';

/// Widget do bottom navigation que pode ser usado em páginas individuais
class BottomNavWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorProvider.primaryColor, // Cor primária no fundo
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.directions_car, 0, context),
          _navItem(Icons.map, 1, context),
          _navItem(Icons.grid_view, 2, context),
          _navItem(Icons.local_gas_station, 3, context),
          _navItem(Icons.videocam, 4, context),
          _navItem(Icons.menu, 5, context),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final isSelected = currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.7);
    
    // Ícone especial para grid com plus
    Widget iconWidget;
    if (index == 2) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.grid_view, color: color, size: 24),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorProvider.primaryColor, width: 1.5),
              ),
              child: Center(
                child: Icon(Icons.add, color: colorProvider.primaryColor, size: 10),
              ),
            ),
          ),
        ],
      );
    } else {
      iconWidget = Icon(icon, color: color, size: 24);
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.all(8),
        child: iconWidget,
      ),
    );
  }
}

