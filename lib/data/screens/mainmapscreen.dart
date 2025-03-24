import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:blinking_text/blinking_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:maktrogps/config/apps/ecommerce/global_style.dart';
import 'package:maktrogps/config/custom_image_assets.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/screens/LiveMapScreen/LiveMapScreen.dart';
import 'package:maktrogps/data/screens/livetrackoriginal.dart';
import 'package:maktrogps/data/screens/playbackselection.dart';
import 'package:maktrogps/data/screens/reports/vehicle_info.dart';
import 'package:maktrogps/mapconfig/CustomColor.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as IMG;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/Session.dart';
import '../../config/constant.dart';
import '../../mvvm/view_model/objects.dart';
import '../model/devices.dart';
import 'livetrack.dart';

class mainmapscreen extends StatefulWidget {
  @override
  _mainmapscreen createState() => _mainmapscreen();
}

class _mainmapscreen extends State<mainmapscreen> {
  // initialize global widget
  final _globalWidget = GlobalWidget();

  late GoogleMapController _controller;
  bool _mapLoading = true;
  Timer? _timerDummy;

  bool _showMarker = true;
  bool _showTitle = true;
  double _currentZoom = 100;

  LatLng _initialPosition = LatLng(35.168033, 74.900467);
  Location currentLocation = Location();
  Set<Marker> _markers = {};
  Map<int, bool> _showDeviceMarker = {};
  int _showDeviceById = 0;
  String searchQueryDevice = "";

  /* List<LatLng> _markerList = [];*/

  Map<MarkerId, Marker> _allMarker = {};
  List<LatLng> _latlng = [];
  bool _isBound = false;
  bool _doneListing = false;
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  bool isshowvehicledetail = false;
  var _trafficButtonColor = Colors.grey[700];
  bool isshowvehiclecount = true;
  bool _searchEnabled = false;
  TextEditingController _etSearch = TextEditingController();

  List<deviceItems> _inactiveVehicles = [];
  List<deviceItems> _runningVehicles = [];
  List<deviceItems> _idleVehicles = [];
  List<deviceItems> _stoppedVehicles = [];

  List<deviceItems> devicesList = [];
  late ObjectStore objectStore;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetHeight: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<BitmapDescriptor> _createImageLabel(
      {String iconpath = '',
      String label = 'label',
      double fontSize = 20,
      double course = 0,
      Color color = Colors.red,
      bool showtitle = true}) async {
    return getMarkerIcon(iconpath, label, color, course, showtitle);
  }

  void _check(CameraUpdate u, GoogleMapController c) async {
    c.moveCamera(u);
    _controller.moveCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      _check(u, c);
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty);
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  // when the Google Maps Camera is change, get the current position
  void _onGeoChanged(CameraPosition position) {
    _currentZoom = position.zoom;
  }

