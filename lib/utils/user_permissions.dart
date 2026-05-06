import 'package:uconnect/data/model/User.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Utility class para verificar permissões de usuário
class UserPermissions {
  // IDs de grupos (ajustar conforme necessário)
  // Normalmente: 1 = Admin, 2 = Gerente, outros = Usuário comum
  static const int ADMIN_GROUP_ID = 1;
  static const int MANAGER_GROUP_ID = 2;
  
  /// Verifica se o usuário é admin
  static Future<bool> isAdmin() async {
    try {
      var user = await _getCurrentUser();
      
      // Se não encontrou no SharedPreferences, buscar da API
      if (user == null) {
        user = await getUserFromAPI();
      }
      
      if (user == null) return false;
      
      // Debug: imprimir dados do usuário
      print('=== VERIFICAÇÃO DE ADMIN ===');
      print('Group ID: ${user.group_id}');
      print('Plan: ${user.plan}');
      print('Email: ${user.email}');
      
      // Admin se group_id == 1 ou plan contém "admin" (case insensitive)
      final isAdminUser = user.group_id == ADMIN_GROUP_ID || 
             (user.plan?.toString().toLowerCase().contains('admin') ?? false);
      
      print('É Admin: $isAdminUser');
      print('===========================');
      
      return isAdminUser;
    } catch (e) {
      print('Erro ao verificar se é admin: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário é gerente
  static Future<bool> isManager() async {
    try {
      var user = await _getCurrentUser();
      
      // Se não encontrou no SharedPreferences, buscar da API
      if (user == null) {
        user = await getUserFromAPI();
      }
      
      if (user == null) return false;
      
      // Debug: imprimir dados do usuário
      print('=== VERIFICAÇÃO DE GERENTE ===');
      print('Group ID: ${user.group_id}');
      print('Group ID Type: ${user.group_id.runtimeType}');
      print('Plan: ${user.plan}');
      print('Email: ${user.email}');
      
      // Gerente se group_id == 2 ou plan contém "gerente" ou "manager" (case insensitive)
      final isManagerUser = user.group_id == MANAGER_GROUP_ID || 
             (user.plan?.toString().toLowerCase().contains('gerente') ?? false) ||
             (user.plan?.toString().toLowerCase().contains('manager') ?? false);
      
      print('É Gerente: $isManagerUser');
      print('==============================');
      
      return isManagerUser;
    } catch (e) {
      print('Erro ao verificar se é gerente: $e');
      return false;
    }
  }
  
  /// Verifica se o usuário é admin ou gerente
  static Future<bool> isAdminOrManager() async {
    final isAdminUser = await isAdmin();
    final isManagerUser = await isManager();
    return isAdminUser || isManagerUser;
  }

  /// Verifica se o usuário pode acessar a página "Meus Usuários"
  /// Apenas Admin (group_id = 1) e Manager (group_id = 3) podem acessar
  static Future<bool> canAccessMyUsers() async {
    try {
      var user = await _getCurrentUser();
      
      if (user == null) {
        user = await getUserFromAPI();
      }
      
      if (user == null) return false;
      
      // Admin (1) ou Manager (3) podem acessar
      // Também verificar se group_id == 2 (compatibilidade)
      return user.group_id == ADMIN_GROUP_ID || 
             user.group_id == 3 || 
             user.group_id == MANAGER_GROUP_ID;
    } catch (e) {
      print('Erro ao verificar acesso a Meus Usuários: $e');
      return false;
    }
  }

  /// Verifica se o usuário pode acessar a página "Meus Usuários" (versão síncrona com group_id)
  static bool canAccessMyUsersSync(int? groupId) {
    if (groupId == null) return false;
    // Admin (1) ou Manager (3) podem acessar
    // Também verificar se group_id == 2 (compatibilidade)
    return groupId == ADMIN_GROUP_ID || groupId == 3 || groupId == MANAGER_GROUP_ID;
  }
  
  /// Obtém o usuário atual do SharedPreferences
  static Future<User?> _getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tentar primeiro com 'user_data' (dados completos do User)
      var userJson = prefs.getString('user_data');
      
      // Se não encontrar, tentar com 'user' (response do login)
      if (userJson == null) {
        userJson = prefs.getString('user');
        if (userJson != null) {
          try {
            final parsed = json.decode(userJson);
            // Verificar se tem estrutura do LoginModel e tentar buscar User via API
            if (parsed['user_api_hash'] != null) {
              // Se for LoginModel, tentar buscar User completo
              return null; // Retornar null para forçar busca via API
            }
            return User.fromJson(parsed);
          } catch (e) {
            print('Erro ao parsear user: $e');
          }
        }
      }
      
      if (userJson != null) {
        final parsed = json.decode(userJson);
        return User.fromJson(parsed);
      }
      return null;
    } catch (e) {
      print('Erro ao obter usuário atual: $e');
      return null;
    }
  }
  
  /// Busca dados do usuário diretamente da API se não estiverem no SharedPreferences
  static Future<User?> getUserFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userApiHash = prefs.getString('user_api_hash') ?? StaticVarMethod.user_api_hash;
      
      if (userApiHash != null) {
        final user = await gpsapis.getUserData();
        if (user != null) {
          // Salvar no SharedPreferences
          final userJson = json.encode(user.toJson());
          await prefs.setString('user_data', userJson);
          return user;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar usuário da API: $e');
      return null;
    }
  }
}

