import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:alxgration_speedometer/speedometer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:location/location.dart';

import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/mapconfig/CommonMethod.dart';
import 'package:maktrogps/mapconfig/CustomColor.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as IMG;
import 'package:http/http.dart' as http;
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constant.dart';
import '../../mvvm/view_model/objects.dart';
import '../../utils/MapUtils.dart';
import '../model/devices.dart';
import 'browser_module_old/browser.dart';
class notificationmapscreen extends StatefulWidget {
  @override
  _notificationmapscreen createState() => _notificationmapscreen();
}

class _notificationmapscreen extends State<notificationmapscreen>{


  late SharedPreferences prefs;
  bool isshowvehicledetail = false;
  @override
  void initState() {
    checkPreference();
    super.initState();

  }
  void checkPreference() async {

    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Text(''+StaticVarMethod.deviceName,
            style: TextStyle(color: Colors.white,fontSize: 15)),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),

        actions: <Widget>[
        ],
        backgroundColor: Color(0xff0D3D65),
      ),//_globalWidget.globalAppBar(),
      body: Stack(
        children: [
          _buildGoogleMap(StaticVarMethod.lat,StaticVarMethod.lng,90,"7857858",0),

          (isshowvehicledetail) ? _buildItem() : Container(),
        ],
      ),

    );
  }

  Widget _buildItem() {
    double imageSize = MediaQuery.of(context).size.width / 25;

    return Positioned(
        bottom: 90,
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
                                    Text(
                                      'Time: ' + StaticVarMethod.time,
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
                                    Text(
                                      'Speed: ' + StaticVarMethod.speed +" kph",
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
                                    Text(
                                      'Type: ' + StaticVarMethod.type,
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
                                            'Notification: ' + StaticVarMethod.message,
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
  String iconred="assets/nepalicon/map-alert-point.png";
  late BitmapDescriptor _markerDirection;
  Future<BitmapDescriptor> _setSourceAndDestinationIcons(String path) async {
    Uint8List? markerIcon = await getBytesFromAsset(path, 80);
    _markerDirection = await  BitmapDescriptor.fromBytes(markerIcon!);
    return _markerDirection;
  }

  Widget _buildGoogleMap(lat,lng,course,imei,speed){

    String iconpath = "assets/nepalicon/map-alert-point.png";
    //String iconpath = devicelist.icon!.path.toString();
    // if(speed > 0){
    //   iconpath =  "assets/nepalicon/map-alert-point.png";
    //
    //   if(StaticVarMethod.pref_static!.get(imei.toString())!=null)
    //     iconpath =  "assets/speedoicon/"+StaticVarMethod.pref_static!.get(imei.toString()).toString()+"grn.png";
    //
    // }
    // else{
    //   iconpath =  "assets/speedoicon/assets_images_markers_m_2_red.png";
    //   if(StaticVarMethod.pref_static!.get(imei.toString())!=null)
    //     iconpath =  "assets/speedoicon/"+StaticVarMethod.pref_static!.get(imei.toString()).toString()+"red.png";
    // }
    return FutureBuilder<BitmapDescriptor>(
        future: _setSourceAndDestinationIcons(iconpath),
        builder: (context, AsyncSnapshot<BitmapDescriptor> snapshot) {
          if (snapshot.hasData) {
            return Container(
              //  height: 150,
                //width: size.width,
                child: GoogleMap(
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  mapToolbarEnabled: false,
                  padding: EdgeInsets.all(200),
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    zoom: 10,
                    target: LatLng(lat!, lng!),
                  ),

                  markers:
                  <Marker>{
                     Marker(
                        markerId: MarkerId(imei),
                       // rotation: course!,
                        icon:(speed! > 0)? snapshot.data! :snapshot.data! ,
                         onTap: () async {
                           var add=await getAddress(lat!, lat!);
                           setState(() {
                             address=add;
                             isshowvehicledetail = true;
                           });
                           /* Fluttertoast.showToast(
                        msg: 'Click marker ' + (i + 1).toString(),
                        toastLength: Toast.LENGTH_SHORT);*/
                         },
                        position: LatLng(lat!, lng!))


                  },
                  onMapCreated: (GoogleMapController controller) {
                    //_onMapCreated(controller,imei);
                  },

                ));
          } else {
            return CircularProgressIndicator();
          }
        }
    );
  }










  String address = "View Address";
  String getAddress(lat, lng) {
    if (lat != null) {
      gpsapis.getGeocoder(lat, lng).then((value) => {
        if (value != null)
          {
            address = value.body,
            setState(() {}),
          }
        else
          {address = "Address not found"}
      });
    } else {
      address = "Address not found";
    }
    print(address);
    return address;
  }
}

Future<BitmapDescriptor> getMarkerIcon(String imagePath,String infoText,Color color,double rotateDegree) async {
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  //size
  Size canvasSize = Size(700.0,220.0);
  Size markerSize = Size(140.0,140.0);



  final Paint infoPaint = Paint()..color = Colors.white;
  final Paint infoStrokePaint = Paint()..color = color;
  final double infoHeight = 70.0;
  final double strokeWidth = 2.0;

 // final Paint markerPaint = Paint()..color = color.withOpacity(0);
  final double shadowWidth = 30.0;

  final Paint borderPaint = Paint()..color = color..strokeWidth=2.0..style = PaintingStyle.stroke;

  final double imageOffset = shadowWidth*.5;

  canvas.translate(canvasSize.width/2, canvasSize.height/2+infoHeight/2);

  // Add shadow circle
  // canvas.drawOval(Rect.fromLTWH(-markerSize.width/2, -markerSize.height/2, markerSize.width, markerSize.height), markerPaint);
  // // Add border circle
  // canvas.drawOval(Rect.fromLTWH(-markerSize.width/2+shadowWidth, -markerSize.height/2+shadowWidth, markerSize.width-2*shadowWidth, markerSize.height-2*shadowWidth), borderPaint);

  // Oval for the image
  Rect oval = Rect.fromLTWH(-markerSize.width/2+.5* shadowWidth, -markerSize.height/2+.5*shadowWidth, markerSize.width-shadowWidth, markerSize.height-shadowWidth);

  //save canvas before rotate
  canvas.save();

  double rotateRadian = (pi/180.0)*rotateDegree;

  //Rotate Image
  canvas.rotate(rotateRadian);

  // Add path for oval image
  canvas.clipPath(Path()
    ..addOval(oval));

  // Add image
  ui.Image image;
  image = await getImageFromPath(imagePath);
  // if(imagePath.contains("arrow-ack.png")){
  //   image = await getImageFromPath("assets/nepalicon/map-alert-point.png");
  // }else{
  //   image = await getImageFromPathUrl(imagePath);
  //
  // }
  paintImage(canvas: canvas,image: image, rect: oval, fit: BoxFit.fitHeight);

  canvas.restore();


  // Convert canvas to image
  final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt()
  );

  // Convert image to bytes
  final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List? uint8List = byteData?.buffer.asUint8List();

  return BitmapDescriptor.fromBytes(uint8List!);
}


Future<ui.Image> getImageFromPath(String imagePath) async {
  //File imageFile = File(imagePath);
  var bd = await rootBundle.load(imagePath);
  Uint8List imageBytes = Uint8List.view(bd.buffer);

  final Completer<ui.Image> completer = new Completer();

  ui.decodeImageFromList(imageBytes, (ui.Image img) {
    return completer.complete(img);
  });

  return completer.future;
}


Future<ui.Image> getImageFromPathUrl(String imagePath) async {
  //File imageFile = File(imagePath);
  final response = await http.Client().get(Uri.parse(imagePath));
  final bytes = response.bodyBytes;
//  var bd = await rootBundle.load(imagePath);
  //Uint8List imageBytes = Uint8List.view(bd.buffer);

  final Completer<ui.Image> completer = new Completer();

  ui.decodeImageFromList(bytes, (ui.Image img) {
    return completer.complete(img);
  });

  return completer.future;
}
