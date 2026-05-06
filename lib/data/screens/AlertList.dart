import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/model/Alert.dart';
import 'package:uconnect/model/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../datasources.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/utils/translation_helper.dart';

class AlertListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _AlertListPageState();
}

class _AlertListPageState extends State<AlertListPage> {
  GoogleMapController? mapController;
  Timer? _timer;
  bool addFenceVisible = false;
  bool deleteFenceVisible = false;
  bool addClicked = false;
  SharedPreferences? prefs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? user;
  int? deleteFenceId;
  bool isLoading = false;
  List<Alert> alertList = [];
  List<int> selectedFenceList = [];
  String? _selectedVehicleId; // Filtro de veículo

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
    getAlerts();
    setState(() {});
  }

  void removeAlert(Alert alert) {
    _showProgress(true);
    alertList.clear();
    selectedFenceList.clear();

    Map<String, String> requestBody = <String, String>{
      'id': alert.id.toString(),
      'active': "false"
    };

    gpsapis.activateAlert(requestBody).then((value) => {
          if (value.statusCode == 200)
            {
              getAlerts(),
              _showProgress(false),
            }
          else
            {
              _showProgress(false),
            }
        });
  }

  void activateAlert(Alert alert) {
    _showProgress(true);
    alertList.clear();
    selectedFenceList.clear();
    // List devices = []; // Não usado
    // alert.devices!.join(','); // Não usado
    Map<String, String> requestBody = <String, String>{
      'id': alert.id.toString(),
      'active': "true"
    };
    gpsapis.activateAlert(requestBody).then((value) => {
          if (value.statusCode == 200)
            {
              getAlerts(),
              _showProgress(false),
            }
          else
            {
              _showProgress(false),
            }
        });
  }

  void getAlerts() async {
    _showProgress(true);
    gpsapis.getAlertList().then((value) => {
          if (value != null)
            {
              alertList.addAll(value),
              _showProgress(false),
              setState(() {}),
            }
          else
            {
              isLoading = false,
              setState(() {}),
              _showProgress(false),
              Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, "Nenhum alerta encontrado", "No alerts found"),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0)
            },
        });
  }

  void getSelectedFenceList() {
    // _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
    //   if (args != null) {
    //     APIService.getGeoFencesByDeviceID(args.id.toString()).then((value) => {
    //           _timer.cancel(),
    //           if (value.length > 0)
    //             {
    //               value.forEach((element) {
    //                 selectedFenceList.add(element.id);
    //               }),
    //               _showProgress(false),
    //               setState(() {}),
    //             }
    //           else
    //             {
    //               isLoading = false,
    //               setState(() {}),
    //               Fluttertoast.showToast(
    //                   msg: AppLocalizations.of(context).translate("noFence"),
    //                   toastLength: Toast.LENGTH_SHORT,
    //                   gravity: ToastGravity.CENTER,
    //                   timeInSecForIosWeb: 1,
    //                   backgroundColor: Colors.green,
    //                   textColor: Colors.white,
    //                   fontSize: 16.0)
    //             },
    //         });
    //   }
    // });
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
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, "Alertas", "Alerts"),
        icon: Icons.warning_amber_outlined,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          // Fundo animado
          AnimatedBackground(opacity: 0.03),
          // Conteúdo
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Column(
            children: [
              // Filtro no topo
              _buildFilterWidget(context, colorProvider),
              // Lista ou mensagem
            Expanded(
              child: alertList.isEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          // Banner
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              TranslationHelper.translateSync(context, 'Nenhum alerta encontrado', 'No alerts found'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16),
                          // Card com ícone
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
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
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  TranslationHelper.translateSync(context, 'Nenhum alerta encontrado', 'No alerts found'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  TranslationHelper.translateSync(context, 'Configure alertas para monitorar seu veículo', 'Configure alerts to monitor your vehicle'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final fence = _filteredAlerts[index];
                        return fenceCard(fence, context);
                      },
                    ),
            ),
            ],
          );
          },
        ),
        ],
      ),
    );
  }

  // Widget de filtro similar ao FleetFilterWidget
  Widget _buildFilterWidget(BuildContext context, ColorProvider colorProvider) {
    final objectStore = Provider.of<ObjectStore>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Dropdown de veículo
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedVehicleId,
              decoration: InputDecoration(
                labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                border: InputBorder.none,
                labelStyle: TextStyle(color: colorProvider.primaryColor),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles')),
                ),
                ...objectStore.objects.map((device) {
                  return DropdownMenuItem<String>(
                    value: device.id?.toString(),
                    child: Text(device.name ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name')),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVehicleId = value;
                });
              },
              dropdownColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Lista filtrada de alertas
  List<Alert> get _filteredAlerts {
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
      return alertList;
    }
    
    final vehicleId = int.tryParse(_selectedVehicleId!);
    if (vehicleId == null) {
      return alertList;
    }
    
    // Filtrar alertas que contêm o veículo selecionado
    return alertList.where((alert) {
      if (alert.devices == null || alert.devices!.isEmpty) {
        return false;
      }
      return alert.devices!.any((deviceId) => deviceId == vehicleId);
    }).toList();
  }

  Widget fenceCard(Alert alert, BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    // Determinar ícone e cor baseado no tipo de alerta
    IconData alertIcon;
    Color alertColor;
    
    final alertName = (alert.name?.toString().toLowerCase() ?? '');
    final alertType = (alert.type?.toString().toLowerCase() ?? '');
    
    if (alertName.contains('velocidade') || alertName.contains('speed') || alertName.contains('overspeed') || alertType.contains('overspeed')) {
      alertIcon = Icons.speed;
      alertColor = colorProvider.primaryColor;
    } else if (alertName.contains('ignição') || alertName.contains('ignition') || alertType.contains('ignition')) {
      alertIcon = Icons.power_settings_new;
      alertColor = colorProvider.primaryColor;
    } else if (alertName.contains('bateria') || alertName.contains('battery') || alertType.contains('battery')) {
      alertIcon = Icons.battery_alert;
      alertColor = colorProvider.primaryColor;
    } else if (alertName.contains('geofence') || alertName.contains('cerca') || alertType.contains('geofence')) {
      alertIcon = Icons.fence;
      alertColor = colorProvider.primaryColor;
    } else if (alertName.contains('pânico') || alertName.contains('panic') || alertType.contains('panic')) {
      alertIcon = Icons.warning;
      alertColor = colorProvider.primaryColor;
    } else {
      alertIcon = Icons.notifications_active;
      alertColor = colorProvider.primaryColor;
    }
    
    final devicesCount = alert.devices?.length ?? 0;
    final geofencesCount = alert.geofences?.length ?? 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: alert.active == 1 
              ? alertColor.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone colorido
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alertIcon,
                    color: alertColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.name?.toString() ?? TranslationHelper.translateSync(context, 'Alerta sem nome', 'Unnamed alert'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 4),
                      // Tipo do alerta
                      if (alert.type != null)
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 14,
                              color: colorProvider.primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              alert.type.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorProvider.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Switch
                Switch(
                  value: alert.active == 1,
                  activeColor: alertColor,
                  onChanged: (value) {
                    if (value) {
                      activateAlert(alert);
                    } else {
                      removeAlert(alert);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: 6),
            // Informações detalhadas
            Row(
              children: [
                // Dispositivos
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: colorProvider.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '$devicesCount ${devicesCount == 1 ? TranslationHelper.translateSync(context, 'dispositivo', 'device') : TranslationHelper.translateSync(context, 'dispositivos', 'devices')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Geofences
                if (geofencesCount > 0)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.fence,
                          size: 16,
                          color: colorProvider.primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$geofencesCount ${geofencesCount == 1 ? 'geofence' : 'geofences'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        alert.active == 1 ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: colorProvider.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        alert.active == 1 ? TranslationHelper.translateSync(context, 'Ativo', 'Active') : TranslationHelper.translateSync(context, 'Inativo', 'Inactive'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Card de velocidade (se for alerta de velocidade)
            if (alertName.contains('velocidade') || alertName.contains('speed') || alertName.contains('overspeed') || alertType.contains('overspeed'))
              Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: alertColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.speed,
                      color: alertColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TranslationHelper.translateSync(context, 'Limite de Velocidade', 'Speed Limit'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final speedLimit = _getSpeedLimit(alert);
                              return Text(
                                speedLimit ?? TranslationHelper.translateSync(context, 'Não definido', 'Not defined'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: speedLimit != null ? alertColor : Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: alertColor,
                        size: 20,
                      ),
                      onPressed: () => _showEditSpeedLimitDialog(alert, context),
                      tooltip: TranslationHelper.translateSync(context, 'Editar limite de velocidade', 'Edit speed limit'),
                    ),
                  ],
                ),
              ),
            // Data e hora
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorProvider.primaryColor,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        alert.created_at != null 
                            ? '${TranslationHelper.translateSync(context, 'Criado', 'Created')}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(alert.created_at.toString()))}'
                            : TranslationHelper.translateSync(context, 'Data não disponível', 'Date not available'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (alert.updated_at != null && alert.updated_at != alert.created_at)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.update,
                        size: 14,
                        color: colorProvider.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${TranslationHelper.translateSync(context, 'Atualizado', 'Updated')}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(alert.updated_at.toString()))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _getSpeedLimit(Alert alert) {
    // Debug: imprimir valores para diagnóstico
    print('_getSpeedLimit - Alert ID: ${alert.id}, overspeed_speed: ${alert.overspeed_speed}, overspeed: ${alert.overspeed}');
    
    // Primeiro, tentar obter do campo overspeed_speed (novo campo da API)
    if (alert.overspeed_speed != null) {
      final speedValueStr = alert.overspeed_speed.toString().trim();
      if (speedValueStr.isNotEmpty && speedValueStr != '0' && speedValueStr != 'null' && speedValueStr != '') {
        // Tentar converter para número para validar
        final speedNum = int.tryParse(speedValueStr);
        if (speedNum != null && speedNum > 0) {
          return '$speedNum km/h';
        } else if (speedValueStr.isNotEmpty && speedValueStr != 'null') {
          return '$speedValueStr km/h';
        }
      }
    }
    
    // Tentar obter do campo overspeed
    if (alert.overspeed != null) {
      final overspeedValue = alert.overspeed;
      if (overspeedValue is int && overspeedValue > 0) {
        return '$overspeedValue km/h';
      } else if (overspeedValue is String) {
        final overspeedStr = overspeedValue.trim();
        if (overspeedStr.isNotEmpty && overspeedStr != '0' && overspeedStr != 'null') {
          final overspeedNum = int.tryParse(overspeedStr);
          if (overspeedNum != null && overspeedNum > 0) {
            return '$overspeedNum km/h';
          }
          return '$overspeedStr km/h';
        }
      } else if (overspeedValue is num && overspeedValue > 0) {
        return '${overspeedValue.toString()} km/h';
      }
    }
    
    // Tentar obter o limite de velocidade do campo zone
    if (alert.zone != null) {
      try {
        if (alert.zone is Map) {
          final zoneMap = alert.zone as Map<String, dynamic>;
          if (zoneMap['overspeed'] != null) {
            return '${zoneMap['overspeed']} km/h';
          }
        } else if (alert.zone is String) {
          // Se zone for uma string, pode conter o overspeed
          final zoneStr = alert.zone.toString();
          final overspeedMatch = RegExp(r'overspeed[:\s]*(\d+)', caseSensitive: false).firstMatch(zoneStr);
          if (overspeedMatch != null) {
            return '${overspeedMatch.group(1)} km/h';
          }
        }
      } catch (e) {
        print('Erro ao obter limite de velocidade: $e');
      }
    }
    
    // Tentar obter do campo command
    if (alert.command != null && alert.command is Map) {
      try {
        final commandMap = alert.command as Map<String, dynamic>;
        if (commandMap['overspeed'] != null) {
          return '${commandMap['overspeed']} km/h';
        }
      } catch (e) {
        print('Erro ao obter limite de velocidade do command: $e');
      }
    }
    
    return null;
  }

  void _showEditSpeedLimitDialog(Alert alert, BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    final TextEditingController speedController = TextEditingController();
    
    // Obter o limite atual
    String? currentLimit = _getSpeedLimit(alert);
    if (currentLimit != null) {
      // Extrair apenas o número
      final match = RegExp(r'(\d+)').firstMatch(currentLimit);
      if (match != null) {
        speedController.text = match.group(1)!;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              TranslationHelper.translateSync(context, 'Editar Limite de Velocidade', 'Edit Speed Limit'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Digite o novo limite de velocidade em km/h', 'Enter the new speed limit in km/h'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          TranslationHelper.translateSync(context, 'Limite de Velocidade (km/h)', 'Speed Limit (km/h)'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: speedController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: TranslationHelper.translateSync(context, 'Ex: 60, 80, 100', 'E.g.: 60, 80, 100'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.speed, color: colorProvider.primaryColor),
                            suffixText: 'km/h',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer - Botões
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              TranslationHelper.translateSync(context, 'Cancelar', 'Cancel'),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final speedValue = speedController.text.trim();
                              if (speedValue.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(TranslationHelper.translateSync(context, 'Por favor, digite um limite de velocidade', 'Please enter a speed limit')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              final speedInt = int.tryParse(speedValue);
                              if (speedInt == null || speedInt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(TranslationHelper.translateSync(context, 'Por favor, digite um valor válido maior que zero', 'Please enter a valid value greater than zero')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              Navigator.of(ctx).pop();
                              _updateSpeedLimit(alert, speedInt);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(TranslationHelper.translateSync(context, 'Salvar', 'Save')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateSpeedLimit(Alert alert, int newSpeedLimit) async {
    _showProgress(true);
    
    try {
      // Build JSON body for edit_alert API
      Map<String, dynamic> alertData = {
        'id': alert.id,
        'active': alert.active ?? 1,
        'type': alert.type?.toString() ?? 'overspeed',
        'name': alert.name?.toString() ?? '',
        'overspeed': newSpeedLimit,
        'overspeed_speed': newSpeedLimit.toString(), // Adicionar overspeed_speed também
        'schedules': alert.schedules ?? {},
        'notifications': alert.notifications ?? {
          'push': {'active': 1},
          'email': {'active': 0, 'input': ''},
        },
        'command': alert.command ?? {'active': 0, 'type': ''},
      };
      
      // Add devices
      if (alert.devices != null && alert.devices!.isNotEmpty) {
        alertData['devices'] = alert.devices!.map((d) => d is int ? d : int.tryParse(d.toString()) ?? 0).toList();
      }
      
      // Add geofences
      if (alert.geofences != null && alert.geofences!.isNotEmpty) {
        alertData['geofences'] = alert.geofences!.map((g) => g is int ? g : int.tryParse(g.toString()) ?? 0).toList();
      }
      
      // Add drivers
      if (alert.drivers != null && alert.drivers!.isNotEmpty) {
        alertData['drivers'] = alert.drivers!.map((d) => d is int ? d : int.tryParse(d.toString()) ?? 0).toList();
      }
      
      // Add custom events
      if (alert.events_custom != null && alert.events_custom!.isNotEmpty) {
        alertData['events_custom'] = alert.events_custom!.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
      
      // Add other fields if they exist
      if (alert.stop_duration != null) alertData['stop_duration'] = alert.stop_duration;
      if (alert.idle_duration != null) alertData['idle_duration'] = alert.idle_duration;
      if (alert.ignition_duration != null) alertData['ignition_duration'] = alert.ignition_duration;
      if (alert.offline_duration != null) alertData['offline_duration'] = alert.offline_duration;
      if (alert.move_duration != null) alertData['move_duration'] = alert.move_duration;
      if (alert.min_parking_duration != null) alertData['min_parking_duration'] = alert.min_parking_duration;
      if (alert.distance != null) alertData['distance'] = alert.distance;
      if (alert.distance_tolerance != null) alertData['distance_tolerance'] = alert.distance_tolerance;
      
      final response = await gpsapis.editAlertJson(alertData, lang: 'br');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Resposta da API ao editar alerta: ${json.encode(responseData)}');
        
        if (responseData['status'] == 1) {
          _showProgress(false);
          
          // Atualizar o alerta localmente imediatamente
          final alertIndex = alertList.indexWhere((a) => a.id == alert.id);
          if (alertIndex != -1) {
            // Sempre atualizar manualmente primeiro para garantir que o valor aparece imediatamente
            alertList[alertIndex].overspeed_speed = newSpeedLimit.toString();
            alertList[alertIndex].overspeed = newSpeedLimit;
            print('Alerta atualizado manualmente - overspeed_speed: ${alertList[alertIndex].overspeed_speed}, overspeed: ${alertList[alertIndex].overspeed}');
            
            // Se a resposta contém o item atualizado, tentar usar ele, mas manter nossos valores se não tiver
            if (responseData['item'] != null) {
              try {
                final updatedAlert = Alert.fromJson(responseData['item']);
                // Só usar o alerta da resposta se tiver os campos de velocidade preenchidos
                if ((updatedAlert.overspeed_speed != null && updatedAlert.overspeed_speed!.isNotEmpty && updatedAlert.overspeed_speed != 'null') ||
                    (updatedAlert.overspeed != null && updatedAlert.overspeed != 0)) {
                  // Garantir que ambos os campos estão definidos
                  if (updatedAlert.overspeed_speed == null || updatedAlert.overspeed_speed!.isEmpty || updatedAlert.overspeed_speed == 'null') {
                    updatedAlert.overspeed_speed = newSpeedLimit.toString();
                  }
                  if (updatedAlert.overspeed == null || updatedAlert.overspeed == 0) {
                    updatedAlert.overspeed = newSpeedLimit;
                  }
                  alertList[alertIndex] = updatedAlert;
                  print('Alerta atualizado da resposta da API - overspeed_speed: ${updatedAlert.overspeed_speed}, overspeed: ${updatedAlert.overspeed}');
                } else {
                  print('Resposta da API não contém valores de velocidade válidos, mantendo valores atualizados manualmente');
                }
              } catch (e) {
                print('Erro ao atualizar alerta da resposta: $e, mantendo valores atualizados manualmente');
              }
            }
            
            setState(() {}); // Atualizar UI imediatamente
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Limite de velocidade atualizado com sucesso!', 'Speed limit updated successfully!')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Recarregar a lista de alertas para garantir sincronização completa
          // Mas preservar o valor atualizado se a API não retornar
          final preservedSpeedLimit = newSpeedLimit;
          final preservedSpeedLimitString = newSpeedLimit.toString();
          final preservedAlertId = alert.id;
          
          Future.delayed(Duration(milliseconds: 1000), () {
            alertList.clear();
            getAlerts();
            
            // Após recarregar, garantir que o alerta atualizado mantenha o valor
            Future.delayed(Duration(milliseconds: 1500), () {
              final updatedIndex = alertList.indexWhere((a) => a.id == preservedAlertId);
              if (updatedIndex != -1) {
                final reloadedAlert = alertList[updatedIndex];
                // Se após recarregar o valor não está presente, restaurar
                if (reloadedAlert.overspeed_speed == null || 
                    reloadedAlert.overspeed_speed!.isEmpty || 
                    reloadedAlert.overspeed_speed == 'null' ||
                    (reloadedAlert.overspeed == null || reloadedAlert.overspeed == 0)) {
                  reloadedAlert.overspeed_speed = preservedSpeedLimitString;
                  reloadedAlert.overspeed = preservedSpeedLimit;
                  print('Valor restaurado após recarregar - overspeed_speed: ${reloadedAlert.overspeed_speed}, overspeed: ${reloadedAlert.overspeed}');
                  setState(() {});
                }
              }
            });
          });
        } else {
          _showProgress(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Erro ao atualizar limite de velocidade. Tente novamente.', 'Error updating speed limit. Please try again.')),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        _showProgress(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Erro ao atualizar limite de velocidade. Status: ${response.statusCode}', 'Error updating speed limit. Status: ${response.statusCode}')),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showProgress(false);
      print('Erro ao atualizar limite de velocidade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao atualizar limite de velocidade: $e', 'Error updating speed limit: $e')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  _showProgress(bool status) {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(TranslationHelper.translateSync(context, 'Carregando..', 'Loading..'))),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }
}

class AlertArguments extends Object {
  Alert? alertModel;
  int? deviceId;
  String? name;

  AlertArguments({this.alertModel, this.deviceId, this.name});
}
