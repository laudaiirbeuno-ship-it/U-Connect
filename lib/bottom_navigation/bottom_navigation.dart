import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/model/loginModel.dart';
import 'package:maktrogps/data/screens/listscreen.dart';
import 'package:maktrogps/data/screens/mainmapscreenoriginal.dart';
import 'package:maktrogps/data/screens/mapscreen.dart';
import 'package:maktrogps/data/screens/newmap.dart';
import 'package:maktrogps/data/screens/notificationscreen.dart';
import 'package:maktrogps/data/screens/settingscreen_old.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:flutter/material.dart';
import 'package:maktrogps/data/gpsserver/datasources.dart';

import '../data/screens/mainmapscreen.dart';
import '../data/screens/settingscreens/settingscreen.dart';
/*
class BottomNavigation extends StatefulWidget {

  final LoginModel loginModel;
  BottomNavigation({Key? key, required this.loginModel}) : super(key: key);
  @override
  _BottomNavigationState createState() => _BottomNavigationState(loginModel:loginModel);
}*/

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  late PageController _pageController;
  int _currentIndex = 0;

  // Pages if you click bottom navigation
  final List<Widget> _contentPages = <Widget>[
    //listscreen(loginModel : ""),
    listscreen(),
    mainmapscreen(),
    NotificationsPage(),
    settingscreen(),
  ];

  @override
  void initState() {
    // set initial pages for navigation to home page
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_handleTabSelection);

    /*gpsserverapis.getuserloginapikey();
    gpsserverapis.login("abc@gmail.com","demo123456");
    gpsserverapis.getDevicesItems("");*/
    super.initState();
    updateToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {});
  }

  Future<void> updateToken() async {
    gpsapis.getUserData().then(
        (value) => {gpsapis.activateFCM(StaticVarMethod.notificationToken)});

    AudioPlayer player = AudioPlayer();
    String audioasset = "assets/audio/ignitiononnoti.mp3";
    ByteData bytes = await rootBundle.load(audioasset); //load sound from assets
    Uint8List soundbytes =
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    // int result = await player.play(soundbytes);
    // if(result == 1){ //play success
    //   print("Sound playing successful.");
    // }else{
    //   print("Error while playing sound.");
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100,
      /*appBar: _globalWidget.globalAppBar(),*/
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _contentPages.map((Widget content) {
          return content;
        }).toList(),
      ),
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 60.0,
        items: <Widget>[
          Icon(
            Icons.list,
            size: 30,
            color: Colors.white,
          ),
          Icon(Icons.fmd_good_outlined, size: 30, color: Colors.white),
          Icon(Icons.more, size: 30, color: Colors.white),
          Icon(Icons.notifications_sharp, size: 30, color: Colors.white),
          // Icon(Icons.more, size: 30,color: Colors.white),
        ],
        color: Colors.blue.shade900,

        //buttonBackgroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        //animationCurve: Curves.easeInOut,
        //animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            setState(() {
              _currentIndex = index;
              _pageController.jumpToPage(index);
              // this unfocus is to prevent show keyboard in the text field
              FocusScope.of(context).unfocus();
            });
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
