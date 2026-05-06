import 'package:flutter/material.dart';
// import 'package:flutter_google_street_view/flutter_google_street_view.dart'; // Temporarily disabled due to Dart 3.0 compatibility issues
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';

class StreetViewScreen extends StatefulWidget {
  final maps.LatLng? initialPosition;
  final String? panoId;

  const StreetViewScreen({
    Key? key,
    this.initialPosition,
    this.panoId,
  }) : super(key: key);

  @override
  _StreetViewScreenState createState() => _StreetViewScreenState();
}

class _StreetViewScreenState extends State<StreetViewScreen> {
  // StreetViewController? _controller; // Temporarily disabled
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.black,
      appBar: StandardHeader(
        title: 'Street View',
        icon: Icons.streetview,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.streetview, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Street View temporariamente indisponível',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Devido a problemas de compatibilidade com Dart 3.0',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

