import 'dart:async';
import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:maktrogps/config/apps/ecommerce/constant.dart';
import 'package:maktrogps/config/apps/food_delivery/global_style.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/gpsserver/model/commandmodel.dart';
import 'package:maktrogps/data/gpsserver/model/cmdmodel.dart';
import 'package:maktrogps/data/model/User.dart';
import 'package:maktrogps/data/model/commandmodel.dart';
import 'package:maktrogps/data/screens/livetrackoriginal.dart';
import 'package:maktrogps/data/screens/playback.dart';
import 'package:maktrogps/data/screens/playbackselection.dart';

import 'package:maktrogps/data/screens/reports/kmdetail.dart';
import 'package:maktrogps/data/screens/reports/reportselection.dart';
import 'package:maktrogps/data/screens/reports/vehicle_info.dart';
import 'package:maktrogps/data/screens/signin.dart';
import 'package:maktrogps/mapconfig/CustomColor.dart';
import 'package:maktrogps/ui/reusable/cache_image_network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:maktrogps/data/gpsserver/datasources.dart';

import '../../config/Session.dart';
import '../../mapconfig/CommonMethod.dart';
import '../model/Command.dart';

class lockscreenNew extends StatefulWidget {
  @override
  _lockscreenNewState createState() => _lockscreenNewState();
}

class _lockscreenNewState extends State<lockscreenNew> {
  List<Command> commands = [];

  List<String> commandsstr = [];

  String selectedcommands = "";
  Timer? _timer;
  var _isLoading = true;
  List<String> _commands = <String>[];
  List<String> _commandsValue = <String>[];
  int _selectedCommand = 0;
  final TextEditingController _customCommand = TextEditingController();

  @override
  void initState() {
    _isLoading = true;

    getCommands();
    super.initState();
  }