  @override
  Widget build(BuildContext context) {
    StaticVarMethod.devicelist = [];
    objectStore = Provider.of<ObjectStore>(context);
    devicesList = objectStore.objects;

    StaticVarMethod.devicelist = devicesList;
    _runningVehicles = [];
    _idleVehicles = [];
    _stoppedVehicles = [];
    _inactiveVehicles = [];
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
      }
    }
    updateMarker();
    print("Map Builder");
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildGoogleMap(),
          Positioned(
            top: 30,
            left: 22,
            right: 55,
            child: (_searchEnabled)
                ? Container(
                    decoration: new BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 1.0),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _etSearch,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800 /*Colors.white*/),
                      onChanged: (value) {
                        setState(() {
                          print('text changed');
                          if (value.isNotEmpty) {
                            _filterdata(value);
                          } else {
                            _filterdata("All");
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
                                  _filterdata("All");

                                  _etSearch = TextEditingController(text: '');
                                  _searchEnabled =
                                      _searchEnabled == false ? true : false;
                                  //  });
                                },
                                child: Icon(Icons.close,
                                    color: Colors.grey[500], size: 16)),
                        focusedBorder: UnderlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0)),
                            borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: UnderlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    ),
                  )
                : Container(),
          ),
          Positioned(
            top: 242,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showMarker = (_showMarker) ? false : true;
                  for (int a = 0; a < _allMarker.length; a++) {
                    if (_allMarker[MarkerId(a.toString())] != null) {
                      _allMarker[MarkerId(a.toString())] =
                          _allMarker[MarkerId(a.toString())]!.copyWith(
                        visibleParam: _showMarker,
                      );
                    }
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.all(5),
                width: 36,
                height: 36,
                decoration: new BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                ),
                // color: Colors.white,
                //color: Color(0x99FFFFFF),
                child: (_showMarker)
                    ? Icon(
                        Icons.place,
                        color: Colors.black,
                        size: 20,
                      )
                    : Icon(
                        Icons.place_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showTitle = (_showTitle) ? false : true;
                  updateMarker();
                });
              },
              child: Container(
                padding: EdgeInsets.all(6),
                width: 36,
                height: 36,
                decoration: new BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                ),
                // color: Colors.white,
                //color: Color(0x99FFFFFF),
                child: (_showTitle)
                    ? Icon(
                        Icons.label,
                        color: Colors.black,
                        size: 20,
                      )
                    : Icon(
                        Icons.label_outline,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                _recenterall();
              },
              child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: new BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.0,
                        offset: const Offset(0.0, 1.0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          isshowvehiclecount =
                              isshowvehiclecount == false ? true : false;
                          _filterdata("All");
                          setState(() {});
                        },
                        child: Container(
                            height: 25,
                            width: 110,
                            alignment: Alignment.center,
                            //margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3),
                                      margin: EdgeInsets.only(
                                        left: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (Colors.grey.shade300),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                      ),
                                      child: ClipRRect(
                                          child: Image.asset(
                                        "assets/sensorsicon/dot.png",
                                        height: 10,
                                        width: 10,
                                      )),
                                    ),
                                    SizedBox(width: 8),
                                    Text(getTranslated(context, 'all')!,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 10,
                                        )),
                                  ],
                                ),
                                Text(devicesList.length.toString() + '   ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 10,
                                    )),
                              ],
                            )),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      (isshowvehiclecount)
                          ? Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _filterdata("Running");
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                      height: 25,
                                      width: 100,
                                      margin: EdgeInsets.only(left: 5),
                                      alignment: Alignment.center,
                                      //margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(0),
                                                margin: EdgeInsets.only(
                                                  left: 7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (Color(0xff24A651)),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(4)),
                                                ),
                                                child: ClipRRect(
                                                    child: Image.asset(
                                                  "assets/sensorsicon/dot.png",
                                                  height: 10,
                                                  width: 10,
                                                  color: Color(0xff24A651),
                                                )),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                  getTranslated(
                                                      context, 'running')!,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 10,
                                                  )),
                                              // SizedBox(width: 15),
                                            ],
                                          ),
                                          Text(
                                              /*'17'+*/
                                              _runningVehicles.length
                                                      .toString() +
                                                  '   ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 10,
                                              )),
                                        ],
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _filterdata("Idle");
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                      height: 25,
                                      width: 100,
                                      margin: EdgeInsets.only(left: 5),
                                      alignment: Alignment.center,
                                      //margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(0),
                                                margin: EdgeInsets.only(
                                                  left: 7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (Color(0xffF03B3B)),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(4)),
                                                ),
                                                child: ClipRRect(
                                                    child: Image.asset(
                                                  "assets/sensorsicon/dot.png",
                                                  height: 10,
                                                  width: 10,
                                                  color: Colors.yellow,

                                                  // color: Color(0xffF03B3B),
                                                )),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                  getTranslated(
                                                      context, 'idle')!,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 10,
                                                  )),
                                            ],
                                          ),
                                          Text(
                                              /*'13   '*/
                                              _idleVehicles.length.toString() +
                                                  '   ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 10,
                                              )),
                                        ],
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _filterdata("Stopped");
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                      height: 25,
                                      width: 100,
                                      margin: EdgeInsets.only(left: 5),
                                      alignment: Alignment.center,
                                      //margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(0),
                                                margin: EdgeInsets.only(
                                                  left: 7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (Color(0xffF03B3B)),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(4)),
                                                ),
                                                child: ClipRRect(
                                                    child: Image.asset(
                                                  "assets/sensorsicon/dot.png",
                                                  height: 10,
                                                  width: 10,
                                                  color: Color(0xffF03B3B),
                                                )),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                  getTranslated(
                                                      context, 'stop')!,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 10,
                                                  )),
                                            ],
                                          ),
                                          Text(
                                              /*'30   '*/
                                              _stoppedVehicles.length
                                                      .toString() +
                                                  '   ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 10,
                                              )),
                                        ],
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _filterdata("Inactive");
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                      height: 25,
                                      width: 100,
                                      margin: EdgeInsets.only(left: 5),
                                      alignment: Alignment.center,
                                      //margin: EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 0.8))),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(0),
                                                margin: EdgeInsets.only(
                                                  left: 7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (Color(0xff818181)),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(4)),
                                                ),
                                                child: ClipRRect(
                                                    child: Image.asset(
                                                  "assets/sensorsicon/dot.png",
                                                  height: 10,
                                                  width: 10,
                                                  color: Color(0xff818181),
                                                )),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                  getTranslated(
                                                      context, 'noData')!,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 10,
                                                  )),
                                            ],
                                          ),
                                          Text(
                                              /*'0   '*/
                                              _inactiveVehicles.length
                                                      .toString() +
                                                  '   ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 10,
                                              )),
                                        ],
                                      )),
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  )),
            ),
          ),
          Positioned(
            top: 80,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _trafficEnabledPressed();
              },
              child: Container(
                padding: EdgeInsets.all(6),
                width: 36,
                height: 36,
                decoration: new BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: (_trafficEnabled)
                    ? Icon(
                        Icons.traffic,
                        color: Colors.black,
                        size: 20,
                      )
                    : Icon(
                        Icons.traffic_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _onMapTypeButtonPressed();
              },
              child: Container(
                  padding: EdgeInsets.all(6),
                  width: 36,
                  height: 36,
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: const Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.layers,
                    color: Colors.black,
                    size: 20,
                  )),
            ),
          ),
          Positioned(
            top: 160,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                getLocation();
              },
              child: Container(
                  padding: EdgeInsets.all(5),
                  width: 36,
                  height: 36,
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Colors.black,
                    size: 20,
                  )),
            ),
          ),
          Positioned(
            bottom: 160,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                var currentZoomLevel = await _controller.getZoomLevel();

                currentZoomLevel = currentZoomLevel + 2;
                _controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _initialPosition,
                      zoom: 15.0,
                    ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(6),
                width: 36,
                height: 36,
                decoration: new BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.zoom_in,
                  color: Colors.grey[700],
                  size: 30,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                var currentZoomLevel = await _controller.getZoomLevel();
                currentZoomLevel = currentZoomLevel - 2;
                if (currentZoomLevel < 0) currentZoomLevel = 0;
                _controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _initialPosition,
                      zoom: currentZoomLevel,
                    ),
                  ),
                );
              },
              child: Container(
                  padding: EdgeInsets.all(6),
                  width: 36,
                  height: 36,
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: const Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.zoom_out,
                    color: Colors.grey[700],
                    size: 30,
                  )),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                _recenterall();
              },
              child: Container(
                  padding: EdgeInsets.all(5),
                  width: 36,
                  height: 36,
                  decoration: new BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: const Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  // color: Colors.white,
                  //color: Color(0x99FFFFFF),
                  child: Image.asset("assets/nepalicon/refresh.png",
                      height: 25, width: 25)),
            ),
          ),
          Positioned(
            right: (MediaQuery.of(context).size.width / 2) - 10,
            bottom: 120,
            child: GestureDetector(
              onTap: () {
                openSelectDeviceModal();
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.arrow_upward,
                ),
              ),
            ),
          ),
          (isshowvehicledetail) ? _buildVehicleDetail() : Container(),
          (_mapLoading)
              ? Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox.shrink()
        ],
      ),
    );
  }

  void openSelectDeviceModal() {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // START 1
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.black,
                      ),
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.3,
                    ),
                  ),
                  // END 1

                  // START 2
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                    child: Text(
                      "SELECIONE UM DISPOSITIVO",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  // END 2

                  // START 3 - Campo de busca
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar dispositivo...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQueryDevice =
                              value; // Atualiza o texto de busca
                        });
                      },
                    ),
                  ),
                  // END 3

                  // START 4
                  SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: getFilteredVehiclesList(context),
                    ),
                  ),

                  SizedBox(height: 50)
                  // END 4
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> getFilteredVehiclesList(BuildContext ctx) {
    // Filtra a lista de dispositivos com base no texto de busca
    final filteredDevices = devicesList.where((device) {
      // Se o campo de busca estiver vazio, retorna true para todos os dispositivos
      if (searchQueryDevice.isEmpty) {
        return true;
      }
      // Caso contrário, verifica se o nome do dispositivo contém o texto de busca (ignorando case)
      return device.name!
          .toLowerCase()
          .contains(searchQueryDevice.toLowerCase());
    }).toList();

    return filteredDevices
        .asMap()
        .map(
          (index, element) => MapEntry(
            element.id,
            InkWell(
              onTap: () {
                setState(() {
                  if (mounted) {
                    _showDeviceById = element.id!;
                  }
                  _latlng.clear();
                  _markers.clear();
                  _allMarker.clear();
                  updateMarker();
                });
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          width: 25.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _showDeviceById == element.id!
                                ? Colors.black
                                : Theme.of(context).colorScheme.onPrimary,
                            border: Border.all(color: Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: _showDeviceById == element.id!
                                ? Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 17.0,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 15.0,
                          ),
                          child: Text(
                            element.name!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  List<Widget> getVehiclesList(BuildContext ctx) {
    return devicesList
        .asMap()
        .map(
          (index, element) => MapEntry(
            element.id,
            InkWell(
              onTap: () {
                setState(() {
                  if (mounted) {
                    _showDeviceById = element.id!;
                    _allMarker.clear();
                    _latlng.clear();
                    updateMarker();
                    // RESTO DAS AÇÕES NECESSÁRIAS
                  }
                });
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 25.0,
                          width: 25.0,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showDeviceById == element.id!
                                  ? Colors.black
                                  : Theme.of(context).colorScheme.onPrimary,
                              border: Border.all(color: Colors.black)),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: _showDeviceById == element.id!
                                ? Icon(
                                    Icons.check,
                                    size: 17.0,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  )
                                : Icon(
                                    Icons.check_box_outline_blank,
                                    size: 17.0,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 15.0,
                            ),
                            child: Text(
                              element.name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(color: Colors.black),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .values
        .toList();
  }

  void _filterdata(String val) async {
    _allMarker.clear();
    StaticVarMethod.devicelist = [];
    if (val.contains("All")) {
      StaticVarMethod.devicelist = devicesList;
    } else if (devicesList.isNotEmpty) {
      for (int i = 0; i < devicesList.length; i++) {
        deviceItems model = devicesList.elementAt(i);

        String other = model.deviceData!.traccar!.other.toString();
        String ignition = "false";
        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }

        if (val.contains("Idle") &&
            ignition.contains("true") &&
            double.parse(model.speed.toString()) < 1.0) {
          StaticVarMethod.devicelist.add(devicesList.elementAt(i));
        } else if (val.contains("Inactive") &&
            model.online.toString().toLowerCase().contains("offline") &&
            model.time.toString().toLowerCase().contains("not connected")) {
          StaticVarMethod.devicelist.add(devicesList.elementAt(i));
        } else if (val.contains("Running") &&
            model.online.toString().toLowerCase().contains("online")) {
          StaticVarMethod.devicelist.add(devicesList.elementAt(i));
        } else if (val.contains("Stopped") &&
            ignition.contains("false") &&
            model.time.toString().toLowerCase() != "not connected") {
          StaticVarMethod.devicelist.add(devicesList.elementAt(i));
        }
      }
    }

    if (mounted) {
      setState(() {
        updateMarker();
      });
    }
  }

  Widget _buildVehicleDetail() {
    double imageSize = MediaQuery.of(context).size.width / 25;
    var devicelist = devicesList
        .where((i) => i.deviceData!.imei!.contains(StaticVarMethod.imei))
        .single;

    double lat = devicelist.lat!.toDouble();
    double lng = devicelist.lng!.toDouble();
    double course = devicelist.course!.toDouble();
    int speed = devicelist.speed!.toInt();
    String imei = devicelist.deviceData!.imei.toString();
    String carstatus = devicelist.online!.toString();

    // String address=getAddress(lat,lng);
    Color statuscolor = Colors.red;
    if (speed > 0) {
      statuscolor = Colors.green;
    } else {
      statuscolor = Colors.red;
    }
    return Positioned(
        bottom: 100,
        right: 0,
        left: 0,
        child: Align(
            alignment: Alignment.bottomCenter,
            //left: 16,
            child: Container(
              margin: EdgeInsets.fromLTRB(3, 0, 3, 0),
              child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                  color: Colors.white,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        prefixIcon(devicelist.speed, devicelist.stopDuration,
                            statuscolor),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                            ),
                            padding: EdgeInsets.fromLTRB(10, 2, 10, 0),
                            margin: EdgeInsets.only(left: 5),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Fluttertoast.showToast(
                                        msg: 'Clique ${devicelist.name}',
                                        toastLength: Toast.LENGTH_SHORT);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                                margin:
                                                    EdgeInsets.only(top: 12),
                                                child:
                                                    //Center(
                                                    Text(
                                                  '' +
                                                      devicelist.name
                                                          .toString(),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.blue.shade900),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                                //   )
                                                ),
                                            Row(children: [
                                              Container(
                                                margin:
                                                    EdgeInsets.only(top: 10),
                                                padding: EdgeInsets.all(5),

                                                decoration: BoxDecoration(
                                                  color: statuscolor,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(
                                                              10.0)),
                                                ),
                                                // color: statuscolor,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                        (speed > 0)
                                                            ? 'Em movimento: ' +
                                                                devicelist
                                                                    .stopDuration!
                                                            : 'Parado: ' +
                                                                devicelist
                                                                    .stopDuration!,
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white))
                                                  ],
                                                ),
                                              ),
                                            ]),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          left: 8,
                                                          top: 12,
                                                          bottom: 15),
                                                      child: Column(
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {
                                                              address =
                                                                  "Carregando....";
                                                              setState(() {});
                                                              getAddress(
                                                                  lat, lng);
                                                            },
                                                            child: RichText(
                                                              maxLines: 5,
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              text: TextSpan(
                                                                  text: address,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade700,
                                                                  ),
                                                                  children: []),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ]),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        postfixIcon(
                            devicelist.name, devicelist.id, lat, lng, imei),
                      ])),
            )));
  }

  Widget postfixIcon(name, id, lat, lng, imei) {
    return Container(
        //width: 40,
        margin: EdgeInsets.only(top: 0, right: 0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  //width: 40,
                  margin: EdgeInsets.all(10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isshowvehicledetail = false;
                      });

                      setState(() {
                        isshowvehicledetail = false;
                      });
                      setState(() {
                        isshowvehicledetail = false;
                      });
                    },
                    child: Image.asset("assets/nepalicon/cancel.png",
                        height: 20, width: 20),
                  )),
              // Container(
              //     //width: 40,
              //     margin: EdgeInsets.only(top: 10, right: 10),
              //     child: GestureDetector(
              //       onTap: () {
              //         StaticVarMethod.deviceName = name.toString();
              //         StaticVarMethod.deviceId = id.toString();
              //         StaticVarMethod.lat = lat;
              //         StaticVarMethod.lng = lng;
              //         StaticVarMethod.imei = imei.toString();
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //               builder: (context) => LiveMapScreen()),
              //         );
              //       },
              //       child: Image.asset("assets/nepalicon/live_tracking.png",
              //           height: 30, width: 30),
              //     )
              // ),
            ]));
  }

  Widget prefixIcon(speed, stopDuration, statuscolor) {
    return Container(
        //width: 40,
        margin: EdgeInsets.only(top: 30, left: 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //  Text("" + (int.parse(speed.toString())/1.6093).toStringAsFixed(0),
              Text("" + speed.toString(),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: statuscolor)),
              Text(/*"KM/H"*/ 'km/h',
                  style: TextStyle(
                      fontSize: 12,
                      //fontWeight: FontWeight.bold,
                      color: statuscolor)),
            ])

        /* child: Icon(Icons.notifications,
          size: 25,
          color:Colors.grey.shade700),*/
        );
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _trafficEnabledPressed() {
    setState(() {
      _trafficEnabled = _trafficEnabled == false ? true : false;
      _trafficButtonColor =
          _trafficEnabled == false ? Colors.grey[700] : Colors.blue;
    });
  }

  void _recenterall() {
    CameraUpdate u2 =
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_latlng), 200);
    this._controller.moveCamera(u2).then((void v) {
      _check(u2, this._controller);
      // Ajuste o zoom após recarregar
      _controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _initialPosition,
          zoom: 15.0, // Ajuste o valor do zoom aqui para um valor menor
        ),
      ));
    });
  }

  void getLocation() async {
    final Uint8List markIcons =
        await getImages("assets/nepalicon/globe.png", 100);
    var location = await currentLocation.getLocation();

    _controller
        ?.animateCamera(CameraUpdate.newCameraPosition(new CameraPosition(
      target: LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0),
      zoom: 15.0,
    )));
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('Home'),
          icon: BitmapDescriptor.fromBytes(markIcons),
          position:
              LatLng(location.latitude ?? 0.0, location.longitude ?? 0.0)));
    });
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      mapType: _currentMapType,
      trafficEnabled: _trafficEnabled,
      compassEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      mapToolbarEnabled: false,
      markers: Set<Marker>.of(_allMarker.values),
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 15.0,
      ),
      onCameraMove: _onGeoChanged,
      onCameraIdle: () {
        if (_isBound == false && _doneListing == true) {
          _isBound = true;
          CameraUpdate u2 =
              CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_latlng), 50);
          this._controller.moveCamera(u2).then((void v) {
            _check(u2, this._controller);
          });
        }
      },
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;

        // we use timer for this demo
        // in the real application, get all marker from database
        // Get the marker from API and add the marker here
        _timerDummy = Timer(Duration(seconds: 2), () {
          setState(() {
            _mapLoading = false;
            updateMarker();
            // zoom to all marker
            // if (_isBound == false /*&& _doneListing==true*/) {
            //   _isBound = true;
            //   CameraUpdate u2 = CameraUpdate.newLatLngBounds(
            //       _boundsFromLatLngList(_latlng), 15.0);
            //   this._controller.moveCamera(u2).then((void v) {
            //     _check(u2, this._controller);
            //   });
            // }
            _recenterall();
            _mapLoading = false;
          });
        });
      },
      onTap: (pos) {
        print('currentZoom : ' + _currentZoom.toString());
      },
    );
  }

  updateMarker() {
    try {
      _initialPosition = LatLng(
          devicesList[0].lat!.toDouble(), devicesList[0].lng!.toDouble());
    } catch (Ex) {
      print(Ex);
      print(" _initialPosition Error occurred");
      //History model = new  History();
      // return model;
    }

    for (int i = 0; i < devicesList.length; i++) {
      if (_showDeviceById == devicesList[i].id) {
        String other = devicesList[i].deviceData!.traccar!.other.toString();

        String baseUrl = "https://web.unnicatelemetria.com.br/";
        String? deviceIconPath = devicesList[i].icon?.path;
        String deviceIconFullPath = baseUrl + (deviceIconPath ?? '');

        String ignition = "false";

        if (other.contains("<ignition>")) {
          const start = "<ignition>";
          const end = "</ignition>";
          final startIndex = other.indexOf(start);
          final endIndex = other.indexOf(end, startIndex + start.length);
          ignition = other.substring(startIndex + start.length, endIndex);
        }
        if (devicesList[i].lat != 0) {
          var color;
          var label;

          if (devicesList[i].speed!.toInt() > 0) {
            color = Colors.green;
            label = devicesList[i].name.toString() +
                '(' +
                devicesList[i].speed!.toString() +
                ' km)';
          } else if (devicesList[i].online!.contains('engine')) {
            color = Colors.yellow;
            label = devicesList[i].name.toString();
          } else if (devicesList[i].online!.contains('online')) {
            color = Colors.green;
            label = devicesList[i].name.toString();
          } else if (devicesList[i].online!.contains('ack')) {
            color = Colors.red;
            label = devicesList[i].name.toString();
          } else if (devicesList[i].online!.contains('offline')) {
            color = Colors.blue;
            label = devicesList[i].name.toString();
          }

          double lat = devicesList[i].lat as double;
          double lng = devicesList[i].lng as double;

          LatLng position = LatLng(lat, lng);
          _latlng.add(position);

          _createImageLabel(
                  iconpath: deviceIconFullPath,
                  label: label,
                  course: devicesList[i].course.toDouble(),
                  color: color,
                  showtitle: _showTitle)
              .then((BitmapDescriptor customIcon) {
            _mapLoading = false;
            _allMarker[MarkerId(i.toString())] = Marker(
                markerId: MarkerId(i.toString()),
                position: position,
                onTap: () {
                  _initialPosition =
                      LatLng(position.latitude, position.longitude);
                  StaticVarMethod.imei =
                      StaticVarMethod.devicelist[i].deviceData!.imei.toString();
                  setState(() {
                    isshowvehicledetail = true;
                  });
                },
                anchor: Offset(0.5, 0.5),
                icon: customIcon);
          });

          if (i == devicesList.length - 1) {
            _doneListing = true;
          }
        }
      }
    }
  }

  String address = "Clique para ver o endereço!";

  String getAddress(lat, lng) {
    if (lat != null) {
      gpsapis.getGeocoder(lat, lng).then((value) => {
            if (value != null)
              {
                address = value.body,
                setState(() {}),
              }
            else
              {address = "Endereço não encontrado"}
          });
    } else {
      address = "Endereço não encontrado";
    }
    print(address);
    return address;
  }
}

