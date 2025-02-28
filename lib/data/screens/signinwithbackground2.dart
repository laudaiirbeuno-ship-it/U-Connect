import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:maktrogps/bottom_navigation/bottom_navigation.dart';
import 'package:maktrogps/bottom_navigation/bottom_navigation_01.dart';
import 'package:maktrogps/config/constant.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/model/loginModel.dart';
import 'package:maktrogps/data/screens/listscreen.dart';
import 'package:maktrogps/data/screens/mainmapscreenoriginal.dart';
import 'package:maktrogps/data/screens/register_page.dart';
import 'package:maktrogps/data/screens/registerscreennew.dart';
import 'package:maktrogps/data/screens/supportscreen.dart';
import 'package:maktrogps/storage/user_repository.dart';
import 'package:maktrogps/ui/reusable/global_function.dart';
import 'package:maktrogps/ui/reusable/global_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../config/Session.dart';
import 'browser_module_old/browser.dart';

class signinwithbackground2 extends StatefulWidget {
  @override
  _signinState createState() => _signinState();
}

class _signinState extends State<signinwithbackground2> {
  bool _obscureText = true;
  IconData _iconVisible = Icons.visibility_off;
  final _globalWidget = GlobalWidget();
  final _globalFunction = GlobalFunction();
  Color _gradientTop = Color(0xFF039be6);
  Color _gradientBottom = Color(0xFF0299e2);
  Color mainColor = Color(0xff0540ac);

  // Color themeDark = Color(0xff009640);
  Color _underlineColor = Color(0xFFCCCCCC);
  late LoginModel loginModel;
  String _username = "abc@gmail.com",
      _password = "123456",
      _cnic = "",
      _customserver = "";

