import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final LatLng _companyLocation = LatLng(-26.0771, -53.0506); // Francisco Beltrão - Edifício El Dourado
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Suporte', 'Support'),
        icon: Icons.support_agent,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Consumer<ColorProvider>(
        builder: (context, colorProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de contato WhatsApp
                _buildWhatsAppCard(colorProvider),
                SizedBox(height: 20),
                
                // Informações de contato
                _buildContactInfoCard(colorProvider),
                SizedBox(height: 20),
                
                // Horário de atendimento
                _buildScheduleCard(colorProvider),
                SizedBox(height: 20),
                
                // Endereço
                _buildAddressCard(colorProvider),
                SizedBox(height: 20),
                
                // Mapa com localização
                _buildMapCard(colorProvider),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhatsAppCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat,
            color: Colors.white,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            TranslationHelper.translateSync(context, 'Fale Conosco', 'Contact Us'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            TranslationHelper.translateSync(context, 'Atendimento via WhatsApp', 'Support via WhatsApp'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(),
              icon: Icon(Icons.chat_bubble),
              label: Text(TranslationHelper.translateSync(context, 'Abrir WhatsApp', 'Open WhatsApp')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(Icons.contact_support, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Informações de Contato', 'Contact Information'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildContactItem(
            TranslationHelper.translateSync(context, 'WhatsApp', 'WhatsApp'),
            '11 93775-8640',
            Icons.chat,
            Colors.green,
            () => _openWhatsApp(),
            colorProvider,
          ),
          SizedBox(height: 12),
          _buildContactItem(
            TranslationHelper.translateSync(context, 'E-mail', 'E-mail'),
            'suporte@unnicatelemtria.com.br',
            Icons.email,
            Colors.blue,
            () => _sendEmail(),
            colorProvider,
          ),
          SizedBox(height: 12),
          _buildContactItem(
            TranslationHelper.translateSync(context, 'Site', 'Website'),
            'unnicateletria.com.br',
            Icons.language,
            Colors.purple,
            () => _openWebsite(),
            colorProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
    ColorProvider colorProvider,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.access_time, color: colorProvider.primaryColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translateSync(context, 'Horário de Atendimento', 'Service Hours'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  TranslationHelper.translateSync(context, 'Segunda a Sexta: 8h às 18h', 'Monday to Friday: 8am to 6pm'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.location_on, color: colorProvider.primaryColor, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translateSync(context, 'Endereço', 'Address'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rua Tenente Camargo\nFrancisco Beltrão - PR\nEdifício El Dourado',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(Icons.map, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Localização', 'Location'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _companyLocation,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('company'),
                    position: _companyLocation,
                    infoWindow: InfoWindow(
                      title: 'Unnicatelemetria',
                      snippet: 'Rua Tenente Camargo - Edifício El Dourado',
                    ),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  // Controller criado
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    try {
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      final link = WhatsAppUnilink(
        phoneNumber: '551193758640',
        text: isEnglish 
            ? 'Hello, I need help with the app.'
            : 'Olá, preciso de ajuda com o aplicativo.',
      );
      await launchUrl(link.asUri(), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao abrir WhatsApp', 'Error opening WhatsApp')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    try {
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'suporte@unnicatelemtria.com.br',
        query: 'subject=${isEnglish ? 'Support - U-Connect' : 'Suporte - U-Connect'}',
      );
      await launchUrl(emailUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao abrir cliente de e-mail', 'Error opening email client')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWebsite() async {
    try {
      final uri = Uri.parse('https://unnicateletria.com.br');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao abrir site', 'Error opening website')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
