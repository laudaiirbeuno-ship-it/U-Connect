import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uconnect/config/static.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/User.dart';
import 'package:uconnect/data/screens/AlertList.dart';
import 'package:uconnect/data/screens/settingscreens/privacypolicy.dart';
import 'package:uconnect/data/screens/settingscreens/termsandconditions.dart';
import 'package:uconnect/data/screens/video_telemetry/views/video_telemetry_screen.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/screens/signinwithbackground2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/data/screens/notificationscreen.dart';
import 'package:uconnect/data/screens/tasks/views/tasks_screen.dart';
import 'package:uconnect/data/screens/contracts/views/contracts_screen.dart';
import 'package:uconnect/data/screens/receipts/views/receipts_screen.dart';
import 'package:uconnect/data/screens/support/views/support_screen.dart';
import 'package:uconnect/data/screens/km_traveled/views/km_traveled_screen.dart';
import 'package:uconnect/data/screens/fuel_consumption/views/fuel_consumption_screen.dart';
import 'package:uconnect/data/screens/emergency_contacts/views/emergency_contacts_screen.dart';
import 'package:uconnect/utils/user_permissions.dart';
import 'package:uconnect/data/screens/drivers/views/drivers_screen.dart';
import 'package:uconnect/data/screens/charges/views/charges_screen.dart';
import 'package:uconnect/data/screens/route_history/views/route_history_screen.dart';
import 'package:uconnect/data/screens/settingscreens/app_settings_screen.dart';
import 'package:uconnect/data/screens/settingscreens/settingscreen.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/data/screens/my_users/views/my_users_screen.dart';
import 'package:uconnect/data/screens/charges/views/admin_charges_screen.dart';
import 'package:uconnect/data/screens/fuel_control/views/fuel_control_screen.dart';
import 'package:uconnect/data/screens/fleet_checklist/views/fleet_checklist_screen.dart';
import 'package:uconnect/data/screens/reports/views/reports_screen.dart';
import 'package:uconnect/data/screens/fleet_sensors/views/fleet_sensors_screen.dart';
import 'package:uconnect/data/screens/fuel_pump/views/fuel_pump_screen.dart';
import 'package:uconnect/data/screens/fleet_documentation/views/fleet_documentation_screen.dart';
import 'package:uconnect/data/screens/advanced_telemetry/views/advanced_telemetry_screen.dart';
import 'package:uconnect/data/screens/tow_service/views/tow_service_screen.dart';
import 'package:uconnect/data/screens/financial_dashboard/views/financial_dashboard_screen.dart';
import 'package:uconnect/data/screens/transactions/views/transactions_screen.dart';
import 'dart:convert';
import 'package:uconnect/utils/translation_helper.dart';

class FloatingMenuDrawer extends StatefulWidget {
  const FloatingMenuDrawer({Key? key}) : super(key: key);

  @override
  State<FloatingMenuDrawer> createState() => _FloatingMenuDrawerState();
}

class _FloatingMenuDrawerState extends State<FloatingMenuDrawer> {
  User? user;
  bool isLoading = true;
  bool notiEnabled = true;
  bool _isAdminOrManager = false;
  bool _isAdmin = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadUserData();
    _loadPrefs();
    _loadPermissions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadPermissions() async {
    print('🔍 [FloatingMenuDrawer] Iniciando verificação de permissões...');
    
    final isAdminOrManagerUser = await UserPermissions.isAdminOrManager();
    final isAdminUser = await UserPermissions.isAdmin();
    
    print('🎯 [FloatingMenuDrawer] isAdminOrManager: $isAdminOrManagerUser');
    print('🎯 [FloatingMenuDrawer] isAdmin: $isAdminUser');
    
    if (mounted) {
      setState(() {
        _isAdminOrManager = isAdminOrManagerUser;
        _isAdmin = isAdminUser;
      });
      
      print('✅ [FloatingMenuDrawer] Estado atualizado! _isAdminOrManager = $_isAdminOrManager');
    }
  }

  Future<void> _loadUserData() async {
    final data = await gpsapis.getUserData();
    if (data != null) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(data.toJson());
      await prefs.setString('user_data', userJson);
      
      setState(() {
        user = data;
        isLoading = false;
      });
      
      _loadPermissions();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    notiEnabled = prefs.getBool("notival") ?? true;
    setState(() {});
  }