  getCommands() {
    gpsapis.getSavedCommands(StaticVarMethod.deviceId.toString()).then((value) {
      if (value != null) {
        _isLoading = false;
        Iterable list = json.decode(value.body);
        if (_commands.isEmpty) {
          list.forEach((element) {
            _commands.add(element["title"]);
            _commandsValue.add(element["type"]);
          });
          setState(() {});
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
        automaticallyImplyLeading: false,
        //automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: IconThemeData(
          color: GlobalStyle.appBarIconThemeColor,
        ),
        systemOverlayStyle: GlobalStyle.appBarSystemOverlayStyle,
        title: Row(
          spacing: 6,
          children: [
            Icon(
              Icons.terminal_outlined,
              color: Colors.black,
            ),
            Text(
              getTranslated(context, 'command')!,
              style: TextStyle(
                color: Colors.black,
              ),
            )
          ],
        ),
        backgroundColor: Colors.grey[300],
        //bottom: _reusableWidget.bottomAppBar(),
      ),
      body: ListView(
        children: [
          _deviceStatus(),
          _createAccountInformation(),
          _buildmoreswitch(),
          //_buildmoreManues(),
          commandControls(),
          // _Commandhistory(),
          //listView(),
        ],
      ),
    );
  }

  Widget _deviceStatus() {
    final double profilePictureSize = MediaQuery.of(context).size.width / 4;
    return Container(
        margin: EdgeInsets.all(5),
        //  padding: EdgeInsets.all(10),
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 8,
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'status')!,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        GestureDetector(
                          onTap: () {
                            Fluttertoast.showToast(
                                msg: 'Click account information / user profile',
                                toastLength: Toast.LENGTH_SHORT);
                          },
                          child: Row(
                            children: [
                              /* Text(''+expiration_date, style: TextStyle(
                          fontSize: 14, color: Colors.grey
                      )),
                      SizedBox(
                        width: 8,
                      ),
                      Icon(Icons.chevron_right, size: 20, color: SOFT_GREY)*/
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('' + StaticVarMethod.devicestatus + '   ',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: StaticVarMethod.devicestatuscolor)),
                        SizedBox(
                          height: 8,
                        ),
                        GestureDetector(
                          onTap: () {
                            Fluttertoast.showToast(
                                msg: 'Click account information / user profile',
                                toastLength: Toast.LENGTH_SHORT);
                          },
                          child: Row(
                            children: [
                              /* Text(''+expiration_date, style: TextStyle(
                          fontSize: 14, color: Colors.grey
                      )),
                      SizedBox(
                        width: 8,
                      ),
                      Icon(Icons.chevron_right, size: 20, color: SOFT_GREY)*/
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  Widget _createAccountInformation() {
    final double profilePictureSize = MediaQuery.of(context).size.width / 4;
    return Container(
        margin: EdgeInsets.all(5),
        //  padding: EdgeInsets.all(10),
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 8,
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.all(5),
              padding: EdgeInsets.only(left: 8, right: 8, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '' + StaticVarMethod.deviceName,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        GestureDetector(
                          onTap: () {
                            Fluttertoast.showToast(
                                msg: 'Click account information / user profile',
                                toastLength: Toast.LENGTH_SHORT);
                          },
                          child: Row(
                            children: [
                              /* Text(''+expiration_date, style: TextStyle(
                          fontSize: 14, color: Colors.grey
                      )),
                      SizedBox(
                        width: 8,
                      ),
                      Icon(Icons.chevron_right, size: 20, color: SOFT_GREY)*/
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('' + StaticVarMethod.imei,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 8,
                        ),
                        GestureDetector(
                          onTap: () {
                            Fluttertoast.showToast(
                                msg: 'Click account information / user profile',
                                toastLength: Toast.LENGTH_SHORT);
                          },
                          child: Row(
                            children: [
                              /* Text(''+expiration_date, style: TextStyle(
                          fontSize: 14, color: Colors.grey
                      )),
                      SizedBox(
                        width: 8,
                      ),
                      Icon(Icons.chevron_right, size: 20, color: SOFT_GREY)*/
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  Widget _buildmoreswitch() {
    return Container(
        margin: EdgeInsets.all(10),
        child: Center(
          child: Text(getTranslated(context, 'controlVehicleEngine')!,
              style: TextStyle(
                  fontSize: 15, height: 1.5, fontWeight: FontWeight.bold)),
        ));
  }

  void sendCommand() {
    Map<String, String> requestBody;

    if (_selectedCommand == 0) {
      requestBody = <String, String>{
        'id': "",
        'device_id': StaticVarMethod.deviceId,
        'type': "custom",
        'data': _customCommand.text
      };
    } else {
      requestBody = <String, String>{
        'id': "",
        'device_id': StaticVarMethod.deviceId,
        'type': _commandsValue[_selectedCommand]
      };
    }

    gpsapis.sendCommands(requestBody).then((res) => {
          print(requestBody),
          print(res.statusCode),
          if (res.statusCode == 200)
            {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                  getTranslated(context, 'command_sent')!,
                  style: TextStyle(fontSize: 20),
                )),
              ),
            }
          else
            {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    backgroundColor: Colors.deepOrange,
                    content: Text(
                      getTranslated(context, 'errorMsg')!,
                      style: TextStyle(fontSize: 20),
                    )),
              ),
              Navigator.of(context).pop()
            }
        });
  }

  void commandDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListView.builder(
          itemCount: _commands.length,
          itemBuilder: (context, index) {
            final command = _commands[index];
            return commandRow(command);
          },
        ));

    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Widget commandRow(command) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            _selectedCommand = _commands.indexOf(command);
            if (_selectedCommand == 0) {
              showSavedCommandDialog(context);
            } else {
              Navigator.of(context).pop();
              sendCommand();
            }
          },
          title: Text(command),
          trailing: Icon(Icons.arrow_forward_ios),
        ),
        Divider()
      ],
    );
  }

  void showSavedCommandDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(getTranslated(context, 'command')!),
                          ],
                        ),
                        Container(
                          child: TextField(
                            controller: _customCommand,
                            decoration: InputDecoration(
                                labelText: getTranslated(context, 'type')!),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                getTranslated(context, 'cancel')!,
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomColor.primaryColor,
                              ),
                              onPressed: () {
                                sendCommand();
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                getTranslated(context, 'ok')!,
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ));

    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Widget commandControls() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: <BoxShadow>[
            BoxShadow(
                blurRadius: 40,
                offset: Offset.zero,
                color: Colors.grey.withOpacity(0.5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  commandDialog(context);
                },
                child: Text(
                  getTranslated(context, 'select_command')!,
                  style: const TextStyle(color: Colors.black),
                ),
              )),
          Container(
              margin: const EdgeInsets.all(10),
              child: Center(
                child: Text(getTranslated(context, 'commandWaring')!,
                    style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.bold)),
              ))
        ],
      ),
    );
  }
