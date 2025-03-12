import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:blinking_text/blinking_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jiffy/jiffy.dart';
import 'package:maktrogps/bloc/kmandfuelhistory/bloc/kmandfuelhistory_bloc.dart';
import 'package:maktrogps/config/constant.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/model/devices.dart';
import 'package:maktrogps/data/model/history.dart';
import 'package:maktrogps/data/model/loginModel.dart';
import 'package:maktrogps/data/model/product_model.dart';
import 'package:maktrogps/data/screens/historyscreen.dart';
import 'package:maktrogps/data/screens/livetrackoriginal.dart';
import 'package:maktrogps/data/screens/mainmapscreenoriginal.dart';
import 'package:maktrogps/data/screens/notificationscreen.dart';
import 'package:maktrogps/data/screens/optionsscreen/alloptions.dart';
import 'package:maktrogps/data/screens/playback.dart';
import 'package:maktrogps/data/screens/playbackscreen.dart';
import 'package:maktrogps/data/screens/playbackselection.dart';
import 'package:maktrogps/data/screens/reports/reportselection.dart';
import 'package:maktrogps/data/screens/reports/vehicle_info.dart';
import 'package:maktrogps/data/screens/task/tasks.dart';
import 'package:maktrogps/data/screens/testscreens/livelocation.dart';
import 'package:maktrogps/data/screens/trip/tripinfoselectionscreen.dart';
import 'package:maktrogps/data/screens/vehicle_dasboard.dart';
import 'package:maktrogps/mapconfig/CustomColor.dart';
import 'package:maktrogps/ui/reusable/cache_image_network.dart';
import 'package:maktrogps/ui/reusable/global_function.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'package:maktrogps/ui/reusable/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/Session.dart';
import '../../mvvm/view_model/objects.dart';
import '../../utils/MapUtils.dart';
import 'LiveMapScreen/LiveMapScreen.dart';
import 'commands/CommandWindow.dart';
import 'livetrack.dart';
import 'package:intl/intl.dart';
import 'lockscreen.dart';

import 'lockscreenNew.dart';
import 'reports/kmdetail.dart';
import 'package:http/http.dart' as http;


class listscreen extends StatefulWidget {
  @override
  _listscreen createState() => _listscreen();
}

