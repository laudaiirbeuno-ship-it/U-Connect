import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maktrogps/config/custom_image_assets.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/screens/playback.dart';
import 'package:maktrogps/data/screens/reports/ReportEvent.dart';
import 'package:maktrogps/data/screens/reports/ReportStop.dart';
import 'package:maktrogps/mapconfig/CommonMethod.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as IMG;
import 'package:maktrogps/utils/Consts.dart';
import 'package:intl/intl.dart';

import '../../../config/Session.dart';

class reportselection extends StatefulWidget {
  @override
  _reportselection createState() => _reportselection();
}

class _reportselection extends State<reportselection> {
  // initialize global widget

  bool _doneListing = false;
  //date time hepers
  int _selectedperiod = 0;

  List<String> _reportliststr = [
    "Daily Travel Report",
    "Travel Summary Bulk",
    "Task Report",
    "Vehicle History",
    "Traval Summary with Playback Image",
    "General information",
    "Drives and stops",
    "Geofence in/out",
    "Events",
    "Work hours daily"
  ];

  List<String> _devicesListstr = [];
  String _selectedReport = "";

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();

  var selectedToTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoToTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedFromTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoFromTime = TimeOfDay.fromDateTime(DateTime.now());
  var fromTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var fromTripInfoTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var toTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var toTripInfoTime = DateFormat("HH:mm:ss").format(DateTime.now());

  String? _chosenValue = "30 min";
  String? _chosenValue1;

  var _stopFilter;

