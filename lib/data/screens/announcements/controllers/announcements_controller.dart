import 'package:flutter/foundation.dart';

class AnnouncementsController extends ChangeNotifier {
  List<Announcement> _announcements = [];
  List<Announcement> _filteredAnnouncements = [];
  String? _selectedCategory;
  String? _selectedVehicleId;
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => _filteredAnnouncements;
  String? get selectedCategory => _selectedCategory;
  String? get selectedVehicleId => _selectedVehicleId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    final cats = _announcements.map((a) => a.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  AnnouncementsController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implementar chamada à API para buscar avisos
      // Em produção, isso viria da API:
      // final response = await gpsapis.getAnnouncements(...);
      // if (response != null) {
      //   _announcements = response.map((a) => Announcement.fromJson(a)).toList();
      // }
      _announcements = [];
      
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
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

  void markAsRead(String id) {
    final index = _announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      _announcements[index] = Announcement(
        id: _announcements[index].id,
        title: _announcements[index].title,
        message: _announcements[index].message,
        category: _announcements[index].category,
        date: _announcements[index].date,
        isRead: true,
      );
      _applyFilter();
      notifyListeners();
    }
  }

  void _applyFilter() {
    _filteredAnnouncements = _announcements.where((announcement) {
      if (_selectedCategory != null && announcement.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
    
    // Ordenar por data (mais recentes primeiro)
    _filteredAnnouncements.sort((a, b) => b.date.compareTo(a.date));
  }
}

class Announcement {
  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime date;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.date,
    required this.isRead,
  });
}