class _listscreen extends State<listscreen>
    with SingleTickerProviderStateMixin {
  // initialize global function and global widget
  final _globalFunction = GlobalFunction();
  final _globalWidget = GlobalWidget();
  final _shimmerLoading = ShimmerLoading();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
  ItemPositionsListener.create();

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  PersistentBottomSheetController? _bottomSheetController;

  String filtertext = "All";
  bool _loading = true;

  Set<Marker> markers = new Set();
  final Completer<GoogleMapController> _mapController = Completer();

  Color _color1 = Color(0xff777777);
  Color _color2 = Color(0xFF515151);
  Color _topSearchColor = Colors.white;
  List<deviceItems> _vehiclesData = [];
  List<deviceItems> _vehiclesData_sorted = [];
  List<deviceItems> _vehiclesData_duplicate = [];

  // _listKey is used for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  TextEditingController _etSearch = TextEditingController();

  int _tabIndex = 0;

  bool _mapLoading = true;
  GoogleMapController? _controller;
  static Color primaryDark = const Color.fromARGB(255, 13, 61, 101);
  double _currentZoom = 14;

//  final LatLng _initialPosition = LatLng(-6.168033, 106.900467);

  Marker? _marker;

  late BitmapDescriptor _markerDirection = BitmapDescriptor.defaultMarker;

  List<String> carstatusList = [
    'All Vehicle',
    'Running',
    'Stopped',
    'Idle',
    'In Active',
    'Expired'
  ];
  int starIndex = 0;
  Color CHARCOAL = Color(0xFF515151);
  bool _searchEnabled = false;
  List<deviceItems> _inactiveVehicles = [];
  List<deviceItems> _runningVehicles = [];
  List<deviceItems> _idleVehicles = [];
  List<deviceItems> _stoppedVehicles = [];
  List<deviceItems> _noDataVehicles = [];
  late SharedPreferences prefs;
  late ObjectStore objectStore;
  String? filterSelected;

  // KmandfuelHistoryBloc kmhistorybloc = KmandfuelHistoryBloc();
  @override
  void initState() {
    // kmhistorybloc.add(KmandfuelHistoryInitialFetchEvent());
    checkPreference();
    _setSourceAndDestinationIcons();
    filterSelected = carstatusList.first;
    super.initState();
  }

  void _setSourceAndDestinationIcons() async {
    _markerDirection = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/images/direction.png');
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _etSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // StaticVarMethod.devicelist.clear();
    objectStore = Provider.of<ObjectStore>(context);
    _vehiclesData = objectStore.objects;
    _runningVehicles = [];
    _idleVehicles = [];
    _stoppedVehicles = [];
    _inactiveVehicles = [];
    _noDataVehicles = [];

    if (_vehiclesData.isNotEmpty) {
      _vehiclesData_duplicate.clear();
      _vehiclesData_sorted.clear();
      _vehiclesData_sorted.addAll(_vehiclesData);

      if (filtertext != "All") {
        for (int i = 0; i < _vehiclesData_sorted.length; i++) {
          deviceItems model = _vehiclesData_sorted.elementAt(i);

          String other = model.deviceData!.traccar!.other.toString();
          String ignition = "false";
          if (other.contains("<ignition>")) {
            const start = "<ignition>";
            const end = "</ignition>";
            final startIndex = other.indexOf(start);
            final endIndex = other.indexOf(end, startIndex + start.length);
            ignition = other.substring(startIndex + start.length, endIndex);
          }
          if (filtertext == "Idle") {
            if (model.online.toString().toLowerCase().contains("engine")) {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('Idle');
            }
          } else if (filtertext == "In Active") {
            if (model.online.toString().toLowerCase().contains("offline")) {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('Offline');
            }
          } else if (filtertext == "Running") {
            if (model.online.toString().toLowerCase().contains("online")) {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('online');
            }
          } else if (filtertext == "Stopped") {
            if (model.online.toString().toLowerCase().contains("ack") &&
                model.time.toString().toLowerCase() != "not connected") {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('stoppedvehile');
            }
          } else if (filtertext == "Expired") {
            if (model.time.toString().toLowerCase().contains("expire")) {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('expire');
            }
          } else {
            if (model.name.toString().toLowerCase().contains(filtertext
                .toLowerCase()) /*||
                  model.devicedata!.first.imei!.contains(query.toLowerCase())*/
            ) {
              _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
              print('item exists');
            }
          }
        }
      } else {
        _vehiclesData_duplicate.addAll(_vehiclesData);
      }

      StaticVarMethod.devicelist = _vehiclesData;

      for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
        deviceItems model = StaticVarMethod.devicelist.elementAt(i);
        String other = model.deviceData!.traccar!.other.toString();
        String ignition = "false";
        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }
        if (model.online.toString().toLowerCase().contains("engine")) {
          _idleVehicles.add(StaticVarMethod.devicelist.elementAt(i));
        } else if (model.online.toString().toLowerCase().contains("offline")) {
          _inactiveVehicles.add(StaticVarMethod.devicelist.elementAt(i));
        } else if (model.online.toString().toLowerCase().contains("online")) {
          _runningVehicles.add(StaticVarMethod.devicelist.elementAt(i));
        } else if (model.online.toString().toLowerCase().contains("ack")) {
          _stoppedVehicles.add(StaticVarMethod.devicelist.elementAt(i));
        } else if (model.time.toString().toLowerCase() == "not connected") {
          _noDataVehicles.add(StaticVarMethod.devicelist.elementAt(i));
        }
      }

      _loading = false;
    } else {
      print("not available");
      _loading = false;
      _vehiclesData_duplicate.clear();
      _vehiclesData_sorted.clear();
    }

    final double boxImageSize = (MediaQuery.of(context).size.width / 12);

    Widget? _child;
    if (_loading == true) {
      _child = const Center(child: CircularProgressIndicator());
    } else if (_vehiclesData_duplicate.isNotEmpty) {
      _child = new RefreshIndicator(
        onRefresh: refreshData,
        child: (_loading == true)
            ? _shimmerLoading.buildShimmerContent()
            : devicesListwidget(boxImageSize),
      );
    } else if (_vehiclesData_duplicate.isEmpty) {
      _child = new RefreshIndicator(
        onRefresh: refreshData,
        child: (_loading == true)
            ? _shimmerLoading.buildShimmerContent()
            : Container(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: (_searchEnabled)
            ? Container(
          child: TextFormField(
            controller: _etSearch,
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800 /*Colors.white*/),
            onChanged: (value) {
              setState(() {
                print('text changed');
                if (value.isNotEmpty) {
                  filterSearchResults(value);
                } else {
                  _vehiclesData.clear();
                  filtertext = "All";
                  // setState(() {
                  //_getData();
                  print("full list");
                  //  });
                }
              });
            },
            decoration: InputDecoration(
              fillColor: Colors.transparent,
              filled: true,
              hintText: 'Enter device name or IMEI',
              hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800 /*Colors.white*/),
              prefixIcon: Icon(Icons.search,
                  color: Colors.black /*Colors.white*/, size: 18),
              suffixIcon: (_etSearch.text == '')
                  ? null
                  : GestureDetector(
                  onTap: () {
                    filtertext = "All";
                    //setState(() {
                    //_getData();
                    _etSearch = TextEditingController(text: '');
                    _searchEnabled =
                    _searchEnabled == false ? true : false;
                    //  });
                  },
                  child: Icon(Icons.close,
                      color: Colors.grey[500], size: 16)),
              focusedBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0)),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
        )
            : Container(
          child: Row(
            spacing: 16,
            children: [
              Icon(
                  Icons.car_rental,
                  color: Colors.black,
              ),
              Text(
                'Veículos',
                style: TextStyle(
                  color: Colors.black,
                ),
              )
            ],
          ),
        ),
        // backgroundColor: themeDark,
        backgroundColor: Colors.grey.shade300,
        bottom: PreferredSize(
          child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      )),
                  color: Colors.white),
              padding: EdgeInsets.fromLTRB(5, 10, 10, 0),
              height: 120,
              child: ListView(
                padding: EdgeInsets.all(10),
                children: [
                  Text("Filtrar"),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: filterSelected,
                    elevation: 16,
                    style: const TextStyle(color: Colors.black),
                    underline: Container(height: 1, color: Colors.grey),
                    onChanged: (String? value) {
                      setState(() {
                        filterSelected = value; // Atualiza o valor selecionado
                        if (value == "All Vehicle") {
                          filterSearchResults("All");
                        } else if (value == "Running") {
                          filterSearchResults("Running");
                        } else if (value == "Stopped") {
                          filterSearchResults("Stopped");
                        } else if (value == "Idle") {
                          filterSearchResults("Idle");
                        } else if (value == "In Active") {
                          filterSearchResults("In Active");
                        } else if (value == "Expired") {
                          filterSearchResults("expire");
                        }
                      });
                    },
                    items: carstatusList.map<DropdownMenuItem<String>>((String value) {
                      String txtVal = "";

                      // Define o texto a ser exibido no dropdown
                      if (value == "All Vehicle") {
                        txtVal = getTranslated(context, 'all')! + " (" + _vehiclesData.length.toString() + ")";
                      } else if (value == "Running") {
                        txtVal = getTranslated(context, 'running')! + " (" + _runningVehicles.length.toString() + ")";
                      } else if (value == "Stopped") {
                        txtVal = getTranslated(context, 'stopped')! + " (" + _stoppedVehicles.length.toString() + ")";
                      } else if (value == "Idle") {
                        txtVal = getTranslated(context, 'idle')! + " (" + _idleVehicles.length.toString() + ")";
                      } else if (value == "In Active") {
                        txtVal = getTranslated(context, 'offline')! + " (" + _inactiveVehicles.length.toString() + ")";
                      } else if (value == "Expired") {
                        txtVal = getTranslated(context, 'noData')! + " (" + _noDataVehicles.length.toString() + ")";
                      }

                      // Retorna o DropdownMenuItem com o valor correto
                      return DropdownMenuItem<String>(
                        value: value, // O valor que será atribuído a filterSelected
                        child: Text(txtVal), // O texto a ser exibido
                      );
                    }).toList(),
                  )
                ],
              )),
          preferredSize: Size.fromHeight(120),
        ),
        actions: [
          IconButton(
              icon: Icon(
                (_searchEnabled) ? Icons.clear_rounded : Icons.search,
                color: Colors.grey.shade800 /*Colors.white*/,
                size: 26,
              ),
              onPressed: () {
                setState(() {
                  filtertext = "All";
                  //setState(() {
                  // _getData();
                  _etSearch = TextEditingController(text: '');
                  _searchEnabled = _searchEnabled == false ? true : false;
                });
              }),
        ],
      ),
      body: _child,
    );
  }

  Widget devicesListwidget(double boxImageSize) {
    return ScrollablePositionedList.builder(
      key: _listKey,
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      itemCount: _vehiclesData_duplicate.length + 1, // Adiciona 1 para o espaçamento
      itemBuilder: (context, index) {
        if (index == _vehiclesData_duplicate.length) {
          // Retorna um SizedBox para o espaçamento
          return SizedBox(height: 125); // Ajuste a altura conforme necessário
        }
        return _buildItem(_vehiclesData_duplicate[index], boxImageSize, index);
      },
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
    );
  }

  void filterSearchResults(String query) {
    filtertext = query;
    print("inside filter");
    _vehiclesData_duplicate.clear();
    if (query.isNotEmpty && query != "All") {
      for (int i = 0; i < _vehiclesData_sorted.length; i++) {
        deviceItems model = _vehiclesData_sorted.elementAt(i);

        String other = model.deviceData!.traccar!.other.toString();
        String ignition = "false";
        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }
        if (query == "Idle") {
          if (model.online.toString().toLowerCase().contains("engine")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Idle');
          }
        } else if (query == "In Active") {
          if (model.online.toString().toLowerCase().contains("offline")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print(model.online.toString());
            print('Offline');
          }
        } else if (query == "Running") {
          if (model.online.toString().toLowerCase().contains("online")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Running');
          }
        } else if (query == "Stopped") {
          if (model.online.toString().toLowerCase().contains("ack")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('Stopped');
            print(model.online.toString());
          }
        } else if (query == "expire") {
          if (model.time.toString().toLowerCase().contains("expire")) {
            _vehiclesData_duplicate.add(_vehiclesData_sorted.elementAt(i));
            print('expire');
          }
        }
      }

    } else {
      if (query == "All") {
        _vehiclesData_duplicate.addAll(_vehiclesData_sorted);
        print('All');
      }
    }
  }

  Color randomColor() =>
      Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0);

  Widget _buildItem(deviceItems productData, boxImageSize, index) {
    double imageSize = MediaQuery.of(context).size.width / 25;
    double lat = productData.lat!.toDouble();
    double lng = productData.lng!.toDouble();
    double course = productData.course!.toDouble();
    int speed = productData.speed!.toInt();
    String imei = productData.deviceData!.imei.toString();
    String carstatus = productData.online!.toString();
    String time = productData.time.toString();
    String stoppedTime = productData.stopDuration.toString();

    Color statuscolor = Colors.red;

    String other = productData.deviceData!.traccar!.other.toString();
    String ignition = "false";
    String enginehours = "0h";
    String sat = "0";
    String totaldistance = "0";
    String distance = "0";
    String devicestatus = "0";

    if (other.contains("<ignition>")) {
      const start = "<ignition>";
      const end = "</ignition>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      ignition = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<enginehours>")) {
      const start = "<enginehours>";
      const end = "</enginehours>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      int hours =
      int.parse(other.substring(startIndex + start.length, endIndex));
      enginehours = (hours / 3600).toStringAsFixed(2);
    }
    if (other.contains("<sat>")) {
      const start = "<sat>";
      const end = "</sat>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      sat = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<totaldistance>")) {
      const start = "<totaldistance>";
      const end = "</totaldistance>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      double dis =
      double.parse(other.substring(startIndex + start.length, endIndex));
      totaldistance = (dis / 1000).toStringAsFixed(2);
      // totaldistance = other.substring(startIndex + start.length, endIndex);
    }
    if (other.contains("<distance>")) {
      const start = "<distance>";
      const end = "</distance>";
      final startIndex = other.indexOf(start);
      final endIndex = other.indexOf(end, startIndex + start.length);
      distance = other.substring(startIndex + start.length, endIndex);
    }

    String labelStatusType = "not_connected";

    if (productData.time!.contains('Not connected')) {

      devicestatus = "Not connected";
      labelStatusType = "not_connected";
      statuscolor = Colors.blue;

    } else if (productData.speed!.toInt() > 0) {

      devicestatus = "Moving";
      labelStatusType = "moving";
      statuscolor = Colors.green;

    } else if (productData.online!.contains('engine')) {
      devicestatus = "Idle";
      labelStatusType = "idle ";
      statuscolor = Colors.yellow;
    } else if (productData.online!.contains('online')) {

      devicestatus = "Online";
      labelStatusType = "online";
      statuscolor = Colors.green;

    } else if (productData.online!.contains('ack')) {

      statuscolor = Colors.red;
      labelStatusType = "stopped";
      devicestatus = "Stopped";

    } else {

      devicestatus = "Not connected";
      labelStatusType = "not_connected";
      statuscolor = Colors.blue;

    }

    return GestureDetector(
        onTap: () {
          StaticVarMethod.deviceName = productData.name.toString();
          StaticVarMethod.deviceId = productData.id.toString();
          StaticVarMethod.imei = productData.deviceData!.imei.toString();
          StaticVarMethod.simno = productData.deviceData!.simNumber.toString();
          StaticVarMethod.lat = productData.lat!.toDouble();
          StaticVarMethod.lng = productData.lng!.toDouble();
          StaticVarMethod.devicestatus = devicestatus;
          StaticVarMethod.devicestatuscolor = statuscolor;

          showModalBottomSheet<void>(
            context: context,
            //isDismissible: false,
            //barrierColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return Container(
                  height: MediaQuery.of(context).size.height / 1.6,
                  child: _showDeliveryPopup());
            },
          );
        },
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(3, 0, 3, 3),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                color: statuscolor,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  padding: EdgeInsets.all(0),
                  margin: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      _buildGoogleMap(lat, lng, course, imei),
                      _buildCardSectionOne(productData, labelStatusType, statuscolor),
                      _buildDivider(),
                      // Verifica se há sensores antes de chamar a função
                      if (productData.sensors != null && productData.sensors!.isNotEmpty)
                        _buildCardSectionSensors(productData),
                      // _buildDivider(),
                      _buildCardSectionAddress(productData, lat, lng),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1, // Altura da linha
      width: double.infinity, // Largura total
      margin: EdgeInsets.symmetric(horizontal: 20), // Margem lateral
      color: Colors.grey[300], // Cor da linha
    );
  }

  // Supondo que productData.time seja uma String no formato '2025-03-12 01:37:29'
  String formatDate(String dateString) {
    try {
      // Tenta converter a string para um objeto DateTime
      DateTime dateTime = DateTime.parse(dateString);

      // Formata a data no formato desejado
      String formattedDate = DateFormat('dd/MM/yyyy \'às\' HH:mm:ss').format(dateTime);

      return formattedDate;
    } catch (e) {
      // Se ocorrer um erro, retorna a mensagem padrão
      return 'Ainda não conectado';
    }
  }

  Widget _buildCardSectionAddress(deviceItems productData, double lat, double lng) {
    String lastUpdated = 'Última Atualização em ' + formatDate(productData.time.toString());

    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informações do Endereço
          addressLoad(lat.toString(), lng.toString()),
          SizedBox(height: 5), // Espaçamento entre os textos
          // Data de Atualização
          Text(
            lastUpdated, // Texto da última atualização
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSectionSensors(deviceItems productData) {
    List<Sensors>? allSensors = productData.sensors;

    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Define a rolagem horizontal
            child: Row(
              children: allSensors!.map((sensor) {
                IconData sensorIcon = _getSensorIconData(sensor.type ?? '');
                return Row(
                  children: [
                    _buildSensorIconCard(sensorIcon, sensor.name ?? 'Desconhecido', sensor.value ?? 'N/A'),
                    SizedBox(width: 10), // Espaço entre os sensores
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSensorIconData(String sensorType) {
    // Define um ícone default
    IconData retIcon = Icons.help; // Ícone padrão para sensores desconhecidos
    switch (sensorType) {
      case "acc":
        retIcon = Icons.access_alarm; // Acelerômetro
        break;
      case "anonymizer":
        retIcon = Icons.privacy_tip; // Anonimizador
        break;
      case "battery":
        retIcon = Icons.battery_full; // Bateria
        break;
      case "battery_external":
        retIcon = Icons.battery_charging_full; // Bateria externa
        break;
      case "counter":
        retIcon = Icons.countertops; // Contador
        break;
      case "datetime":
        retIcon = Icons.calendar_today; // Data e hora
        break;
      case "door":
        retIcon = Icons.door_front_door; // Porta ON/OFF
        break;
      case "engine":
        retIcon = Icons.motorcycle; // Motor ON/OFF (usando ícone de motocicleta como alternativa)
        break;
      case "engine_hours":
        retIcon = Icons.access_time; // Horas do motor
        break;
      case "fuel_consumption":
        retIcon = Icons.local_gas_station; // Consumo de combustível
        break;
      case "fuel_tank":
        retIcon = Icons.local_gas_station; // Tanque de combustível
        break;
      case "gsm":
        retIcon = Icons.signal_cellular_alt; // GSM
        break;
      case "harsh_acceleration":
        retIcon = Icons.speed; // Aceleração brusca
        break;
      case "harsh_breaking":
        retIcon = Icons.warning; // Quebra brusca (usando ícone de aviso)
        break;
      case "harsh_turning":
        retIcon = Icons.rotate_right; // Viragem brusca
        break;
      case "ignition":
        retIcon = Icons.power; // Ignição ON/OFF
        break;
      case "load":
        retIcon = Icons.file_upload; // Carga
        break;
      case "logical":
        retIcon = Icons.code; // Lógico
        break;
      case "numerical":
        retIcon = Icons.format_list_numbered; // Numérico
        break;
      case "odometer":
        retIcon = Icons.speed; // Odômetro
        break;
      case "plugged":
        retIcon = Icons.power; // Plugado
        break;
      case "rfid":
        retIcon = Icons.radio; // RFID
        break;
      case "satellites":
        retIcon = Icons.public; // Satélites
        break;
      case "seatbelt":
        retIcon = Icons.check; // Cinto de segurança ON/OFF
        break;
      case "speed_ecm":
        retIcon = Icons.speed; // Velocidade ECM
        break;
      case "tachometer":
        retIcon = Icons.speed; // Tacômetro
        break;
      case "temperature":
        retIcon = Icons.thermostat; // Temperatura
        break;
      case "textual":
        retIcon = Icons.text_fields; // Textual
        break;
      case "vin":
        retIcon = Icons.vpn_key; // VIN
        break;
      default:
        retIcon = Icons.help; // Ícone padrão para sensores desconhecidos
        break;
    }

    return retIcon;
  }

  // Função auxiliar para criar o card de velocidade
  Widget _buildSensorIconCard(IconData icon, String label, String card_value) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícone e Informações do Veículo
          Row(
            children: [
              // Ícone do carro
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  icon, // Ícone do carro

                  color: Colors.black,
                ),
              ),
              SizedBox(width: 10), // Espaçamento entre o ícone e o texto
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, // Número do veículo
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12
                    ),
                  ),
                  Text(
                    card_value, // Tipo do veículo
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                        fontSize: 12
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardSectionOne(deviceItems productData, String labelStatusType, Color statusColor) {
    String baseUrl = "https://web.unnicatelemetria.com.br/";
    String? deviceIconPath = productData.icon?.path;
    String deviceIconFullPath = baseUrl + (deviceIconPath ?? '');

    String deviceName = productData.name.toString();

    String labelStatus = "Não Conectado";

    switch (labelStatusType) {
      case "not_connected":
        labelStatus = "Não Conectado";
        break;
      case "moving":
        labelStatus = "Em movimento";
        break;
      case "idle":
        labelStatus = "Parado";
        break;
      case "online":
        labelStatus = "Ligado";
        break;
      case "stopped":
        labelStatus = "Parado";
        break;
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícone e Informações do Veículo
          Row(
            children: [
              // Ícone do carro
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Image.network(
                  deviceIconFullPath, // URL do ícone do carro
                  width: 40, // Largura do ícone
                  height: 40, // Altura do ícone
                  fit: BoxFit.scaleDown, // Ajusta a imagem para caber no container
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.directions_car_filled, // Ícone padrão em caso de erro
                      color: Colors.black,
                    );
                  },
                ),
              ),
              SizedBox(width: 10), // Espaçamento entre o ícone e o texto
              Container(
                width: 130, // Defina a largura fixa desejada
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName, // Número do veículo
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Adiciona reticências se o texto for muito longo
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Botão de Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: statusColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              labelStatus, // Texto do botão
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _showDeliveryPopup() {
    double imageSize = MediaQuery.of(context).size.width / 17;
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter mystate) {
          return Container(
              margin: EdgeInsets.only(left: 10, right: 10, bottom: 140),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(
                        top: 12,
                      ),
                      child: Text('${StaticVarMethod.deviceName}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 12, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        //  builder: (context) => livetrack()),
                                          builder: (context) => LiveMapScreen()),
                                    );
                                  },
                                  child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: new BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.rectangle,
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(15)),
                                        // borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 1.0,
                                            //offset: const Offset(0.0, 10.0),
                                          ),
                                        ],
                                      ),
                                      // color: Colors.white,
                                      //color: Color(0x99FFFFFF),
                                      child: Column(children: <Widget>[
                                        Icon(
                                          Icons.map_outlined,
                                          color: Colors.black,
                                        ),
                                        Text(
                                            getTranslated(context, 'liveTracking')!,
                                            style:
                                            TextStyle(fontSize: 12, height: 2))
                                      ])),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => kmdetail()),
                                    );
                                  },
                                  child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: new BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.rectangle,
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(15)),
                                        // borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 1.0,
                                            //offset: const Offset(0.0, 10.0),
                                          ),
                                        ],
                                      ),
                                      // color: Colors.white,
                                      //color: Color(0x99FFFFFF),
                                      child: Column(children: <Widget>[
                                        Icon(
                                          Icons.query_stats_outlined,
                                          color: Colors.black,
                                        ),
                                        Text(getTranslated(context, 'mileage')!,
                                            style: TextStyle(
                                                fontSize: 12, height: 2.0))
                                      ])),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              playbackselection()),
                                    );
                                  },
                                  child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: new BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.rectangle,
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(15)),
                                        // borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 1.0,
                                            //offset: const Offset(0.0, 10.0),
                                          ),
                                        ],
                                      ),
                                      // color: Colors.white,
                                      //color: Color(0x99FFFFFF),
                                      child: Column(children: <Widget>[
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.black,
                                        ),
                                        Text(getTranslated(context, 'playback')!,
                                            style: TextStyle(
                                                fontSize: 12, height: 2.0))
                                      ])),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => reportselection()),
                                  );
                                },
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: new BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                      // borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 1.0,
                                          //offset: const Offset(0.0, 10.0),
                                        ),
                                      ],
                                    ),
                                    // color: Colors.white,
                                    //color: Color(0x99FFFFFF),
                                    child: Column(children: <Widget>[
                                      Icon(
                                        Icons.summarize_outlined,
                                        color: Colors.black,
                                      ),
                                      Text(getTranslated(context, 'reports')!,
                                          style:
                                          TextStyle(fontSize: 12, height: 2.0))
                                    ])),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //       builder: (context) => CommandWindowPage()),
                                  // );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => lockscreenNew()),
                                  );
                                },
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: new BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                      // borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 1.0,
                                          //offset: const Offset(0.0, 10.0),
                                        ),
                                      ],
                                    ),
                                    // color: Colors.white,
                                    //color: Color(0x99FFFFFF),
                                    child: Column(children: <Widget>[
                                      Icon(
                                        Icons.terminal_outlined,
                                        color: Colors.black,
                                      ),
                                      Text(getTranslated(context, 'command')!,
                                          style:
                                          TextStyle(fontSize: 12, height: 2.0))
                                    ])),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(

                                      // builder: (context) => tripinfoselectionscreen()),
                                      // builder: (context) => vehicle_info()),
                                        builder: (context) => vehicle_dasboard()),
                                  );

                                  //_onMapTypeButtonPressed();
                                },
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: new BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                      // borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 1.0,
                                          //offset: const Offset(0.0, 10.0),
                                        ),
                                      ],
                                    ),
                                    // color: Colors.white,
                                    //color: Color(0x99FFFFFF),
                                    child: Column(children: <Widget>[
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.black,
                                      ),
                                      Text(getTranslated(context, 'device_info')!,
                                          style:
                                          TextStyle(fontSize: 12, height: 2.0))
                                    ])),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap: () async {
                                  String url =
                                      "https://www.google.com/maps/search/?api=1&query=${StaticVarMethod.lat},${StaticVarMethod.lng}";

                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else {
                                    throw 'Could not open the map.';
                                  }
                                },
                                child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: new BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                      // borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 1.0,
                                          //offset: const Offset(0.0, 10.0),
                                        ),
                                      ],
                                    ),
                                    // color: Colors.white,
                                    //color: Color(0x99FFFFFF),
                                    child: Column(children: <Widget>[
                                      Icon(
                                        Icons.share_outlined,
                                        color: Colors.black,
                                      ),
                                      Text(getTranslated(context, 'share')!,
                                          style:
                                          TextStyle(fontSize: 12, height: 2.0))
                                    ])),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ));
        });
  }

  // add marker
  Set<Marker> getmarkers(double lat, double lng, double course, String imei) {
    LatLng position = LatLng(lat, lng);

    // set initial marker
    markers.add(Marker(
      markerId: MarkerId(imei),
      anchor: Offset(0.5, 0.5),
      position: position,
      rotation: course,
      icon: _markerDirection,
    ));

    if (_controller != null) {
      _controller!
          .animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
    }

    return markers;
  }

  void _check(CameraUpdate u, GoogleMapController c) async {
    c.moveCamera(u);
    _controller!.moveCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      _check(u, c);
  }

  // when the Google Maps Camera is change, get the current position
  void _onGeoChanged(CameraPosition position) {
    _currentZoom = position.zoom;
  }

  Future<BitmapDescriptor> getBitmapDescriptorFromUrl(String url) async {
    // Baixe a imagem da URL
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Converta a imagem em bytes
      Uint8List bytes = response.bodyBytes;
      // Crie um BitmapDescriptor a partir dos bytes
      return BitmapDescriptor.fromBytes(bytes);
    } else {
      throw Exception('Falha ao carregar a imagem do ícone');
    }
  }

  // GOOGLE MAP WIDGET
  Widget _buildGoogleMap(double lat, double lng, double course, String imei) {
    return Container(
        padding: EdgeInsets.only(bottom: 5),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero),
          // Ajuste o valor conforme necessário
          boxShadow: [
            BoxShadow(
              color: Colors.black12, // Sombra opcional
              // spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 1), // Sombra abaixo do container
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.zero,
              bottomRight: Radius.zero),
          child: GoogleMap(
            mapType: MapType.normal,
            trafficEnabled: false,
            //compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            mapToolbarEnabled: true,
            markers: getmarkers(lat, lng, course, imei),
            //markers: Set.of((_marker != null) ? [_marker!] : []),
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: _currentZoom,
            ),
            // onCameraMove: _onGeoChanged,
            onCameraMove: (cameraPosition) {
              lat = cameraPosition.target.longitude; //gets the center longitude
              lng = cameraPosition.target.latitude; //gets the center lattitude
            },
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              Timer(Duration(milliseconds: 500), () {
                setState(() {
                  _mapLoading = true;

                  _controller!.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17));
                  // Fluttertoast.showToast(
                  //     msg:
                  //     '_controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17));',
                  //     toastLength: Toast.LENGTH_SHORT);
                });
              });
            },
            onTap: (pos) {
              print('currentZoom : $_currentZoom');
            },
          ),
        ));
  }

  void showPopupDeleteFavorite(index, boxImageSize) {
    // set up the buttons
    Widget cancelButton = TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text('No', style: TextStyle(color: SOFT_BLUE)));
    Widget continueButton = TextButton(
        onPressed: () {
          int removeIndex = index;

          // Remove the item from the data list.
          var removedItem = _vehiclesData.removeAt(removeIndex);

          // Use the AnimatedList's removeItem method to trigger the animation.
          _listKey.currentState!.removeItem(
            removeIndex,
                (BuildContext context, Animation<double> animation) {
              // Build the widget for the removed item during the animation.
              return SizeTransition(
                sizeFactor: animation,
                child: _buildItem(removedItem, boxImageSize, removeIndex),
              );
            },
          );

          // Navigate back and show a toast message.
          Navigator.pop(context);
          Fluttertoast.showToast(
            msg: 'Item has been deleted from your favorites',
            toastLength: Toast.LENGTH_SHORT,
          );
        },
        child: Text('Yes', style: TextStyle(color: SOFT_BLUE)));

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Text(
        'Delete Favorite',
        style: TextStyle(fontSize: 18),
      ),
      content: Text('Are you sure to delete this item from your Favorite ?',
          style: TextStyle(fontSize: 13, color: _color1)),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future refreshData() async {
    // IMPLEMENTAR ATUALIZAÇÃO DE DADOS
  }

  Widget kmandfueldetail(int deviceId) {
    var dev = deviceId;
    return FutureBuilder<History>(
        future: gpsapis.getHistory(deviceId),
        builder: (context, AsyncSnapshot<History> snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '${snapshot.data!.distanceSum} mi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0.00',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0 km',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 11, 0, 0),
                  child: Text(
                    '0.00',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            );
          }
        });
  }

  Widget addressLoad(String lat, String lng) {
    return FutureBuilder<String>(
      future: gpsapis.geocode(lat, lng),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Container(
            child: Text(
              (snapshot.data!.replaceAll('"', '')),
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              maxLines: 2,
            ),
          );
        } else {
          return Text("Carregando...");
        }
      },
    );
  }
}
