import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/data/model/User.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';

import '../../../config/Session.dart';
import '../../../main.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/utils/responsive_helper.dart';
import 'package:uconnect/utils/translation_helper.dart';

class settingscreen extends StatefulWidget {
  @override
  State<settingscreen> createState() => _settingscreenState();
}

class _settingscreenState extends State<settingscreen> {
  late User user;
  bool isLoading = true;
  String? _currentLanguageCode;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentLanguage();
  }

  Future<void> _loadUserData() async {
    final data = await gpsapis.getUserData();
    if (data != null) {
      setState(() {
        user = data;
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(LAGUAGE_CODE) ?? 'pt';
    setState(() {
      _currentLanguageCode = languageCode;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAGUAGE_CODE, languageCode);
    
    final locale = await setLocale(languageCode);
    
    if (mounted) {
      MyHomePage.setLocale(context, locale);
      setState(() {
        _currentLanguageCode = languageCode;
      });
      
      String languageName = '';
      switch (languageCode) {
        case 'pt':
          languageName = TranslationHelper.translateSync(context, "Português (Brasil)", "Portuguese (Brazil)", spanish: "Portugués (Brasil)", french: "Portugais (Brésil)", italian: "Portoghese (Brasile)");
          break;
        case 'en':
          languageName = TranslationHelper.translateSync(context, "English (British)", "English (British)", spanish: "Inglés (Británico)", french: "Anglais (Britannique)", italian: "Inglese (Britannico)");
          break;
        case 'es':
          languageName = TranslationHelper.translateSync(context, "Español", "Spanish", spanish: "Español", french: "Espagnol", italian: "Spagnolo");
          break;
        case 'fr':
          languageName = TranslationHelper.translateSync(context, "Français", "French", spanish: "Francés", french: "Français", italian: "Francese");
          break;
        case 'it':
          languageName = TranslationHelper.translateSync(context, "Italiano", "Italian", spanish: "Italiano", french: "Italien", italian: "Italiano");
          break;
      }
      
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(
          context, 
          "Idioma alterado para $languageName", 
          "Language changed to $languageName",
          spanish: "Idioma cambiado a $languageName",
          french: "Langue changée en $languageName",
          italian: "Lingua cambiata in $languageName"
        ),
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _openSupportWhatsApp() async {
    final url = Uri.parse("https://wa.me/5511937758640");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, "Não foi possível abrir o WhatsApp", "Could not open WhatsApp"),
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F5C),
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String languageCode, IconData icon) {
    final isSelected = _currentLanguageCode == languageCode;
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
          ? colorProvider.primaryColor.withOpacity(0.1) 
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? colorProvider.primaryColor 
            : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
            ? colorProvider.primaryColor 
            : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
              ? colorProvider.primaryColor 
              : Colors.grey.shade800,
          ),
        ),
        trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: colorProvider.primaryColor,
            )
          : null,
        onTap: () => _changeLanguage(languageCode),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, "Configurações", "Settings"),
          icon: Icons.settings
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
          ),
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, "Configurações", "Settings"),
        icon: Icons.settings
      ),
      backgroundColor: Colors.grey.shade50,
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            
            // Seção: Login e Senha
            _buildSection(TranslationHelper.translateSync(context, "Login e Senha", "Login and Password"), [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TranslationHelper.translateSync(context, "Para alterar seu login ou senha, entre em contato com o suporte.", "To change your login or password, please contact support."),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _openSupportWhatsApp,
                            icon: Icon(Icons.chat, size: 18),
                            label: Text(TranslationHelper.translateSync(context, "Falar com Suporte", "Contact Support")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),

            // Seção: Idiomas
            _buildSection(TranslationHelper.translateSync(context, "Idiomas", "Languages"), [
              _buildLanguageOption(
                TranslationHelper.translateSync(context, "Português (Brasil)", "Portuguese (Brazil)"),
                "pt",
                Icons.language,
              ),
              _buildLanguageOption(
                TranslationHelper.translateSync(context, "English (British)", "English (British)"),
                "en",
                Icons.language,
              ),
              _buildLanguageOption(
                TranslationHelper.translateSync(context, "Español", "Spanish", spanish: "Español", french: "Espagnol", italian: "Spagnolo"),
                "es",
                Icons.language,
              ),
              _buildLanguageOption(
                TranslationHelper.translateSync(context, "Français", "French", spanish: "Francés", french: "Français", italian: "Francese"),
                "fr",
                Icons.language,
              ),
              _buildLanguageOption(
                TranslationHelper.translateSync(context, "Italiano", "Italian", spanish: "Italiano", french: "Italien", italian: "Italiano"),
                "it",
                Icons.language,
              ),
            ]),

            SizedBox(height: 100), // Espaço para o bottom navigation
          ],
        ),
      ),
    );
  }
}
