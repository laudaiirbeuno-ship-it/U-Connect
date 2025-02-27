import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:maktrogps/config/apps/ecommerce/global_style.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/model/PositionHistory.dart';
import 'package:maktrogps/data/model/history.dart';
import 'package:maktrogps/mapconfig/CommonMethod.dart';
import 'package:http/http.dart' as http;
import 'package:maktrogps/data/datasources.dart';

import '../../../config/Session.dart';

class tasks extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _tasksState();
}

class _tasksState extends State<tasks> {


  TextEditingController commentController = TextEditingController();
  TextEditingController _titleFieldController = TextEditingController();
  TextEditingController _commentFieldController = TextEditingController();
  TextEditingController _pickupaddressFieldController = TextEditingController();
  TextEditingController _pickupaddresslatFieldController = TextEditingController();
  TextEditingController _pickupaddresslngFieldController = TextEditingController();
  List<String> _devicesListstr=[];
  String? _chosenValue1;
  @override
  initState() {
    super.initState();
    getdeviesList();
  }

  Future<void> getdeviesList() async {
    _devicesListstr.clear();
    for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
      _devicesListstr.add(StaticVarMethod.devicelist.elementAt(i).name!);
    }
    setState(() {
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Tasks"),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.home_filled),
                text: "New Trip",
              ),
              Tab(
                icon: Icon(Icons.account_box_outlined),
                text: "All Trips",
              ),
              // Tab(
              //   icon: Icon(Icons.alarm),
              //   text: "Alarm",
              // ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20, left: 15, right: 15),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Colors.white,
                      // border: Border(
                      //     bottom: BorderSide(
                      //       color: Colors.transparent,
                      //       width: 1.0,
                      //     )
                      // ),
                    ),
                    child:Card(
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
                                      hintText: getTranslated(context, 'selectVehicle')!,
                                      border: InputBorder.none
                                  )),
                              onChanged: (dynamic value) {
                                for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
                                  if (value != null) {
                                    if (StaticVarMethod.devicelist.elementAt(i).name!.contains(value)) {
                                      StaticVarMethod.deviceId=StaticVarMethod.devicelist.elementAt(i).id.toString();
                                      print("value: " + value);
                                      break;
                                    }
                                  }
                                }
                                setState(() {
                                  //_selectedReport = value;
                                });

                              },

                            )
                        )),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child:TextField(
                        controller: _titleFieldController,
                        onChanged: (String value) {
                        },

                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade500)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade500),
                          ),
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                  ),

                  Container(
                      margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child:TextField(
                        controller: _commentFieldController,
                        onChanged: (String value) {
                        },

                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade500)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade500),
                          ),
                          labelText: 'Comment',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child:TextField(
                        controller: _pickupaddressFieldController,
                        onChanged: (String value) {
                        },

                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade500)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade500),
                          ),
                          labelText: 'Pickup Address',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child:TextField(
                        controller: _pickupaddresslatFieldController,
                        onChanged: (String value) {
                        },

                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade500)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade500),
                          ),
                          labelText: 'Pickup Address lat',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child:TextField(
                        controller: _pickupaddresslngFieldController,
                        onChanged: (String value) {
                        },

                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade500)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade500),
                          ),
                          labelText: 'Pickup Address lng',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                  ),
                  // Container(
                  //   margin: EdgeInsets.only(top: 20, left: 15, right: 15),
                  //   padding: EdgeInsets.only(left: 10, right: 10),
                  //   child: TextFormField(
                  //       readOnly: false,
                  //       style: TextStyle(color: Colors.black),
                  //       keyboardType: TextInputType.multiline,
                  //       maxLines: 6,
                  //       controller: commentController,
                  //       decoration: InputDecoration(
                  //           isDense: true,
                  //           labelText: "Comment",
                  //           border: OutlineInputBorder()),
                  //       onChanged: (val) {
                  //         if (val.isNotEmpty) {
                  //         //  itemsrRemarks = val;
                  //         } else {
                  //          // itemsrRemarks = "";
                  //         }
                  //       }),
                  // ),
                  Container(

                    margin: EdgeInsets.only(top: 20, left: 15, right: 15),
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      // color: CustomColor.primaryColor,
                      onPressed: () {

                        _savetask();

                      },
                      child: Text("Save",
                          style: TextStyle(
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Icon(Icons.account_circle),
            ),
            // Center(
            //   child: Icon(Icons.alarm),
            // )
          ],
        ),
      ),
    );
  }

  void _savetask() async {

    try {

      Response result = await gpsapis.AddTask(
          _titleFieldController.text, _commentFieldController.text,_pickupaddressFieldController.text,_pickupaddresslatFieldController.text,_pickupaddresslngFieldController.text);




      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task Added Successful'),
          backgroundColor: Colors.green,
        ),
      );



    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task Added Successful'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigator.pop(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Something went wrong'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }
}