import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/emergency_contacts/controllers/emergency_contacts_controller.dart';
import 'package:uconnect/data/screens/emergency_contacts/widgets/emergency_contacts_filter_widget.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class EmergencyContactsScreen extends StatefulWidget {
  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isFilterSticky = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _isFilterSticky = _scrollController.offset > 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyContactsController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Contatos de Emergência', 'Emergency Contacts'),
          icon: Icons.emergency,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer2<EmergencyContactsController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                if (controller.isLoading && controller.contacts.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorProvider.primaryColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    EmergencyContactsFilterWidget(isSticky: _isFilterSticky),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => controller.loadData(),
                        color: colorProvider.primaryColor,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.contacts.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.emergency_outlined,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          TranslationHelper.translateSync(context, 'Nenhum contato disponível', 'No contacts available'),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...controller.contacts.map((contact) => _buildContactCard(
                                      contact,
                                      colorProvider,
                                    )),
                              SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, ColorProvider colorProvider) {
    IconData icon;
    Color iconColor;
    
    // Traduzir categorias
    final category = contact.category;
    final translatedCategory = _translateCategory(category);
    
    switch (category) {
      case 'Bombeiros':
      case 'Fire Department':
        icon = Icons.local_fire_department;
        iconColor = Colors.red;
        break;
      case 'Polícia Militar':
      case 'Military Police':
      case 'Polícia Civil':
      case 'Civil Police':
      case 'Polícia Rodoviária Federal':
      case 'Federal Highway Police':
      case 'Polícia Federal':
      case 'Federal Police':
        icon = Icons.badge;
        iconColor = Colors.blue;
        break;
      case 'SAMU':
      case 'SAMU (Emergency Medical Service)':
        icon = Icons.medical_services;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.phone;
        iconColor = colorProvider.primaryColor;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      translatedCategory,
                      style: TextStyle(
                        color: colorProvider.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  // Name
                  Text(
                    contact.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 4),
                  // Phone
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        contact.phone,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Call button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorProvider.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _makeCall(contact.phone),
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateCategory(String category) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    if (isEnglish) {
      switch (category) {
        case 'Bombeiros':
          return 'Fire Department';
        case 'Polícia Militar':
          return 'Military Police';
        case 'Polícia Civil':
          return 'Civil Police';
        case 'Polícia Rodoviária Federal':
          return 'Federal Highway Police';
        case 'Polícia Federal':
          return 'Federal Police';
        case 'SAMU':
          return 'SAMU (Emergency Medical Service)';
        default:
          return category;
      }
    } else {
      // Se já está em português, retornar como está
      return category;
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Não foi possível fazer a ligação', 'Could not make the call')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
