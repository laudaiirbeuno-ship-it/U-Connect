import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:blinking_text/blinking_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maktrogps/config/constant.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/model/devices.dart';
import 'package:maktrogps/data/model/history.dart';

import 'package:maktrogps/data/screens/playbackselection.dart';
import 'package:maktrogps/data/screens/reports/reportselection.dart';

import 'package:maktrogps/data/screens/vehicle_dasboard.dart';

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
import 'LiveMapScreen/LiveMapScreen.dart';

import 'lockscreenNew.dart';
import 'reports/kmdetail.dart';

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

  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> markers = new Set();

  Color primaryColor = Color(0xff0540ac);
  Color secondaryColor = Color(0xFF050A30);

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

  GoogleMapController? _controller;
  bool _mapLoading = true;
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
      backgroundColor: secondaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: (_searchEnabled)
            ? Container(
                  child: TextFormField(
                    controller: _etSearch,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        print('text changed');
                        if (value.isNotEmpty) {
                          filterSearchResults(value);
                        } else {
                          _vehiclesData.clear();
                          filtertext = "All";
                          print("full list");
                        }
                      });
                    },
                    decoration: InputDecoration(
                      fillColor: Colors.transparent,
                      filled: true,
                      hintText: 'Nome do rastreador, imei...',
                      hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.white
                      ),
                      prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white, size: 18
                      ),
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
            : Text(
          'Veículos',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        bottom: PreferredSize(
          child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                        color: secondaryColor,
                        width: 1.0,
                      )),
                  color: secondaryColor
              ),
              padding: EdgeInsets.fromLTRB(5, 10, 10, 0),
              height: 120,
              child: ListView(
                padding: EdgeInsets.all(10),
                children: [
                  Text(
                      "Filtrar",
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: filterSelected,
                    elevation: 16,
                    style: const TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Colors.white),
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
                    items: carstatusList
                        .map<DropdownMenuItem<String>>((String value) {
                      String txtVal = "";

                      // Define o texto a ser exibido no dropdown
                      if (value == "All Vehicle") {
                        txtVal = getTranslated(context, 'all')! +
                            " (" +
                            _vehiclesData.length.toString() +
                            ")";
                      } else if (value == "Running") {
                        txtVal = getTranslated(context, 'running')! +
                            " (" +
                            _runningVehicles.length.toString() +
                            ")";
                      } else if (value == "Stopped") {
                        txtVal = getTranslated(context, 'stopped')! +
                            " (" +
                            _stoppedVehicles.length.toString() +
                            ")";
                      } else if (value == "Idle") {
                        txtVal = getTranslated(context, 'idle')! +
                            " (" +
                            _idleVehicles.length.toString() +
                            ")";
                      } else if (value == "In Active") {
                        txtVal = getTranslated(context, 'offline')! +
                            " (" +
                            _inactiveVehicles.length.toString() +
                            ")";
                      } else if (value == "Expired") {
                        txtVal = getTranslated(context, 'noData')! +
                            " (" +
                            _noDataVehicles.length.toString() +
                            ")";
                      }

                      // Retorna o DropdownMenuItem com o valor correto
                      return DropdownMenuItem<String>(
                        value: value,
                        // O valor que será atribuído a filterSelected
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
                color: Colors.white /*Colors.white*/,
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
      itemCount: _vehiclesData_duplicate.length,
      itemBuilder: (context, index) =>
          _buildItem(_vehiclesData_duplicate[index], boxImageSize, index),
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

    String iconpath = 'assets/tbtrack/car_sidestop.png';
    if (productData.time!.contains('Not connected')) {
      iconpath = 'assets/tbtrack/car_sideinactive.png';
      devicestatus = "Not connected";
      statuscolor = Colors.blue;
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}sideinactive.png";
    } else if (productData.speed!.toInt() > 0) {
      iconpath = 'assets/tbtrack/car_siderunning.png';
      devicestatus = "Moving";
      statuscolor = Colors.green;
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}siderunning.png";
    } else if (productData.online!.contains('engine')) {
      iconpath = 'assets/tbtrack/car_sideidle.png';
      devicestatus = "Idle";
      statuscolor = Colors.yellow;
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}sideidle.png";
    } else if (productData.online!.contains('online')) {
      iconpath = 'assets/tbtrack/car_siderunning.png';
      devicestatus = "Online";
      statuscolor = Colors.green;
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}siderunning.png";
    } else if (productData.online!.contains('ack')) {
      iconpath = 'assets/tbtrack/car_sidestop.png';
      statuscolor = Colors.red;

      devicestatus = "Stopped";
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}sidestop.png";
    } else {
      iconpath = 'assets/tbtrack/car_sideinactive.png';
      devicestatus = "Not connected";
      statuscolor = Colors.blue;
      if (StaticVarMethod.pref_static!
          .get(productData.deviceData!.imei.toString()) !=
          null)
        iconpath =
        "assets/tbtrack/${StaticVarMethod.pref_static!.get(productData.deviceData!.imei.toString())}sideinactive.png";
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
                //color: Colors.transparent,
                  height: MediaQuery.of(context).size.height / 1.6,
                  child: _showDeliveryPopup());
            },
          );
          //Fluttertoast.showToast(msg: 'Click ${productData.name}', toastLength: Toast.LENGTH_SHORT);
        },
        child: Column(
          children: [
            // Street views here...
            Container(
              margin: EdgeInsets.fromLTRB(3, 0, 3, 3),
              //padding:EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                color: statuscolor,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  padding: EdgeInsets.all(0),
                  margin: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      _buildGoogleMap(lat, lng, course, imei),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin: EdgeInsets.only(top: 0),
                                        padding: EdgeInsets.all(0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(15)),
                                        ),
                                        child: Image.asset(iconpath,
                                            height: 80, width: 80)),
                                    Row(children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 8, 15),
                                        child: Image.asset(
                                            "assets/tbtrack/outlinedcircle.png",
                                            height: 8,
                                            width: 8),
                                      ),
                                      Container(
                                        height: 30,
                                        width: 60,
                                        child: Text(
                                          '${productData.deviceData!.name}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff494C60),
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                  ],
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      height: 140,
                                      width: 106,
                                      //color:Colors.yellowAccent,
                                      child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 11, 0, 5),
                                              child: Text(
                                                getTranslated(
                                                    context, 'lastUpdate')!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 0, 0, 2),
                                              child: Text(
                                                getTranslated(
                                                    context, 'total')!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                  height: 3,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 2, 0, 0),
                                              child: Text(
                                                getTranslated(
                                                    context, 'engineHours')!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                  height: 2,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 0, 0, 0),
                                              child: Text(
                                                getTranslated(
                                                    context, 'speed')!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                  height: 2,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 3, 0, 0),
                                              child: Text(
                                                getTranslated(
                                                    context, 'stopDuration')!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                  height: 2,
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ),
                                    Container(
                                      height: 140,
                                      width: 10,
                                      // color:Colors.white,
                                      child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  0, 15, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/fillcircle.png",
                                                  height: 6,
                                                  width: 6,
                                                  color: Color(0xff7E3885)),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 2, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 2, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 2, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 2, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 2, 0, 3),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Image.asset(
                                                "assets/tbtrack/fillcircle.png",
                                                height: 6,
                                                width: 6,
                                                color: Color(0xffE83F82)),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 3),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Image.asset(
                                                "assets/tbtrack/fillcircle.png",
                                                height: 6,
                                                width: 6,
                                                color: Color(0xff26C090)),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 3),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Image.asset(
                                                "assets/tbtrack/fillcircle.png",
                                                height: 6,
                                                width: 6,
                                                color: Color(0xffBD712E)),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Container(
                                              padding:
                                              const EdgeInsets.fromLTRB(
                                                  2, 1, 0, 3),
                                              child: Image.asset(
                                                  "assets/tbtrack/ellipse.png",
                                                  height: 2.5,
                                                  width: 2.5,
                                                  color: Colors.black26),
                                            ),
                                            Image.asset(
                                                "assets/tbtrack/fillcircle.png",
                                                height: 6,
                                                width: 6,
                                                color: Color(0xffA731F7)),
                                          ]),
                                    ),
                                    Container(
                                      height: 140,
                                      width: 75,
                                      child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  0, 10, 10, 0),
                                              // padding:  EdgeInsets.fromLTRB(5, 11, 10, 0),
                                              child: Text(
                                                productData.time.toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                  height: 0,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 11, 0, 0),
                                              child: Text(
                                                '$totaldistance mi',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 11, 0, 0),
                                              child: Text(
                                                '$enginehours h',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 11, 0, 0),
                                              child: Text(
                                                '$speed km/ h',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.fromLTRB(
                                                  0, 5, 0, 0),
                                              child: Text(
                                                productData.stopDuration
                                                    .toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ),
                                    (productData.sensors == null)
                                        ? Container(
                                      height: 140,
                                      width: 20,
                                      //color:Colors.blue,
                                      child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(0, 10, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/frozen.png",
                                                  height: 15,
                                                  width: 15,
                                                  color: Colors.black38),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                //color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(0, 15, 0, 0),
                                              child: Image.asset(
                                                "assets/tbtrack/battery.png",
                                                height: 18,
                                                width:
                                                18, //color:Colors.black38
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                //color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(0, 15, 0, 0),
                                              child: Image.asset(
                                                "assets/tbtrack/signal.png",
                                                height: 15,
                                                width:
                                                15, //color:Colors.black38
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(0, 15, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/circle.png",
                                                  height: 20,
                                                  width: 20,
                                                  color: Colors.black38),
                                            ),
                                          ]),
                                    )
                                        : (productData.sensors!.isNotEmpty)
                                        ? Container(
                                      height: 140,
                                      width: 60,
                                      child: ListView.builder(
                                          scrollDirection:
                                          Axis.vertical,
                                          itemCount: productData
                                              .sensors!.length,
                                          itemBuilder:
                                              (context, index) {
                                            return Padding(
                                              padding:
                                              const EdgeInsets
                                                  .only(
                                                  left: 15.0,
                                                  right: 8,
                                                  top: 10),
                                              child: Container(
                                                  child: Column(
                                                      children: <Widget>[
                                                        productData
                                                            .sensors![
                                                        index]
                                                            .type
                                                            .toString()
                                                            .toLowerCase() ==
                                                            'ignition'
                                                            ? Image.asset(
                                                            "assets/saftyappicon/ignintion.png",
                                                            height:
                                                            imageSize,
                                                            width:
                                                            imageSize)
                                                            : productData
                                                            .sensors![
                                                        index]
                                                            .type
                                                            .toString()
                                                            .toLowerCase() ==
                                                            'engine'
                                                            ? Image.asset(
                                                            "assets/saftyappicon/ignintion.png",
                                                            height:
                                                            imageSize,
                                                            width:
                                                            imageSize)
                                                            : productData.sensors![index].type.toString().toLowerCase() ==
                                                            'sat'
                                                            ? Image.asset(
                                                            "assets/saftyappicon/sattelite.png",
                                                            height: imageSize,
                                                            width: imageSize)
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'odometer'
                                                            ? Image.asset("assets/saftyappicon/odomenetr.png", height: imageSize, width: imageSize)
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'battery'
                                                            ? Image.asset(
                                                          "assets/saftyappicon/battery.png",
                                                          height: imageSize,
                                                          width: imageSize,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'charge'
                                                            ? Image.asset(
                                                          "assets/saftyappicon/charge_icon.png",
                                                          height: imageSize,
                                                          width: imageSize,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'engine lock'
                                                            ? Icon(
                                                          Icons.hourglass_bottom_rounded,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'gps'
                                                            ? Icon(
                                                          Icons.gps_fixed_outlined,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'gsm'
                                                            ? Image.asset(
                                                          "assets/saftyappicon/gsmicon.png",
                                                          height: imageSize,
                                                          width: imageSize,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'moving'
                                                            ? Icon(
                                                          Icons.moving_outlined,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'gps starting km'
                                                            ? Icon(
                                                          Icons.gps_fixed_outlined,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'temp'
                                                            ? Icon(
                                                          FontAwesomeIcons.temperatureLow,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : productData.sensors![index].type.toString().toLowerCase() == 'engine_hours'
                                                            ? Icon(
                                                          Icons.alarm,
                                                          size: 16,
                                                          color: themeDark,
                                                        )
                                                            : Image.asset("assets/saftyappicon/mileage.png", height: imageSize, width: imageSize, color: themeDark),
                                                        Text(
                                                            productData
                                                                .sensors![
                                                            index]
                                                                .name
                                                                .toString(),
                                                            style: TextStyle(
                                                                fontSize:
                                                                7,
                                                                height:
                                                                1.5,
                                                                color:
                                                                themeDark)),
                                                        Text(
                                                            "${productData.sensors![index].value.toString()}",
                                                            style: TextStyle(
                                                                fontSize:
                                                                7,
                                                                height: 1,
                                                                color:
                                                                themeDark))
                                                      ])),
                                            );
                                          }),
                                    )
                                        : Container(
                                      height: 140,
                                      child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(
                                                  0, 10, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/frozen.png",
                                                  height: 15,
                                                  width: 15,
                                                  color:
                                                  Colors.black38),
                                            ),
                                            Container(
                                              decoration:
                                              BoxDecoration(
                                                //color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(
                                                  0, 15, 0, 0),
                                              child: Image.asset(
                                                "assets/tbtrack/battery.png",
                                                height: 18,
                                                width:
                                                18, //color:Colors.black38
                                              ),
                                            ),
                                            Container(
                                              decoration:
                                              BoxDecoration(
                                                //color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(
                                                  0, 15, 0, 0),
                                              child: Image.asset(
                                                "assets/tbtrack/signal.png",
                                                height: 15,
                                                width:
                                                15, //color:Colors.black38
                                              ),
                                            ),
                                            Container(
                                              decoration:
                                              BoxDecoration(
                                                //color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      20)),
                                              margin: const EdgeInsets
                                                  .fromLTRB(
                                                  0, 15, 0, 0),
                                              child: Image.asset(
                                                  "assets/tbtrack/circle.png",
                                                  height: 20,
                                                  width: 20,
                                                  color:
                                                  Colors.black38),
                                            ),
                                          ]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                addressLoad(lat.toString(), lng.toString()),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
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
                                        Image.asset(
                                            "assets/images/movingdurationicon.png",
                                            height: imageSize,
                                            width: imageSize),
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
                                        Image.asset(
                                            "assets/images/icons8-bar-chart-100.png",
                                            height: imageSize,
                                            width: imageSize),
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
                                        Image.asset(
                                            "assets/images/icons8-play-100.png",
                                            height: imageSize,
                                            width: imageSize),
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
                                      Image.asset(
                                          "assets/images/icons8-bar-chart-100.png",
                                          height: imageSize,
                                          width: imageSize),
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
                                      Image.asset(
                                          "assets/images/icons8-play-100.png",
                                          height: imageSize,
                                          width: imageSize),
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
                                      Image.asset(
                                          "assets/images/icons8-info-popup-100.png",
                                          height: imageSize,
                                          width: imageSize),
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
                                      Image.asset(
                                          "assets/speedoicon/assets_images_shareicon.png",
                                          height: imageSize,
                                          width: imageSize),
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
              height: 32,
              width: 310,
              padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Text(
                (snapshot.data!.replaceAll('"', '')),
                style: TextStyle(
                    color: Colors.black, fontFamily: "Popins", fontSize: 9),
              ),
            );
          } else {
            return Text("loading...");
          }
        });
  }
}
