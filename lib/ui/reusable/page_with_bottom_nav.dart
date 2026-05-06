import 'package:flutter/material.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';

/// Wrapper para páginas que precisam ter bottom navigation
/// Use este widget para envolver páginas que são acessadas via Navigator.push
class PageWithBottomNav extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const PageWithBottomNav({
    Key? key,
    required this.child,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se já estamos dentro do BottomNavigation_01, não adicionar novamente
    if (context.findAncestorWidgetOfExactType<BottomNavigation_01>() != null) {
      return Scaffold(
        appBar: appBar,
        body: child,
      );
    }

    // Caso contrário, retornar apenas o Scaffold sem bottom nav
    // pois essas páginas são acessadas via Navigator.push
    return Scaffold(
      appBar: appBar,
      body: child,
    );
  }
}