  Future<void> _logout() async {
    print("Deslogando...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    StaticVarMethod.user_api_hash = null;

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => signinwithbackground2()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildSection(String title, List<Widget> children, {String? subtitle, bool addTopPadding = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8, top: addTopPadding ? 10 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildItem(String label, IconData icon, VoidCallback onTap,
      {Color? iconColor, Color? backgroundColor}) {
    return Builder(
      builder: (context) {
        final colorProvider = Provider.of<ColorProvider>(context);
        final defaultIconColor = iconColor ?? colorProvider.primaryColor;
        final defaultBgColor = backgroundColor ?? defaultIconColor.withOpacity(0.1);
        
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Bordas redondas nos botões
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: defaultBgColor,
                        borderRadius: BorderRadius.circular(12), // Bordas redondas
                      ),
                      child: Icon(
                        icon,
                        color: defaultIconColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88,
      child: Container(
        color: Colors.grey.shade50,
        child: SafeArea(
          child: isLoading
              ? Builder(
                  builder: (context) {
                    final colorProvider = Provider.of<ColorProvider>(context);
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                      ),
                    );
                  },
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        // Header fixo - azul em toda a altura
                        Builder(
                            builder: (context) {
                              final colorProvider = Provider.of<ColorProvider>(context);
                              return Container(
                                width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                decoration: BoxDecoration(
                                  color: colorProvider.primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorProvider.primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                              child: SafeArea(
                                bottom: false,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8), // Bordas redondas
                                          ),
                                          child: Icon(
                                            Icons.menu,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          TranslationHelper.translateSync(context, 'Navegação', 'Menu'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8), // Bordas redondas
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.pop(context),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              );
                            },
                          ),
                          
                          // Conteúdo rolável
                          Expanded(
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(
                                decelerationRate: ScrollDecelerationRate.fast,
                              ),
                              controller: _scrollController,
                              child: Column(
                                children: [
                              // CATEGORIA ADMINISTRAÇÃO (apenas Admin e Manager) - SEGUNDA SEÇÃO
                              if (_isAdminOrManager)
                                _buildSection(
                                  TranslationHelper.translateSync(context, 'ADMINISTRAÇÃO', 'ADMINISTRATION'),
                                  [
                          // Meus Usuários
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Meus Usuários', 'My Users'),
                            Icons.people,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MyUsersScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                          // Cobranças para Pagar
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Cobranças para Pagar', 'Charges to Pay'),
                            Icons.payment,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChargesScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                        ],
                                  addTopPadding: true,
                                ),

                              // CATEGORIA SERVIÇOS (apenas Admin) - TERCEIRA SEÇÃO
                              if (_isAdmin)
                                _buildSection(
                                  TranslationHelper.translateSync(context, 'SERVIÇOS', 'SERVICES'),
                                  [
                          // Chamar Reboque
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Chamar Reboque', 'Call Tow Service'),
                            Icons.local_taxi,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TowServiceScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                        ],
                                  addTopPadding: true,
                                ),

                              // Mapa Principal e Lista de Veículos
                              _buildSection("", [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Monitoramento', 'Main Map'),
                          Icons.map,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BottomNavigation_01(initialIndex: 1)));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Lista de Veículos', 'Vehicle List'),
                          Icons.list_alt,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BottomNavigation_01(initialIndex: 0)));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Dashboard da Frota', 'Fleet Dashboard'),
                          Icons.dashboard,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BottomNavigation_01(initialIndex: 2)));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA GESTÃO DE FROTAS
                              _buildSection(TranslationHelper.translateSync(context, 'GESTÃO DE FROTAS', 'FLEET MANAGEMENT'), [
                        // Meus Motoristas - visível para todos
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Meus Motoristas', 'My Drivers'),
                          Icons.people_outline,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DriversScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Manutenção', 'Maintenance'),
                          Icons.task,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TasksScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Km Percorrida', 'Distance Travelled'),
                          Icons.speed,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => KmTraveledScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Consumo de Combustível', 'Fuel Consumption'),
                          Icons.local_gas_station,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FuelConsumptionScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Video Telemetria', 'Video Telemetry'),
                          Icons.videocam,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => VideoTelemetryScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Histórico de Rotas', 'Route History'),
                          Icons.route,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RouteHistoryScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Controle de Abastecimento', 'Fuel Control'),
                          Icons.local_gas_station,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FuelControlScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Checklist da Frota', 'Fleet Checklist'),
                          Icons.checklist,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FleetChecklistScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Relatórios', 'Reports'),
                          Icons.insert_chart,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Sensores da Frota', 'Fleet Sensors'),
                          Icons.sensors,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FleetSensorsScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Controle de Bomba de Combustível', 'Fuel Pump Control'),
                          Icons.local_gas_station,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FuelPumpScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Documentação da Frota', 'Fleet Documentation'),
                          Icons.description,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FleetDocumentationScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Telemetria Avançada', 'Advanced Telemetry'),
                          Icons.sensors,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AdvancedTelemetryScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA EVENTOS
                              _buildSection(TranslationHelper.translateSync(context, 'EVENTOS', 'EVENTS'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Central de Notificações', 'Notifications Centre'),
                          Icons.notifications,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsPage()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Alertas', 'Alerts'),
                          Icons.warning_amber_outlined,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AlertListPage()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),


                              // CATEGORIA FINANCEIRO (Admin, Gerente e Usuário Comum)
                              _buildSection(TranslationHelper.translateSync(context, 'FINANCEIRO', 'FINANCIAL'), [
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Minhas Cobranças', 'My Charges'),
                            Icons.payment,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ChargesScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                          // Dashboard Financeiro (liberado para todos - cada usuário vê seus dados)
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Dashboard Financeiro', 'Financial Dashboard'),
                            Icons.dashboard,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialDashboardScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                          // Transações (liberado para todos - cada usuário vê seus dados)
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Transações', 'Transactions'),
                            Icons.swap_horiz,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Meus Contratos', 'My Contracts'),
                            Icons.description,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ContractsScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                          _buildItem(
                            TranslationHelper.translateSync(context, 'Comprovantes', 'Receipts'),
                            Icons.receipt,
                            () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptsScreen()));
                            },
                            iconColor: colorProvider.primaryColor,
                            backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                          ),
                        ]),


                              // CATEGORIA CONTATOS
                              _buildSection(TranslationHelper.translateSync(context, 'CONTATOS', 'CONTACTS'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Contatos de Emergência', 'Emergency Contacts'),
                          Icons.emergency,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyContactsScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA SUPORTE
                              _buildSection(TranslationHelper.translateSync(context, 'SUPORTE', 'SUPPORT'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Suporte', 'Support'),
                          Icons.support_agent,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SupportScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA CONFIGURAÇÕES
                              _buildSection(TranslationHelper.translateSync(context, 'CONFIGURAÇÕES', 'SETTINGS'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Configuração', 'Settings'),
                          Icons.settings,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => settingscreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Configuração da Personalização', 'Personalization Settings'),
                          Icons.palette,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AppSettingsScreen()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA LEGAIS
                              _buildSection(TranslationHelper.translateSync(context, 'LEGAIS', 'LEGAL'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Políticas e Privacidade', 'Privacy Policy'),
                          Icons.privacy_tip_outlined,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => privacypolicy()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Termos de Uso', 'Terms of Use'),
                          Icons.description_outlined,
                          () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => termsandconditions()));
                          },
                          iconColor: colorProvider.primaryColor,
                          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
                        ),
                      ]),

                              // CATEGORIA LOGOUT
                              _buildSection(TranslationHelper.translateSync(context, 'LOGOUT', 'LOGOUT'), [
                        _buildItem(
                          TranslationHelper.translateSync(context, 'Sair', 'Exit'),
                          Icons.logout_outlined,
                          () {
                            Navigator.pop(context);
                            _logout();
                          },
                          iconColor: Colors.red.shade600,
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ]),
                              
                              SizedBox(height: 20), // Espaço para o botão flutuante
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                    
                    // Botão flutuante de scroll para baixo
                    Positioned(
                      bottom: 60,
                      right: 16,
                      child: Builder(
                        builder: (context) {
                          final colorProvider = Provider.of<ColorProvider>(context);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colorProvider.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorProvider.primaryColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
