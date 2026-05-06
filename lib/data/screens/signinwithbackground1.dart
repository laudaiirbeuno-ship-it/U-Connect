import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/config/constant.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/loginModel.dart';
import 'package:uconnect/data/screens/listscreen.dart';
import 'package:uconnect/data/screens/supportscreen.dart';
import 'package:uconnect/ui/reusable/global_function.dart';
import 'package:uconnect/ui/reusable/global_widget.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/ui/widgets/one_nova_era_logo.dart';

import 'browser_module_old/browser.dart';

class signinwithbackground1 extends StatefulWidget {
  @override
  _signinState createState() => _signinState();
}

class _signinState extends State<signinwithbackground1> {
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
  String _username = "", _password = "", _cnic = "", _customserver = "";

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
                    image: DecorationImage(
                  image: AssetImage(
                    "assets/images/backgroundimage.jpeg",
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.70,
                )),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo personalizada ou nova imagem padrão
                      Consumer<AppSettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          return Container(
                            alignment: Alignment.topCenter,
                            child: settingsProvider.customLogo != null && 
                                   settingsProvider.customLogo!.existsSync()
                                ? Image.file(
                                    settingsProvider.customLogo!,
                                    width: 280,
                                    height: 140,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Em caso de erro, usar logo-main padrão
                                      return Image.asset(
                                        'assets/appsicon/logo-main.png',
                                        width: 280,
                                        height: 140,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback para IMG se logo-main não existir
                                          return Image.asset(
                                            'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
                                            width: 280,
                                            height: 140,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Fallback para OneNovaEraLogo se nenhuma imagem existir
                                              return OneNovaEraLogo(
                                                width: 280,
                                                height: 140,
                                                useCustomStyle: settingsProvider.logoCustomStyle,
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  )
                                : Image.asset(
                              'assets/appsicon/logo-main.png',
                              width: 280,
                              height: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback para IMG se logo-main não existir
                                return Image.asset(
                                  'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
                                  width: 280,
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback para OneNovaEraLogo se nenhuma imagem existir
                                    return OneNovaEraLogo(
                                      width: 280,
                                      height: 140,
                                      useCustomStyle: settingsProvider.logoCustomStyle,
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
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
                                        borderSide: BorderSide(
                                            color: Colors.transparent)),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.transparent),
                                    ),
                                    //labelText: 'Email / IMEI',
                                    labelText: TranslationHelper.translateSync(context, 'ID do Usuário', 'User ID'),
                                    labelStyle:
                                        TextStyle(color: Colors.grey[500])),
                              ))),
                      SizedBox(
                        height: 10,
                      ),
                      Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
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
                                      borderSide: BorderSide(
                                          color: Colors.transparent)),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                  ),
                                  labelText: TranslationHelper.translateSync(context, 'Senha', 'Password'),
                                  labelStyle:
                                      TextStyle(color: Colors.grey[500]),
                                  suffixIcon: IconButton(
                                      icon: Icon(_iconVisible,
                                          color: Colors.grey[500], size: 20),
                                      onPressed: () {
                                        _toggleObscureText();
                                      }),
                                ),
                              ))),
                      SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 48,
                        // width: double.maxFinite,
                        child: TextButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) => _mainColor,
                              ),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.transparent),
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              )),
                            ),
                            onPressed: () {
                              EasyLoading.show(status: TranslationHelper.translateSync(context, 'Carregando...', 'Loading...'));
                              //_globalFunction.showProgressDialog(context);
                              if (_username == null || _username.isEmpty) {
                                Fluttertoast.showToast(
                                    msg: TranslationHelper.translateSync(context, 'Por favor, informe o ID do usuário!', 'Please provide username!'),
                                    toastLength: Toast.LENGTH_SHORT);
                                EasyLoading.dismiss();
                              } else if (_password == null ||
                                  _password.isEmpty) {
                                Fluttertoast.showToast(
                                    msg: TranslationHelper.translateSync(context, 'Por favor, informe a senha!', 'Please provide password!'),
                                    toastLength: Toast.LENGTH_SHORT);
                                EasyLoading.dismiss();
                              } else {
                                login();
                              }
                              // Fluttertoast.showToast(msg: 'Click login', toastLength: Toast.LENGTH_SHORT);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
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
                                    TranslationHelper.translateSync(context, 'ENTRAR', 'LOGIN'),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )),
                      ),

                      //  bottomtermandconditions()
                      SizedBox(
                        height: 30,
                      ),
                      support()
                    ],
                  ),
                );
              }),
            ],
          ),
        ));
  }

  Widget support() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // _username="abc@gmail.com";
              _username = "demo@gmail.com";
              _password = "123456";
              login();
            },
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                child: Container(
                    height: 48,
                    padding: EdgeInsets.only(left: 20, right: 10),
                    child: Row(children: <Widget>[
                      Icon(
                        Icons.person,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      Text(TranslationHelper.translateSync(context, 'Usuário Demo', 'Demo User'),
                          style: TextStyle(
                              fontSize: 12,
                              height: 2.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black))
                    ]))),
          ),
        ),

        Expanded(
          child: GestureDetector(
            onTap: () {
              //  _launchURL("http://167.86.91.29/registration/create");
              //  String url ='http://167.86.91.29/registration/create';
              // String url ='http://103.254.84.148/registration/create';
              // RegisterPage removido - não é mais necessário
            },
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
                child: Container(
                    height: 48,
                    color: Color(0xff13BBAF),
                    padding: EdgeInsets.only(left: 20, right: 10),
                    child: Row(children: <Widget>[
                      Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(TranslationHelper.translateSync(context, 'Registrar-se', 'Sign up'),
                          style: TextStyle(
                              fontSize: 12,
                              height: 2.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.white))
                    ]))),
          ),
        ),
        // Expanded(
        //   child:  GestureDetector(
        //     onTap: () {
        //       // _launchURL("https://m.me/253098044733617?ref=bb54fea9559f614364722d530070222f3980223b84f769ff1");
        //       // launchWhatsApp();
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //             builder: (context) => supportscreen()),
        //       );
        //
        //     },
        //     child: Container(
        //
        //         child:   Column(
        //             children: <Widget>[
        //               Image.asset("assets/speedoicon/assets_images_whatsappicon.png", height: 30,width: 30),
        //               Text('  Support  ',  style: TextStyle(
        //                   fontSize: 12,height: 2.0,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent))
        //             ]
        //         )
        //     ),
        //   ),
        // ),
        // Expanded(
        //   child:  GestureDetector(
        //     onTap: () {
        //      // _launchURL("http://184.174.37.251/assets/landing/index.html");
        //
        //    //   String url ='http://184.174.37.251/assets/landing/index.html';
        //       String url ='http://167.86.91.29';
        //
        //       //_launchURL("https://safetygpstracker.com.bd/Pay_bill");
        //     //  _launchURL("https://mototrackerbd.com/dashboard/customer_bill_pay");
        //       Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //               builder: (context) => Browser(
        //                 dashboardName: "Pricing",
        //                 dashboardURL: url,
        //               )));
        //
        //     },
        //     child: Container(
        //
        //         child:   Column(
        //             children: <Widget>[
        //               Image.asset("assets/speedoicon/assets_images_payicon.png", height: 30,width: 30),
        //               Text('  Pricing  ',  style: TextStyle(
        //                   fontSize: 12,height: 2.0,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent))
        //             ]
        //         )
        //     ),
        //   ),
        // ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              showserverDialog(context);
            },
            child: Container(
                child: Column(children: <Widget>[
              Image.asset("assets/images/switchserver.png",
                  height: 30, width: 30),
              Text(TranslationHelper.translateSync(context, '  Trocar Servidor  ', '  Switch Server  '),
                  style: TextStyle(
                      fontSize: 13,
                      height: 2.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlueAccent))
            ])),
          ),
        ),
      ],
    );
  }

  _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  launchWhatsApp() async {
    final link = WhatsAppUnilink(
      phoneNumber: '+8801711927826',
      text: "Hey! I'm inquiring about the Tracking listing",
    );
    await launch('$link');
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

          // Enviar token FCM ao servidor após login
          if (StaticVarMethod.notificationToken.isNotEmpty) {
            gpsapis.activateFCM(StaticVarMethod.notificationToken).then((fcmResponse) {
              if (fcmResponse.statusCode == 200 || fcmResponse.statusCode == 201) {
                print("✅ Token FCM enviado ao servidor após login");
              } else {
                print("⚠️ Erro ao enviar token FCM após login: ${fcmResponse.statusCode}");
              }
            }).catchError((e) {
              print("❌ Erro ao enviar token FCM após login: $e");
            });
          }

          Navigator.push(
            context,
            MaterialPageRoute(
                // builder: (context) => BottomNavigation( loginModel: response)),
                //  builder: (context) => BottomNavigation()),
                builder: (context) => BottomNavigation_01()),
          );
        } else if (response.statusCode == 401) {
          isBusy = false;
          isLoggedIn = false;
          EasyLoading.dismiss();
          Fluttertoast.showToast(
              msg: TranslationHelper.translateSync(context, "Login falhou", "Login Failed"),
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
                title: Text(TranslationHelper.translateSync(context, "Falhou", "Failed")),
                content: Text(TranslationHelper.translateSync(context, "Login falhou", "Login Failed")),
                actions: <Widget>[
                  new ElevatedButton(
                    onPressed: () {
                      EasyLoading.dismiss();
                      Navigator.of(context, rootNavigator: true)
                          .pop(); // dismisses only the dialog and returns nothing
                    },
                    child: new Text(TranslationHelper.translateSync(context, "OK", "OK")),
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
            msg: TranslationHelper.translateSync(context, "Mensagem de erro", "Error message"),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.lightGreen.shade50,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      /*   if (response != null) {
        var res= LoginModel.fromJson(json.decode(response.body));
        StaticVarMethod.user_api_hash=res.userApiHash;
        EasyLoading.dismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
             // builder: (context) => BottomNavigation( loginModel: response)),
              builder: (context) => BottomNavigation()),
        );
      }else{

      }*/
    });
    // }
    // else{
    //
    //
    //   Fluttertoast.showToast(
    //       msg: "You are not registered!!!",
    //       toastLength: Toast.LENGTH_SHORT,
    //       gravity: ToastGravity.CENTER,
    //       timeInSecForIosWeb: 1,
    //       backgroundColor: Colors.black54,
    //       textColor: Colors.white,
    //       fontSize: 16.0);
    // }
  }

  void showserverDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new Container(
            height: _dialogHeight,
            width: 300.0,
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
                          // new Row(
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   children: <Widget>[
                          //     new Radio(
                          //       value: 0,
                          //       groupValue: _selectedserver,
                          //       onChanged: (value) {
                          //         setState(() {
                          //           _selectedserver = value!;
                          //           _dialogHeight = 300.0;
                          //         });
                          //       },
                          //     ),
                          //     new Text('Impressive Security',
                          //       style: new TextStyle(fontSize: 16.0),
                          //     ),
                          //   ],
                          // ),
                          // new Row(
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   children: <Widget>[
                          //     new Radio(
                          //       value: 1,
                          //       groupValue: _selectedserver,
                          //       onChanged: (value) {
                          //         setState(() {
                          //           _selectedserver = value!;
                          //           _dialogHeight = 300.0;
                          //         });
                          //       },
                          //     ),
                          //     new Text('Safety GPS',
                          //       style: new TextStyle(fontSize: 16.0),
                          //     ),
                          //   ],
                          // ),
                          // new Row(
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   children: <Widget>[
                          //     new Radio(
                          //       value: 2,
                          //       groupValue: _selectedserver,
                          //       onChanged: (value) {
                          //         setState(() {
                          //           _selectedserver = value!;
                          //           _dialogHeight = 300.0;
                          //         });
                          //       },
                          //     ),
                          //     new Text('BRTC VTS',
                          //       style: new TextStyle(fontSize: 16.0),
                          //     ),
                          //   ],
                          // ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 3,
                                groupValue: _selectedserver,
                                onChanged: (value) {
                                  setState(() {
                                    _dialogHeight = 400.0;
                                    _selectedserver = value!;
                                  });
                                },
                              ),
                              new Text(
                                TranslationHelper.translateSync(context, 'Servidor Personalizado', 'Custom Server'),
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          _selectedserver == 3
                              ? new Container(
                                  padding: EdgeInsets.all(20),
                                  child: new Column(
                                    children: <Widget>[
                                      TextField(
                                        controller:
                                            _customserverFieldController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        //controller: _usernameFieldController,
                                        onChanged: (String value) {
                                          _customserver = value;
                                        },
                                        decoration: InputDecoration(
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.grey)),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey),
                                            ),
                                            labelText: TranslationHelper.translateSync(context, 'Servidor Personalizado', 'Custom Server'),
                                            labelStyle: TextStyle(
                                                color: Colors.grey[500])),
                                      )
                                    ],
                                  ))
                              : new Container(),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  TranslationHelper.translateSync(context, 'Cancelar', 'Cancel'),
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showReport();
                                },
                                child: Text(
                                  TranslationHelper.translateSync(context, 'Salvar', 'Save'),
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
                ),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> showReport() async {
    if (_selectedserver == 0) {
      await prefs!.setString('baseurlall', "https://track.impressivebd.com");

      StaticVarMethod.baseurlall = "https://track.impressivebd.com";
      _customserverFieldController.text = StaticVarMethod.baseurlall;
      Navigator.pop(context);
    } else if (_selectedserver == 1) {
      await prefs!.setString('baseurlall', "https://track.safetyvts.com");
      StaticVarMethod.baseurlall = "https://track.safetyvts.com";
      _customserverFieldController.text = StaticVarMethod.baseurlall;
      Navigator.pop(context);
    } else if (_selectedserver == 2) {
      await prefs!.setString('baseurlall', "http://brtcvts.com");
      StaticVarMethod.baseurlall = "http://brtcvts.com";
      _customserverFieldController.text = StaticVarMethod.baseurlall;
      Navigator.pop(context);
    } else if (_selectedserver == 3) {
      await prefs!.setString('baseurlall', _customserver);
      StaticVarMethod.baseurlall = _customserver;
      _customserverFieldController.text = StaticVarMethod.baseurlall;
      Navigator.pop(context);
    }

    setState(() {});
  }

/*  void updateToken() {
    gpsapis.getUserData()
        .then((value) => {gpsapis.activateFCM(StaticVarMethod.notificationToken)});
  }*/
/*  api.getHistory(response.userApiHash).then((response){
          if (response != null) {

            var res=response.items?.length;

          }
        });
        api.getEvents(response.userApiHash).then((response){
          if (response != null) {

            var res=response.items?.data?.length;
            print(res);

          }
        });
        print(response.userApiHash);*/
}
