import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/model/PlayBackRoute.dart';
import 'package:maktrogps/data/model/PositionHistory.dart';
import 'package:maktrogps/data/model/history.dart';
import 'package:maktrogps/mapconfig/CommonMethod.dart';
import 'package:maktrogps/mapconfig/CustomColor.dart';

import '../../config/Session.dart';



class PlaybackPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  MapType _currentMapType = MapType.normal;
  bool _isPlaying = false;
  var _isPlayingIcon = Icons.pause_circle_outline;
  bool _trafficEnabled = false;
  Color _trafficButtonColor = CustomColor.primaryColor;
  Set<Marker> _markers = Set<Marker>();
  double currentZoom = 14.0;
  late StreamController<dynamic> _postsController;
  late Timer _timer;
  late Timer timerPlayBack;
  late List<PlayBackRoute> routeList = [];
  late List<PlayBackRoute> tripList = [];
  late bool isLoading;
  double pinPillPosition = 0;

  int _sliderValue = 0;
  int _sliderValueMax = 0;
  int playbackTime = 600;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  List<Choice> choices = [];

  late Choice _selectedChoice; // The app's "state".

  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice.title =='slow') {
      playbackTime = 600;
      timerPlayBack.cancel();
      playRoute();
    } else if (_selectedChoice.title =='medium') {
      playbackTime = 400;
      timerPlayBack.cancel();
      playRoute();
    } else if (_selectedChoice.title =='fast') {
      playbackTime = 100;
      timerPlayBack.cancel();
      playRoute();
    }
  }



  int _selectedperiod = 0;
  double _dialogHeight = 300.0;
  int _selectedTripInfoPeriod = 0;
  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();

  var selectedToTime =  TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoToTime =  TimeOfDay.fromDateTime(DateTime.now());
  var selectedFromTime =  TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoFromTime =  TimeOfDay.fromDateTime(DateTime.now());
  var fromTime=        DateFormat("HH:mm:ss").format(DateTime.now());
  var fromTripInfoTime=        DateFormat("HH:mm:ss").format(DateTime.now());
  var toTime=  DateFormat("HH:mm:ss").format(DateTime.now());
  var toTripInfoTime=  DateFormat("HH:mm:ss").format(DateTime.now());
  String distance_sum="O mile";
  String top_speed="O mile";
  String move_duration="Os";
  String stop_duration="Os";
  String fuel_consumption="O ltr";

  bool isshowvehicledetail = false;
  @override
  initState() {
    _postsController = new StreamController();

   // gethistory(StaticVarMethod.deviceId,StaticVarMethod.fromdate,StaticVarMethod.fromtime,StaticVarMethod.todate,StaticVarMethod.totime);

    getReport(StaticVarMethod.deviceId,StaticVarMethod.fromdate,StaticVarMethod.fromtime,StaticVarMethod.todate,StaticVarMethod.totime);
    super.initState();
  }

  Timer interval(Duration duration, func) {
    Timer function() {
      Timer timer = new Timer(duration, function);
      func(timer);
      return timer;
    }

    return new Timer(duration, function);
  }

  void playRoute() async {
    //var iconPath = "assets/images/direction.png";
    //var iconPath = "assets/images/direction.png";
  //  var iconPath = "assets/images/mylocation.png";
    var iconPath = "assets/tbtrack/car_toprunning.png";

    //
    // try {
    //   if(int.tryParse(statusspeed)! > 0){
    //     iconPath =  "assets/tbtrack/car_toprunning.png";
    //
    //     if(StaticVarMethod.pref_static!.get(StaticVarMethod.imei)!=null)
    //       iconPath =  "assets/tbtrack/"+StaticVarMethod.pref_static!.get(StaticVarMethod.imei).toString()+"toprunning.png";
    //
    //   }
    //   else{
    //
    //     iconPath =  "assets/tbtrack/car_topstop.png";
    //     if(StaticVarMethod.pref_static!.get(StaticVarMethod.imei)!=null)
    //       iconPath =  "assets/tbtrack/"+StaticVarMethod.pref_static!.get(StaticVarMethod.imei).toString()+"topstop.png";
    //   }
    // }catch(e){
    //
    //   print("playback exception"+ e.toString());
    // }
    //
    // final Uint8List? icon = await getBytesFromAsset(iconPath, 50);

    interval(new Duration(milliseconds: playbackTime), (timer) async {
      if (routeList.length != _sliderValue) {
        _sliderValue++;
      }
      timerPlayBack = timer;
      _markers.remove(routeList[_sliderValue.toInt()].device_id.toString());
      if (routeList.length == _sliderValue.toInt()) {
        timerPlayBack.cancel();
      } else if (routeList.length != _sliderValue.toInt()) {
        try {
          if(int.tryParse(   routeList[_sliderValue.toInt()].speed.toString())! > 0){
            iconPath =  "assets/tbtrack/car_toprunning.png";

            if(StaticVarMethod.pref_static!.get(StaticVarMethod.imei)!=null)
              iconPath =  "assets/tbtrack/"+StaticVarMethod.pref_static!.get(StaticVarMethod.imei).toString()+"toprunning.png";

          }
          else{

            iconPath =  "assets/tbtrack/car_topstop.png";
            if(StaticVarMethod.pref_static!.get(StaticVarMethod.imei)!=null)
              iconPath =  "assets/tbtrack/"+StaticVarMethod.pref_static!.get(StaticVarMethod.imei).toString()+"topstop.png";
          }
        }catch(e){

          print("playback exception"+ e.toString());
        }

        final Uint8List? icon = await getBytesFromAsset(iconPath, 50);
        moveCamera(routeList[_sliderValue.toInt()]);

        if (routeList[_sliderValue.toInt()] != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(
                  routeList[_sliderValue.toInt()].device_id.toString()),
              position: LatLng(
                  double.parse(
                      routeList[_sliderValue.toInt()].latitude.toString()),
                  double.parse(routeList[_sliderValue.toInt()]
                      .longitude
                      .toString())), // updated position
              rotation: double.parse(routeList[_sliderValue.toInt()].course!),
              icon: BitmapDescriptor.fromBytes(icon!),
            ),
          );
        }
        if (mounted) {
          setState(() {});
        }
      } else {
        timerPlayBack.cancel();
      }
    });
  }

  void playUsingSlider(int pos) async {
   // var iconPath = "assets/images/direction.png";
    //var iconPath = "assets/images/mylocation.png";
    var iconPath = "assets/speedoicon/assets_images_starticon.png";

    final Uint8List? icon = await getBytesFromAsset(iconPath, 50);
    _markers.remove(routeList[_sliderValue.toInt()].device_id.toString());
    if (routeList.length != _sliderValue.toInt()) {
      moveCamera(routeList[_sliderValue.toInt()]);
      _markers.add(
        Marker(
          markerId:
          MarkerId(routeList[_sliderValue.toInt()].device_id.toString()),
          position: LatLng(
              double.parse(routeList[_sliderValue.toInt()].latitude.toString()),
              double.parse(routeList[_sliderValue.toInt()]
                  .longitude
                  .toString())), // updated position
          rotation: double.parse(routeList[_sliderValue.toInt()].course!),
          icon: BitmapDescriptor.fromBytes(icon!),
        ),
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  void moveCamera(PlayBackRoute pos) async {
    CameraPosition cPosition = CameraPosition(
      target: LatLng(double.parse(pos.latitude.toString()),
          double.parse(pos.longitude.toString())),
      zoom: currentZoom,
    );

    if (isLoading) {
      _showProgress(false);
    }
    isLoading = false;
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));
  }

  /* getReport() {
   // _timer = new Timer.periodic(Duration(milliseconds: 20000), (timer) {
    polylineCoordinates.clear();
      gpsapis.getHistorynew(StaticVarMethod.deviceId, StaticVarMethod.fromdate, StaticVarMethod.fromtime, StaticVarMethod.todate, StaticVarMethod.totime)
            .then((value) => {
          if (value!.items?.length != 0)
            {

              value.items?.forEach((element) {
                _postsController.add(element);
                element['items'].forEach((element) {
                  if (element['latitude'] != null) {
                    PlayBackRoute blackRoute = PlayBackRoute();
                    blackRoute.device_id =
                        element['device_id'].toString();
                    blackRoute.longitude =
                        element['longitude'].toString();
                    blackRoute.latitude =
                        element['latitude'].toString();
                    blackRoute.speed = element['speed'];
                    blackRoute.course = element['course'].toString();
                    blackRoute.raw_time =
                        element['raw_time'].toString();

                    polylineCoordinates.add(LatLng(
                        double.parse(element['latitude'].toString()),
                        double.parse(element['longitude'].toString())));
                    routeList.add(blackRoute);
                  }
                });
                _sliderValueMax = polylineCoordinates.length;
              }),
              playRoute(),

              setState(() {}),
              drawPolyline(),
            }
          else
            {
              if (isLoading)
                {
                  _showProgress(false),
                  isLoading = false,
                },
             // _timer.cancel(),
              AlertDialogCustom().showAlertDialog(
                  context,
                  'noData',
                  'failed',
                  'ok')
            }
        });

   // });


  }*/
  List<TripsItems> triplist2 = [];
  gethistory(String deviceID, String fromDate,
      String fromTime, String toDate, String toTime) async {
    // isLoading = true;
    // if (isLoading) {
    //   _showProgress(true);
    // }
    print("reports start");
    final Uri apiUrl = Uri.parse(StaticVarMethod.baseurlall+"/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date="+StaticVarMethod.fromdate+"&from_time="+StaticVarMethod.fromtime+"&to_date="+StaticVarMethod.todate+"&to_time="+StaticVarMethod.totime+"&device_id="+StaticVarMethod.deviceId+"");
    final response = await http.get(apiUrl).timeout(const Duration(minutes: 5));
    print(response.request);
    if (response.statusCode == 200) {

      //var data= response.body;
      // var data1= response.body.toString();
      var jsonData = json.decode(response.body.toString());
      var history = History.fromJson(jsonData);
      for (var i = 0; i < history.items!.length; i++) {
       // triplist.add(history.items![i]);

        for(var j = 0; j < history.items![i].items!.length; j++){
          PlayBackRoute blackRoute = PlayBackRoute();
          blackRoute.device_id =history.items![i].items![j].deviceId.toString();
          blackRoute.longitude =history.items![i].items![j].latitude.toString();
          blackRoute.latitude =history.items![i].items![j].longitude.toString();
          blackRoute.speed = history.items![i].items![j].speed;
          blackRoute.course = history.items![i].items![j].course.toString();
          blackRoute.raw_time =history.items![i].items![j].rawTime.toString();

          if(blackRoute.latitude !="null" && blackRoute.latitude !="0"){
            polylineCoordinates.add(
                LatLng(
                double.parse(history.items![i].items![j].latitude.toString()),
                double.parse(history.items![i].items![j].longitude.toString())
            )
            );

            routeList.add(blackRoute);
          }


        }

      }

      _sliderValueMax = polylineCoordinates.length;


      if (mounted) {
        setState(() {
          top_speed=history.topSpeed.toString();
         // top_speed=history.topSpeed.toString();
          move_duration=history.moveDuration.toString();
          stop_duration=history.stopDuration.toString();
          fuel_consumption=history.fuelConsumption.toString();
          distance_sum=history.distanceSum.toString();

        });

      }

      playRoute();
      drawPolyline();





    } else {
      print(response.statusCode);
    }
  }

  Future<PositionHistory?> getReport(String deviceID, String fromDate,
      String fromTime, String toDate, String toTime) async {
    print("reports start");
    // final response = await http.get(Uri.parse(StaticVarMethod.baseurlall+"/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date=$fromDate&from_time=$fromTime&to_date=$toDate&to_time=$toTime&device_id=$deviceID"));
    // print(response.request);
    final Uri apiUrl = Uri.parse(StaticVarMethod.baseurlall+"/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date="+StaticVarMethod.fromdate+"&from_time="+StaticVarMethod.fromtime+"&to_date="+StaticVarMethod.todate+"&to_time="+StaticVarMethod.totime+"&device_id="+StaticVarMethod.deviceId+"");
    final response = await http.get(apiUrl).timeout(const Duration(minutes: 5));
    print(response.request);
    if (response.statusCode == 200) {
      print(
          "dod${StaticVarMethod.baseurlall+"/api/get_history?lang=en&user_api_hash=${StaticVarMethod.user_api_hash}&from_date=$fromDate&from_time=$fromTime&to_date=$toDate&to_time=$toTime&device_id=$deviceID"}");
      var value= PositionHistory.fromJson(json.decode(response.body));

      if (value!.items?.length != 0)
      {

        value.items?.forEach((element) {

          PlayBackRoute tripmodel = PlayBackRoute();



          tripmodel.show = element['show'].toString();
          tripmodel.left = element['left'].toString();
          tripmodel.time = element['time'].toString();
          tripmodel.distance = element['distance'].toString();
          // tripmodel.timeSeconds = element['time_seconds'].toString();
          // tripmodel.engineWork = element['engine_work'].toString();
          // tripmodel.engineIdle = element['engine_idle'].toString();
          // tripmodel.engineHours = element['engine_hours'].toString();
          // tripmodel.fuelConsumption = element['fuel_consumption'].toString();
          // tripmodel.topSpeed = element['top_speed'].toString();
          // tripmodel.averageSpeed = element['average_speed'].toString();


          _postsController.add(element);
          element['items'].forEach((element) {

            String lat=element['latitude'].toString();
            String lng=element['longitude'].toString();
            if (lat.toLowerCase().contains("null") || lat == "0.0" || lat == "null" || lat == " ") {

              print(lat);
              print(lat);
            }else{

              PlayBackRoute blackRoute = PlayBackRoute();
              blackRoute.device_id = element['device_id'].toString();
              blackRoute.longitude = element['longitude'].toString();
              blackRoute.latitude = element['latitude'].toString();
              blackRoute.speed = element['speed'];
              blackRoute.course = element['course'].toString();
              blackRoute.raw_time = element['raw_time'].toString();

              tripmodel.device_id = element['device_id'].toString();
              tripmodel.longitude = element['longitude'].toString();
              tripmodel.latitude = element['latitude'].toString();
              tripmodel.speed = element['speed'];
              tripmodel.course = element['course'].toString();

              // polylineCoordinates.add(LatLng(
              //     double.parse(element['latitude'].toString()),
              //     double.parse(element['longitude'].toString())));

              try{
                if(lat != "null" ){
                  polylineCoordinates.add(LatLng(element['latitude'] as  double,element['longitude'] as double));
                  routeList.add(blackRoute);
                }else{
                  print(lat);
                  print(lat);
                }

              }catch(e){
                print(e);
                print(lat);
                print(lat);
              }

            }
          });

          // _markers.add(
          //   Marker(
          //     markerId: MarkerId(tripmodel.show.toString()),
          //     position: LatLng(
          //         double.parse(tripmodel.latitude.toString()),
          //         double.parse(tripmodel.longitude.toString())), // updated position
          //   //  rotation: double.parse(routeList[_sliderValue.toInt()].course!),
          //     //icon: BitmapDescriptor.fromBytes(icon!),
          //   ),
          // );
          tripList.add(tripmodel);
          _sliderValueMax = polylineCoordinates.length;
        });
        playRoute();

        if (mounted) {
          setState(() {
            top_speed=value.top_speed.toString();

            // if(top_speed != "null" || top_speed != "0" ){
            //   top_speed= (int.parse(value.top_speed.toString())/1.6093).toStringAsFixed(0);
            // }else{
            //   top_speed= "0";
            // }

           // top_speed=value.top_speed.toString();
            move_duration=value.move_duration.toString();
            stop_duration=value.stop_duration.toString();
            fuel_consumption=value.fuel_consumption.toString();
            distance_sum=value.distance_sum.toString();
          });

        }
        drawPolyline();
      }
      else
      {
        if (isLoading)
        {
          _showProgress(false);
          isLoading = false;
        };
        // _timer.cancel(),
        AlertDialogCustom().showAlertDialog(
            context,
            'NoData',
            'Failed',
            'Ok');
      }
    } else {

      print("Error reports start");
      print(response.statusCode);
      return null;
    }
  }

  String distance="not valable";
  String time="not valable";
  String lat="not valable";
  String lng="not valable";
  String avgspeed="not valable";

  void drawPolyline() async {
    var iconPath = "assets/speedoicon/assets_images_parkingicon.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 50);

    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 4,
        polylineId: id,
        //color: Colors.redAccent,
        color: Colors.blueAccent,
        points: polylineCoordinates);
    polylines[id] = polyline;



    _markers = Set<Marker>();
    for (var i = 0; i < tripList.length; i++) {


      try{
        if(tripList[i].latitude.toString() != "null" ){
          _markers.add(
            Marker(
              markerId: MarkerId(tripList[i].show.toString()),
              position: LatLng(
                  double.parse(tripList[i].latitude.toString()),
                  double.parse(tripList[i].longitude.toString())), // updated position
              //  rotation: double.parse(routeList[_sliderValue.toInt()].course!),
              icon: BitmapDescriptor.fromBytes(icon!),
              onTap: () async {

                 distance=tripList[i].distance.toString();
                 time=tripList[i].time.toString();
                 lat=tripList[i].latitude.toString();
                 lng=tripList[i].longitude.toString();
                 avgspeed=tripList[i].averageSpeed.toString();
                setState(() {
                  isshowvehicledetail = true;
                });
                /* Fluttertoast.showToast(
                        msg: 'Click marker ' + (i + 1).toString(),
                        toastLength: Toast.LENGTH_SHORT);*/
              },
            ),
          );
        }else{
          print(tripList[i].latitude.toString());
          print(tripList[i].latitude.toString());
        }

      }catch(e){
        print(e);
        print(tripList[i].latitude.toString());
        print(tripList[i].latitude.toString());
      }


    }

    if (mounted) {
      setState(() {});
    }



  }


  Widget _buildItem() {
    double imageSize = MediaQuery.of(context).size.width / 25;

    return Positioned(
        top: 90,
        right: 5,
        left: 5,
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
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                        ),
                        padding: EdgeInsets.fromLTRB(10, 2, 10, 5),
                        margin: EdgeInsets.only(left: 5),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      //Row(children:[Text("Some Data"), Spacer(), Text("Some Data")]),

                                      Container(
                                          margin: EdgeInsets.only(top: 5),
                                          child:
                                          //Center(
                                          Text(
                                            'Name: ' + StaticVarMethod.deviceName,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                Colors.blue.shade900),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        //   )
                                      ),

                                    ],
                                  ),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[

                                Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child:
                                    //Center(
                                    Text(getTranslated(context, 'time')! + time,
                                      style: TextStyle(
                                          fontSize: 12,
                                          // fontWeight: FontWeight.bold,
                                          color:
                                          Colors.blue.shade900),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  //   )
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[

                                Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child:
                                    //Center(
                                    Text(getTranslated(context, 'averageSpeed')! + avgspeed +" kph",
                                      style: TextStyle(
                                          fontSize: 12,
                                          // fontWeight: FontWeight.bold,
                                          color:
                                          Colors.blue.shade900),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  //   )
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                    margin: EdgeInsets.only(top: 5),
                                    child:
                                    //Center(
                                    Text(getTranslated(context, 'distance')! + distance,
                                      style: TextStyle(
                                          fontSize: 12,
                                          // fontWeight: FontWeight.bold,
                                          color:
                                          Colors.blue.shade900),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  //   )
                                ),

                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      //Row(children:[Text("Some Data"), Spacer(), Text("Some Data")]),

                                      Container(
                                          margin: EdgeInsets.only(top: 5),
                                          child:
                                          //Center(
                                          Text(
                                            'Lat/Lng: (' + lat+" , "+lng+")",
                                            style: TextStyle(
                                                fontSize: 12,
                                                // fontWeight: FontWeight.bold,
                                                color:
                                                Colors.blue.shade900),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        //   )
                                      ),

                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    postfixIcon(),
                  ])),
        ));
  }
  Widget postfixIcon() {
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
                  child:  GestureDetector(
                    onTap: (){
                      setState(() {
                        isshowvehicledetail = false;
                      });
                    },
                    child:   Image.asset("assets/nepalicon/cancel.png", height: 10,width: 10),
                  )),


            ])

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
      _trafficEnabled == false ? CustomColor.primaryColor : Colors.green;
    });
  }

  void _playPausePressed() {
    setState(() {
      _isPlaying = _isPlaying == false ? true : false;
      if (_isPlaying) {
        timerPlayBack.cancel();
      } else {
        playRoute();
      }
      _isPlayingIcon = _isPlaying == false
          ? Icons.pause_circle_outline
          : Icons.play_circle_outline;
    });
  }

  currentMapStatus(CameraPosition position) {
    currentZoom = position.zoom;
  }

  @override
  void dispose() {
    if (timerPlayBack != null) {
      if (timerPlayBack.isActive) {
        timerPlayBack.cancel();
      }
    }
    super.dispose();
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  String? _chosenValue;
  String? _chosenValue1;
  @override
  Widget build(BuildContext context) {
    // Future.delayed(Duration.zero, () => showAlert(context));
    var selectTime1 = Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: DropdownButton<String>(
            isDense: false,
            icon: Icon(Icons.keyboard_arrow_down_sharp),
            value: _chosenValue,
            //elevation: 5,
            style: TextStyle(color: Colors.black),
            items: <String>[
              '1 min',
              '2 min',
              '5 min',
              '10 min',
              '30 min',
              '1 Hours',
              '5 Hours',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            hint: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "1 min",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
            onChanged: (String? value) {
              setState(() {
                _chosenValue = value!;
              });
            },
          ),
        ),
      ),
    );
    var selectTime2 = Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: DropdownButton<String>(
            isDense: false,
            icon: Icon(Icons.keyboard_arrow_down_sharp),
            value: _chosenValue1,
            //elevation: 5,
            style: TextStyle(color: Colors.black),
            items: <String>[
              'Last Hour',
              'Today',
              'Yesterday',
              'Before 2 Days',
              'Before 3 Days',
              'This Week',
              'Last Week',
              'This Month',
              'Last Month',
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            hint: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "Today",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
            onChanged: (String? value) {
              setState(() {
                _chosenValue1 = value!;
              });
            },
          ),
        ),
      ),
    );
    DateTime selectedDate = DateTime.now();
    String _formatDate = DateFormat("dd/MM/yyyy").format(selectedDate);

    Future<Null> _fromDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1990, 1),
          lastDate: DateTime(2050, 1));
      if (picked != null && picked != selectedDate)
        setState(() {
          selectedDate = picked;
          var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
        });
    }

    Future<Null> _toDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1990, 1),
          lastDate: DateTime(2050, 1));
      if (picked != null && picked != selectedDate)
        setState(() {
          selectedDate = picked;
          var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
        });
    }

    choices = <Choice>[
      Choice(
          title:'slow',
          icon: Icons.directions_car),
      Choice(
          title: 'medium',
          icon: Icons.directions_bike),
      Choice(
          title: 'fast',
          icon: Icons.directions_boat),
    ];
    _selectedChoice = choices[0];
    return Scaffold(
      appBar: AppBar(
        title: Text(''+StaticVarMethod.deviceName,
            style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        actions: <Widget>[
          // action button
          // PopupMenuButton<Choice>(
          //   onSelected: _select,
          //   icon: Icon(Icons.timer),
          //   itemBuilder: (BuildContext context) {
          //     return choices.map((Choice choice) {
          //       return PopupMenuItem<Choice>(
          //         value: choice,
          //         child: Text(choice.title!),
          //       );
          //     }).toList();
          //   },
          // ),
          /*IconButton(
              icon: Icon(Icons.date_range, color: Colors.black),
              onPressed: () {

                showReportDialog(context,"",67);
                *//* showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _datepickerDialog();
                  },
                );*//*
                //_datepickerDialog(context);
              }),*/
        ],
        backgroundColor: Colors.white,
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          onCameraMove: currentMapStatus,
          trafficEnabled: _trafficEnabled,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
            CustomProgressIndicatorWidget().showProgressDialog(context,
                'Loading ..');
            isLoading = true;
          },
          markers: _markers,
          polylines: Set<Polyline>.of(polylines.values),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  onPressed: _onMapTypeButtonPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.map, size: 20.0,color: Colors.black),
                  mini: true,
                ),
                FloatingActionButton(
                  heroTag: "traffic",
                  onPressed: _trafficEnabledPressed,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.traffic, size: 20.0,color: Colors.black),
                  mini: true,
                ),
              ],
            ),
          ),
        ),
        playBackControls(),

        (isshowvehicledetail) ? _buildItem() : Container(),
      ]),
    );
  }

  String statusspeed="";
  Widget playBackControls() {
    String fUpdateTime =
        'Loading ..';
    String speed ='Loading ..';
    if (routeList.length > _sliderValue.toInt()) {
      fUpdateTime = formatTime(routeList[_sliderValue.toInt()].raw_time!);
      speed = convertSpeed(routeList[_sliderValue.toInt()].speed);

      statusspeed= routeList[_sliderValue.toInt()].speed.toString();
    }

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.only(left: 10,right: 10,top: 5,bottom: 40),

          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              //color:Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              // boxShadow: <BoxShadow>[
              //   BoxShadow(
              //       blurRadius: 20,
              //       offset: Offset.zero,
              //       color: Colors.grey.withOpacity(0.5))
              // ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
            /*  _sliderValue.toInt() > 0
                  ? routeList[_sliderValue.toInt()].longitude != null
                  ? Row(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: 5.0),
                    child: Icon(Icons.location_on_outlined,
                        color: Colors.black, size: 25.0),
                  ),
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(
                                  top: 10.0, left: 5.0, right: 0),
                              child: Text(
                                utf8.decode(utf8.encode(
                                    routeList[_sliderValue.toInt()]
                                        .latitude.toString())),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ]),
                  )
                ],
              )
                  : new Container()
                  : new Container(),*/
              new Container(
                  width: MediaQuery.of(context).size.width ,
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(top: 5.0, left: 5.0),
                          child: InkWell(
                            child: Icon(_isPlayingIcon,
                                color: Colors.black, size: 40.0),
                            onTap: () {
                              _playPausePressed();
                            },
                          )),
                      Container(
                          padding: EdgeInsets.only(top: 5.0, left: 0.0),
                          width: MediaQuery.of(context).size.width * 0.65,
                          child: Slider(
                            value: _sliderValue.toDouble(),
                            onChanged: (newSliderValue) {
                              setState(
                                      () => _sliderValue = newSliderValue.toInt());
                              if (timerPlayBack != null) {
                                if (!timerPlayBack.isActive) {
                                  playUsingSlider(newSliderValue.toInt());
                                }
                              }
                            },
                            min: 0,
                            max: _sliderValueMax.toDouble(),
                          )),
                      Container(
                      //  padding: EdgeInsets.only(top: 5.0, right: 30.0),
                        child: PopupMenuButton<Choice>(
                          onSelected: _select,
                          icon: Icon(Icons.timer),
                          itemBuilder: (BuildContext context) {
                            return choices.map((Choice choice) {
                              return PopupMenuItem<Choice>(
                                value: choice,
                                child: Text(choice.title!),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  )),
              Container(
                margin: EdgeInsets.fromLTRB(80, 1, 80, 1),

                child: Row(
                    children: [
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/speedometer.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(''+speed,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'digital_font'

                                                  )),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ))
                      )
                    ]
                ),
              ),
              Container(
                //margin: EdgeInsets.fromLTRB(12, 6, 12, 6),

                child: Row(
                    children: [
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/movingdurationicon.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(''+move_duration,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    //fontFamily: 'digital_font'

                                                  )),
                                            ),
                                            Container(
                                              // margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  /*Icon(Icons.location_on,
                                                      color: Colors.blue, size: 12),*/
                                                  Text(getTranslated(context, 'moveDuration')!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        //color: Colors.blue
                                                        fontWeight: FontWeight.bold,
                                                      ))
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ))
                      ),
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/stopdurationicon.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              // margin: EdgeInsets.only(top: 5),
                                              child: Text(''+stop_duration,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      //height: 0.8,
                                                      // fontFamily: 'digital_font'
                                                      fontWeight: FontWeight.bold
                                                  )),
                                            ),
                                            Container(
                                              // margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  /*Icon(Icons.location_on,
                                                      color: Colors.blue, size: 12),*/
                                                  Text(getTranslated(context, 'stopDuration')!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        //color: Colors.blue
                                                        fontWeight: FontWeight.bold,
                                                      ))
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ))
                      ),
                      // Expanded(
                      //     child:Card(
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(10),
                      //         ),
                      //         elevation: 2,
                      //         color: Colors.white,
                      //         child: Container(
                      //             margin: EdgeInsets.fromLTRB(12, 6, 12, 6),
                      //             child: Row(
                      //               mainAxisAlignment: MainAxisAlignment.start,
                      //               crossAxisAlignment: CrossAxisAlignment.start,
                      //               children: <Widget>[
                      //                 ClipRRect(
                      //                     borderRadius:
                      //                     BorderRadius.all(Radius.circular(4)),
                      //                     child: Image.asset("assets/images/speedometer1.png", height: 25,width: 25)),
                      //                 SizedBox(
                      //                   width: 10,
                      //                 ),
                      //                 Expanded(
                      //                   child: Column(
                      //                     crossAxisAlignment: CrossAxisAlignment.start,
                      //                     children: [
                      //                       /* Text(
                      //                         '_productData[index].name',
                      //                         style: TextStyle(
                      //                             fontSize: 13,
                      //                             color: Colors.blue
                      //                         ),
                      //                         maxLines: 3,
                      //                         overflow: TextOverflow.ellipsis,
                      //                       ),*/
                      //                       Container(
                      //                         margin: EdgeInsets.only(top: 5),
                      //                         child: Text(''+top_speed,
                      //                             style: TextStyle(
                      //                                 fontSize: 10,
                      //                                 fontWeight: FontWeight.bold,
                      //                                 fontFamily: 'digital_font'
                      //                             )),
                      //                       ),
                      //                       Container(
                      //                        // margin: EdgeInsets.only(top: 5),
                      //                         child: Row(
                      //                           children: [
                      //                             /*Icon(Icons.location_on,
                      //                                 color: Colors.blue, size: 12),*/
                      //                             Text('Top Speed',
                      //                                 style: TextStyle(
                      //                                     fontSize: 11,
                      //                                     //color: Colors.blue
                      //                                   fontWeight: FontWeight.bold,
                      //                                 ))
                      //                           ],
                      //                         ),
                      //                       ),
                      //                       /*  Container(
                      //                         margin: EdgeInsets.only(top: 5),
                      //                         child: Row(
                      //                           children: [
                      //                             // _globalWidget.createRatingBar(rating: _productData[index].rating!, size: 12),
                      //                             Text('(tests)', style: TextStyle(
                      //                                 fontSize: 11,
                      //                                 color: Colors.blue
                      //                             ))
                      //                           ],
                      //                         ),
                      //                       ),
                      //                       Container(
                      //                         margin: EdgeInsets.only(top: 5),
                      //                         child: Text(' '+'Sale',
                      //                             style: TextStyle(
                      //                                 fontSize: 11,
                      //                                 color: Colors.blue
                      //                             )),
                      //                       ),*/
                      //                     ],
                      //                   ),
                      //                 )
                      //               ],
                      //             ))
                      //     )
                      // )
                    ]
                ),
              ),
              Container(
                //margin: EdgeInsets.fromLTRB(12, 6, 12, 6),

                child: Row(
                    children: [

                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/icons8-clock-100.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                             // margin: EdgeInsets.only(top: 5),
                                              child: Text(''+fUpdateTime,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      height: 0.8,
                                                      fontFamily: 'digital_font'
                                                     // fontWeight: FontWeight.bold
                                                  )),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ))
                      ),
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(12, 6, 12, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/routeicon.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                           /* Text(
                                              '_productData[index].name',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),*/
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(''+distance_sum,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'digital_font'
                                                  )),
                                            ),
                                          /*  Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      color: Colors.blue, size: 12),
                                                  Text(' ',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.blue
                                                      ))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  // _globalWidget.createRatingBar(rating: _productData[index].rating!, size: 12),
                                                  Text('(tests)', style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue
                                                  ))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(' '+'Sale',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue
                                                  )),
                                            ),*/
                                          ],
                                        ),
                                      )
                                    ],
                                  ))
                          )
                      ),
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 1, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/speedometer1.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 1,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            /* Text(
                                              '_productData[index].name',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),*/
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(''+top_speed,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      //fontFamily: 'digital_font'
                                                  )),
                                            ),
                                            Container(
                                              // margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  /*Icon(Icons.location_on,
                                                      color: Colors.blue, size: 12),*/
                                                  Text(getTranslated(context, 'maximumSpeed')!,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        //color: Colors.blue
                                                        fontWeight: FontWeight.bold,
                                                      ))
                                                ],
                                              ),
                                            ),
                                            /*  Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  // _globalWidget.createRatingBar(rating: _productData[index].rating!, size: 12),
                                                  Text('(tests)', style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue
                                                  ))
                                                ],
                                              ),
                                            ),
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(' '+'Sale',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue
                                                  )),
                                            ),*/
                                          ],
                                        ),
                                      )
                                    ],
                                  ))
                          )
                      )
                    ]
                ),
              ),

             /* Container(
                //alignment: Alignment.center,
                margin: EdgeInsets.fromLTRB(40, 6, 40, 6),
                child: Row(
                  //mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child:Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              color: Colors.white,

                              child: Container(
                                  margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      ClipRRect(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                          child: Image.asset("assets/images/markersicon.png", height: 25,width: 25)),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(top: 5),
                                              child: Text(''+ utf8.decode(utf8.encode(
                                                  routeList[_sliderValue.toInt()]
                                                      .latitude.toString())).toString() + ' ,  '+ utf8.decode(utf8.encode(
                                              routeList[_sliderValue.toInt()]
                                          .longitude.toString())).toString() ,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    //fontFamily: 'digital_font'

                                                  )),
                                            ),
                                            Container(
                                              // margin: EdgeInsets.only(top: 5),
                                              child: Row(
                                                children: [
                                                  */
              /*Icon(Icons.location_on,
                                                      color: Colors.blue, size: 12),*/
              /*
                                                  Text('google map address',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        //color: Colors.blue
                                                        fontWeight: FontWeight.bold,
                                                      ))
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                              ))
                      ),

                    ]
                ),
              ),*/
            ],
          ),
        ),
      ),
    );



    /* return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    blurRadius: 20,
                    offset: Offset.zero,
                    color: Colors.grey.withOpacity(0.5))
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Row(
                    children: <Widget>[
                      Container(
                          padding: EdgeInsets.only(top: 5.0, left: 10.0),
                          child: InkWell(
                            child: Icon(_isPlayingIcon,
                                color: CustomColor.primaryColor, size: 50.0),
                            onTap: () {
                              _playPausePressed();
                            },
                          )),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          padding: EdgeInsets.only(top: 5.0),
                          child: Slider(
                            value: _sliderValue.toDouble(),
                            onChanged: (newSliderValue) {
                              setState(
                                      () => _sliderValue = newSliderValue.toInt());
                              if (timerPlayBack != null) {
                                if (!timerPlayBack.isActive) {
                                  playUsingSlider(newSliderValue.toInt());
                                }
                              }
                            },
                            min: 0,
                            max: _sliderValueMax.toDouble(),
                          )),
                    ],
                  )),
              new Container(
                margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Icon(Icons.radio_button_checked,
                          color: CustomColor.primaryColor, size: 20.0),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('positionSpeed' +
                          ": " +
                          speed),
                    ),
                  ],
                ),
              ),
              new Container(
                margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Icon(Icons.av_timer,
                          color: CustomColor.primaryColor, size: 20.0),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text('deviceLastUpdate' +
                          ": " +
                          fUpdateTime),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );*/
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
                    child: Text('Loading ...')),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }



  void showReportDialog(BuildContext context, String heading,   final device) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Radio(
                                  value: 0,
                                  groupValue: _selectedperiod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedperiod = value!;
                                      _dialogHeight = 300.0;
                                    });
                                  },
                                ),
                                new Text('Today'
                                ),
                              ],
                            ),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Radio(
                                  value: 1,
                                  groupValue: _selectedperiod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedperiod = value!;
                                      _dialogHeight = 300.0;
                                    });
                                  },
                                ),
                                new Text('Yesterday'
                                ),
                              ],
                            ),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Radio(
                                  value: 2,
                                  groupValue: _selectedperiod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedperiod = value!;
                                      _dialogHeight = 300.0;
                                    });
                                  },
                                ),
                                new Text('ThisWeek'
                                ),
                              ],
                            ),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Radio(
                                  value: 3,
                                  groupValue: _selectedperiod,
                                  onChanged: (value) {
                                    setState(() {
                                      _dialogHeight = 400.0;
                                      _selectedperiod = value!;
                                    });
                                  },
                                ),
                                new Text('Custom',
                                ),
                              ],
                            ),
                            _selectedperiod == 3
                                ? new Container(
                                child: new Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        ElevatedButton(
                                          //color: CustomColor.primaryColor,
                                          onPressed: () => _selectFromDate(
                                              context, setState),
                                          child: Text(
                                              formatReportDate(
                                                  _selectedFromDate),
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        ElevatedButton(
                                          // color: CustomColor.primaryColor,
                                          onPressed: () {setState(() {
                                            _fromTime(context);  });

                                          },
                                          child: Text(
                                              formatReportTime(
                                                  selectedFromTime),
                                              style: TextStyle(
                                                  backgroundColor: Colors.blue,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        ElevatedButton(
                                          //color: CustomColor.primaryColor,
                                          onPressed: () =>
                                              _selectToDate(context, setState),
                                          child: Text(
                                              formatReportDate(_selectedToDate),
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        ElevatedButton(
                                          // color: CustomColor.primaryColor,
                                          onPressed: () {setState(() {
                                            _toTime(context);  });

                                          },
                                          child: Text(
                                              formatReportTime(selectedToTime),
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    )
                                  ],
                                ))
                                : new Container(),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                ElevatedButton(
                                  // color: Colors.red,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('cancel'
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                ElevatedButton(
                                  // color: CustomColor.primaryColor,
                                  onPressed: () {
                                    timerPlayBack.cancel();
                                    getReport(StaticVarMethod.deviceId,StaticVarMethod.fromdate,StaticVarMethod.fromtime,StaticVarMethod.todate,StaticVarMethod.totime);
                                    Navigator.of(context).pop();
                                    //showReport(heading,  device);
                                  },
                                  child: Text('ok'
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedFromDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedFromDate)
      setState(() {
        _selectedFromDate = picked;
      });
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedToDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedToDate)
      setState(() {
        _selectedToDate = picked;
      });
  }

  Future<Null> _fromTime(BuildContext context) async {
    var picked = await showTimePicker(
      context: context,
      initialTime:selectedFromTime,

    );
    if (picked != null && picked != selectedFromTime)
      setState(() {
        selectedFromTime = picked;
        var hour= selectedFromTime.hour;
        var minute= selectedFromTime.minute;
        fromTime ="$hour:$minute:00";
        print(fromTime);
        //var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
  }

  Future<Null> _toTime(BuildContext context) async {
    var picked = await showTimePicker(
      context: context,
      initialTime:selectedToTime,

    );
    if (picked != null && picked != selectedToTime)
      setState(() {
        selectedToTime = picked;
        var hour= selectedToTime.hour;
        var minute= selectedToTime.minute;
        toTime ="$hour:$minute:00";
        //  TimeOfDayFormat.H_colon_mm.toString();
        //var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
  }

}

class Choice {
  const Choice({this.title, this.icon});

  final String? title;
  final IconData? icon;
}

class AlertDialogCustom {
// showAlertDialog(BuildContext context, String message, String heading,
//      String buttonAcceptTitle, String buttonCancelTitle) {
//    // set up the buttons
//    Widget cancelButton = FlatButton(
//      child: Text(buttonCancelTitle),
//      onPressed: () {},
//    );
//    Widget continueButton = FlatButton(
//      child: Text(buttonAcceptTitle),
//      onPressed: () {
//
//      },
//    );
//
//    // set up the AlertDialog
//    AlertDialog alert = AlertDialog(
//      title: Text(heading),
//      content: Text(message),
//      actions: [
//        cancelButton,
//      ],
//    );
//
//    // show the dialog
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        return alert;
//      },
//    );
//  }
  showAlertDialog(BuildContext context, String message, String heading,
      String buttonAcceptTitle) {
    // set up the buttons
    Widget okButton = TextButton(
      child: Text(buttonAcceptTitle),
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(heading),
      content: Text(message),
      actions: [
        okButton,
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




}

class CustomProgressIndicatorWidget {
  showProgressDialog(BuildContext context, String message) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(margin: EdgeInsets.only(left: 5), child: Text(message)),
        ],
      ),
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}