  //text controlller//
  TextEditingController _usernameFieldController = TextEditingController();
  TextEditingController _passwordFieldController = TextEditingController();
  TextEditingController _customserverFieldController = TextEditingController();
  late SharedPreferences prefs;
  bool isBusy = true;
  bool isLoggedIn = false;

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
      if (_obscureText == true) {
        _iconVisible = Icons.visibility_off;
      } else {
        _iconVisible = Icons.visibility;
      }
    });
  }

  int _selectedserver = 0;
  double _dialogHeight = 300.0;
  double _dialogCommandHeight = 150.0;
  Color _mainColor = Color(0xff2e414b);
  @override
  void initState() {
    _usernameFieldController.addListener(_emailListen);
    _passwordFieldController.addListener(_passwordListen);

    checkPreference();
    super.initState();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.get('email') != null) {
      _usernameFieldController.text = prefs.getString('email')!;
      _passwordFieldController.text = prefs.getString('password')!;

      _customserverFieldController.text = prefs!.get('baseurlall').toString();
      login();
    } else {
      isBusy = false;
      setState(() {});
    }
  }

  void _emailListen() {
    if (_usernameFieldController.text.isEmpty) {
      _username = "";
    } else {
      _username = _usernameFieldController.text;
    }
  }

  void _passwordListen() {
    if (_passwordFieldController.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFieldController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: Platform.isIOS
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
          child: Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                    color: Color(0xFF050A30),
                    // imagColor.fromARGB(255, 8, 64, 128)ge(
                    //   // image: AssetImage(
                    //   //   "assets/images/login-background.png",
                    //   // ),
                    //   // fit: BoxFit.cover,
                    //   // opacity: 1,
                    // ),
                    //   image: DecorationImage(image: AssetImage("assets/images/loginbackgroundimage.jpeg",),fit: BoxFit.cover,opacity: 0.70,)
                    ),
              ),
              // top blue background gradient

              // Container(
              //   height: MediaQuery.of(context).size.height,
              //   decoration: BoxDecoration(
              //     image: DecorationImage(
              //       image: AssetImage("assets/images/backgroundimage.jpeg"),
              //       fit: BoxFit.cover,
              //     ),
              //     /* gradient: LinearGradient(
              //           colors: [_gradientTop, _gradientBottom],
              //           begin: Alignment.topCenter,
              //           end: Alignment.bottomCenter)*/
              //   ),
              // ),
              // Container(
              //   height: MediaQuery.of(context).size.height / 3.5,
              //   decoration: BoxDecoration(
              //       gradient: LinearGradient(
              //           colors: [_gradientTop, _gradientBottom],
              //           begin: Alignment.topCenter,
              //           end: Alignment.bottomCenter)),
              // ),
              // set your logo here
              //           Container(
              //               margin: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height / 10, 0, 0),
              //               alignment: Alignment.topCenter,
              //               child:Image.asset(StaticVarMethod.splashimageurl,height: 60) /*Image.asset('assets/appsicon/btplloginlogo.png', height: 90)*/
              //
              //            // child: Text("Track With Advance Technology"),
              // ),
              StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ListView(
                    children: [
                      //SizedBox(height:MediaQuery.of(context).size.height*0.15),

                      Container(
                        margin: EdgeInsets.fromLTRB(0, 50, 0, 25),
                        alignment: Alignment.topCenter,
                        child: Image.asset(
                          StaticVarMethod.loginimageurl,
                          scale: 1.5,
                        ),
                      ),
                      //const SizedBox(height: 50,),
                      Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Color(0xFF050A30),
                          elevation: 2,
                          child: Container(
                              height: 48,
                              padding: EdgeInsets.only(left: 20, right: 10),
                              child: TextField(
                                controller: _usernameFieldController,
                                keyboardType: TextInputType.emailAddress,
                                //controller: _usernameFieldController,
                                onChanged: (String value) {
                                  _username = value;
                                },
                                decoration: InputDecoration(
                                  focusedBorder: const UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  //labelText: 'Email / IMEI',
                                  // labelText: 'USER  ID',

                                  labelText:
                                      getTranslated(context, 'username')!,
                                  // labelText: 'Email / UserName',
                                  labelStyle: TextStyle(color: Colors.white),
                                  prefixIcon: Icon(
                                    Icons.mail_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ))),
                      SizedBox(
                        height: 16,
                      ),
                      Card(
                          color: Color(0xFF050A30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: Container(
                              height: 48,
                              padding: EdgeInsets.only(left: 20, right: 10),
                              child: TextField(
                                controller: _passwordFieldController,
                                obscureText: _obscureText,
                                //controller: _passwordFieldController,
                                onChanged: (String value) {
                                  _password = value;
                                },
                                decoration: InputDecoration(
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  labelText:
                                      getTranslated(context, 'password')!,
                                  labelStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white,
                                  ),
                                  suffixIcon: IconButton(
                                      icon: Icon(_iconVisible,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        _toggleObscureText();
                                      }),
                                ),
                                style: TextStyle(color: Colors.white),
                              ))),
                      SizedBox(
                        height: 40,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: SizedBox(
                          height: 48,
                          // width: double.maxFinite,
                          child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Color(0xFF223DFF)),
                                overlayColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                EasyLoading.show(status: 'loading...');
                                //_globalFunction.showProgressDialog(context);
                                if (_username == null || _username.isEmpty) {
                                  Fluttertoast.showToast(
                                      msg: 'please provide username !!',
                                      toastLength: Toast.LENGTH_SHORT);
                                  EasyLoading.dismiss();
                                } else if (_password == null ||
                                    _password.isEmpty) {
                                  Fluttertoast.showToast(
                                      msg:
                                          '_password == null || _password.isEmpty',
                                      toastLength: Toast.LENGTH_SHORT);
                                  EasyLoading.dismiss();
                                } else {
                                  login();
                                }
                                // Fluttertoast.showToast(msg: 'Click login', toastLength: Toast.LENGTH_SHORT);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.login,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Text(
                                      getTranslated(context, 'loginTitle')!,
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: SizedBox(
                          height: 48,
                          // width: double.maxFinite,
                          child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                overlayColor: MaterialStateProperty.all(
                                    Colors.transparent),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                const url = 'https://web.unnicatelemetria.com.br/password_reminder';
                                final Uri _url = Uri.parse(url);
                                if (await canLaunchUrl(_url)) {
                                  await launchUrl(_url);
                                } else {
                                  Fluttertoast.showToast(msg: 'Sem permissão para abrir navegador', toastLength: Toast.LENGTH_SHORT);
                                }
                                // Fluttertoast.showToast(msg: 'Reset password', toastLength: Toast.LENGTH_SHORT);
                              },
                              child: Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    Text(
                                      "Esqueci minha senha",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              }),
            ],
          ),
        ));
  }

  Future<void> login() async {
    gpsapis api = new gpsapis();

    // if(_username.contains("abc@gmail.co")){
    api.getlogin(_username, _password).then((response) {
      if (response != null) {
        if (response.statusCode == 200) {
          prefs.setBool("popup_notify", true);
          prefs.setString("user", response.body);
          isBusy = false;
          isLoggedIn = true;
          final res = LoginModel.fromJson(json.decode(response.body));
          StaticVarMethod.user_api_hash = res.userApiHash;
          EasyLoading.dismiss();
          prefs.setString('user_api_hash', res.userApiHash!);

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BottomNavigation_01()),
          );
        } else if (response.statusCode == 401) {
          isBusy = false;
          isLoggedIn = false;
          EasyLoading.dismiss();
          Fluttertoast.showToast(
              msg: "Login Failed",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0);
          setState(() {});
        } else if (response.statusCode == 400) {
          isBusy = false;
          isLoggedIn = false;
          if (response.body ==
              "Account has expired - SecurityException (PermissionsManager:259 < *:441 < SessionResource:104 < ...)") {
            setState(() {});
            showDialog(
              context: context,
              builder: (context) => new AlertDialog(
                title: Text("Failed"),
                content: Text("Login Failed"),
                actions: <Widget>[
                  new ElevatedButton(
                    onPressed: () {
                      EasyLoading.dismiss();
                      Navigator.of(context, rootNavigator: true)
                          .pop(); // dismisses only the dialog and returns nothing
                    },
                    child: new Text("ok"),
                  ),
                ],
              ),
            );
          }
        } else {
          isBusy = false;
          isLoggedIn = false;
          EasyLoading.dismiss();
          Fluttertoast.showToast(
              msg: response.body,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0);
          setState(() {});
        }
      } else {
        isLoggedIn = false;
        isBusy = false;
        setState(() {});
        EasyLoading.dismiss();
        Fluttertoast.showToast(
            msg: "Error Msg",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.lightGreen.shade50,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    
    });
  }

}