Future<BitmapDescriptor> getMarkerIcon(String imagePath, String infoText,
    Color color, double rotateDegree, bool _showTitle) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  //size
  Size canvasSize = Size(700.0, 220.0);
  Size markerSize = Size(120.0, 120.0);
  late TextPainter textPainter;
  if (_showTitle) {
    // Add info text
    textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: infoText,
      style:
          TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: color),
    );
    textPainter.layout();
  }

  final Paint infoPaint = Paint()..color = Colors.white;
  final Paint infoStrokePaint = Paint()..color = color;
  final double infoHeight = 70.0;
  final double strokeWidth = 2.0;

  //final Paint markerPaint = Paint()..color = color.withOpacity(0);
  final double shadowWidth = 30.0;

  final Paint borderPaint = Paint()
    ..color = color
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final double imageOffset = shadowWidth * .5;

  canvas.translate(
      canvasSize.width / 2, canvasSize.height / 2 + infoHeight / 2);

  // Oval for the image
  Rect oval = Rect.fromLTWH(
      -markerSize.width / 2 + .5 * shadowWidth,
      -markerSize.height / 2 + .5 * shadowWidth,
      markerSize.width - shadowWidth,
      markerSize.height - shadowWidth);

  //save canvas before rotate
  canvas.save();

  double rotateRadian = (pi / 180.0) * rotateDegree;

  //Rotate Image
  canvas.rotate(rotateRadian);

  // Add path for oval image
  canvas.clipPath(Path()..addOval(oval));

  ui.Image image;
  // Add image
  // if(imagePath.contains("arrow-ack.png")){
  image = await getImageFromPathUrl(imagePath);
  // image = await getImageFromPath("assets/images/direction.png");
  /* }else{
    image = await getImageFromPathUrl(imagePath);

  }*/

  paintImage(canvas: canvas, image: image, rect: oval, fit: BoxFit.fitHeight);

  canvas.restore();
  if (_showTitle) {
    // Add info box stroke
    canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
              -textPainter.width / 2 - infoHeight / 2,
              -canvasSize.height / 2 - infoHeight / 2 + 1,
              textPainter.width / 2 + infoHeight / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1,
              Radius.circular(35.0)))
          ..moveTo(-15, -canvasSize.height / 2 + infoHeight / 2 + 1)
          ..lineTo(0, -canvasSize.height / 2 + infoHeight / 2 + 25)
          ..lineTo(15, -canvasSize.height / 2 + infoHeight / 2 + 1),
        infoStrokePaint);

    //info info box
    canvas.drawPath(
        Path()
          ..addRRect(RRect.fromLTRBR(
              -textPainter.width / 2 - infoHeight / 2 + strokeWidth,
              -canvasSize.height / 2 - infoHeight / 2 + 1 + strokeWidth,
              textPainter.width / 2 + infoHeight / 2 - strokeWidth,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth,
              Radius.circular(32.0)))
          ..moveTo(-15 + strokeWidth / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth)
          ..lineTo(
              0, -canvasSize.height / 2 + infoHeight / 2 + 25 - strokeWidth * 2)
          ..lineTo(15 - strokeWidth / 2,
              -canvasSize.height / 2 + infoHeight / 2 + 1 - strokeWidth),
        infoPaint);
    textPainter.paint(
        canvas,
        Offset(
            -textPainter.width / 2,
            -canvasSize.height / 2 -
                infoHeight / 2 +
                infoHeight / 2 -
                textPainter.height / 2));

    canvas.restore();
  }

  final ui.Image markerAsImage = await pictureRecorder
      .endRecording()
      .toImage(canvasSize.width.toInt(), canvasSize.height.toInt());

  final ByteData? byteData =
      await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List? uint8List = byteData?.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(uint8List!);
}

Future<ui.Image> getImageFromPath(String imagePath) async {
  var bd = await rootBundle.load(imagePath);
  Uint8List imageBytes = Uint8List.view(bd.buffer);

  final Completer<ui.Image> completer = new Completer();

  ui.decodeImageFromList(imageBytes, (ui.Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

Future<ui.Image> getImageFromPathUrl(String imagePath) async {
  final response = await http.Client().get(Uri.parse(imagePath));
  final bytes = response.bodyBytes;

  final Completer<ui.Image> completer = new Completer();

  ui.decodeImageFromList(bytes, (ui.Image img) {
    return completer.complete(img);
  });

  return completer.future;
}
