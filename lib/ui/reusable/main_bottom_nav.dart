import 'package:flutter/material.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';

/// Widget de navegação inferior principal
/// Compatível com o padrão usado no projeto
class MainBottomNav extends StatelessWidget {
  final int currentIndex;

  const MainBottomNav({
    Key? key,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReusableFluidBottomNav(currentIndex: currentIndex);
  }
}
























