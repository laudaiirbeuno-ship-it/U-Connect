import 'package:flutter/material.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/user_api.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdministrationController with ChangeNotifier {
  List<UserItem> _users = [];
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<UserItem> get users => _users;
  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdministrationController() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadUsers();
      await _loadVehicles();
    } catch (e) {
      _error = 'Erro ao carregar dados: $e';
      print('❌ AdministrationController.loadData: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({
    String? search,
    bool? active,
    int? groupId,
    int? page,
    int? perPage,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.getUsers(
        search: search,
        active: active,
        groupId: groupId,
        page: page,
        perPage: perPage,
      );

      if (response != null && response.status == 1) {
        _users = response.items.data;
      } else {
        _error = 'Erro ao carregar usuários';
        _users = [];
      }
    } catch (e) {
      _error = 'Erro ao carregar usuários: $e';
      print('❌ AdministrationController.loadUsers: $e');
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadVehicles() async {
    // TODO: Implementar chamada à API para buscar veículos
    // Em produção, isso viria da API:
    // final response = await gpsapis.getVehicles(...);
    // if (response != null) {
    //   _vehicles = response;
    // }
    _vehicles = [];
  }

  Future<bool> createUser(CreateUserRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.createUser(request);

      if (response != null && response.status == 1) {
        // Recarregar lista de usuários
        await loadUsers();
        Fluttertoast.showToast(
          msg: response.message ?? 'Usuário criado com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
        );
        return true;
      } else {
        _error = 'Erro ao criar usuário';
        Fluttertoast.showToast(
          msg: _error ?? 'Erro ao criar usuário',
          toastLength: Toast.LENGTH_SHORT,
        );
        return false;
      }
    } catch (e) {
      _error = 'Erro ao criar usuário: $e';
      print('❌ AdministrationController.createUser: $e');
      Fluttertoast.showToast(
        msg: _error ?? 'Erro ao criar usuário',
        toastLength: Toast.LENGTH_SHORT,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(int userId, CreateUserRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await gpsapis.updateUser(userId, request);

      if (response != null && response.status == 1) {
        // Recarregar lista de usuários
        await loadUsers();
        Fluttertoast.showToast(
          msg: response.message ?? 'Usuário atualizado com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
        );
        return true;
      } else {
        _error = 'Erro ao atualizar usuário';
        Fluttertoast.showToast(
          msg: _error ?? 'Erro ao atualizar usuário',
          toastLength: Toast.LENGTH_SHORT,
        );
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar usuário: $e';
      print('❌ AdministrationController.updateUser: $e');
      Fluttertoast.showToast(
        msg: _error ?? 'Erro ao atualizar usuário',
        toastLength: Toast.LENGTH_SHORT,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await gpsapis.deleteUser(userId);

      if (success) {
        // Recarregar lista de usuários
        await loadUsers();
        Fluttertoast.showToast(
          msg: 'Usuário excluído com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
        );
        return true;
      } else {
        _error = 'Erro ao excluir usuário';
        Fluttertoast.showToast(
          msg: _error ?? 'Erro ao excluir usuário',
          toastLength: Toast.LENGTH_SHORT,
        );
        return false;
      }
    } catch (e) {
      _error = 'Erro ao excluir usuário: $e';
      print('❌ AdministrationController.deleteUser: $e');
      Fluttertoast.showToast(
        msg: _error ?? 'Erro ao excluir usuário',
        toastLength: Toast.LENGTH_SHORT,
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createVehicle(String name, String imei) async {
    // TODO: Implementar chamada à API para criar veículo
    _vehicles.add({'id': _vehicles.length + 1, 'name': name, 'imei': imei});
    notifyListeners();
  }
}
