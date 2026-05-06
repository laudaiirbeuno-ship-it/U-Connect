import 'package:flutter/foundation.dart';

class PartnersController extends ChangeNotifier {
  List<Partner> _partners = [];
  List<Partner> _filteredPartners = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  List<Partner> get partners => _filteredPartners;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    final cats = _partners.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  PartnersController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implementar chamada à API para buscar parceiros
      // Em produção, isso viria da API:
      // final response = await gpsapis.getPartners(...);
      // if (response != null) {
      //   _partners = response.map((p) => Partner.fromJson(p)).toList();
      // }
      _partners = [];
      
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

  void _applyFilter() {
    _filteredPartners = _partners.where((partner) {
      if (_selectedCategory != null && partner.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }
}

class Partner {
  final String id;
  final String name;
  final String description;
  final String category;
  final String logoUrl;
  final List<String> images;
  final String website;
  final String phone;
  final String address;
  final String whatsapp;

  Partner({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.logoUrl,
    required this.images,
    required this.website,
    required this.phone,
    required this.address,
    required this.whatsapp,
  });
}





































