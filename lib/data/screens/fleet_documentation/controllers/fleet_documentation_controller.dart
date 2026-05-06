import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/devices.dart';

/// Controller para documentação da frota
class FleetDocumentationController extends ChangeNotifier {
  List<deviceItems> _vehicles = [];
  List<VehicleDocument> _documents = [];
  bool _isLoading = false;
  String? _error;
  
  // Filtros
  String? _selectedVehicleId;
  String? _selectedDocumentType;
  
  // Getters
  List<deviceItems> get vehicles => _vehicles;
  List<VehicleDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedVehicleId => _selectedVehicleId;
  String? get selectedDocumentType => _selectedDocumentType;
  
  // Estatísticas
  Map<String, int> _documentCountByType = {};
  Map<String, int> _expiringDocuments = {}; // Documentos próximos do vencimento
  
  Map<String, int> get documentCountByType => _documentCountByType;
  Map<String, int> get expiringDocuments => _expiringDocuments;
  
  FleetDocumentationController() {
    loadData();
  }
  
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _loadVehicles();
      await _loadDocuments();
      _calculateStatistics();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadVehicles() async {
    try {
      final devices = await gpsapis.getDevicesList(StaticVarMethod.user_api_hash);
      if (devices != null) {
        _vehicles = devices;
      }
    } catch (e) {
      print('Erro ao carregar veículos: $e');
    }
  }
  
  Future<void> _loadDocuments() async {
    // Carregar documentos da API
    // TODO: Implementar chamada à API quando disponível
    _documents = [];
    
    // Em produção, isso viria da API:
    // final response = await gpsapis.getVehicleDocuments(...);
    // if (response != null) {
    //   _documents = response.map((d) => VehicleDocument.fromJson(d)).toList();
    // }
    
    // Aplicar filtros
    if (_selectedVehicleId != null) {
      _documents = _documents
          .where((d) => d.vehicleId?.toString() == _selectedVehicleId)
          .toList();
    }
    
    if (_selectedDocumentType != null) {
      _documents = _documents
          .where((d) => d.documentType == _selectedDocumentType)
          .toList();
    }
    
    // Ordenar por data de vencimento
    _documents.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }
  
  void _calculateStatistics() {
    _documentCountByType.clear();
    _expiringDocuments.clear();
    
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(Duration(days: 30));
    
    for (var doc in _documents) {
      // Contar por tipo
      _documentCountByType[doc.documentType] = 
          (_documentCountByType[doc.documentType] ?? 0) + 1;
      
      // Contar documentos próximos do vencimento
      if (doc.expiryDate.isBefore(thirtyDaysFromNow) && doc.expiryDate.isAfter(now)) {
        _expiringDocuments[doc.documentType] = 
            (_expiringDocuments[doc.documentType] ?? 0) + 1;
      }
    }
  }
  
  void setSelectedVehicle(String? vehicleId) {
    _selectedVehicleId = vehicleId;
    _loadDocuments();
    _calculateStatistics();
    notifyListeners();
  }
  
  void setSelectedDocumentType(String? documentType) {
    _selectedDocumentType = documentType;
    _loadDocuments();
    notifyListeners();
  }
  
  Future<void> addDocument(VehicleDocument document) async {
    _documents.insert(0, document);
    _calculateStatistics();
    notifyListeners();
  }
  
  Future<void> deleteDocument(String documentId) async {
    _documents.removeWhere((d) => d.id == documentId);
    _calculateStatistics();
    notifyListeners();
  }
  
  List<VehicleDocument> getExpiringDocuments({int days = 30}) {
    final cutoffDate = DateTime.now().add(Duration(days: days));
    return _documents
        .where((d) => d.expiryDate.isBefore(cutoffDate) && d.expiryDate.isAfter(DateTime.now()))
        .toList();
  }
}

class VehicleDocument {
  final String id;
  final int? vehicleId;
  final String vehicleName;
  final String documentType; // CRLV, Seguro, IPVA, Licenciamento, Vistoria, etc.
  final String documentNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String issuingAgency;
  final String? notes;
  final String? filePath; // Caminho do arquivo anexado (se houver)
  
  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.documentType,
    required this.documentNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.issuingAgency,
    this.notes,
    this.filePath,
  });
  
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon {
    final thirtyDaysFromNow = DateTime.now().add(Duration(days: 30));
    return expiryDate.isBefore(thirtyDaysFromNow) && !isExpired;
  }
  
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}
