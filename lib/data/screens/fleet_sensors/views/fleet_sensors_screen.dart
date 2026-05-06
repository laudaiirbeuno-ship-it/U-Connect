import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/services/health_check_service.dart';
import 'package:uconnect/data/model/device_health_data.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class FleetSensorsScreen extends StatefulWidget {
  const FleetSensorsScreen({Key? key}) : super(key: key);

  @override
  State<FleetSensorsScreen> createState() => _FleetSensorsScreenState();
}

class _FleetSensorsScreenState extends State<FleetSensorsScreen> {
  final HealthCheckService _service = HealthCheckService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<DeviceHealthData> _devices = [];
  HealthStats? _stats;
  bool _isLoading = true;
  String? _error;

  // Filtros
  int? _selectedDeviceId; // Veículo selecionado (sempre deve ter um valor)
  Map<String, dynamic>? _selectedDevice;
  DeviceHealthData? _selectedDeviceHealthData;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        if (_selectedDeviceId != null) {
          _loadDeviceDashboard(_selectedDeviceId!);
        } else {
          _loadDevices();
        }
      }
    });
  }

  Future<void> _loadDevices() async {
    print('\n🔄 [FleetSensorsScreen] Carregando dispositivos...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📡 [FleetSensorsScreen] Chamando API getDevices()...');
      final result = await _service.getDevices();
      print('✅ [FleetSensorsScreen] API retornou com sucesso');

      final devices = result['devices'] as List<DeviceHealthData>;
      final stats = result['stats'] as HealthStats;
      
      print('📱 [FleetSensorsScreen] Dispositivos recebidos: ${devices.length}');
      print('📊 [FleetSensorsScreen] Stats recebidos: Total=${stats.totalDevices}, Online=${stats.onlineDevices}');
      
      setState(() {
        _devices = devices;
        _stats = stats;
        _isLoading = false;
      });
      
      // SEMPRE selecionar automaticamente o primeiro veículo se não houver um selecionado
      if (devices.isNotEmpty) {
        if (_selectedDeviceId == null || !devices.any((d) => d.deviceId == _selectedDeviceId)) {
          print('🚗 [FleetSensorsScreen] Selecionando primeiro veículo: ${devices.first.deviceId}');
          setState(() {
            _selectedDeviceId = devices.first.deviceId;
          });
          _loadDeviceDashboard(_selectedDeviceId!);
        } else if (_selectedDeviceHealthData == null) {
          // Se já tem um selecionado mas não carregou o dashboard ainda
          print('🚗 [FleetSensorsScreen] Carregando dashboard do veículo selecionado: $_selectedDeviceId');
          _loadDeviceDashboard(_selectedDeviceId!);
        }
      } else {
        print('⚠️ [FleetSensorsScreen] Nenhum dispositivo encontrado');
      }
    } catch (e, stackTrace) {
      print('❌ [FleetSensorsScreen] Erro ao carregar dispositivos: $e');
      print('📚 Stack Trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceDashboard(int deviceId) async {
    print('\n🔄 [FleetSensorsScreen] Carregando dashboard do dispositivo $deviceId...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📡 [FleetSensorsScreen] Chamando API getDeviceDetails($deviceId)...');
      final result = await _service.getDeviceDetails(deviceId);
      print('✅ [FleetSensorsScreen] Dashboard carregado com sucesso');
      
      setState(() {
        _selectedDevice = result['device'] as Map<String, dynamic>;
        _selectedDeviceHealthData = result['health_data'] as DeviceHealthData;
        _isLoading = false;
      });
      
      print('📱 [FleetSensorsScreen] Device: ${_selectedDevice?['name'] ?? 'Não disponível'}');
      print('💚 [FleetSensorsScreen] Health: Status=${_selectedDeviceHealthData?.statusText}, GPS=${_selectedDeviceHealthData?.gpsSignal}');
    } catch (e, stackTrace) {
      print('❌ [FleetSensorsScreen] Erro ao carregar dashboard: $e');
      print('📚 Stack Trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDevice() async {
    try {
      final url = Uri.parse('${UserRepository.getServerURL()}/api/get_devices');
      
      final body = jsonEncode({});
      
      final headers = {
        'Authorization': 'Bearer ${StaticVarMethod.user_api_hash ?? ''}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            TranslationHelper.translateSync(context, 'A requisição demorou mais de 90 segundos. Tente um período menor ou verifique sua conexão.', 'Request took more than 90 seconds. Try a shorter period or check your connection.'),
            Duration(seconds: 90),
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && (data['status'] == 0 || data['status'] == false)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        List<Map<String, dynamic>> devices = [];
        
        if (data is List) {
          for (var group in data) {
            if (group is Map && group['items'] != null && group['items'] is List) {
              final groupItems = group['items'] as List;
              for (var item in groupItems) {
                if (item is Map<String, dynamic>) {
                  devices.add(item);
                } else if (item is Map) {
                  devices.add(Map<String, dynamic>.from(item));
                }
              }
            }
          }
        } else if (data is Map && data['items'] != null && data['items'] is List) {
          for (var item in data['items']) {
            if (item is Map<String, dynamic>) {
              devices.add(item);
            } else if (item is Map) {
              devices.add(Map<String, dynamic>.from(item));
            }
          }
        }

        if (devices.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Nenhum dispositivo disponível', 'No devices available')),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final colorProvider = Provider.of<ColorProvider>(context, listen: false);
        
        final selected = await showModalBottomSheet<Map<String, dynamic>>(
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
                      Icon(Icons.directions_car, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          TranslationHelper.translateSync(context, 'Selecionar Veículo', 'Select Vehicle'),
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
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final deviceId = device['id'];
                      final deviceIdInt = deviceId is int ? deviceId : (deviceId is String ? int.tryParse(deviceId) : null);
                      final deviceName = device['name'] ?? device['display'] ?? 'Dispositivo $deviceId';
                      
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
                            deviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: device['plate'] != null 
                              ? Text('${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${device['plate']}')
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: colorProvider.primaryColor,
                            size: 18,
                          ),
                          onTap: () {
                            if (deviceIdInt != null) {
                              Navigator.pop(context, {'id': deviceIdInt, 'name': deviceName});
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        if (selected != null && selected['id'] != null) {
          final deviceIdInt = selected['id'] as int;
          setState(() {
            _selectedDeviceId = deviceIdInt; // Sempre manter um veículo selecionado
          });
          _loadDeviceDashboard(deviceIdInt);
        } else if (_devices.isNotEmpty && _selectedDeviceId == null) {
          // Se não selecionou nenhum mas há dispositivos, selecionar o primeiro
          setState(() {
            _selectedDeviceId = _devices.first.deviceId;
          });
          _loadDeviceDashboard(_selectedDeviceId!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices')}: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Sensores da Frota', 'Fleet Sensors'),
        icon: Icons.sensors,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Column(
                children: [
                  _buildFiltersSection(colorProvider),
                  
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                            ),
                          )
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    SizedBox(height: 16),
                                    Text(
                                      TranslationHelper.translateSync(context, 'Erro ao carregar dados', 'Error loading data'),
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadDevices,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorProvider.primaryColor,
                                      ),
                                      child: Text(TranslationHelper.translateSync(context, 'Tentar Novamente', 'Try Again')),
                                    ),
                                  ],
                                ),
                              )
                            : _selectedDeviceId != null && _selectedDeviceHealthData != null
                                ? _buildDeviceDashboard(colorProvider)
                                : Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                                    ),
                                  ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ColorProvider colorProvider) {
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
      child: _buildVehicleSelector(colorProvider),
    );
  }

  Widget _buildVehicleSelector(ColorProvider colorProvider) {
    final deviceName = _selectedDevice != null 
        ? (_selectedDevice!['name'] ?? _selectedDevice!['device_name'] ?? '')
        : (_devices.isNotEmpty && _selectedDeviceId != null
            ? _devices.firstWhere((d) => d.deviceId == _selectedDeviceId, orElse: () => _devices.first).deviceName
            : TranslationHelper.translateSync(context, 'Selecione um veículo', 'Select a vehicle'));

    return InkWell(
      onTap: _selectDevice,
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
                color: colorProvider.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car,
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
                    TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    deviceName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorProvider.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFleetView(ColorProvider colorProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_stats != null) _buildStatsCards(colorProvider),
          SizedBox(height: 16),
          if (_devices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      TranslationHelper.translateSync(context, 'Nenhum dispositivo encontrado', 'No devices found'),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._devices.map((device) => _buildDeviceCard(device, colorProvider)),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Total', 'Total'),
            _stats!.totalDevices.toString(),
            Icons.devices,
            colorProvider.primaryColor,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Online', 'Online'),
            _stats!.onlineDevices.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Offline', 'Offline'),
            _stats!.offlineDevices.toString(),
            Icons.cancel,
            Colors.red,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Sinal Ruim', 'Poor Signal'),
            _stats!.poorSignalDevices.toString(),
            Icons.signal_wifi_off,
            Colors.orange,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Bateria Baixa', 'Low Battery'),
            _stats!.lowBatteryDevices.toString(),
            Icons.battery_alert,
            Colors.yellow[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceHealthData device, ColorProvider colorProvider) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _buildStatusIcon(device, colorProvider),
        title: Text(
          device.deviceName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('IMEI: ${device.imei}'),
        trailing: Icon(Icons.chevron_right, color: colorProvider.primaryColor),
        onTap: () {
          setState(() {
            _selectedDeviceId = device.deviceId;
          });
          _loadDeviceDashboard(device.deviceId);
        },
      ),
    );
  }

  Widget _buildStatusIcon(DeviceHealthData device, ColorProvider colorProvider) {
    Color color;
    IconData icon;

    if (!device.isOnline) {
      color = Colors.red;
      icon = Icons.cancel;
    } else if (device.statusClass == 'warning') {
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildDeviceDashboard(ColorProvider colorProvider) {
    if (_selectedDeviceHealthData == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
        ),
      );
    }

    final health = _selectedDeviceHealthData!;
    final deviceName = _selectedDevice?['name'] ?? _selectedDevice?['device_name'] ?? health.deviceName;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header do Dashboard
          Container(
            padding: EdgeInsets.all(16),
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
            child: Row(
              children: [
                _buildStatusIcon(health, colorProvider),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (health.deviceModel != null)
                        Text(
                          health.deviceModel!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cards de Estatísticas (2 por linha)
          Container(
            padding: EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Status', 'Status'),
                  health.statusText,
                  Icons.info_outline,
                  _getStatusColor(health.statusClass),
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Velocidade', 'Speed'),
                  '${(health.speed ?? 0).toStringAsFixed(0)} km/h',
                  Icons.speed,
                  (health.speed ?? 0) > 0 ? Colors.green : Colors.grey,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Última Atualização', 'Last Update'),
                  _getTimeAgo(health.lastUpdate),
                  Icons.access_time,
                  Colors.blue,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Satélites', 'Satellites'),
                  '${health.gpsSignal}',
                  Icons.satellite_alt,
                  Colors.purple,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'GPS', 'GPS'),
                  _getGpsDescription(context, health.gpsSignal),
                  Icons.location_on,
                  _getSignalColor(health.gpsSignal),
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Tempo Parado', 'Stop Duration'),
                  health.stopDuration ?? '---',
                  Icons.timer_off,
                  Colors.orange,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'GSM', 'GSM'),
                  _getGsmDescription(context, health.gsmSignal),
                  Icons.signal_cellular_alt,
                  _getSignalColor(health.gsmSignal),
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Bateria', 'Battery'),
                  health.batteryLevel != null 
                      ? '${health.batteryLevel}%'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  Icons.battery_std,
                  health.batteryLevel != null 
                      ? _getBatteryColor(health.batteryLevel!)
                      : Colors.grey,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Voltagem', 'Voltage'),
                  health.powerVoltage != null
                      ? '${health.powerVoltage!.toStringAsFixed(1)}V'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  Icons.battery_charging_full,
                  health.powerVoltage != null
                      ? _getVoltageColor(health.powerVoltage!)
                      : Colors.grey,
                  colorProvider,
                ),
                _buildDashboardCard(
                  TranslationHelper.translateSync(context, 'Uptime', 'Uptime'),
                  '${health.uptimePercentage.toStringAsFixed(1)}%',
                  Icons.timer,
                  _getUptimeColor(health.uptimePercentage),
                  colorProvider,
                ),
              ],
            ),
          ),

          // Informações Detalhadas
          Container(
            margin: EdgeInsets.all(16),
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
                Text(
                  TranslationHelper.translateSync(context, 'Informações Detalhadas', 'Detailed Information'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Endereço', 'Address'),
                  health.address ?? TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'IMEI', 'IMEI'),
                  health.imei,
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Número do Chip', 'SIM Number'),
                  health.simNumber ?? TranslationHelper.translateSync(context, 'Não informado', 'Not informed'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Placa', 'Plate'),
                  health.plateNumber ?? TranslationHelper.translateSync(context, 'Não informado', 'Not informed'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Ignição', 'Ignition'),
                  health.ignition == true
                      ? TranslationHelper.translateSync(context, 'Ligada', 'On')
                      : health.ignition == false
                          ? TranslationHelper.translateSync(context, 'Desligada', 'Off')
                          : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                  valueColor: health.ignition == true 
                      ? Colors.green 
                      : health.ignition == false 
                          ? Colors.red 
                          : Colors.grey,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Movimento', 'Motion'),
                  health.motion == true
                      ? TranslationHelper.translateSync(context, 'Movendo', 'Moving')
                      : health.motion == false
                          ? TranslationHelper.translateSync(context, 'Parado', 'Stopped')
                          : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                  valueColor: health.motion == true 
                      ? Colors.green 
                      : health.motion == false 
                          ? Colors.orange 
                          : Colors.grey,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Posição Válida', 'Valid Position'),
                  health.validPosition == true
                      ? TranslationHelper.translateSync(context, 'Sim', 'Yes')
                      : health.validPosition == false
                          ? TranslationHelper.translateSync(context, 'Não', 'No')
                          : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                  valueColor: health.validPosition == true 
                      ? Colors.green 
                      : health.validPosition == false 
                          ? Colors.red 
                          : Colors.grey,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Odômetro', 'Odometer'),
                  health.odometer != null
                      ? '${health.odometer!.toStringAsFixed(0)} km'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Horas Motor', 'Engine Hours'),
                  health.engineHours != null
                      ? '${health.engineHours!.toStringAsFixed(1)} h'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Distância Total', 'Total Distance'),
                  health.totalDistance != null
                      ? '${health.totalDistance!.toStringAsFixed(0)} km'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Precisão GPS', 'GPS Accuracy'),
                  health.accuracy != null
                      ? '${health.accuracy!.toStringAsFixed(1)} m'
                      : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Carregando', 'Charging'),
                  health.charge == true
                      ? TranslationHelper.translateSync(context, 'Sim', 'Yes')
                      : health.charge == false
                          ? TranslationHelper.translateSync(context, 'Não', 'No')
                          : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                  valueColor: health.charge == true 
                      ? Colors.green 
                      : health.charge == false 
                          ? Colors.grey 
                          : Colors.grey,
                ),
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Bloqueado', 'Blocked'),
                  health.blocked == true
                      ? TranslationHelper.translateSync(context, 'Sim', 'Yes')
                      : health.blocked == false
                          ? TranslationHelper.translateSync(context, 'Não', 'No')
                          : TranslationHelper.translateSync(context, 'Não disponível', 'Not available'),
                  colorProvider,
                  valueColor: health.blocked == true 
                      ? Colors.red 
                      : health.blocked == false 
                          ? Colors.green 
                          : Colors.grey,
                ),
                if (health.lastReset != null) ...[
                  SizedBox(height: 8),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    TranslationHelper.translateSync(context, 'Auto-Reset', 'Auto-Reset'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(
                    TranslationHelper.translateSync(context, 'Data/Hora', 'Date/Time'),
                    health.lastReset!.time,
                    colorProvider,
                  ),
                  _buildDetailRow(
                    TranslationHelper.translateSync(context, 'Status', 'Status'),
                    health.lastReset!.status,
                    colorProvider,
                    valueColor: health.lastReset!.status == 'Sucesso' ? Colors.green : Colors.red,
                  ),
                  _buildDetailRow(
                    TranslationHelper.translateSync(context, 'Comando', 'Command'),
                    health.lastReset!.command,
                    colorProvider,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ColorProvider colorProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: colorProvider.primaryColor, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ColorProvider colorProvider, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (valueColor ?? colorProvider.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (valueColor ?? colorProvider.primaryColor).withOpacity(0.3),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? colorProvider.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String statusClass) {
    switch (statusClass) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSignalColor(int signal) {
    if (signal >= 4) return Colors.green;
    if (signal >= 2) return Colors.orange;
    return Colors.red;
  }

  Color _getBatteryColor(int battery) {
    if (battery >= 50) return Colors.green;
    if (battery >= 20) return Colors.orange;
    return Colors.red;
  }

  Color _getTemperatureColor(double temp) {
    if (temp >= 30) return Colors.red;
    if (temp >= 25) return Colors.orange;
    return Colors.green;
  }

  Color _getVoltageColor(double voltage) {
    if (voltage >= 12.0) return Colors.green;
    if (voltage >= 11.0) return Colors.orange;
    return Colors.red;
  }

  Color _getUptimeColor(double uptime) {
    if (uptime >= 90) return Colors.green;
    if (uptime >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getTimeAgo(DateTime? time) {
    if (time == null) return '---';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _getGpsDescription(BuildContext context, int gpsSignal) {
    if (gpsSignal >= 8) {
      return TranslationHelper.translateSync(context, 'Excelente', 'Excellent');
    } else if (gpsSignal >= 4) {
      return TranslationHelper.translateSync(context, 'Bom', 'Good');
    } else if (gpsSignal >= 1) {
      return TranslationHelper.translateSync(context, 'Fraco', 'Weak');
    } else {
      return TranslationHelper.translateSync(context, 'Sem sinal', 'No signal');
    }
  }

  String _getGsmDescription(BuildContext context, int gsmSignal) {
    if (gsmSignal >= 4) {
      return TranslationHelper.translateSync(context, 'Excelente', 'Excellent');
    } else if (gsmSignal >= 2) {
      return TranslationHelper.translateSync(context, 'Bom', 'Good');
    } else if (gsmSignal >= 1) {
      return TranslationHelper.translateSync(context, 'Fraco', 'Weak');
    } else {
      return TranslationHelper.translateSync(context, 'Sem sinal', 'No signal');
    }
  }

}
