import 'package:flutter/foundation.dart';

class EmergencyContactsController extends ChangeNotifier {
  List<EmergencyContact> _contacts = [];
  List<EmergencyContact> _filteredContacts = [];
  String? _selectedCategory;
  String? _selectedState;
  bool _isLoading = false;
  String? _error;

  List<EmergencyContact> get contacts => _filteredContacts;
  String? get selectedCategory => _selectedCategory;
  String? get selectedState => _selectedState;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    final cats = _contacts.map((c) => c.category).toSet().toList();
    cats.sort();
    return ['Todas', ...cats];
  }

  List<String> get states {
    final states = _contacts.map((c) => c.state).toSet().toList();
    states.sort();
    return ['Todos', ...states];
  }

  EmergencyContactsController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gerar contatos de emergência de todo o Brasil
      await Future.delayed(Duration(seconds: 1));
      
      _contacts = _generateEmergencyContacts();
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

  void setState(String? state) {
    _selectedState = state == 'Todos' ? null : state;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredContacts = _contacts.where((contact) {
      if (_selectedCategory != null && contact.category != _selectedCategory) {
        return false;
      }
      if (_selectedState != null && contact.state != _selectedState) {
        return false;
      }
      return true;
    }).toList();
    
    // Ordenar por estado e categoria
    _filteredContacts.sort((a, b) {
      final stateCompare = a.state.compareTo(b.state);
      if (stateCompare != 0) return stateCompare;
      return a.category.compareTo(b.category);
    });
  }

  List<EmergencyContact> _generateEmergencyContacts() {
    final contacts = <EmergencyContact>[];
    
    // Estados brasileiros
    final states = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
      'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
      'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
    ];
    
    final stateNames = {
      'AC': 'Acre', 'AL': 'Alagoas', 'AP': 'Amapá', 'AM': 'Amazonas',
      'BA': 'Bahia', 'CE': 'Ceará', 'DF': 'Distrito Federal', 'ES': 'Espírito Santo',
      'GO': 'Goiás', 'MA': 'Maranhão', 'MT': 'Mato Grosso', 'MS': 'Mato Grosso do Sul',
      'MG': 'Minas Gerais', 'PA': 'Pará', 'PB': 'Paraíba', 'PR': 'Paraná',
      'PE': 'Pernambuco', 'PI': 'Piauí', 'RJ': 'Rio de Janeiro', 'RN': 'Rio Grande do Norte',
      'RS': 'Rio Grande do Sul', 'RO': 'Rondônia', 'RR': 'Roraima', 'SC': 'Santa Catarina',
      'SP': 'São Paulo', 'SE': 'Sergipe', 'TO': 'Tocantins',
    };
    
    // Categorias
    final categories = [
      'Bombeiros',
      'Polícia Militar',
      'Polícia Civil',
      'Polícia Rodoviária Federal',
      'Polícia Federal',
      'SAMU',
    ];
    
    // Números nacionais (mesmos para todos os estados)
    final nationalNumbers = {
      'Bombeiros': '193',
      'Polícia Militar': '190',
      'Polícia Civil': '197',
      'Polícia Rodoviária Federal': '191',
      'Polícia Federal': '194',
      'SAMU': '192',
    };
    
    int id = 1;
    
    // Gerar contatos para cada estado e categoria
    for (var state in states) {
      for (var category in categories) {
        contacts.add(EmergencyContact(
          id: id.toString(),
          name: '$category - ${stateNames[state]}',
          phone: nationalNumbers[category] ?? '190',
          category: category,
          state: state,
          description: 'Emergência $category no estado de ${stateNames[state]}',
        ));
        id++;
      }
    }
    
    return contacts;
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String category;
  final String state;
  final String description;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    required this.state,
    required this.description,
  });
}





































