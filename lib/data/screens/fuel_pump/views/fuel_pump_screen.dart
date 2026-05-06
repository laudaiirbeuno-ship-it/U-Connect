import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/fuel_pump/controllers/fuel_pump_controller.dart';
import 'package:intl/intl.dart';

class FuelPumpScreen extends StatefulWidget {
  @override
  _FuelPumpScreenState createState() => _FuelPumpScreenState();
}

class _FuelPumpScreenState extends State<FuelPumpScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FuelPumpController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Controle de Bomba de Combustível', 'Fuel Pump Control'),
          icon: Icons.local_gas_station,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer<FuelPumpController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(),
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
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumo
                        _buildSummarySection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Filtros
                        _buildFiltersSection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Lista de registros
                        _buildRecordsList(context, controller),
                        
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

  Widget _buildSummarySection(BuildContext context, FuelPumpController controller) {
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
              Icon(Icons.local_gas_station, color: colorProvider.primaryColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Resumo de Bombas', 'Pump Summary'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.water_drop,
                  TranslationHelper.translateSync(context, 'Total Abastecido', 'Total Fueled'),
                  '${controller.totalFuelPumped.toStringAsFixed(1)} L',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.attach_money,
                  TranslationHelper.translateSync(context, 'Custo Total', 'Total Cost'),
                  'R\$ ${controller.totalCost.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.list_alt,
                  TranslationHelper.translateSync(context, 'Registros', 'Records'),
                  '${controller.totalRecords}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String label, String value) {
    final colorProvider = Provider.of<ColorProvider>(context);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorProvider.primaryColor, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, FuelPumpController controller) {
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
          Text(
            TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.directions_car),
            ),
            value: controller.selectedVehicleId,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles')),
              ),
              ...controller.vehicles.map((vehicle) => DropdownMenuItem(
                value: vehicle.id.toString(),
                child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
              )),
            ],
            onChanged: (value) => controller.setSelectedVehicle(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, FuelPumpController controller) {
    if (controller.pumpRecords.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.local_gas_station_outlined, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Nenhum registro de bomba encontrado', 'No pump records found'),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Registros de Bomba', 'Pump Records'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...controller.pumpRecords.map((record) => _buildRecordCard(context, record, controller)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, FuelPumpRecord record, FuelPumpController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
                child: Icon(Icons.local_gas_station, color: colorProvider.primaryColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.vehicleName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
                child: _buildRecordInfo(
                  context,
                  Icons.water_drop,
                  '${record.fuelAmount.toStringAsFixed(1)} L',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildRecordInfo(
                  context,
                  Icons.attach_money,
                  'R\$ ${record.totalCost.toStringAsFixed(2)}',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildRecordInfo(
                  context,
                  Icons.numbers,
                  record.pumpNumber,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                record.operatorName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              SizedBox(width: 16),
              Icon(Icons.speed, size: 14, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                '${record.odometer.toStringAsFixed(0)} km',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordInfo(BuildContext context, IconData icon, String value) {
    final colorProvider = Provider.of<ColorProvider>(context);
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorProvider.primaryColor),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