//   Widget _Commandhistory(){
//     return Container(
//         margin: EdgeInsets.all(10),
//        // child:     Center(
//           child:
//         Text('Command History',  style: TextStyle(
//             fontSize: 17,height: 1.5,fontWeight: FontWeight.bold)),
//      //   )
//     );
//   }
//
//   Widget listView(){
//
//     return   Container(
//       height: MediaQuery.of(context).size.height / 1.5,
//       width: MediaQuery.of(context).size.width,
//       child: _isLoading == true
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         padding: EdgeInsets.only(bottom: 70),
//           itemCount: commandList.length,
//           itemBuilder: (BuildContext context, int index) {
//             return GestureDetector(
//                 child: listViewItems( index),
//                 onTap: () => onTapped());
//           }),
//     );
//     /*return ListView.builder(itemBuilder:(context,index){
//       return listViewItems(index);
//     },separatorBuilder: (context,index){
//       return Divider(height: 0);
//     }, itemCount: eventList.length);*/
//   }
//
//   onTapped() async {
//     /* Consts.DocId=approvalModel.DocId;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => GetApproval(loginModel: loginModel)),
//     );*/
//   }
//
//
//   Widget listViewItems(int index){
//     return Container(
//         margin: EdgeInsets.fromLTRB(6, 6, 6, 0),
//         child: Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             elevation: 2,
//             color: Colors.white,
//             child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Container(
//                       margin: EdgeInsets.only(left: 8,right: 5,top: 8,bottom: 15),
//
//                       child: Column(
//                         children: [
//                           //DeleteIcon(index),
//                           message(index),
//                           commandtext(index),
//                           timeAndDate(index),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ]
//             )
//         )
//     );
//   }
//
// /*  Widget listViewItems(int index){
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           prefixIcon(index),
//           Expanded(
//             child: Container(
//               margin: EdgeInsets.only(left: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   message(index),
//                   timeAndDate(index),
//                 ],
//               ),
//             ),
//           ),
//           DeleteIcon(index),
//         ],
//       ),
//     );
//   }*/
//
//   Widget prefixIconinfo(){
//     return
//       Container(
//         height: 55,
//         width: 55,
//         margin: EdgeInsets.only(top:15,left: 10),
//         padding: EdgeInsets.all(5),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white,
//         ),
//         child: Image.asset("assets/settingicon/aboutus.png", height: 55,width: 55),
//         /* child: Icon(Icons.notifications,
//           size: 25,
//           color:Colors.grey.shade700),*/
//       );
//   }
//
//
//
//   Widget message(int index){
//     double textsize=12;
//     return Container(
//       padding: EdgeInsets.only(right: 1,top: 10,bottom: 5),
//       child: RichText(
//         maxLines: 5,
//         textAlign: TextAlign.left,
//         overflow: TextOverflow.ellipsis,
//         text: TextSpan(
//             text:'Command send On ' +commandList[index].imei.toString() + ' Command Type ('+ commandList[index].commandtype.toString()+')',
//             style: TextStyle(
//               fontSize: textsize,
//               color: Colors.grey.shade700,
//               //fontWeight: FontWeight.bold
//             ),
//             children: [
//               /* TextSpan(
//                 text:eventList[index].message.toString() == "null" ? "" : eventList[index].message.toString(),
//                 style: TextStyle(
//
//                     fontWeight: FontWeight.w400),
//               )*/
//             ]
//         ),
//       ),
//     );
//   }
//
//   Widget commandtext(int index){
//     return Container(
//       //margin: EdgeInsets.only(top: 5),
//       padding: EdgeInsets.only(right: 10,bottom: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(commandList[index].command.toString(),style: TextStyle(
//             fontSize: 11,
//             color: Colors.grey.shade700,
//           ),
//           ),
//
//         ],
//       ),
//     );
//   }
//   Widget timeAndDate(int index){
//     return Container(
//       //margin: EdgeInsets.only(top: 5),
//       padding: EdgeInsets.only(right: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(formatTime(commandList[index].time.toString()),style: TextStyle(
//             fontSize: 11,
//             color: Colors.grey.shade700,
//           ),
//           ),
//           (commandList[index].status!.contains("green"))?
//           Image.asset("assets/images/cmddoubletickgreen.png", height: 20): Image.asset("assets/images/cmddoubletickred.png", height: 20),
//         ],
//       ),
//     );
//   }
//
//
}
