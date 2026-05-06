import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:provider/provider.dart';

import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

import '../../config/Session.dart';
import '../../config/static.dart';
import '../../res/AssetsRes.dart';
import '../../ui/reusable/Mycolor/MyColor.dart';
import '../../ui/reusable/standard_header.dart';
import '../../utils/translation_helper.dart';
import '../../provider/color_provider.dart';
import '../datasources.dart';
import '../model/devices.dart';
import '../model/events.dart';
import 'notificationscreen.dart';
import 'fleet_sensors/views/fleet_sensors_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int touchedIndex = -1;

  // late ObjectStore objectStore;
  // late EventsStore eventsStore;
  // late DashboardStore dashboardStore;
  // Map<String, ObjectResponse> devicesList = HashMap();
  Map<String, dynamic> devicesSettingsList = HashMap();

  int key = 0;
  SharedPreferences? prefs;

  List<deviceItems> _inactiveVehicles = [];
  List<deviceItems> _allVehicles = [];
  List<deviceItems> _runningVehicles = [];
  List<deviceItems> _idleVehicles = [];
  List<deviceItems> _stoppedVehicles = [];

  List<EventsData> eventList = [];

  List<deviceItems> devicesList = [];
  late ObjectStore objectStore;

  @override
  initState() {
    //notiList = Consts.notiList;
    getnotiList();
    checkPreference();

    super.initState();
    
    // Carregar dados do ObjectStore se necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final objectStore = Provider.of<ObjectStore>(context, listen: false);
      if (objectStore.objects.isEmpty && !objectStore.isLoading) {
        objectStore.getObjects();
      }
    });
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    // Não processar veículos no build - isso será feito no dashboardView
    // Isso evita processamento desnecessário a cada rebuild e melhora performance
    // if (devicesList.isNotEmpty) {
    //
    //   for (int i = 0; i < devicesList.length; i++) {
    //     deviceItems model = devicesList.elementAt(i);
    //     if (model.online.toString().toLowerCase().contains("offline") &&
    //         model.time.toString().toLowerCase().contains("not connected")) {
    //       _inactiveVehicles.add(devicesList.elementAt(i));
    //     } else if (model.online.toString().toLowerCase().contains("online")) {
    //       _runningVehicles.add(devicesList.elementAt(i));
    //     } else if (model.online.toString().toLowerCase().contains("ack") &&
    //         double.parse(model.speed.toString()) < 1.0) {
    //       _idleVehicles.add(devicesList.elementAt(i));
    //     } else if (model.online
    //         .toString()
    //         .toLowerCase()
    //         .contains("offline") &&
    //         model.time.toString().toLowerCase() != "not connected") {
    //       _stoppedVehicles.add(devicesList.elementAt(i));
    //     }
    //   }
    //   if (mounted) {
    //     setState(() {});
    //   }
    // }

    return Scaffold(
      appBar: StandardHeader(
        title: getTranslated(context, 'dashboard') ?? 'Dashboard',
        icon: Icons.dashboard,
      ),
      body: Consumer<ObjectStore>(
        builder: (context, objectStore, child) {
          return dashboardView(objectStore);
        },
      ),
    );
  }

  Widget dashboardView(ObjectStore objectStore) {
    // Atualizar listas com base no objectStore atualizado
    final currentDevicesList = objectStore.objects;
    
    // Verificar se está carregando (com timeout de 10 segundos)
    // Se estiver carregando há muito tempo, mostrar conteúdo mesmo assim
    final isLoadingTooLong = objectStore.isLoading && 
        (currentDevicesList.isNotEmpty || StaticVarMethod.devicelist.isNotEmpty);
    
    if (objectStore.isLoading && !isLoadingTooLong) {
      // Mostrar loading apenas se não houver dados anteriores
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Carregando dados do dashboard...', 'Loading dashboard data...'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Forçar atualização
                objectStore.getObjects(forceRefresh: true);
              },
              child: Text(TranslationHelper.translateSync(
                context,
                'Atualizar',
                'Refresh',
              )),
            ),
          ],
        ),
      );
    }

    // Verificar se há erro
    if (objectStore.error != null && currentDevicesList.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Erro ao carregar dados', 'Error loading data'),
                style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                objectStore.error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  objectStore.getObjects(forceRefresh: true);
                },
                icon: Icon(Icons.refresh),
                label: Text(TranslationHelper.translateSync(context, 'Tentar Novamente', 'Try Again')),
              ),
            ],
          ),
        ),
      );
    }

    // Verificar se não há veículos (mas permitir mostrar dashboard mesmo sem veículos)
    // Se não houver veículos, mostrar dashboard vazio mas funcional
    final hasAnyData = currentDevicesList.isNotEmpty || StaticVarMethod.devicelist.isNotEmpty;
    
    if (!hasAnyData && !objectStore.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Nenhum veículo encontrado', 'No vehicles found'),
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                TranslationHelper.translateSync(context, 'Adicione veículos para visualizar o dashboard', 'Add vehicles to view the dashboard'),
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  objectStore.getObjects(forceRefresh: true);
                },
                icon: Icon(Icons.refresh),
                label: Text(TranslationHelper.translateSync(context, 'Atualizar', 'Refresh')),
              ),
            ],
          ),
        ),
      );
    }

    // Reprocessar veículos com os dados atualizados
    _runningVehicles = [];
    _idleVehicles = [];
    _stoppedVehicles = [];
    _inactiveVehicles = [];
    _allVehicles = currentDevicesList;

    // Verificar se há dados disponíveis
    final hasDevicelist = StaticVarMethod.devicelist.isNotEmpty;
    final hasObjectStore = currentDevicesList.isNotEmpty;

    // Processar veículos apenas se houver dados
    if (hasDevicelist) {
      for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
        try {
          deviceItems model = StaticVarMethod.devicelist.elementAt(i);
          
          // Verificar se model.deviceData e traccar existem
          if (model.deviceData?.traccar?.other == null) {
            continue;
          }
          
          String other = model.deviceData!.traccar!.other.toString();
          String ignition = "false";
          if (other.contains("<ignition>")) {
            const start = "<ignition>";
            const end = "</ignition>";
            final startIndex = other.indexOf(start);
            if (startIndex != -1) {
              final endIndex = other.indexOf(end, startIndex + start.length);
              if (endIndex != -1) {
                ignition = other.substring(startIndex + start.length, endIndex);
              }
            }
          }
          
          // Verificar velocidade de forma segura
          double speed = 0.0;
          try {
            speed = double.parse(model.speed?.toString() ?? "0");
          } catch (e) {
            speed = 0.0;
          }
          
          if (ignition.contains("true") && speed < 1.0) {
            _idleVehicles.add(StaticVarMethod.devicelist.elementAt(i));
          } else if (model.online?.toString().toLowerCase().contains("offline") == true &&
              model.time?.toString().toLowerCase().contains("not connected") == true) {
            _inactiveVehicles.add(StaticVarMethod.devicelist.elementAt(i));
          } else if (model.online?.toString().toLowerCase().contains("online") == true) {
            _runningVehicles.add(StaticVarMethod.devicelist.elementAt(i));
          } else if (ignition.contains("false") &&
              model.time?.toString().toLowerCase() != "not connected") {
            _stoppedVehicles.add(StaticVarMethod.devicelist.elementAt(i));
          }
        } catch (e) {
          print('Erro ao processar veículo $i: $e');
          continue;
        }
      }
    } else if (hasObjectStore) {
      // Se não houver devicelist, tentar usar objectStore
      for (int i = 0; i < currentDevicesList.length; i++) {
        try {
          deviceItems model = currentDevicesList.elementAt(i);
          
          if (model.deviceData?.traccar?.other == null) {
            continue;
          }
          
          String other = model.deviceData!.traccar!.other.toString();
          String ignition = "false";
          if (other.contains("<ignition>")) {
            const start = "<ignition>";
            const end = "</ignition>";
            final startIndex = other.indexOf(start);
            if (startIndex != -1) {
              final endIndex = other.indexOf(end, startIndex + start.length);
              if (endIndex != -1) {
                ignition = other.substring(startIndex + start.length, endIndex);
              }
            }
          }
          
          double speed = 0.0;
          try {
            speed = double.parse(model.speed?.toString() ?? "0");
          } catch (e) {
            speed = 0.0;
          }
          
          if (ignition.contains("true") && speed < 1.0) {
            _idleVehicles.add(currentDevicesList.elementAt(i));
          } else if (model.online?.toString().toLowerCase().contains("offline") == true &&
              model.time?.toString().toLowerCase().contains("not connected") == true) {
            _inactiveVehicles.add(currentDevicesList.elementAt(i));
          } else if (model.online?.toString().toLowerCase().contains("online") == true) {
            _runningVehicles.add(currentDevicesList.elementAt(i));
          } else if (ignition.contains("false") &&
              model.time?.toString().toLowerCase() != "not connected") {
            _stoppedVehicles.add(currentDevicesList.elementAt(i));
          }
        } catch (e) {
          print('Erro ao processar veículo do objectStore $i: $e');
          continue;
        }
      }
    }

    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    
    return ListView(
      children: [
        fleetStatus(colorProvider),
        Flex(
            direction: Axis.horizontal,
            children: [Expanded(child: alertStatus(colorProvider))]),
        // Seção de Sensores
        _buildSensorsSection(colorProvider),
        //fleetIdle(),
        // Flex(
        //     direction: Axis.horizontal,
        //     children: [
        //       Expanded(
        //           child:
        //       maintenanceRemainder()),
        //     ]),
        // RenewalRemainder()
      ],
    );
  }

  Widget fleetStatus(ColorProvider colorProvider) {
    double all = _allVehicles.length.toDouble(),
        moving = _runningVehicles.length.toDouble(),
        idle = _idleVehicles.length.toDouble(),
        stop = _stoppedVehicles.length.toDouble(),
        disconnect = 0,
        noData = _inactiveVehicles.length.toDouble();

    // devicesList.forEach((key, d) {
    //   all++;
    //   if(d.status !=  false) {
    //     if (Util.getDeviceStatusType(d, devicesSettingsList, key) ==
    //         IS_MOVING) {
    //       moving++;
    //     } else
    //     if (Util.getDeviceStatusType(d, devicesSettingsList, key) == IS_IDLE) {
    //       idle++;
    //     } else
    //     if (Util.getDeviceStatusType(d, devicesSettingsList, key) == IS_STOP) {
    //       stop++;
    //     } else if (Util.getDeviceStatusType(d, devicesSettingsList, key) ==
    //         IS_INACTIVE) {
    //       disconnect++;
    //     } else if (Util.getDeviceStatusType(d, devicesSettingsList, key) ==
    //         IS_NO_DATA) {
    //       noData++;
    //     } else if (Util.getDeviceStatusType(d, devicesSettingsList, key) ==
    //         IS_EXPIRED) {
    //       expired++;
    //     }
    //   }else{
    //     noData++;
    //   }
    // });

    final dataMap = <_PieData>[
      _PieData(
        TranslationHelper.translateSync(context, 'Em movimento', 'Moving'),
        moving,
        moving.toStringAsFixed(0),
        MyColor.ONLINE_COLOR,
      ),
      _PieData(
        TranslationHelper.translateSync(context, 'Parado', 'Idle'),
        idle,
        idle.toStringAsFixed(0),
        MyColor.IDLE_COLOR,
      ),
      _PieData(
        TranslationHelper.translateSync(context, 'Offline', 'Offline'),
        stop,
        stop.toStringAsFixed(0),
        MyColor.STOP_COLOR,
      ),
      _PieData(
        TranslationHelper.translateSync(context, 'Inativo', 'Inactive'),
        disconnect,
        disconnect.toStringAsFixed(0),
        MyColor.INACTIVE_COLOR,
      ),
      _PieData(
        TranslationHelper.translateSync(context, 'Sem registro', 'No data'),
        noData,
        noData.toStringAsFixed(0),
        Colors.black,
      ),
    ];

    return Card(
      child: Container(
          padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'fleetStatus')!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 250,
                      width: MediaQuery.of(context).size.width / 1.1,
                      alignment: Alignment.center,
                      child: SfCircularChart(
                          legend: Legend(
                              isVisible: true,
                              overflowMode: LegendItemOverflowMode.scroll,
                              position: LegendPosition.right),
                          annotations: <CircularChartAnnotation>[
                            CircularChartAnnotation(
                                widget: Text(all.toStringAsFixed(0),
                                    style: TextStyle(
                                        color: Color.fromRGBO(0, 0, 0, 0.5),
                                        fontSize: 25))),
                          ],
                          series: <DoughnutSeries<_PieData, String>>[
                            DoughnutSeries<_PieData, String>(
                                explode: true,
                                explodeOffset: '10%',
                                radius: '100%',
                                innerRadius: '60%',
                                onPointTap: (val) {
                                  // print(dataMap[val.pointIndex!].xData);
                                  if (dataMap[val.pointIndex!].xData ==
                                      "Moving") {
                                    // widget.parent!.setState(() {
                                    //   Util.selectedIndex = 2;
                                    //   objectFilter  = 1;
                                    // });
                                  } else if (dataMap[val.pointIndex!].xData ==
                                      "Idle") {
                                    // widget.parent!.setState(() {
                                    //   Util.selectedIndex = 2;
                                    //   objectFilter  = 2;
                                    // });
                                  } else if (dataMap[val.pointIndex!].xData ==
                                      "Stop") {
                                    // widget.parent!.setState(() {
                                    //   Util.selectedIndex = 2;
                                    //   objectFilter  = 3;
                                    // });
                                  } else if (dataMap[val.pointIndex!].xData ==
                                      "Inactive") {
                                    // widget.parent!.setState(() {
                                    //   Util.selectedIndex = 2;
                                    //   objectFilter  = 4;
                                    // });
                                  } else if (dataMap[val.pointIndex!].xData ==
                                      "No Data") {
                                    // widget.parent!.setState(() {
                                    //   Util.selectedIndex = 2;
                                    //   objectFilter  = 5;
                                    // });
                                  }
                                },
                                dataSource: dataMap,
                                xValueMapper: (_PieData data, _) => data.xData,
                                yValueMapper: (_PieData data, _) => data.yData,
                                dataLabelMapper: (_PieData data, _) =>
                                    data.text,
                                pointColorMapper: (_PieData data, _) =>
                                    data.color,
                                dataLabelSettings: DataLabelSettings(
                                    isVisible: true,
                                    showZeroValue: false,
                                    labelPosition:
                                        ChartDataLabelPosition.inside,
                                    color: Colors.white30,
                                    useSeriesColor: true,
                                    borderColor: Colors.white30,
                                    borderWidth: 10,
                                    borderRadius: 0.2)),
                          ]))
                ],
              )
            ],
          )),
    );
  }

  Widget alertStatus(ColorProvider colorProvider) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, "/alerts");
      },
      child: Card(
        child: Container(
          padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'alerts')!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Divider(),
              // loadEventsData(),
              loadEventsData1(colorProvider)
            ],
          ),
        ),
      ),
    );
  }

  Widget loadEventsData1(ColorProvider colorProvider) {
    return Container(
      constraints: BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 10),
              // width: 280,
              // height: 52,
              // width: MediaQuery.of(context).size.width / 1.1,

              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey[300]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                      print("Today Alerts");
                    },
                    icon: Icon(
                      Icons.add_alert,
                      color: Provider.of<ColorProvider>(context, listen: false).primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'totalAlerts')!,
                      style: TextStyle(color: Colors.black),
                    ), //label text
                  ),
                  Text(eventList.length
                      .toString() /*,style: TextStyle(color: Colors.white)*/),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              //  width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.shade300),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _geofencealets;
                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                      print("Geofance");
                    },
                    icon: Icon(
                      Icons.fence,
                      color: Provider.of<ColorProvider>(context, listen: false).primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'geofences')!,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ), //label text
                  ),
                  Text(
                    _geofencealets.length.toString(),
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              // width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.grey[300],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _overspeedalets;
                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                      print("Overspeed");
                    },
                    icon: Icon(
                      Icons.speed,
                      color: Provider.of<ColorProvider>(context, listen: false).primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'overspeed')!,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ), //label text
                  ),
                  Text(
                    _overspeedalets.length.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              //  width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _idlealets;

                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                    },
                    icon: Icon(
                      Icons.park,
                      color: Colors.black,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'excessIdle')!,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ), //label text
                  ),
                  Text(
                    _idlealets.length.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              // width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _stopalets;

                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                    },
                    icon: Icon(
                      Icons.fire_truck,
                      color: colorProvider.primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'parked')!,
                      style: TextStyle(color: Colors.black),
                    ), //label text
                  ),
                  Text(_stopalets.length.toString(),
                      style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              //  width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                color: Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _ignitiononalets;
                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );

                      print("Ignition On");
                    },
                    icon: Icon(
                      Icons.key,
                      color: colorProvider.primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'ignitionOn')!,
                      style: TextStyle(color: Colors.black),
                    ), //label text
                  ),
                  Text(
                    _ignitiononalets.length.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10),
              margin: EdgeInsets.only(right: 13, top: 10),
              // width: 280,
              // height: 52,
              // width: MediaQuery.of(context).size.width / 2.3,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
                color: Colors.grey.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      // shape: RoundedRectangleBorder(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      // padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      // textStyle: TextStyle(
                      //     fontSize: 16,
                      //     fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      StaticVarMethod.eventList = _ignitionoffalets;

                      StaticVarMethod.notificationback = false;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                    },
                    icon: Icon(
                      Icons.key_off,
                      color: colorProvider.primaryColor,
                    ),
                    // icon: Image.asset(AssetsRes.WARNING, width: 25,),
                    label: Text(
                      getTranslated(context, 'ignitionOff')!,
                      style: TextStyle(color: Colors.black),
                    ), //label text
                  ),
                  Text(
                    _ignitionoffalets.length.toString(),
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loadEventsData() {
    return InkWell(
      onTap: () {
        StaticVarMethod.notificationback = false;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationsPage()),
        );
      },
      child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 10, right: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                AssetsRes.WARNING,
                width: 60,
              ),
              Text(
                '${TranslationHelper.translateSync(context, 'Alertas', 'Alerts')}: ${eventList.length}',
                style: TextStyle(
                    color: MyColor.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )),
    );
  }

  List<EventsData> _geofencealets = [];
  List<EventsData> _overspeedalets = [];
  List<EventsData> _idlealets = [];
  List<EventsData> _stopalets = [];
  List<EventsData> _ignitiononalets = [];
  List<EventsData> _ignitionoffalets = [];

  Future<void> getnotiList() async {
    gpsapis api = new gpsapis();
    try {
      eventList = await api.getEventsList(StaticVarMethod.user_api_hash);
      if (eventList.isNotEmpty) {
        for (int i = 0; i < eventList.length; i++) {
          EventsData model = eventList.elementAt(i);
          if (model.name.toString().toLowerCase().contains("geofance")) {
            _geofencealets.add(eventList.elementAt(i));
          } else if (model.name
              .toString()
              .toLowerCase()
              .contains("overspeed")) {
            _overspeedalets.add(eventList.elementAt(i));
          } else if (model.name.toString().toLowerCase().contains("idle")) {
            _idlealets.add(eventList.elementAt(i));
          } else if (model.name.toString().toLowerCase().contains("stop")) {
            _stopalets.add(eventList.elementAt(i));
          } else if (model.name
              .toString()
              .toLowerCase()
              .contains("ignition on")) {
            _ignitiononalets.add(eventList.elementAt(i));
          } else if (model.name
              .toString()
              .toLowerCase()
              .contains("ignition off")) {
            _ignitionoffalets.add(eventList.elementAt(i));
          }
        }
        if (mounted) {
          setState(() {});
        }
      } else {}
    } catch (e) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Não existe', 'Not exist'), 
        toastLength: Toast.LENGTH_SHORT
      );
    }
  }

  // Widget fleetIdle(){
  //   return Card(
  //       child:   Container(
  //           padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
  //           alignment: Alignment.centerLeft,
  //           child: Column(
  //               mainAxisAlignment: MainAxisAlignment.start,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(('fleetIdle').tr(), style: TextStyle(fontWeight: FontWeight.bold),),
  //                 Divider(),
  //               ]
  //           ))
  //   );
  // }

  Widget maintenanceRemainder() {
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, "/maintenanceRemainder");
        },
        child: Card(
            child: Container(
                padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
                alignment: Alignment.centerLeft,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, 'Lembrete de Manutenção', 'Maintenance Reminder'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      loadMaintenanceData()
                    ]))));
  }

  Widget loadMaintenanceData() {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10, right: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            AssetsRes.MAINTENANCE_REMAINDER,
            width: 50,
          ),
          Text(
            '${TranslationHelper.translateSync(context, 'Lembrete de Manutenção', 'Maintenance Reminder')}: 0',
            style: TextStyle(
                color: MyColor.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget RenewalRemainder() {
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, "/renewalRemainder");
        },
        child: Card(
            child: Container(
                padding: EdgeInsets.only(top: 10, left: 10, bottom: 5),
                alignment: Alignment.centerLeft,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, 'Lembrete de Renovação', 'Renewal Reminder'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Divider(),
                      loadRemainderData()
                    ]))));
  }

  Widget loadRemainderData() {
    List<dynamic> devices = [];

    // objectStore.objectSettings.forEach((key, value) {
    //   if(value[33] != "0000-00-00"){
    //     DateTime now = DateTime.now();
    //     DateTime date =  DateTime.parse(value[33].toString());
    //     if(now.isAfter(date)){
    //       devices.add(value);
    //     }
    //   }
    // });

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, "/renewalRemainder");
      },
      child: Container(
          padding: EdgeInsets.only(top: 10, bottom: 10, right: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                AssetsRes.CARD,
                width: 60,
              ),
              Text(
                '${TranslationHelper.translateSync(context, 'Lembrete de Renovação', 'Renewal Reminder')}: ${devices.length}',
                style: TextStyle(
                    color: MyColor.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )),
    );
  }

  Widget _buildSensorsSection(ColorProvider colorProvider) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: colorProvider.primaryColor, size: 24),
                SizedBox(width: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Sensores da Frota', 'Fleet Sensors'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Acesse a página de Sensores da Frota para visualizar informações detalhadas sobre os sensores dos veículos.', 'Access the Fleet Sensors page to view detailed information about vehicle sensors.'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FleetSensorsScreen()),
                );
              },
              icon: Icon(Icons.arrow_forward),
              label: Text(TranslationHelper.translateSync(context, 'Ver Sensores', 'View Sensors')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieData {
  _PieData(this.xData, this.yData, this.text, this.color);

  final String xData;
  final num yData;
  final String text;
  final Color color;
}
