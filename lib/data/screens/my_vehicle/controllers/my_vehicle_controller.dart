import 'package:flutter/foundation.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/device_latest_response.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';

class MyVehicleController extends ChangeNotifier {
  List<DeviceLatestItem> _vehicles = [];
  bool _isLoading = false;
  String? _error;
  DeviceLatestItem? _selectedVehicle;
  String? _selectedVehicleId; // ID do veículo selecionado no filtro
  String _searchQuery = '';

  List<DeviceLatestItem> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DeviceLatestItem? get selectedVehicle => _selectedVehicle;
  String? get selectedVehicleId => _selectedVehicleId;
  String get searchQuery => _searchQuery;

  List<DeviceLatestItem> get filteredVehicles {
    List<DeviceLatestItem> filtered = List.from(_vehicles); // Criar cópia para não modificar a lista original

    // Filtro por veículo selecionado - APENAS se um veículo específico foi selecionado
    if (_selectedVehicleId != null && _selectedVehicleId!.isNotEmpty) {
      final vehicleId = int.tryParse(_selectedVehicleId!);
      if (vehicleId != null) {
        filtered = filtered.where((v) => v.id == vehicleId).toList();
      }
    }
    // Se _selectedVehicleId for null ou vazio, mostrar TODOS os veículos (não filtrar)

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((vehicle) {
        return vehicle.name.toLowerCase().contains(query) ||
            vehicle.deviceData.plateNumber.toLowerCase().contains(query) ||
            vehicle.deviceData.imei.toLowerCase().contains(query) ||
            vehicle.address.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> loadVehicles([ObjectStore? objectStore]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('\n🔄 ========== CARREGANDO VEÍCULOS ==========');
      
      // PRIMEIRO: Garantir que ObjectStore tenha os veículos carregados
      // (usando a mesma lógica da lista de veículos - fonte principal)
      if (objectStore != null && objectStore.objects.isEmpty) {
        print('📡 Carregando veículos do ObjectStore...');
        await objectStore.getObjects();
      }
      
      // SEGUNDO: Se ObjectStore tem veículos, usar como base
      if (objectStore != null && objectStore.objects.isNotEmpty) {
        print('📡 ObjectStore tem ${objectStore.objects.length} veículo(s) - usando como base');
        
        // Tentar buscar dados completos via get_devices_latest para enriquecer
        final latestResponse = await gpsapis.getDevicesLatest();
        
        if (latestResponse != null && latestResponse.items.isNotEmpty) {
          print('✅ get_devices_latest retornou ${latestResponse.items.length} veículo(s) - usando dados completos');
          _vehicles = latestResponse.items;
        } else {
          print('⚠️ get_devices_latest retornou vazio, convertendo ObjectStore para DeviceLatestItem');
          // Converter deviceItems para DeviceLatestItem (estrutura básica)
          _vehicles = objectStore.objects.map((device) {
            return DeviceLatestItem(
              id: device.id ?? 0,
              name: device.name ?? 'Sem nome',
              online: device.online ?? 'offline',
              alarm: '',
              time: device.time ?? '',
              timestamp: 0,
              acktimestamp: 0,
              speed: (device.speed as num?)?.toDouble() ?? 0.0,
              lat: CoordinateUtils.toDouble(device.lat) ?? 0.0,
              lng: CoordinateUtils.toDouble(device.lng) ?? 0.0,
              course: device.course?.toString() ?? '0',
              power: '-',
              altitude: 0.0,
              address: device.address ?? '-',
              protocol: '',
              driver: '',
              sensors: '[]',
              services: '[]',
              tail: '[]',
              distanceUnitHour: 'kph',
              deviceData: DeviceLatestData(
                id: device.id?.toString() ?? '',
                traccarDeviceId: '',
                iconId: '',
                active: device.deviceData?.active?.toString() ?? '0',
                deleted: '0',
                name: device.name ?? '',
                imei: device.deviceData?.imei ?? '',
                fuelMeasurementId: '',
                fuelQuantity: '0.00',
                fuelPrice: '0.00',
                fuelPerKm: '0.00',
                simNumber: '',
                deviceModel: '',
                plateNumber: device.plateNumber ?? '',
                vin: '',
                registrationNumber: '',
                objectOwner: '',
                expirationDate: '0000-00-00',
                tailColor: '#0000FF',
                tailLength: '5',
                engineHours: 'gps',
                detectEngine: 'gps',
                minMovingSpeed: '6',
                minFuelFillings: '10',
                minFuelThefts: '10',
                snapToRoad: '0',
                createdAt: '',
                updatedAt: '',
              ),
            );
          }).toList();
          print('✅ ${_vehicles.length} veículo(s) carregado(s) do ObjectStore!');
        }
      } else {
        // ObjectStore está vazio ou não foi fornecido
        print('⚠️ ObjectStore está vazio ou não foi fornecido');
        
        // Tentar get_devices_latest como última tentativa
        final latestResponse = await gpsapis.getDevicesLatest();
        if (latestResponse != null && latestResponse.items.isNotEmpty) {
          _vehicles = latestResponse.items;
          print('✅ ${_vehicles.length} veículo(s) carregado(s) via get_devices_latest!');
        } else {
          _vehicles = [];
          _error = 'Nenhum veículo encontrado. Verifique se há veículos cadastrados no sistema.';
        }
      }
    } catch (e, stackTrace) {
      _error = 'Erro ao carregar veículos: $e';
      print('❌ Erro ao carregar veículos: $e');
      print('❌ Stack trace: $stackTrace');
      _vehicles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedVehicle(DeviceLatestItem? vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void setSelectedVehicleId(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
}

// Helper para conversão de coordenadas
class CoordinateUtils {
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
