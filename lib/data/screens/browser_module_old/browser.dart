import 'package:flutter/material.dart';
import 'package:uconnect/ui/reusable/custom_app_bar.dart'; // Importe o CustomAppBar
//import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Browser extends StatefulWidget {
  static final String path = "/browser_module_old/browser.dart";

  String dashboardName = "";
  String dashboardURL = "";

  Browser({Key? key, required this.dashboardName, required this.dashboardURL})
      : super(key: key);

  @override
  _BrowserState createState() =>
      _BrowserState(dashboardName: dashboardName, dashboardURL: dashboardURL);
}

class _BrowserState extends State<Browser> with SingleTickerProviderStateMixin {
  String dashboardName = "";
  String dashboardURL = "";
  String returnUrlVal = "";
  static const primary = Color(0xff0540ac);
  // static const primary = Color(0xffD73034);
  final key = new GlobalKey<ScaffoldState>();
  _BrowserState({required this.dashboardName, required this.dashboardURL});

  var _isRestored = false;
  bool status = false;

  @override
  void initState() {
//    status = false;

    super.initState();
  }

  @override
  void dispose() {
    returnUrlVal = "";
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isRestored) {
      _isRestored = true;
    }
    precacheImage(AssetImage("assets/images/app_icon.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: key,
        // resizeToAvoidBottomPadding: false,
        appBar: CustomAppBar(title: dashboardName), // Usando o CustomAppBar
        backgroundColor: Colors.white,
        //   body: InAppWebView(
        //     initialUrlRequest: URLRequest(
        //         url: Uri.parse(dashboardURL)) // updated
        //
        // /*    initialHeaders: {},
        //     initialOptions: InAppWebViewGroupOptions(
        //       crossPlatform: InAppWebViewOptions(
        //           supportZoom: false, // zoom support
        //           debuggingEnabled: true,
        //           preferredContentMode: UserPreferredContentMode.MOBILE), // here you change the mode
        //     ),
        //     onWebViewCreated: (InAppWebViewController controller) {
        //       webView = controller;
        //     },
        //     onLoadStart: (InAppWebViewController controller, String url) {
        //
        //     },
        //     onLoadStop: (InAppWebViewController controller, String url) async {
        //
        //     },*/
        //   )
        body: Text(
            "No Browser") /* WebView(
          initialUrl: Uri.parse(dashboardURL).toString(),
          javascriptMode: JavascriptMode.unrestricted,
        )*/
        );
  }

  /* Widget _buildBrowser() {




    return WebView(
      initialUrl: dashboardURL,
      javascriptMode: JavascriptMode.unrestricted,
    );
  }*/
}
