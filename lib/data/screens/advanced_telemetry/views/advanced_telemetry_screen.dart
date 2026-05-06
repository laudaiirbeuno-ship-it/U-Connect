import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/advanced_telemetry/controllers/advanced_telemetry_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class AdvancedTelemetryScreen extends StatefulWidget {
  @override
  _AdvancedTelemetryScreenState createState() => _AdvancedTelemetryScreenState();
}

class _AdvancedTelemetryScreenState extends State<AdvancedTelemetryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdvancedTelemetryController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Telemetria Avançada', 'Advanced Telemetry'),
          icon: Icons.sensors,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer2<AdvancedTelemetryController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                if (controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorProvider.primaryColor,
                      ),
                    ),
                  );
                }

                if (controller.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        SizedBox(height: 16),
                        Text(
                          TranslationHelper.translateSync(context, 'Erro ao carregar dados', 'Error loading data'),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(controller.error!),
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
                  color: colorProvider.primaryColor,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seletor de veículo
                        _buildVehicleSelector(context, controller, colorProvider),
                        
                        SizedBox(height: 24),
                        
                        // Mensagem "Em breve"
                        _buildComingSoonSection(context, controller, colorProvider),
                        
                        SizedBox(height: 24),
                        
                        // Informações sobre RedeCAN
                        _buildInfoSection(context, colorProvider),
                        
                        SizedBox(height: 80),
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

  Widget _buildVehicleSelector(BuildContext context, AdvancedTelemetryController controller, ColorProvider colorProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
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
              Icon(Icons.directions_car, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                TranslationHelper.translateSync(context, 'Selecionar Veículo', 'Select Vehicle'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<deviceItems>(
            decoration: InputDecoration(
              labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.directions_car),
            ),
            value: controller.selectedVehicle,
            items: controller.vehicles.map((vehicle) => DropdownMenuItem(
              value: vehicle,
              child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
            )).toList(),
            onChanged: (value) => controller.setSelectedVehicle(value),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonSection(BuildContext context, AdvancedTelemetryController controller, ColorProvider colorProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorProvider.primaryColor.withOpacity(0.1),
            colorProvider.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorProvider.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors,
              size: 64,
              color: colorProvider.primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            TranslationHelper.translateSync(context, 'Em Breve', 'Coming Soon'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorProvider.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            TranslationHelper.translateSync(
              context,
              'A Telemetria Avançada com dados da RedeCAN estará disponível em breve.',
              'Advanced Telemetry with CAN Bus data will be available soon.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              TranslationHelper.translateSync(
                context,
                'Esta funcionalidade permitirá monitorar dados em tempo real da RedeCAN do veículo, incluindo RPM, temperatura, pressão, e outros parâmetros do motor.',
                'This feature will allow real-time monitoring of vehicle CAN Bus data, including RPM, temperature, pressure, and other engine parameters.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, ColorProvider colorProvider) {
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
              Icon(Icons.info_outline, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                TranslationHelper.translateSync(context, 'Sobre a RedeCAN', 'About CAN Bus'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoItem(
            Icons.speed,
            TranslationHelper.translateSync(context, 'RPM do Motor', 'Engine RPM'),
            TranslationHelper.translateSync(
              context,
              'Monitoramento em tempo real da rotação do motor',
              'Real-time engine rotation monitoring',
            ),
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            Icons.thermostat,
            TranslationHelper.translateSync(context, 'Temperatura', 'Temperature'),
            TranslationHelper.translateSync(
              context,
              'Temperatura do motor, líquido de arrefecimento e outros sensores',
              'Engine temperature, coolant and other sensors',
            ),
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            Icons.water_drop,
            TranslationHelper.translateSync(context, 'Nível de Combustível', 'Fuel Level'),
            TranslationHelper.translateSync(
              context,
              'Monitoramento preciso do nível de combustível',
              'Accurate fuel level monitoring',
            ),
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            Icons.compress,
            TranslationHelper.translateSync(context, 'Pressão', 'Pressure'),
            TranslationHelper.translateSync(
              context,
              'Pressão do óleo, ar e outros sistemas',
              'Oil pressure, air and other systems',
            ),
          ),
          SizedBox(height: 12),
          _buildInfoItem(
            Icons.electric_bolt,
            TranslationHelper.translateSync(context, 'Sistema Elétrico', 'Electrical System'),
            TranslationHelper.translateSync(
              context,
              'Voltagem da bateria e sistema elétrico',
              'Battery voltage and electrical system',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
