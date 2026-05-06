import 'package:flutter/material.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';

class TasksController with ChangeNotifier {
  List<Map<String, dynamic>> _tasks = [];
  List<deviceItems> _devices = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedDeviceId;

  // Formulário
  String _title = '';
  String _comment = '';
  String _pickupAddress = '';
  double? _pickupLat;
  double? _pickupLng;

  List<Map<String, dynamic>> get tasks => _tasks;
  List<deviceItems> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedDeviceId => _selectedDeviceId;

  String get title => _title;
  String get comment => _comment;
  String get pickupAddress => _pickupAddress;

  TasksController() {
    loadDevices();
    // loadTasks(); // API de listagem não está disponível, vamos simular
  }

  Future<void> loadDevices() async {
    try {
      final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      if (devices != null) {
        _devices = devices;
        if (_devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = _devices.first.id?.toString();
          if (_selectedDeviceId != null && _selectedDeviceId!.isNotEmpty) {
            StaticVarMethod.deviceId = _selectedDeviceId!;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar dispositivos: $e');
    }
  }

  void setSelectedDevice(String? deviceId) {
    _selectedDeviceId = deviceId;
    if (deviceId != null && deviceId.isNotEmpty) {
      StaticVarMethod.deviceId = deviceId;
    }
    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setComment(String value) {
    _comment = value;
    notifyListeners();
  }

  void setPickupAddress(String value) {
    _pickupAddress = value;
    notifyListeners();
  }

  void setPickupLocation(double lat, double lng) {
    _pickupLat = lat;
    _pickupLng = lng;
    notifyListeners();
  }

  Future<bool> createTask() async {
    if (_title.isEmpty) {
      _error = 'Título da tarefa é obrigatório';
      notifyListeners();
      return false;
    }

    if (_selectedDeviceId == null) {
      _error = 'Selecione um veículo';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await gpsapis.AddTask(
        _title,
        _comment,
        _pickupAddress,
        _pickupLat?.toString() ?? '',
        _pickupLng?.toString() ?? '',
      );

      if (response.statusCode == 200) {
        // Adicionar à lista local (já que não há API de listagem)
        _tasks.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': _title,
          'comment': _comment,
          'pickup_address': _pickupAddress,
          'device_id': _selectedDeviceId,
          'status': 1, // Pendente
          'created_at': DateTime.now().toIso8601String(),
        });

        _resetForm();
        return true;
      } else {
        _error = 'Erro ao criar tarefa: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    _title = '';
    _comment = '';
    _pickupAddress = '';
    _pickupLat = null;
    _pickupLng = null;
    notifyListeners();
  }

  void deleteTask(int index) {
    if (index >= 0 && index < _tasks.length) {
      _tasks.removeAt(index);
      notifyListeners();
    }
  }

  void updateTaskStatus(int index, int status) {
    if (index >= 0 && index < _tasks.length) {
      _tasks[index]['status'] = status;
      notifyListeners();
    }
  }
}

