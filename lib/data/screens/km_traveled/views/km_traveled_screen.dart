import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/screens/km_traveled/controllers/km_traveled_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class KmTraveledScreen extends StatefulWidget {
  @override
  _KmTraveledScreenState createState() => _KmTraveledScreenState();
}

class _KmTraveledScreenState extends State<KmTraveledScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Carregar dispositivos do ObjectStore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ObjectStore>(context, listen: false).getObjects();
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KmTraveledController(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.grey.shade50,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, 'KM Percorrido', 'Distance Travelled'),
          icon: Icons.speed,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: Stack(
          children: [
            // Fundo animado
            AnimatedBackground(opacity: 0.03),
            // Conteúdo
            Consumer2<KmTraveledController, ColorProvider>(
              builder: (context, controller, colorProvider, child) {
                return RefreshIndicator(
                  onRefresh: () => controller.loadData(),
                  color: colorProvider.primaryColor,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 100, // Espaço extra no final para scroll completo
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtros
                        _buildFiltersSection(controller, colorProvider),
                        SizedBox(height: 24),
                        
                        // Gráfico
                        _buildChartSection(controller, colorProvider),
                        SizedBox(height: 24),
                        
                        // Lista detalhada
                        _buildDetailedList(controller, colorProvider),
                        
                        // Espaço no final para garantir scroll completo
                        SizedBox(height: 100),
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

  Widget _buildFiltersSection(KmTraveledController controller, ColorProvider colorProvider) {
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
          _buildDeviceSelector(controller, colorProvider),
          SizedBox(height: 12),
          _buildPeriodSelector(controller, colorProvider),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector(KmTraveledController controller, ColorProvider colorProvider) {
    return InkWell(
      onTap: () => _selectDevice(controller),
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
                    controller.selectedDevice == null 
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
                    controller.selectedDevice == null
                        ? TranslationHelper.translateSync(context, 'Toque para escolher um veículo', 'Tap to choose a vehicle')
                        : controller.selectedDevice?.name ?? TranslationHelper.translateSync(context, 'Dispositivo', 'Device'),
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

  Widget _buildPeriodSelector(KmTraveledController controller, ColorProvider colorProvider) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectPeriod(controller),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today, color: colorProvider.primaryColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${TranslationHelper.translateSync(context, 'De', 'From')}: ${DateFormat('dd/MM/yyyy HH:mm').format(controller.fromDate)}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        ),
                        Text(
                          '${TranslationHelper.translateSync(context, 'Até', 'To')}: ${DateFormat('dd/MM/yyyy HH:mm').format(controller.toDate)}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDevice(KmTraveledController controller) async {
    try {
      final objectStore = Provider.of<ObjectStore>(context, listen: false);
      final devices = objectStore.objects.isNotEmpty 
          ? List<deviceItems>.from(objectStore.objects)
          : <deviceItems>[];
      
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Nenhum dispositivo disponível', 'No devices available')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final colorProvider = Provider.of<ColorProvider>(context, listen: false);
      
      final selected = await showModalBottomSheet<deviceItems>(
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
                      final isSelected = controller.selectedDevice == null;
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
                    final isSelected = controller.selectedDevice?.id == device.id;
                    
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
                        onTap: () => Navigator.pop(context, device),
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
        controller.setSelectedDevice(selected);
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

  Future<void> _selectPeriod(KmTraveledController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: controller.fromDate, end: controller.toDate),
    );

    if (picked != null) {
      final fromTimeStr = controller.fromTime;
      final toTimeStr = controller.toTime;
      final fromTimeParts = fromTimeStr.split(':');
      final toTimeParts = toTimeStr.split(':');
      
      final fromDateTime = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        int.tryParse(fromTimeParts[0]) ?? 0,
        int.tryParse(fromTimeParts[1]) ?? 0,
      );
      
      final toDateTime = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        int.tryParse(toTimeParts[0]) ?? 23,
        int.tryParse(toTimeParts[1]) ?? 59,
      );
      
      controller.setCustomDateRange(
        fromDateTime,
        toDateTime,
        fromTimeStr,
        toTimeStr,
      );
    }
  }



  Widget _buildChartSection(KmTraveledController controller, ColorProvider colorProvider) {
    if (controller.isLoading || controller.detailedData.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
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
              Icon(Icons.bar_chart, color: colorProvider.primaryColor),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'KM por Veículo', 'KM per Vehicle'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelRotation: -45,
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
              ),
              series: <CartesianSeries<Map<String, dynamic>, String>>[
                ColumnSeries<Map<String, dynamic>, String>(
                  dataSource: controller.detailedData.take(10).toList(),
                  xValueMapper: (Map<String, dynamic> data, _) {
                    final name = data['deviceName'] as String? ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name');
                    return name.length > 10 ? name.substring(0, 10) + '...' : name;
                  },
                  yValueMapper: (Map<String, dynamic> data, _) => data['km'] as double,
                  color: colorProvider.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedList(KmTraveledController controller, ColorProvider colorProvider) {
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorProvider.primaryColor),
      );
    }

    if (controller.detailedData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhum dado encontrado', 'No data found'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
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
              Icon(Icons.list, color: colorProvider.primaryColor),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Detalhamento', 'Details'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...controller.detailedData.map((data) => _buildKmCard(data, colorProvider)),
        ],
      ),
    );
  }

  Widget _buildKmCard(Map<String, dynamic> data, ColorProvider colorProvider) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    final km = data['km'] as double;
    final kmStr = currencyFormat.format(km).replaceAll('R\$', '').trim();
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['deviceName'] as String? ?? TranslationHelper.translateSync(context, 'Sem nome', 'No name'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'IMEI: ${data['imei']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (data['status'] == 'Online' ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data['status'] as String? ?? TranslationHelper.translateSync(context, 'N/A', 'N/A'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: data['status'] == 'Online' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.translateSync(context, 'KM no Período', 'KM in Period'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$kmStr km',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.straighten,
                  color: colorProvider.primaryColor,
                  size: 32,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKmDetailItem(
                  TranslationHelper.translateSync(context, 'Hoje', 'Today'),
                  '${currencyFormat.format(data['kmToday'] as double? ?? 0.0).replaceAll('R\$', '').trim()} km',
                  Icons.today,
                  colorProvider,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildKmDetailItem(
                  TranslationHelper.translateSync(context, 'Semana', 'Week'),
                  '${currencyFormat.format(data['kmWeek'] as double? ?? 0.0).replaceAll('R\$', '').trim()} km',
                  Icons.date_range,
                  colorProvider,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKmDetailItem(
                  TranslationHelper.translateSync(context, 'Mês', 'Month'),
                  '${currencyFormat.format(data['kmMonth'] as double? ?? 0.0).replaceAll('R\$', '').trim()} km',
                  Icons.calendar_month,
                  colorProvider,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildKmDetailItem(
                  TranslationHelper.translateSync(context, 'Total', 'Total'),
                  '${currencyFormat.format(data['kmTotal'] as double? ?? 0.0).replaceAll('R\$', '').trim()} km',
                  Icons.auto_graph,
                  colorProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKmDetailItem(String label, String value, IconData icon, ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorProvider.primaryColor),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
