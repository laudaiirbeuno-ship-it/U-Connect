import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/screens/fuel_control/controllers/fuel_control_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:url_launcher/url_launcher.dart';

class FuelControlScreen extends StatefulWidget {
  @override
  _FuelControlScreenState createState() => _FuelControlScreenState();
}

class _FuelControlScreenState extends State<FuelControlScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FuelControlController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Controle de Abastecimento', 'Fuel Control'),
          icon: Icons.local_gas_station,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            AnimatedBackground(opacity: 0.03),
            Consumer<FuelControlController>(
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
                        
                        // Seção de Gastos
                        _buildExpensesSection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Filtros
                        _buildFiltersSection(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Gráficos de consumo
                        _buildConsumptionCharts(context, controller),
                        
                        SizedBox(height: 16),
                        
                        // Histórico completo
                        _buildHistorySection(context, controller),
                        
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
            // Botão flutuante para criar novo abastecimento
            Consumer<ColorProvider>(
              builder: (context, colorProvider, child) {
                return Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () => _showAddFuelRecordDialog(context),
                    backgroundColor: colorProvider.primaryColor,
                    child: Icon(Icons.add, color: Colors.white),
                    tooltip: TranslationHelper.translateSync(context, 'Criar Novo Abastecimento', 'Create New Fuel Record'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, FuelControlController controller) {
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
        children: [
          Row(
            children: [
              Icon(Icons.local_gas_station, color: colorProvider.primaryColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Resumo de Abastecimento', 'Fuel Summary'),
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
                  '${controller.totalFuel.toStringAsFixed(1)} L',
                  TranslationHelper.translateSync(context, 'Total Abastecido', 'Total Fuel'),
                  Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.attach_money,
                  'R\$ ${controller.totalCost.toStringAsFixed(2)}',
                  TranslationHelper.translateSync(context, 'Custo Total', 'Total Cost'),
                  Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.trending_up,
                  'R\$ ${controller.averagePrice.toStringAsFixed(2)}/L',
                  TranslationHelper.translateSync(context, 'Preço Médio', 'Average Price'),
                  Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  Icons.list,
                  '${controller.totalRecords}',
                  TranslationHelper.translateSync(context, 'Registros', 'Records'),
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final biWeekStart = now.subtract(Duration(days: 15));
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    
    final weeklyExpense = _calculateExpense(controller, weekStart, weekEnd);
    final biWeeklyExpense = _calculateExpense(controller, biWeekStart, now);
    final monthlyExpense = _calculateExpense(controller, monthStart, monthEnd);
    final yearlyExpense = _calculateExpense(controller, yearStart, yearEnd);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.attach_money, color: colorProvider.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Gastos com Abastecimento', 'Fuel Expenses'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildExpenseCard(
                  context,
                  TranslationHelper.translateSync(context, 'Semanal', 'Weekly'),
                  weeklyExpense,
                  weekStart,
                  weekEnd,
                  colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildExpenseCard(
                  context,
                  TranslationHelper.translateSync(context, 'Quinzenal', 'Bi-weekly'),
                  biWeeklyExpense,
                  biWeekStart,
                  now,
                  colorProvider,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildExpenseCard(
                  context,
                  TranslationHelper.translateSync(context, 'Mensal', 'Monthly'),
                  monthlyExpense,
                  monthStart,
                  monthEnd,
                  colorProvider,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildExpenseCard(
                  context,
                  TranslationHelper.translateSync(context, 'Anual', 'Yearly'),
                  yearlyExpense,
                  yearStart,
                  yearEnd,
                  colorProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateExpense(FuelControlController controller, DateTime startDate, DateTime endDate) {
    return controller.fuelRecords
        .where((record) => record.date.isAfter(startDate.subtract(Duration(days: 1))) && 
                          record.date.isBefore(endDate.add(Duration(days: 1))))
        .fold(0.0, (sum, record) => sum + (record.totalCost ?? 0.0));
  }

  Widget _buildExpenseCard(
    BuildContext context,
    String period,
    double expense,
    DateTime startDate,
    DateTime endDate,
    ColorProvider colorProvider,
  ) {
    return InkWell(
      onTap: () => _showExpenseDetailModal(context, period, expense, startDate, endDate, colorProvider),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'R\$ ${expense.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String value, String label, Color iconColor) {
    final colorProvider = Provider.of<ColorProvider>(context);
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorProvider.primaryColor, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildFiltersSection(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
              Icon(Icons.filter_list, color: colorProvider.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Filtros', 'Filters'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Filtro de veículo com botão de calibração
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: controller.selectedVehicleId,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
              ),
              if (controller.selectedVehicleId != null) ...[
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.sync),
                  tooltip: TranslationHelper.translateSync(context, 'Calibrar Odômetro', 'Calibrate Odometer'),
                  onPressed: () => _showCalibrateOdometerDialog(context, controller),
                  color: colorProvider.primaryColor,
                ),
              ],
            ],
          ),
          SizedBox(height: 12),
          // Filtro de data
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.fromDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.setDateRange(date, controller.toDate);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'De', 'From'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(controller.fromDate)),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: controller.toDate,
                      firstDate: controller.fromDate,
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.setDateRange(controller.fromDate, date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'Até', 'To'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(controller.toDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.fuelRecords.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.local_gas_station_outlined, size: 64, color: Colors.grey.shade300),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Nenhum registro de abastecimento encontrado', 'No fuel records found'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
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
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(Icons.history, color: colorProvider.primaryColor, size: 20),
                SizedBox(width: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Histórico de Abastecimentos', 'Fuel History'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          ...controller.fuelRecords.map((record) => _buildRecordCard(context, record, controller)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, FuelRecord record, FuelControlController controller) {
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_gas_station,
                  color: colorProvider.primaryColor,
                  size: 24,
                ),
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
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(record.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (record.deviceName != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.devices, size: 12, color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Text(
                            record.deviceName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (record.driverName != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Text(
                            record.driverName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(TranslationHelper.translateSync(context, 'Excluir Registro', 'Delete Record')),
                      content: Text(TranslationHelper.translateSync(context, 'Deseja realmente excluir este registro?', 'Do you really want to delete this record?')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.deleteFuelRecord(record.id);
                            Navigator.pop(context);
                          },
                          child: Text(TranslationHelper.translateSync(context, 'Excluir', 'Delete'), style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRecordInfo(
                  Icons.water_drop,
                  '${record.fuelAmount.toStringAsFixed(1)} L',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildRecordInfo(
                  Icons.attach_money,
                  'R\$ ${record.totalCost.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildRecordInfo(
                  Icons.speed,
                  '${record.odometer.toStringAsFixed(0)} km',
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRecordInfo(
                  Icons.speed_outlined,
                  TranslationHelper.translateSync(context, 'Atual: ${record.currentOdometer.toStringAsFixed(0)} km', 'Current: ${record.currentOdometer.toStringAsFixed(0)} km'),
                  Colors.purple,
                ),
              ),
              if (record.distanceSinceLastFuel != null) ...[
                SizedBox(width: 8),
                Expanded(
                  child: _buildRecordInfo(
                    Icons.straighten,
                    TranslationHelper.translateSync(context, 'Dist: ${record.distanceSinceLastFuel!.toStringAsFixed(0)} km', 'Dist: ${record.distanceSinceLastFuel!.toStringAsFixed(0)} km'),
                    Colors.teal,
                  ),
                ),
              ],
              if (record.consumptionSinceLastFuel != null) ...[
                SizedBox(width: 8),
                Expanded(
                  child: _buildRecordInfo(
                    Icons.trending_up,
                    TranslationHelper.translateSync(context, '${record.consumptionSinceLastFuel!.toStringAsFixed(2)} km/L', '${record.consumptionSinceLastFuel!.toStringAsFixed(2)} km/L'),
                    Colors.indigo,
                  ),
                ),
              ],
            ],
          ),
          if (record.station.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 4),
                Text(
                  record.station,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordInfo(IconData icon, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 4),
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

  Widget _buildConsumptionCharts(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.selectedVehicleId == null || !controller.consumptionHistory.containsKey(controller.selectedVehicleId)) {
      return SizedBox.shrink();
    }
    
    final consumptionData = controller.consumptionHistory[controller.selectedVehicleId]!;
    if (consumptionData.isEmpty) {
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
              Icon(Icons.show_chart, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Gráfico de Consumo', 'Consumption Chart'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('dd/MM'),
                labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(
                  text: TranslationHelper.translateSync(context, 'km/L', 'km/L'),
                  textStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                LineSeries<ConsumptionData, DateTime>(
                  dataSource: consumptionData,
                  xValueMapper: (ConsumptionData data, _) => data.date,
                  yValueMapper: (ConsumptionData data, _) => data.consumption,
                  color: colorProvider.primaryColor,
                  width: 3,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 8,
                    width: 8,
                    color: colorProvider.primaryColor,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Indicadores
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  context,
                  Icons.trending_up,
                  '${consumptionData.map((d) => d.consumption).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)} km/L',
                  TranslationHelper.translateSync(context, 'Máximo', 'Maximum'),
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildIndicator(
                  context,
                  Icons.trending_down,
                  '${consumptionData.map((d) => d.consumption).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} km/L',
                  TranslationHelper.translateSync(context, 'Mínimo', 'Minimum'),
                  Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildIndicator(
                  context,
                  Icons.analytics,
                  '${(consumptionData.map((d) => d.consumption).reduce((a, b) => a + b) / consumptionData.length).toStringAsFixed(2)} km/L',
                  TranslationHelper.translateSync(context, 'Média', 'Average'),
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    if (controller.selectedVehicleId == null) {
      return SizedBox.shrink();
    }
    
    final vehicleHistory = controller.getVehicleHistory(controller.selectedVehicleId);
    if (vehicleHistory.length < 2) {
      return SizedBox.shrink();
    }
    
    // Ordenar por data (mais antigo primeiro)
    final sortedHistory = List<FuelRecord>.from(vehicleHistory)..sort((a, b) => a.date.compareTo(b.date));
    
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
              Icon(Icons.history, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Histórico Completo de Abastecimento', 'Complete Fuel History'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...List.generate(sortedHistory.length - 1, (index) {
            final current = sortedHistory[index + 1];
            final previous = sortedHistory[index];
            final distance = (current.odometer - previous.odometer).abs();
            final consumption = distance > 0 && current.fuelAmount > 0 
                ? distance / current.fuelAmount 
                : 0.0;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(current.date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: consumption > 0 
                              ? (consumption > 10 ? Colors.green.shade50 : consumption > 7 ? Colors.orange.shade50 : Colors.red.shade50)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          consumption > 0 ? '${consumption.toStringAsFixed(2)} km/L' : 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: consumption > 0 
                                ? (consumption > 10 ? Colors.green.shade700 : consumption > 7 ? Colors.orange.shade700 : Colors.red.shade700)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHistoryItem(
                          Icons.straighten,
                          '${distance.toStringAsFixed(0)} km',
                          TranslationHelper.translateSync(context, 'Distância', 'Distance'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildHistoryItem(
                          Icons.water_drop,
                          '${current.fuelAmount.toStringAsFixed(1)} L',
                          TranslationHelper.translateSync(context, 'Combustível', 'Fuel'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildHistoryItem(
                          Icons.speed,
                          '${current.odometer.toStringAsFixed(0)} km',
                          TranslationHelper.translateSync(context, 'Odômetro', 'Odometer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showCalibrateOdometerDialog(BuildContext context, FuelControlController controller) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final vehicleId = controller.selectedVehicleId;
    if (vehicleId == null) return;
    
    final vehicle = controller.vehicles.firstWhere((v) => v.id.toString() == vehicleId);
    final vehicleOdometer = controller.getVehicleOdometer(vehicle);
    
    final vehicleOdometerController = TextEditingController(text: vehicleOdometer.toStringAsFixed(0));
    final manualOdometerController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(context, 'Calibrar Odômetro', 'Calibrate Odometer')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')}: ${vehicle.name ?? 'Veículo'}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: vehicleOdometerController,
                decoration: InputDecoration(
                  labelText: TranslationHelper.translateSync(context, 'Odômetro do Sistema (km)', 'System Odometer (km)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.speed),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                enabled: false,
              ),
              SizedBox(height: 12),
              TextField(
                controller: manualOdometerController,
                decoration: InputDecoration(
                  labelText: TranslationHelper.translateSync(context, 'Odômetro Real do Veículo (km)', 'Real Vehicle Odometer (km)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.edit),
                  helperText: TranslationHelper.translateSync(context, 'Digite o odômetro real do veículo', 'Enter the real vehicle odometer'),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final manualOdometer = double.tryParse(manualOdometerController.text);
              if (manualOdometer != null) {
                controller.calibrateOdometer(
                  vehicleId,
                  vehicleOdometer,
                  manualOdometer,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(TranslationHelper.translateSync(
                      context,
                      'Odômetro calibrado com sucesso!',
                      'Odometer calibrated successfully!'
                    )),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorProvider.primaryColor,
            ),
            child: Text(TranslationHelper.translateSync(context, 'Calibrar', 'Calibrate')),
          ),
        ],
      ),
    );
  }

  void _showAddFuelRecordDialog(BuildContext context) {
    final controller = Provider.of<FuelControlController>(context, listen: false);
    
    final fuelAmountController = TextEditingController();
    final fuelPriceController = TextEditingController();
    final odometerController = TextEditingController();
    final stationController = TextEditingController();
    final notesController = TextEditingController();
    final invoiceNumberController = TextEditingController();
    
    String? selectedVehicleId;
    String? selectedDeviceId;
    String? selectedDriverId;
    String? selectedPaymentMethod;
    String? selectedFuelQuality;
    String? selectedFuelType; // Gasolina ou Diesel
    String? selectedVehicleType; // Carro, Moto ou Caminhão
    DateTime selectedDate = DateTime.now();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Novo Abastecimento', 'New Fuel Record'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003087),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                    ],
                  ),
                ),
                // Conteúdo com scroll
                  Expanded(
                    child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Veículo', 'Vehicle') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  value: selectedVehicleId,
                  items: controller.vehicles.map((vehicle) => DropdownMenuItem(
                    value: vehicle.id.toString(),
                    child: Text(vehicle.name ?? 'Veículo ${vehicle.id}'),
                  )).toList(),
                  onChanged: (value) => setState(() {
                    selectedVehicleId = value;
                    // Auto-selecionar o dispositivo quando selecionar o veículo
                    if (value != null) {
                      selectedDeviceId = value;
                    }
                  }),
                ),
                // Imagem do veículo selecionado
                if (selectedVehicleId != null) ...[
                  SizedBox(height: 12),
                  _buildVehicleImageInDialog(context, controller, selectedVehicleId!),
                ],
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Dispositivo', 'Device') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.devices),
                    helperText: TranslationHelper.translateSync(context, 'Dispositivo GPS vinculado', 'Linked GPS device'),
                  ),
                  value: selectedDeviceId,
                  items: controller.vehicles.map((vehicle) => DropdownMenuItem(
                    value: vehicle.id.toString(),
                    child: Text('${vehicle.name ?? 'Veículo ${vehicle.id}'} (${vehicle.id})'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedDeviceId = value),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Motorista (Opcional)', 'Driver (Optional)'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  value: selectedDriverId,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(TranslationHelper.translateSync(context, 'Nenhum motorista', 'No driver')),
                    ),
                    ...controller.drivers.map((driver) => DropdownMenuItem(
                      value: driver.id.toString(),
                      child: Text(driver.name ?? 'Motorista ${driver.id}'),
                    )),
                  ],
                  onChanged: (value) => setState(() => selectedDriverId = value),
                ),
                SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: TranslationHelper.translateSync(context, 'Data', 'Date'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                ),
                SizedBox(height: 12),
                // Tipo de Combustível
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Tipo de Combustível', 'Fuel Type') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                  value: selectedFuelType,
                  items: [
                    DropdownMenuItem(
                      value: 'Gasolina',
                      child: Text(TranslationHelper.translateSync(context, 'Gasolina', 'Gasoline')),
                    ),
                    DropdownMenuItem(
                      value: 'Diesel',
                      child: Text(TranslationHelper.translateSync(context, 'Diesel', 'Diesel')),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedFuelType = value),
                ),
                SizedBox(height: 12),
                // Tipo de Veículo
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Tipo de Veículo', 'Vehicle Type') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  value: selectedVehicleType,
                  items: [
                    DropdownMenuItem(
                      value: 'Carro',
                      child: Text(TranslationHelper.translateSync(context, 'Carro', 'Car')),
                    ),
                    DropdownMenuItem(
                      value: 'Moto',
                      child: Text(TranslationHelper.translateSync(context, 'Moto', 'Motorcycle')),
                    ),
                    DropdownMenuItem(
                      value: 'Caminhão',
                      child: Text(TranslationHelper.translateSync(context, 'Caminhão', 'Truck')),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedVehicleType = value),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: fuelAmountController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Quantidade (Litros)', 'Amount (Liters)') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.water_drop),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: fuelPriceController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Preço por Litro (R\$)', 'Price per Liter (R\$)') + ' *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: odometerController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Odômetro (km)', 'Odometer (km)'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: stationController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Posto', 'Gas Station'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 12),
                // Número da Nota Fiscal
                TextField(
                  controller: invoiceNumberController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Número da Nota Fiscal', 'Invoice Number'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.receipt),
                  ),
                ),
                SizedBox(height: 12),
                // Método de Pagamento
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Método de Pagamento', 'Payment Method'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  value: selectedPaymentMethod,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(TranslationHelper.translateSync(context, 'Selecione', 'Select')),
                    ),
                    DropdownMenuItem(
                      value: 'Dinheiro',
                      child: Text(TranslationHelper.translateSync(context, 'Dinheiro', 'Cash')),
                    ),
                    DropdownMenuItem(
                      value: 'Cartão de Débito',
                      child: Text(TranslationHelper.translateSync(context, 'Cartão de Débito', 'Debit Card')),
                    ),
                    DropdownMenuItem(
                      value: 'Cartão de Crédito',
                      child: Text(TranslationHelper.translateSync(context, 'Cartão de Crédito', 'Credit Card')),
                    ),
                    DropdownMenuItem(
                      value: 'PIX',
                      child: Text('PIX'),
                    ),
                    DropdownMenuItem(
                      value: 'Vale Combustível',
                      child: Text(TranslationHelper.translateSync(context, 'Vale Combustível', 'Fuel Voucher')),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedPaymentMethod = value),
                ),
                SizedBox(height: 12),
                // Qualidade do Combustível
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Qualidade do Combustível', 'Fuel Quality'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.star),
                  ),
                  value: selectedFuelQuality,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(TranslationHelper.translateSync(context, 'Selecione', 'Select')),
                    ),
                    DropdownMenuItem(
                      value: 'Comum',
                      child: Text(TranslationHelper.translateSync(context, 'Comum', 'Regular')),
                    ),
                    DropdownMenuItem(
                      value: 'Aditivada',
                      child: Text(TranslationHelper.translateSync(context, 'Aditivada', 'Additive')),
                    ),
                    DropdownMenuItem(
                      value: 'Premium',
                      child: Text(TranslationHelper.translateSync(context, 'Premium', 'Premium')),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedFuelQuality = value),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(context, 'Observações', 'Notes'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                        ],
                      ),
                    ),
                  ),
                // Botões fixos na parte inferior
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
                      ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF003087), Color(0xFF0077D7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validação dos campos obrigatórios
                            if (selectedVehicleId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Selecione um veículo', 'Select a vehicle')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (selectedDeviceId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Selecione um dispositivo', 'Select a device')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (fuelAmountController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Informe a quantidade de combustível', 'Enter fuel amount')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (fuelPriceController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Informe o preço por litro', 'Enter price per liter')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final fuelAmount = double.tryParse(fuelAmountController.text.trim());
                            if (fuelAmount == null || fuelAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Quantidade de combustível inválida', 'Invalid fuel amount')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final fuelPrice = double.tryParse(fuelPriceController.text.trim());
                            if (fuelPrice == null || fuelPrice <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Preço por litro inválido', 'Invalid price per liter')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            try {
                              final vehicle = controller.vehicles.firstWhere((v) => v.id.toString() == selectedVehicleId);
                              final device = controller.vehicles.firstWhere((v) => v.id.toString() == selectedDeviceId);
                              
                              DriverData? driver;
                              if (selectedDriverId != null) {
                                try {
                                driver = controller.drivers.firstWhere((d) => d.id.toString() == selectedDriverId);
                                } catch (e) {
                                  print('Motorista não encontrado: $e');
                                }
                              }
                              
                              // Calcular odômetro atual e distância desde último abastecimento
                              final odometer = double.tryParse(odometerController.text.trim()) ?? 0.0;
                              final currentOdometer = controller.getVehicleOdometer(vehicle);
                              final lastFuelRecords = controller.fuelRecords
                                  .where((r) => r.vehicleId == vehicle.id)
                                  .where((r) => r.date.isBefore(selectedDate))
                                  .toList();
                              final lastFuelRecord = lastFuelRecords.isNotEmpty
                                  ? lastFuelRecords.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
                                  : null;
                              
                              final previousOdometer = lastFuelRecord?.odometer;
                              final distanceSinceLast = previousOdometer != null 
                                  ? odometer - previousOdometer 
                                  : null;
                              final consumptionSinceLast = distanceSinceLast != null && fuelAmount > 0
                                  ? distanceSinceLast / fuelAmount
                                  : null;
                              
                              final record = FuelRecord(
                                id: '${DateTime.now().millisecondsSinceEpoch}',
                                vehicleId: vehicle.id,
                                vehicleName: vehicle.name ?? 'Veículo',
                                deviceId: device.id,
                                deviceName: device.name ?? 'Dispositivo',
                                driverId: driver?.id,
                                driverName: driver?.name,
                                date: selectedDate,
                                fuelAmount: fuelAmount,
                                fuelPrice: fuelPrice,
                                totalCost: fuelAmount * fuelPrice,
                                odometer: odometer,
                                currentOdometer: currentOdometer > odometer ? currentOdometer : odometer,
                                fuelType: selectedFuelType ?? 'Gasolina',
                                station: stationController.text.trim(),
                                notes: notesController.text.trim(),
                                invoiceNumber: invoiceNumberController.text.trim().isNotEmpty 
                                    ? invoiceNumberController.text.trim() 
                                    : null,
                                paymentMethod: selectedPaymentMethod,
                                previousOdometer: previousOdometer,
                                distanceSinceLastFuel: distanceSinceLast,
                                consumptionSinceLastFuel: consumptionSinceLast,
                                fuelQuality: selectedFuelQuality,
                              );
                              
                              controller.addFuelRecord(record);
                              
                              // Mostrar mensagem de sucesso
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Abastecimento cadastrado com sucesso!', 'Fuel record added successfully!')),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              
                              Navigator.pop(context);
                            } catch (e) {
                              print('Erro ao cadastrar abastecimento: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(context, 'Erro ao cadastrar abastecimento: $e', 'Error adding fuel record: $e')),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            TranslationHelper.translateSync(context, 'Salvar', 'Save'),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ),
                ],
              ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleImageInDialog(BuildContext context, FuelControlController controller, String vehicleId) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final vehicle = controller.vehicles.firstWhere(
      (v) => v.id.toString() == vehicleId,
      orElse: () => deviceItems(),
    );
    
    if (vehicle.id == null) return SizedBox.shrink();
    
    final String baseUrl = "https://web.unnicatelemetria.com.br/";
    final imageUrl = vehicle.image != null && vehicle.image!.isNotEmpty
        ? (vehicle.image!.startsWith('http') ? vehicle.image! : "$baseUrl${vehicle.image}")
        : "$baseUrl/images/device_icons/rotating/1.png";
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 120,
              color: colorProvider.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.directions_car,
                size: 50,
                color: colorProvider.primaryColor,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 120,
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showExpenseDetailModal(
    BuildContext context,
    String period,
    double expense,
    DateTime startDate,
    DateTime endDate,
    ColorProvider colorProvider,
  ) {
    final controller = Provider.of<FuelControlController>(context, listen: false);
    final records = controller.fuelRecords
        .where((record) => record.date.isAfter(startDate.subtract(Duration(days: 1))) && 
                          record.date.isBefore(endDate.add(Duration(days: 1))))
        .toList();
    
    final totalFuel = records.fold(0.0, (sum, record) => sum + (record.fuelAmount ?? 0.0));
    final averagePrice = records.isNotEmpty 
        ? records.fold(0.0, (sum, record) => sum + (record.fuelPrice ?? 0.0)) / records.length
        : 0.0;
    final totalRecords = records.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Gastos com Abastecimento', 'Fuel Expenses'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          period,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'R\$ ${expense.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Estatísticas
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            Icons.local_gas_station,
                            '${totalFuel.toStringAsFixed(2)} L',
                            TranslationHelper.translateSync(context, 'Total de Combustível', 'Total Fuel'),
                            colorProvider,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDetailCard(
                            Icons.attach_money,
                            'R\$ ${averagePrice.toStringAsFixed(2)}/L',
                            TranslationHelper.translateSync(context, 'Preço Médio', 'Average Price'),
                            colorProvider,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            Icons.list,
                            '$totalRecords',
                            TranslationHelper.translateSync(context, 'Registros', 'Records'),
                            colorProvider,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Lista de registros
                    if (records.isNotEmpty) ...[
                      Text(
                        TranslationHelper.translateSync(context, 'Registros de Abastecimento', 'Fuel Records'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...records.map((record) => _buildExpenseRecordCard(record, colorProvider)),
                    ] else ...[
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.local_gas_station_outlined, size: 64, color: Colors.grey.shade300),
                              SizedBox(height: 16),
                              Text(
                                TranslationHelper.translateSync(context, 'Nenhum registro encontrado neste período', 'No records found in this period'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer com botões
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadExpensePDF(period, expense, startDate, endDate, records, colorProvider),
                      icon: Icon(Icons.download),
                      label: Text(TranslationHelper.translateSync(context, 'Baixar PDF', 'Download PDF')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareExpenseWhatsApp(period, expense, startDate, endDate, records),
                      icon: Icon(Icons.share),
                      label: Text(TranslationHelper.translateSync(context, 'WhatsApp', 'WhatsApp')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorProvider.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String value, String label, ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorProvider.primaryColor, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRecordCard(FuelRecord record, ColorProvider colorProvider) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
          child: Icon(Icons.local_gas_station, color: colorProvider.primaryColor),
        ),
        title: Text(record.vehicleName ?? 'Veículo'),
        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(record.date)),
        trailing: Text(
          'R\$ ${(record.totalCost ?? 0.0).toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorProvider.primaryColor,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadExpensePDF(
    String period,
    double expense,
    DateTime startDate,
    DateTime endDate,
    List<FuelRecord> records,
    ColorProvider colorProvider,
  ) async {
    // TODO: Implementar geração de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translateSync(context, 'Funcionalidade de PDF em desenvolvimento', 'PDF feature under development')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _shareExpenseWhatsApp(
    String period,
    double expense,
    DateTime startDate,
    DateTime endDate,
    List<FuelRecord> records,
  ) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totalFuel = records.fold(0.0, (sum, record) => sum + (record.fuelAmount ?? 0.0));
    final averagePrice = records.isNotEmpty 
        ? records.fold(0.0, (sum, record) => sum + (record.fuelPrice ?? 0.0)) / records.length
        : 0.0;

    final message = '''
*Gastos com Abastecimento - $period*

📅 Período: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}
💰 Total Gasto: R\$ ${expense.toStringAsFixed(2)}
⛽ Total de Combustível: ${totalFuel.toStringAsFixed(2)} L
💵 Preço Médio: R\$ ${averagePrice.toStringAsFixed(2)}/L
📋 Registros: ${records.length}
''';

    try {
      final whatsappLink = WhatsAppUnilink(
        phoneNumber: '', // Número vazio para abrir o WhatsApp sem número específico
        text: message,
      );
      
      final url = whatsappLink.toString();
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao compartilhar: $e', 'Error sharing: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
