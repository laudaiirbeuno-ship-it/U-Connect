import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/arguments/ReportArguments.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/PermissionModel.dart';
import 'package:uconnect/data/screens/geofences/GeofenceAdd.dart';
import 'package:uconnect/model/User.dart';
import 'package:uconnect/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/Session.dart';
import '../../model/GeofenceModel.dart';
import 'package:uconnect/ui/reusable/custom_app_bar.dart'; // Importe o CustomAppBar

class GeofenceListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _GeofenceListPageState();
}

class _GeofenceListPageState extends State<GeofenceListPage> {
  GoogleMapController? mapController;
  Timer? _timer;
  bool addFenceVisible = false;
  bool deleteFenceVisible = false;
  bool addClicked = false;
  SharedPreferences? prefs;
  User? user;
  int? deleteFenceId;
  bool isLoading = false;
  List<Geofence> fenceList = [];
  List<int> selectedFenceList = [];
  static Color primaryDark = const Color.fromARGB(255, 13, 61, 101);
  Marker? newFenceMarker;

  @override
  initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    String? userJson = prefs!.getString("user");
    final parsed = json.decode(userJson!);
    user = User.fromJson(parsed);
    getFences();
    setState(() {});
  }

  void getFences() async {
    gpsapis.getGeoFences().then((value) => {
          if (value != null)
            {
              fenceList.addAll(value),
              setState(() {}),
            }
          else
            {
              isLoading = false,
              setState(() {}),
              Fluttertoast.showToast(
                  msg: "Não há cercas registradas",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: const Color.fromARGB(255, 131, 141, 131),
                  textColor: Colors.white,
                  fontSize: 16.0)
            },
        });
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Cercas Virtuais"), // Usando o CustomAppBar
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card de Resumo
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF001F5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem(Icons.location_on, '0', 'Cercas'),
                  _buildSummaryItem(Icons.check_circle, '0', 'Ativas'),
                  _buildSummaryItem(Icons.add_location, '0', 'Nova'),
                ],
              ),
            ),

            // Conteúdo Principal
            if (fenceList.isEmpty) _buildEmptyState() else _buildFenceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          // Logo "noFence"
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 131, 141, 131),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Não há cercas registradas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Ícone de localização com linha diagonal
          Container(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Icon(
                  Icons.location_on,
                  size: 80,
                  color: Colors.grey[300],
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(1),
                      ),
                      transform: Matrix4.rotationZ(0.785398), // 45 graus
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Mensagem de estado vazio
          Text(
            'Nenhuma cerca virtual encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Crie sua primeira cerca virtual para monitorar áreas específicas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),

          // Botão Criar Primeira Cerca
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GeofenceAddPage()),
                );
              },
              icon: Icon(Icons.add_location, color: Colors.white, size: 20),
              label: Text(
                'Criar Primeira Cerca',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFenceList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: fenceList.length,
      itemBuilder: (context, index) {
        final fence = fenceList[index];
        return _buildFenceCard(fence, context);
      },
    );
  }

  Widget _buildFenceCard(Geofence fence, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF1976D2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: Color(0xFF1976D2),
            size: 20,
          ),
        ),
        title: Text(
          fence.name ?? 'Sem nome',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Cerca virtual',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Navegação para detalhes da cerca
        },
      ),
    );
  }
}

class FenceArguments extends Object {
  Geofence? fenceModel;
  int? deviceId;
  String? name;

  FenceArguments({this.fenceModel, this.deviceId, this.name});
}
