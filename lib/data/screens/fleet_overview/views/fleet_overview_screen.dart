import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/fleet_overview/controllers/fleet_overview_controller.dart';
import 'package:uconnect/data/screens/fleet_overview/widgets/status_cards_widget.dart';
import 'package:uconnect/data/screens/fleet_overview/widgets/km_cards_widget.dart';
import 'package:uconnect/data/screens/fleet_overview/widgets/fuel_cards_widget.dart';
import 'package:uconnect/data/screens/fleet_overview/widgets/alerts_list_widget.dart';
import 'package:uconnect/data/screens/fleet_sensors/views/fleet_sensors_screen.dart';

class FleetOverviewScreen extends StatefulWidget {
  @override
  _FleetOverviewScreenState createState() => _FleetOverviewScreenState();
}

class _FleetOverviewScreenState extends State<FleetOverviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FleetOverviewController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Dashboard da Frota', 'Fleet Dashboard'),
          icon: Icons.dashboard,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer<FleetOverviewController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          TranslationHelper.translateSync(context, 'Carregando dados...', 'Loading data...'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (controller.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
              children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        SizedBox(height: 16),
                        Text(
                          TranslationHelper.translateSync(context, 'Erro ao carregar dados', 'Error loading data'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          controller.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => controller.loadData(),
                          icon: Icon(Icons.refresh),
                          label: Text(TranslationHelper.translateSync(context, 'Tentar novamente', 'Try again')),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                    onRefresh: () => controller.loadData(),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Resumo geral
                        _buildSummarySection(context, controller),
                        
                    SizedBox(height: 16),
                    
                        // Cards de status
                        StatusCardsWidget(),
                        
                    SizedBox(height: 16),
                    
                        // Cards de quilometragem
                        KmCardsWidget(),
                    
                    SizedBox(height: 16),
                    
                        // Cards de combustível
                    FuelCardsWidget(),
                        
                    SizedBox(height: 16),
                    
                        // Estatísticas adicionais
                        _buildAdditionalStats(context, controller),
                        
                    SizedBox(height: 16),
                    
                        // Lista de alertas recentes
                    AlertsListWidget(isCritical: false),
                        
                    SizedBox(height: 16),
                    
                        // Lista de alertas críticos
                    AlertsListWidget(isCritical: true),
                        
                        SizedBox(height: 16),
                        
                        // Seção de Sensores
                        _buildSensorsSection(context),
                        
                        SizedBox(height: 16),
                        
                        // Lista de veículos
                        _buildVehiclesList(context, controller),
                        
                        SizedBox(height: 80), // Espaço para o bottom nav
                      ],
                    ),
                  ),
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, FleetOverviewController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: colorProvider.primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translateSync(context, 'Resumo da Frota', 'Fleet Summary'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${controller.totalVehicles} ${TranslationHelper.translateSync(context, 'veículos', 'vehicles')}',
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
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  Icons.check_circle,
                  '${controller.onlineCount}',
                  TranslationHelper.translateSync(context, 'Online', 'Online'),
                  Colors.green,
                  colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  Icons.cancel,
                  '${controller.offlineCount}',
                  TranslationHelper.translateSync(context, 'Offline', 'Offline'),
                  Colors.red,
                  colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  Icons.directions_car,
                  '${controller.movingCount}',
                  TranslationHelper.translateSync(context, 'Em Movimento', 'Moving'),
                  colorProvider.primaryColor,
                  colorProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, IconData icon, String value, String label, Color color, ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats(BuildContext context, FleetOverviewController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
              Icon(
                Icons.analytics,
                color: colorProvider.primaryColor,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Estatísticas Adicionais', 'Additional Statistics'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildStatRow(
            context,
            Icons.speed,
            TranslationHelper.translateSync(context, 'Velocidade Máxima', 'Top Speed'),
            '${controller.topSpeed.toStringAsFixed(1)} km/h',
            Colors.orange,
          ),
          SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.timer,
            TranslationHelper.translateSync(context, 'Tempo em Movimento', 'Moving Time'),
            controller.moveDuration,
            Colors.blue,
          ),
          SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.pause_circle,
            TranslationHelper.translateSync(context, 'Tempo Parado', 'Stopped Time'),
            controller.stopDuration,
            Colors.grey,
          ),
          SizedBox(height: 16),
          _buildStatRow(
            context,
            Icons.power,
            TranslationHelper.translateSync(context, 'Ligações de Ignição', 'Ignition On Events'),
            '${controller.ignitionOnEvents}',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesList(BuildContext context, FleetOverviewController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.vehicleDetailedData.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
              Icon(
                Icons.list,
                color: colorProvider.primaryColor,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Veículos da Frota', 'Fleet Vehicles'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...controller.vehicleDetailedData.take(5).map((vehicleData) {
            return _buildVehicleCard(context, vehicleData);
          }).toList(),
          if (controller.vehicleDetailedData.length > 5)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  TranslationHelper.translateSync(
                    context,
                    'E mais ${controller.vehicleDetailedData.length - 5} veículos...',
                    'And ${controller.vehicleDetailedData.length - 5} more vehicles...',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleDetailedData vehicleData) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final vehicle = vehicleData.vehicle;
    final online = vehicle.online?.toLowerCase() ?? '';
    final isOnline = online.contains('online');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOnline 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: isOnline ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          isOnline 
                              ? TranslationHelper.translateSync(context, 'Online', 'Online')
                              : TranslationHelper.translateSync(context, 'Offline', 'Offline'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildVehicleStat(
                  context,
                  Icons.speed,
                  vehicleData.topSpeed,
                  colorProvider.primaryColor,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildVehicleStat(
                  context,
                  Icons.straighten,
                  vehicleData.distanceSum,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStat(BuildContext context, IconData icon, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsSection(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sensors,
                  color: colorProvider.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Sensores da Frota', 'Fleet Sensors'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            TranslationHelper.translateSync(
              context,
              'Acesse a página de Sensores da Frota para visualizar informações detalhadas sobre os sensores dos veículos.',
              'Access the Fleet Sensors page to view detailed information about vehicle sensors.',
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FleetSensorsScreen(),
                  ),
                );
              },
              icon: Icon(Icons.arrow_forward),
              label: Text(TranslationHelper.translateSync(context, 'Ver Sensores', 'View Sensors')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