  @override
  void initState() {
    super.initState();
    getdeviesList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getdeviesList() async {
    _devicesListstr.clear();

    for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
      _devicesListstr.add(StaticVarMethod.devicelist.elementAt(i).name!);
    }

    setState(() {});

    /*  if (locationList.isEmpty) {

      }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '' + StaticVarMethod.deviceName,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        actions: <Widget>[
          // action button
        ],
        backgroundColor: Colors.grey[300],
      ), //_globalWidget.globalAppBar(),
      body: Stack(
        children: [
          reportControls(),
        ],
      ),
    );
  }

  void showStopDialog(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: size.height * 0.5,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(getTranslated(context, 'selectReport')!),
                    const Divider(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 10),
                      child: SizedBox(
                          height: size.height * 0.3,
                          child: SingleChildScrollView(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'dayWiseInformation')!),
                                  value: "Daily Travel Report",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(
                                      getTranslated(context, 'travel_sheet')!),
                                  value: "Travel Summary Bulk",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'generalInformationMerged')!),
                                  value: "Task Report",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title:
                                      Text(getTranslated(context, 'history')!),
                                  value: "Vehicle History",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'travel_sheet_custom')!),
                                  value: "Traval Summary with Playback Image",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'general_information')!),
                                  value: "General information",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'drives_and_stops_drivers')!),
                                  value: "Drives and stops",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(
                                      getTranslated(context, 'geofence_in')!),
                                  value: "Geofence in/out",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title:
                                      Text(getTranslated(context, 'events')!),
                                  value: "Events",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                              RadioListTile(
                                  title: Text(getTranslated(
                                      context, 'work_hours_Daily')!),
                                  value: "Work hours daily",
                                  groupValue: _stopFilter,
                                  onChanged: (value) {
                                    setState(() {
                                      _stopFilter = value;
                                    });
                                  }),
                            ],
                          ))),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red, // foreground
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            getTranslated(context, 'cancel')!,
                            style:
                                TextStyle(fontSize: 15.0, color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _selectedReport = _stopFilter;

                            Navigator.pop(context);
                          },
                          child: Text(
                            getTranslated(context, 'ok')!,
                            style:
                                TextStyle(fontSize: 15.0, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Widget reportControls() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 30),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: <BoxShadow>[
            BoxShadow(
                blurRadius: 20,
                offset: Offset.zero,
                color: Colors.grey.withOpacity(0.5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: 10, left: 15, right: 15),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                //color: Colors.grey.shade900,
                //shadowColor: Colors.pink,
                child: GestureDetector(
                  onTap: () {
                    showStopDialog(context);
                  },
                  child: Container(
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      padding: EdgeInsets.only(
                        left: 100,
                        right: 100,
                        top: 15,
                        bottom: 15,
                      ),
                      child: Text(
                        getTranslated(context, 'selectReport')!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.left,
                      )),
                ),
              )),
          Container(
            margin: EdgeInsets.only(top: 20, left: 15, right: 15),
            padding: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
            ),
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                //color: Colors.grey.shade900,
                //shadowColor: Colors.pink,
                child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: DropdownSearch(
                      items: _devicesListstr,
                      popupProps: const PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        searchFieldProps: const TextFieldProps(
                          cursorColor: Colors.red,
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              //labelText: "Location",
                              hintText:
                                  getTranslated(context, 'selectVehicle')!,
                              border: InputBorder.none)),
                      onChanged: (dynamic value) {
                        for (int i = 0;
                            i < StaticVarMethod.devicelist.length;
                            i++) {
                          if (value != null) {
                            if (StaticVarMethod.devicelist
                                .elementAt(i)
                                .name!
                                .contains(value)) {
                              StaticVarMethod.deviceId = StaticVarMethod
                                  .devicelist
                                  .elementAt(i)
                                  .id
                                  .toString();
                              print("value: " + value);
                              break;
                            }
                          }
                        }
                        setState(() {
                          //_selectedReport = value;
                        });
                      },
                    ))),
          ),

          Container(
            margin: EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 0),
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
          ),
          Container(
            margin: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedperiod = 0;
                            showReport();
                          });
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 1.0),
                            )),
                        child: Text(
                          'Utlimas horas',
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedperiod = 1;
                            showReport();
                          });
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 1.0),
                            )),
                        child: Text(
                          getTranslated(context, 'today')!,
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedperiod = 2;
                            showReport();
                          });
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 0.5),
                            )),
                        child: Text(
                          getTranslated(context, 'yesterday')!,
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 13),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 3,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedperiod = 3;
                            showReport();
                          });
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 1.0),
                            )),
                        child: Text(
                          'Before 2 days',
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 11),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedperiod = 4;
                          });
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 1.0),
                            )),
                        child: Text(
                          getTranslated(context, 'last7days')!,
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 11),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: OutlinedButton(
                        onPressed: () {
                          /* Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => mainmapscreen()),
                          );*/
                          //Fluttertoast.showToast(msg: 'Item has been added to Shopping Cart');
                        },
                        style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(Size(0, 45)),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            )),
                            side: MaterialStateProperty.all(
                              BorderSide(color: Colors.grey, width: 1),
                            )),
                        child: Text(
                          'Ultima semana',
                          style: TextStyle(
                              color: Colors.grey,
                              //fontWeight: FontWeight.bold,
                              fontSize: 11),
                          textAlign: TextAlign.center,
                        ))),
                SizedBox(
                  width: 3,
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: Text(
              getTranslated(context, 'customDateTIme')!,
              style: TextStyle(
                  color: Colors.grey,
                  //fontWeight: FontWeight.bold,
                  fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          Container(

              // margin: EdgeInsets.all(20),
              child: Column(
            children: <Widget>[
              Container(

                  //  margin: EdgeInsets.all(20),
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    //color: CustomColor.primaryColor,
                    onPressed: () => _selectFromDate(context, setState),
                    child: Text(formatReportDate(_selectedFromDate),
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        textStyle: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    // color: CustomColor.primaryColor,
                    onPressed: () {
                      setState(() {
                        _fromTime(context);
                      });
                    },
                    /*style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              animationDuration: 3
                              ),*/
                    child: Text(formatReportTime(selectedFromTime),
                        style: TextStyle(
                            //backgroundColor: Colors.blue,
                            color: Colors.white)),
                  ),
                ],
              )),
              Container(
                  margin: EdgeInsets.only(top: 20 /*,right: 20*/),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            textStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        //color: CustomColor.primaryColor,
                        onPressed: () => _selectToDate(context, setState),
                        child: Text(formatReportDate(_selectedToDate),
                            style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            textStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        // color: CustomColor.primaryColor,
                        onPressed: () {
                          setState(() {
                            _toTime(context);
                          });
                        },
                        child: Text(formatReportTime(selectedToTime),
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )),
            ],
          )),
          // Container(
          //   margin: EdgeInsets.only(top: 20,left: 20,right: 20),
          //   child: Row(
          //     children: [
          //
          //       Expanded(
          //           child:OutlinedButton(
          //               onPressed: () {
          //                 setState(() {
          //                   _selectedperiod = 5;
          //                 });
          //               },
          //               style: ButtonStyle(
          //                   minimumSize: MaterialStateProperty.all(
          //                       Size(0, 45)
          //                   ),
          //                   overlayColor: MaterialStateProperty.all(Colors.transparent),
          //                   shape: MaterialStateProperty.all(
          //                       RoundedRectangleBorder(
          //                         borderRadius: BorderRadius.circular(20.0),
          //                       )
          //                   ),
          //                   side: MaterialStateProperty.all(
          //                     BorderSide(
          //                         color: Colors.grey,
          //                         width: 1.0
          //                     ),
          //                   )
          //               ),
          //               child: Text(
          //                 'Select Custom Date & Time',
          //                 style: TextStyle(
          //                     color: Colors.grey,
          //                     fontWeight: FontWeight.bold,
          //                     fontSize: 15
          //                 ),
          //                 textAlign: TextAlign.center,
          //               )
          //           )
          //       ),
          //       SizedBox(
          //         width: 3,
          //       ),
          //
          //     ],
          //   ),
          // ),
          //
          // _selectedperiod == 5
          //     ?Container(
          //     child: new Column(
          //       children: <Widget>[
          //         Row(
          //           mainAxisAlignment:
          //           MainAxisAlignment.spaceBetween,
          //           children: <Widget>[
          //             ElevatedButton(
          //               //color: CustomColor.primaryColor,
          //               onPressed: () => _selectFromDate(
          //                   context, setState),
          //               child: Text(
          //                   formatReportDate(
          //                       _selectedFromDate),
          //                   style: TextStyle(
          //                       color: Colors.white)),
          //             ),
          //             ElevatedButton(
          //               // color: CustomColor.primaryColor,
          //               onPressed: () {setState(() {
          //                 _fromTime(context);  });
          //
          //               },
          //               /*style: ElevatedButton.styleFrom(
          //                     backgroundColor: Colors.red,
          //                     animationDuration: 3
          //                     ),*/
          //               child: Text(
          //                   formatReportTime(
          //                       selectedFromTime),
          //                   style: TextStyle(
          //                       backgroundColor: Colors.blue,
          //                       color: Colors.white)),
          //             ),
          //           ],
          //         ),
          //         Row(
          //           mainAxisAlignment:
          //           MainAxisAlignment.spaceBetween,
          //           children: <Widget>[
          //             ElevatedButton(
          //               //color: CustomColor.primaryColor,
          //               onPressed: () =>
          //                   _selectToDate(context, setState),
          //               child: Text(
          //                   formatReportDate(_selectedToDate),
          //                   style: TextStyle(
          //                       color: Colors.white)),
          //             ),
          //             ElevatedButton(
          //               // color: CustomColor.primaryColor,
          //               onPressed: () {setState(() {
          //                 _toTime(context);  });
          //
          //               },
          //               child: Text(
          //                   formatReportTime(selectedToTime),
          //                   style: TextStyle(
          //                       color: Colors.white)),
          //             ),
          //           ],
          //         )
          //       ],
          //     ))
          //     :Container(),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: () {
                showReport();
                // Fluttertoast.showToast(msg: 'Press Outline Button', toastLength: Toast.LENGTH_SHORT);
              },
              style: ButtonStyle(
                  overlayColor: MaterialStateProperty.all(Colors.grey),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  )),
                  side: MaterialStateProperty.all(
                    BorderSide(color: Colors.grey, width: 1.0),
                  )),
              icon: Icon(
                Icons.file_copy_outlined,
                size: 24.0,
                color: Colors.grey,
              ),
              label: Text(getTranslated(context, 'generateReport')!,
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  //date time picker
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
      initialTime: selectedFromTime,
    );
    if (picked != null && picked != selectedFromTime)
      setState(() {
        selectedFromTime = picked;
        var hour = selectedFromTime.hour;
        var minute = selectedFromTime.minute;
        fromTime = "$hour:$minute:00";
        print(fromTime);
        //var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
  }

  Future<Null> _toTime(BuildContext context) async {
    var picked = await showTimePicker(
      context: context,
      initialTime: selectedToTime,
    );
    if (picked != null && picked != selectedToTime)
      setState(() {
        selectedToTime = picked;
        var hour = selectedToTime.hour;
        var minute = selectedToTime.minute;
        toTime = "$hour:$minute:00";
        //  TimeOfDayFormat.H_colon_mm.toString();
        //var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
  }

  void showReport() {
    String fromDate;
    String toDate;
    String fromTime;
    String toTime;

    DateTime current = DateTime.now();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    if (current.day < 10) {
      day = "0" + current.day.toString();
    } else {
      day = current.day.toString();
    }

    if (_selectedperiod == 1) {
      String today;

      int dayCon = current.day + 1;
      if (dayCon <= 10) {
        today = "0" + dayCon.toString();
      } else {
        today = dayCon.toString();
      }

      var date = DateTime.parse("${current.year}-"
          "$month-"
          "$today "
          "00:00:00");
      fromDate = formatDateReport(DateTime.now().toString());
      toDate = formatDateReport(date.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";

      StaticVarMethod.fromdate = formatDateReport(DateTime.now().toString());
      StaticVarMethod.todate = formatDateReport(date.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else if (_selectedperiod == 2) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day <= 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else if (_selectedperiod == 3) {
      String sevenDay, currentDayString;
      int dayCon = current.day - current.weekday;
      int currentDay = current.day;
      if (dayCon < 10) {
        sevenDay = "0" + dayCon.abs().toString();
      } else {
        sevenDay = dayCon.toString();
      }
      if (currentDay < 10) {
        currentDayString = "0" + currentDay.toString();
      } else {
        currentDayString = currentDay.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$sevenDay "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$currentDayString "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else {
      String startMonth, endMoth;
      if (_selectedFromDate.month < 10) {
        startMonth = "0" + _selectedFromDate.month.toString();
      } else {
        startMonth = _selectedFromDate.month.toString();
      }

      if (_selectedToDate.month < 10) {
        endMoth = "0" + _selectedToDate.month.toString();
      } else {
        endMoth = _selectedToDate.month.toString();
      }

      String startHour, endHour;
      if (selectedFromTime.hour < 10) {
        startHour = "0" + selectedFromTime.hour.toString();
      } else {
        startHour = selectedFromTime.hour.toString();
      }

      String startMin, endMin;
      if (selectedFromTime.minute < 10) {
        startMin = "0" + selectedFromTime.minute.toString();
      } else {
        startMin = selectedFromTime.minute.toString();
      }

      if (selectedToTime.minute < 10) {
        endMin = "0" + selectedToTime.minute.toString();
      } else {
        endMin = selectedToTime.minute.toString();
      }

      if (selectedToTime.hour < 10) {
        endHour = "0" + selectedToTime.hour.toString();
      } else {
        endHour = selectedToTime.hour.toString();
      }

      String startDay, endDay;
      if (_selectedFromDate.day <= 10) {
        if (_selectedFromDate.day == 10) {
          startDay = _selectedFromDate.day.toString();
        } else {
          startDay = "0" + _selectedFromDate.day.toString();
        }
      } else {
        startDay = _selectedFromDate.day.toString();
      }

      if (_selectedToDate.day <= 10) {
        if (_selectedToDate.day == 10) {
          endDay = _selectedToDate.day.toString();
        } else {
          endDay = "0" + _selectedToDate.day.toString();
        }
      } else {
        endDay = _selectedToDate.day.toString();
      }

      var start = DateTime.parse("${_selectedFromDate.year}-"
          "$startMonth-"
          "$startDay "
          "$startHour:"
          "$startMin:"
          "00");

      var end = DateTime.parse("${_selectedToDate.year}-"
          "$endMoth-"
          "$endDay "
          "$endHour:"
          "$endMin:"
          "00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = formatTimeReport(start.toString());
      toTime = formatTimeReport(end.toString());

      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = formatTimeReport(start.toString());
      StaticVarMethod.totime = formatTimeReport(end.toString());
    }

    print(fromDate);
    print(toDate);

    //Navigator.pop(context);
    if (_selectedReport.contains("General information")) {
      StaticVarMethod.reportType = 1;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
      );
    } else if (_selectedReport.contains("Daily Travel Report")) {
      StaticVarMethod.reportType = 48;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Travel Summary Bulk")) {
      StaticVarMethod.reportType = 2;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Task Report")) {
      StaticVarMethod.reportType = 27;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Vehicle History")) {
      StaticVarMethod.reportType = 25;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Traval Summary with Playback Image")) {
      StaticVarMethod.reportType = 43;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Drives and stops")) {
      StaticVarMethod.reportType = 3;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        // builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Events")) {
      StaticVarMethod.reportType = 8;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        //  builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Geofence in/out")) {
      StaticVarMethod.reportType = 7;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportStopPage()),
      );
    } else if (_selectedReport.contains("Work hours daily")) {
      StaticVarMethod.reportType = 48;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportEventPage()),
        //  builder: (context) => ReportStopPage()),
      );
    }

    //,"Drives and stops","Geofence in/out","Events","Work hours daily"

    // getReport(StaticVarMethod.deviceId,StaticVarMethod.fromdate,StaticVarMethod.fromtime,StaticVarMethod.todate,StaticVarMethod.totime);
    /* Navigator.pushNamed(context, "/reportList",
        arguments: ReportArguments(device['id'], fromDate, fromTime,
            toDate, toTime, device["name"], 0));*/
  }
}
