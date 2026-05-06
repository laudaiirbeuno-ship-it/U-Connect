import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:uconnect/data/screens/listscreen.dart';
import 'package:uconnect/data/screens/map/views/main_map_screen.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';
import 'package:uconnect/data/screens/fleet_overview/views/fleet_overview_screen.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/review_helper.dart';
import '../../mvvm/view_model/objects.dart';

class BottomNavigation_01 extends StatefulWidget {
  final int? initialIndex;
  
  const BottomNavigation_01({Key? key, this.initialIndex}) : super(key: key);
  
  @override
  _BottomNavigation_01State createState() => _BottomNavigation_01State();
  
  // Método estático para obter o estado atual
  static _BottomNavigation_01State? of(BuildContext context) {
    return context.findAncestorStateOfType<_BottomNavigation_01State>();
  }
}

// Wrapper para permitir navegação com índice inicial e abrir drawer
class BottomNavigation_01WithIndex extends StatelessWidget {
  final int initialIndex;
  final bool openDrawer;
  
  const BottomNavigation_01WithIndex({
    Key? key, 
    required this.initialIndex,
    this.openDrawer = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (openDrawer) {
      // Aguardar um frame e então abrir o drawer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bottomNavState = BottomNavigation_01.of(context);
        bottomNavState?.openDrawer();
      });
    }
    return BottomNavigation_01(initialIndex: initialIndex);
  }
}

class _BottomNavigation_01State extends State<BottomNavigation_01> {
  Widget? _child;
  Timer? _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Método público para abrir o drawer
  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    final initialPage = widget.initialIndex ?? 0;
    
    // Inicializar o conteúdo baseado no índice inicial
    switch (initialPage) {
      case 0:
        _child = KeyedSubtree(key: ValueKey<int>(0), child: listscreen());
        break;
      case 1:
        _child = KeyedSubtree(key: ValueKey<int>(1), child: MainMapScreen());
        break;
      case 2:
        _child = KeyedSubtree(key: ValueKey<int>(2), child: FleetOverviewScreen());
        break;
      default:
        _child = KeyedSubtree(key: ValueKey<int>(0), child: listscreen());
    }
    
    getObjects();
    Timer.periodic(Duration(seconds: 10), (timer) {
      // Aqui você pode atualizar notificações se quiser
      setState(() {});
    });
    
    // Mostrar modal de avaliação se necessário (após um pequeno delay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          ReviewHelper.showReviewModalIfNeeded(context);
        }
      });
    });

  }

  void getObjects() {
    Provider.of<ObjectStore>(context, listen: false).getObjects();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      Provider.of<ObjectStore>(context, listen: false).getObjects();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: true);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: FloatingMenuDrawer(),
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          AnimatedSwitcher(
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            duration: Duration(milliseconds: 500),
            child: _child,
          ),
          // Botão de chat global flutuante padronizado
          ChatFloatingButton(),
        ],
      ),
      bottomNavigationBar: Container(
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
              extras: {"label": "Monitoramento", "index": 1},
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
          onChange: _handleNavigationChange,
          style: FluidNavBarStyle(
            barBackgroundColor: colorProvider.primaryColor, // Cor primária no fundo
            iconBackgroundColor: colorProvider.primaryColor, // Cor primária no fundo
            iconSelectedForegroundColor: Colors.white, // Ícones ativos: branco
            iconUnselectedForegroundColor: Colors.white.withOpacity(0.7), // Ícones inativos: branco com opacidade
          ),
          scaleFactor: 1.0,
          defaultIndex: widget.initialIndex ?? 0,
          itemBuilder: (icon, item) => Semantics(
            label: icon.extras!["label"],
            child: item,
          ),
        ),
      ),
    );
  }

  void _handleNavigationChange(int index) {
    setState(() {
      // Mapeamento dos índices:
      // 0: Veículos -> listscreen
      // 1: Mapa Principal -> MainMapScreen
      // 2: Dashboard -> FleetOverviewScreen
      // 3: Video Telemetria -> VideoTelemetryScreen
      // 4: Hambúrguer -> abrir drawer
      
      if (index == 4) {
        // Menu hambúrguer - abrir drawer
        _scaffoldKey.currentState?.openDrawer();
        return; // Não mudar o conteúdo
      } else if (index == 3) {
        // Video Telemetria - navegar para a página
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VideoTelemetryScreen()),
        );
        return; // Não mudar o conteúdo aqui
      } else {
        // Mudar o conteúdo baseado no índice
        switch (index) {
          case 0:
            _child = KeyedSubtree(key: ValueKey<int>(0), child: listscreen());
            break;
          case 1:
            _child = KeyedSubtree(key: ValueKey<int>(1), child: MainMapScreen());
            break;
          case 2:
            _child = KeyedSubtree(key: ValueKey<int>(2), child: FleetOverviewScreen());
            break;
          default:
            _child = KeyedSubtree(key: ValueKey<int>(0), child: listscreen());
        }
      }
    });
  }
}

