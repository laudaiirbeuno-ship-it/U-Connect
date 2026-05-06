import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/data/screens/fuel_consumption/controllers/fuel_consumption_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';

class FuelConsumptionScreen extends StatefulWidget {
  @override
  _FuelConsumptionScreenState createState() => _FuelConsumptionScreenState();
}

class _FuelConsumptionScreenState extends State<FuelConsumptionScreen> {
  late FuelConsumptionController _controller;
  String? _selectedVehicleId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = FuelConsumptionController();
    _loadData();
  }


  Future<void> _loadData() async {
    final objectStore = context.read<ObjectStore>();
    List<deviceItems> devices = objectStore.objects;
    
    // Filtrar por veículo se selecionado
    if (_selectedVehicleId != null && _selectedVehicleId!.isNotEmpty) {
      devices = devices.where((d) => d.id != null && d.id.toString() == _selectedVehicleId).toList();
    }
    
    await _controller.loadFuelData(devices);
  }

  Widget _buildDeviceSelector(ColorProvider colorProvider, ObjectStore objectStore) {
    final selectedDevice = _selectedVehicleId != null
        ? objectStore.objects.firstWhere(
            (device) => device.id?.toString() == _selectedVehicleId,
            orElse: () => deviceItems(),
          )
        : null;
    
    return InkWell(
      onTap: () => _selectDevice(colorProvider, objectStore),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorProvider.primaryColor.withOpacity(0.1),
              colorProvider.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorProvider.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.devices, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedVehicleId == null 
                        ? TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device')
                        : TranslationHelper.translateSync(context, 'Dispositivo Selecionado', 'Device Selected'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedVehicleId == null
                        ? TranslationHelper.translateSync(context, 'Toque para escolher um veículo', 'Tap to choose a vehicle')
                        : selectedDevice?.name ?? TranslationHelper.translateSync(context, 'Dispositivo', 'Device'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorProvider.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDevice(ColorProvider colorProvider, ObjectStore objectStore) async {
    try {
      final devices = objectStore.objects.isNotEmpty 
          ? List<deviceItems>.from(objectStore.objects)
          : <deviceItems>[];
      
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                    Icon(Icons.devices, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Lista de dispositivos
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: devices.length + 1, // +1 para "Todos os veículos"
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedVehicleId == null;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                          title: Text(
                            TranslationHelper.translateSync(context, 'Todos os veículos', 'All vehicles'),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                              color: isSelected ? colorProvider.primaryColor : Colors.black87,
                            ),
                          ),
                          trailing: isSelected 
                              ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  color: colorProvider.primaryColor,
                                  size: 18,
                                ),
                          onTap: () => Navigator.pop(context, null),
                        ),
                      );
                    }
                    
                    final device = devices[index - 1];
                    final isSelected = _selectedVehicleId == device.id?.toString();
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: colorProvider.primaryColor,
                          ),
                        ),
                        title: Text(
                          device.name ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name'),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                            color: isSelected ? colorProvider.primaryColor : Colors.black87,
                          ),
                        ),
                        subtitle: device.plateNumber != null && device.plateNumber!.isNotEmpty
                            ? Text('${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${device.plateNumber}')
                            : null,
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: colorProvider.primaryColor)
                            : Icon(
                                Icons.arrow_forward_ios,
                                color: colorProvider.primaryColor,
                                size: 18,
                              ),
                        onTap: () => Navigator.pop(context, device.id?.toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (selected != null || selected == null) {
        setState(() {
          _selectedVehicleId = selected;
        });
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao carregar dispositivos: $e', 'Error loading devices: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    // Não precisa fazer nada
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'Consumo de Combustível', 'Fuel Consumption'),
          icon: Icons.local_gas_station,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              // Filtro
              Consumer<ObjectStore>(
                builder: (context, objectStore, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        _buildDeviceSelector(colorProvider, objectStore),
                      ],
                    ),
                  );
                },
              ),
              // Conteúdo
              Expanded(
                child: Consumer<FuelConsumptionController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorProvider.primaryColor,
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cards de Resumo
                          _buildSummaryCards(colorProvider, controller),
                          SizedBox(height: 16),
                          
                          // Gráfico
                          _buildChart(colorProvider, controller),
                          SizedBox(height: 16),
                          
                          // Lista de Veículos
                          _buildVehicleList(colorProvider, controller),
                          SizedBox(height: 80), // Espaço para o bottom nav
                        ],
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

  Widget _buildSummaryCards(ColorProvider colorProvider, FuelConsumptionController controller) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              TranslationHelper.translateSync(context, 'Hoje', 'Today'),
              controller.fuelToday,
              'L',
              Icons.today,
              colorProvider.primaryColor,
              colorProvider,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              TranslationHelper.translateSync(context, 'Semana', 'Week'),
              controller.fuelWeek,
              'L',
              Icons.date_range,
              colorProvider.primaryColor,
              colorProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double value,
    String unit,
    IconData icon,
    Color color,
    ColorProvider colorProvider,
  ) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: colorProvider.primaryColor, size: 28),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '${value.toStringAsFixed(2)} $unit',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ColorProvider colorProvider, FuelConsumptionController controller) {
    final chartData = [
      _ChartData(
        TranslationHelper.translateSync(context, 'Hoje', 'Today'),
        controller.fuelToday,
        colorProvider.primaryColor,
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Semana', 'Week'),
        controller.fuelWeek,
        colorProvider.primaryColor.withOpacity(0.8),
      ),
      _ChartData(
        TranslationHelper.translateSync(context, 'Mês', 'Month'),
        controller.fuelMonth,
        colorProvider.primaryColor.withOpacity(0.6),
      ),
    ];

    final maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
              Icon(Icons.bar_chart, color: colorProvider.primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Consumo por Período', 'Consumption by Period'),
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
            height: 220,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: maxValue > 0 ? maxValue * 1.2 : 100,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                axisLine: AxisLine(color: Colors.grey.shade300),
                majorTickLines: MajorTickLines(color: Colors.grey.shade300),
                numberFormat: NumberFormat.compact(locale: 'pt_BR'),
              ),
              plotAreaBorderWidth: 0,
              series: <CartesianSeries>[
                ColumnSeries<_ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (_ChartData data, _) => data.category,
                  yValueMapper: (_ChartData data, _) => data.value,
                  pointColorMapper: (_ChartData data, _) => data.color,
                  borderRadius: BorderRadius.circular(8),
                  width: 0.6,
                  spacing: 0.2,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(ColorProvider colorProvider, FuelConsumptionController controller) {
    if (controller.vehicleFuelData.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhum dado de combustível disponível', 'No fuel data available'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.directions_car, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Consumo por Veículo', 'Consumption per Vehicle'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.vehicleFuelData.length,
          itemBuilder: (context, index) {
            final vehicleData = controller.vehicleFuelData[index];
            return _buildVehicleCard(vehicleData, colorProvider);
          },
        ),
      ],
    );
  }

  Widget _buildVehicleCard(VehicleFuelData vehicleData, ColorProvider colorProvider) {
    final vehicle = vehicleData.vehicle;
    final imageUrl = vehicle.image != null && vehicle.image!.isNotEmpty
        ? "https://web.unnicatelemetria.com.br/${vehicle.image}"
        : "https://web.unnicatelemetria.com.br/images/device_icons/rotating/1.png";

    return InkWell(
      onTap: () => _showFuelDetailsModal(vehicleData, colorProvider),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Row(
          children: [
            // Imagem do veículo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: colorProvider.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.directions_car,
                      color: colorProvider.primaryColor,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Consumo Real
                  if (vehicleData.realConsumption > 0) ...[
                    Row(
                      children: [
                        Icon(Icons.speed, size: 16, color: colorProvider.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          TranslationHelper.translateSync(context, 'Consumo Real: ${vehicleData.realConsumption.toStringAsFixed(2)} km/L', 'Real Consumption: ${vehicleData.realConsumption.toStringAsFixed(2)} km/L'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorProvider.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (vehicleData.distanceTraveled > 0)
                      Text(
                        TranslationHelper.translateSync(context, 'Distância: ${vehicleData.distanceTraveled.toStringAsFixed(0)} km', 'Distance: ${vehicleData.distanceTraveled.toStringAsFixed(0)} km'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    SizedBox(height: 8),
                  ],
                  Text(
                    vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFuelBadge(
                        TranslationHelper.translateSync(context, 'Hoje', 'Today'),
                        vehicleData.fuelToday,
                        Colors.blue,
                      ),
                      SizedBox(width: 8),
                      _buildFuelBadge(
                        TranslationHelper.translateSync(context, 'Semana', 'Week'),
                        vehicleData.fuelWeek,
                        Colors.green,
                      ),
                      SizedBox(width: 8),
                      _buildFuelBadge(
                        TranslationHelper.translateSync(context, 'Mês', 'Month'),
                        vehicleData.fuelMonth,
                        colorProvider.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelBadge(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            '${value.toStringAsFixed(1)}L',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFuelDetailsModal(VehicleFuelData vehicleData, ColorProvider colorProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FuelDetailsModal(
        vehicleData: vehicleData,
        colorProvider: colorProvider,
      ),
    );
  }
}

class _FuelDetailsModal extends StatefulWidget {
  final VehicleFuelData vehicleData;
  final ColorProvider colorProvider;

  const _FuelDetailsModal({
    required this.vehicleData,
    required this.colorProvider,
  });

  @override
  State<_FuelDetailsModal> createState() => _FuelDetailsModalState();
}

class _FuelDetailsModalState extends State<_FuelDetailsModal> {
  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicleData.vehicle;
    final imageUrl = vehicle.image != null && vehicle.image!.isNotEmpty
        ? "https://web.unnicatelemetria.com.br/${vehicle.image}"
        : "https://web.unnicatelemetria.com.br/images/device_icons/rotating/1.png";

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.colorProvider.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty)
                        Text(
                          vehicle.plateNumber!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
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
          
          // Conteúdo
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumo de Consumo
                  _buildSectionTitle(
                    TranslationHelper.translateSync(context, 'Resumo de Consumo', 'Consumption Summary'),
                    Icons.local_gas_station,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          TranslationHelper.translateSync(context, 'Hoje', 'Today'),
                          '${widget.vehicleData.fuelToday.toStringAsFixed(2)} L',
                          Icons.today,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailCard(
                          TranslationHelper.translateSync(context, 'Semana', 'Week'),
                          '${widget.vehicleData.fuelWeek.toStringAsFixed(2)} L',
                          Icons.date_range,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildDetailCard(
                    TranslationHelper.translateSync(context, 'Mês', 'Month'),
                    '${widget.vehicleData.fuelMonth.toStringAsFixed(2)} L',
                    Icons.calendar_month,
                    widget.colorProvider.primaryColor,
                    fullWidth: true,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Estatísticas Detalhadas
                  _buildSectionTitle(
                    TranslationHelper.translateSync(context, 'Estatísticas Detalhadas', 'Detailed Statistics'),
                    Icons.analytics,
                  ),
                  SizedBox(height: 16),
                  
                  if (widget.vehicleData.realConsumption > 0) ...[
                    _buildStatRow(
                      TranslationHelper.translateSync(context, 'Consumo Real', 'Real Consumption'),
                      '${widget.vehicleData.realConsumption.toStringAsFixed(2)} km/L',
                      Icons.speed,
                      widget.colorProvider.primaryColor,
                    ),
                    SizedBox(height: 12),
                  ],
                  
                  if (widget.vehicleData.distanceTraveled > 0) ...[
                    _buildStatRow(
                      TranslationHelper.translateSync(context, 'Distância Percorrida', 'Distance Traveled'),
                      '${widget.vehicleData.distanceTraveled.toStringAsFixed(0)} km',
                      Icons.straighten,
                      Colors.orange,
                    ),
                    SizedBox(height: 12),
                  ],
                  
                  _buildStatRow(
                    TranslationHelper.translateSync(context, 'Consumo Total', 'Total Consumption'),
                    '${widget.vehicleData.fuelTotal.toStringAsFixed(2)} L',
                    Icons.local_gas_station,
                    Colors.red,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Informações do Veículo
                  _buildSectionTitle(
                    TranslationHelper.translateSync(context, 'Informações do Veículo', 'Vehicle Information'),
                    Icons.info,
                  ),
                  SizedBox(height: 16),
                  
                  if (vehicle.id != null)
                    _buildInfoRow(
                      TranslationHelper.translateSync(context, 'ID', 'ID'),
                      vehicle.id.toString(),
                    ),
                  if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty)
                    _buildInfoRow(
                      TranslationHelper.translateSync(context, 'Placa', 'Plate'),
                      vehicle.plateNumber!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.colorProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: widget.colorProvider.primaryColor, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Row(
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
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String category;
  final double value;
  final Color color;

  _ChartData(this.category, this.value, this.color);
}
