import 'package:flutter/foundation.dart';

class CamerasController extends ChangeNotifier {
  List<CameraInfo> _allCameras = [];
  List<CameraInfo> _filteredCameras = [];
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedVehicleId;
  bool _isLoading = false;
  String? _error;

  List<CameraInfo> get cameras => _filteredCameras;
  String? get selectedStatus => _selectedStatus;
  String? get selectedCategory => _selectedCategory;
  String? get selectedVehicleId => _selectedVehicleId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get statuses {
    final statuses = _allCameras.map((c) => c.status).toSet().toList();
    statuses.sort();
    return ['Todos', ...statuses];
  }

  List<String> get categories {
    final cats = _allCameras.map((c) => c.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  CamerasController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implementar chamada à API para buscar câmeras
      // Em produção, isso viria da API:
      // final response = await gpsapis.getCameras(...);
      // if (response != null) {
      //   _allCameras = response.map((c) => CameraInfo.fromJson(c)).toList();
      // }
      _allCameras = [];
      
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String? status) {
    _selectedStatus = status == 'Todos' ? null : status;
    _applyFilter();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category == 'Todas' ? null : category;
    _applyFilter();
    notifyListeners();
  }

  void setVehicleId(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredCameras = _allCameras.where((camera) {
      if (_selectedStatus != null && camera.status != _selectedStatus) {
        return false;
      }
      if (_selectedCategory != null && camera.category != _selectedCategory) {
        return false;
      }
      if (_selectedVehicleId != null && camera.vehicleId != _selectedVehicleId) {
        return false;
      }
      return true;
    }).toList();
  }
}

class CameraInfo {
  final String id;
  final String name;
  final String status;
  final String category;
  final String vehicleId;
  final String vehicleName;
  final DateTime lastUpdate;
  final String snapshotUrl;
  final String streamUrl;

  CameraInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
    required this.vehicleId,
    required this.vehicleName,
    required this.lastUpdate,
    required this.snapshotUrl,
    required this.streamUrl,
  });
}

