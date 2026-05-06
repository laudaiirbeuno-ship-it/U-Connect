import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/video_telemetry/controllers/cameras_controller.dart';
import 'package:uconnect/data/screens/video_telemetry/widgets/cameras_filter_widget.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class VideoTelemetryScreen extends StatefulWidget {
  @override
  _VideoTelemetryScreenState createState() => _VideoTelemetryScreenState();
}

class _VideoTelemetryScreenState extends State<VideoTelemetryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Interface simplificada - apenas filtros e aviso sem câmeras

  @override
  void initState() {
    super.initState();
    // Inicialização simplificada
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CamerasController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Câmeras', 'Cameras'),
          icon: Icons.videocam,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(
          scaffoldKey: _scaffoldKey,
          currentIndex: 3, // Câmera selecionada
        ),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer2<CamerasController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                if (controller.isLoading && controller.cameras.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorProvider.primaryColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    CamerasFilterWidget(isSticky: false), // Filtro sempre visível no topo
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => controller.loadData(),
                        color: colorProvider.primaryColor,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  TranslationHelper.translateSync(context, 'Não há câmeras no momento', 'No cameras available at the moment'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
