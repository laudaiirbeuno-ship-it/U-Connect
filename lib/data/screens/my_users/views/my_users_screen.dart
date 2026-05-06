import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/user_permissions.dart';
import 'package:uconnect/data/services/clients_service.dart';
import 'package:uconnect/data/model/client.dart';
import 'package:uconnect/data/model/User.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uconnect/utils/responsive_helper.dart';

class MyUsersScreen extends StatefulWidget {
  const MyUsersScreen({Key? key}) : super(key: key);

  @override
  _MyUsersScreenState createState() => _MyUsersScreenState();
}

class _MyUsersScreenState extends State<MyUsersScreen> {
  final ClientsService _clientsService = ClientsService();
  
  ClientsResponse? _clientsResponse;
  bool _loading = true;
  String? _searchPhrase;
  String? _statusFilter;
  int _currentPage = 1;
  int? _currentUserGroupId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadClients();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await UserPermissions.getUserFromAPI();
      if (user != null) {
        setState(() {
          _currentUserGroupId = user.group_id;
        });
      } else {
        // Tentar obter do SharedPreferences diretamente
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        if (userJson != null) {
          final user = User.fromJson(jsonDecode(userJson));
          setState(() {
            _currentUserGroupId = user.group_id;
          });
        }
      }
    } catch (e) {
      // Erro ao carregar informações do usuário - silencioso
      debugPrint('Erro ao carregar informações do usuário: $e');
    }
  }

  Future<void> _loadClients({int page = 1}) async {
    setState(() => _loading = true);
    
    try {
      final response = await _clientsService.getClients(
        searchPhrase: _searchPhrase,
        status: _statusFilter,
        page: page,
        limit: 25,
      );
      
      setState(() {
        _clientsResponse = response;
        _currentPage = page;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao carregar usuários: $e',
                'Error loading users: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    // Verificar permissão ANTES de renderizar
    if (!UserPermissions.canAccessMyUsersSync(_currentUserGroupId)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            TranslationHelper.translateSync(
              context,
              'Meus Usuários',
              'My Users',
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: ResponsiveHelper.iconSize(64), color: Colors.grey),
              ResponsiveHelper.verticalSpace(16),
              Text(
                TranslationHelper.translateSync(
                  context,
                  'Acesso Negado',
                  'Access Denied',
                ),
                style: TextStyle(
                  fontSize: ResponsiveHelper.fontSize(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              ResponsiveHelper.verticalSpace(8),
              Text(
                TranslationHelper.translateSync(
                  context,
                  'Você não tem permissão para acessar esta página.',
                  'You do not have permission to access this page.',
                ),
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorProvider.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          TranslationHelper.translateSync(
            context,
            'Meus Usuários',
            'My Users',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showCreateUserDialog();
            },
            tooltip: TranslationHelper.translateSync(
              context,
              'Adicionar Usuário',
              'Add User',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filtros e Busca
              _buildFilters(),
              
              // Estatísticas
              if (_clientsResponse != null)
                _buildStatistics(_clientsResponse!.statistics),
              
              // Lista de Usuários
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _clientsResponse == null || _clientsResponse!.data.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  TranslationHelper.translateSync(
                                    context,
                                    'Nenhum usuário encontrado',
                                    'No users found',
                                  ),
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.fontSize(18),
                                    color: Colors.grey,
                                  ),
                                ),
                                if (_searchPhrase != null || _statusFilter != null)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchPhrase = null;
                                        _statusFilter = null;
                                      });
                                      _loadClients(page: 1);
                                    },
                                    child: Text(
                                      TranslationHelper.translateSync(
                                        context,
                                        'Limpar filtros',
                                        'Clear filters',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadClients(page: 1),
                            child: ListView.builder(
                              itemCount: _clientsResponse!.data.length,
                              itemBuilder: (context, index) {
                                final client = _clientsResponse!.data[index];
                                return _buildUserCard(client);
                              },
                            ),
                          ),
              ),
              
              // Paginação
              if (_clientsResponse != null && _clientsResponse!.lastPage > 1)
                _buildPagination(),
            ],
          ),
          
          // Botão de Chat Interno no lado esquerdo
          Positioned(
            left: 16,
            bottom: 100,
            child: ChatFloatingButton(alignLeft: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: ResponsiveHelper.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(
                context,
                'Buscar por nome, email ou telefone',
                'Search by name, email or phone',
              ),
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchPhrase != null && _searchPhrase!.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _searchPhrase = null);
                        _loadClients(page: 1);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchPhrase = value.isEmpty ? null : value);
            },
            onSubmitted: (_) => _loadClients(page: 1),
          ),
          
          ResponsiveHelper.verticalSpace(12),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: TranslationHelper.translateSync(
                      context,
                      'Status',
                      'Status',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Todos',
                        'All',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Ativos',
                        'Active',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'unactive',
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Inativos',
                        'Inactive',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'overdue',
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Inadimplentes',
                        'Overdue',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'em_teste',
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Em Teste',
                        'In Test',
                      )),
                    ),
                    DropdownMenuItem(
                      value: 'closed',
                      child: Text(TranslationHelper.translateSync(
                        context,
                        'Fechados',
                        'Closed',
                      )),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                    _loadClients(page: 1);
                  },
                ),
              ),
              ResponsiveHelper.horizontalSpace(12),
              ElevatedButton.icon(
                onPressed: () => _loadClients(page: 1),
                icon: Icon(Icons.filter_list),
                label: Text(TranslationHelper.translateSync(
                  context,
                  'Filtrar',
                  'Filter',
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ClientsStatistics stats) {
    return Container(
      padding: ResponsiveHelper.padding(all: 16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Total', 'Total'),
            stats.total.toString(),
            Colors.blue,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Ativos', 'Active'),
            stats.active.toString(),
            Colors.green,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Inadimplentes', 'Overdue'),
            stats.overdue.toString(),
            Colors.red,
          ),
          _buildStatCard(
            TranslationHelper.translateSync(context, 'Em Dia', 'Paid'),
            stats.paid.toString(),
            Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Client client) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showUserDetails(client);
        },
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getStatusColor(client.status).withOpacity(0.2),
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(client.status),
                  ),
                ),
              ),
              
              SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      client.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (client.phoneNumber != null && client.phoneNumber!.isNotEmpty)
                      Text(
                        client.phoneNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(
                      client.statusLabel,
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(client.status).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getStatusColor(client.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleMenuAction(value, client);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text(TranslationHelper.translateSync(
                              context,
                              'Ver Detalhes',
                              'View Details',
                            )),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text(TranslationHelper.translateSync(
                              context,
                              'Editar',
                              'Edit',
                            )),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: client.active ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              client.active ? Icons.block : Icons.check_circle,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(TranslationHelper.translateSync(
                              context,
                              client.active ? 'Desativar' : 'Ativar',
                              client.active ? 'Deactivate' : 'Activate',
                            )),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              TranslationHelper.translateSync(
                                context,
                                'Excluir',
                                'Delete',
                              ),
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: ResponsiveHelper.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _loadClients(page: _currentPage - 1)
                : null,
          ),
          Text(
            TranslationHelper.translateSync(
              context,
              'Página $_currentPage de ${_clientsResponse!.lastPage}',
              'Page $_currentPage of ${_clientsResponse!.lastPage}',
            ),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentPage < _clientsResponse!.lastPage
                ? () => _loadClients(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'unactive':
        return Colors.grey;
      case 'overdue':
        return Colors.red;
      case 'em_teste':
        return Colors.orange;
      case 'closed':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(String action, Client client) {
    switch (action) {
      case 'view':
        _showUserDetails(client);
        break;
      case 'edit':
        _showEditUserDialog(client);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(client);
        break;
      case 'delete':
        _showDeleteConfirmation(client);
        break;
    }
  }

  void _showUserDetails(Client client) {
    // TODO: Implementar modal de detalhes idêntico ao modal de relatórios
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(
          context,
          'Detalhes do Usuário',
          'User Details',
        )),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Nome', 'Name'),
                client.name,
              ),
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Email', 'Email'),
                client.email,
              ),
              if (client.phoneNumber != null)
                _buildDetailRow(
                  TranslationHelper.translateSync(context, 'Telefone', 'Phone'),
                  client.phoneNumber!,
                ),
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Status', 'Status'),
                client.statusLabel,
              ),
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Ativo', 'Active'),
                client.active
                    ? TranslationHelper.translateSync(context, 'Sim', 'Yes')
                    : TranslationHelper.translateSync(context, 'Não', 'No'),
              ),
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Dispositivos', 'Devices'),
                client.devicesCount.toString(),
              ),
              _buildDetailRow(
                TranslationHelper.translateSync(context, 'Subusuários', 'Subusers'),
                client.subusersCount.toString(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(
              context,
              'Fechar',
              'Close',
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    // TODO: Implementar modal de criação idêntico ao modal de motorista
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(
          context,
          'Adicionar Usuário',
          'Add User',
        )),
        content: Text(TranslationHelper.translateSync(
          context,
          'Formulário de criação será implementado',
          'Creation form will be implemented',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(
              context,
              'Cancelar',
              'Cancel',
            )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(TranslationHelper.translateSync(
              context,
              'Criar',
              'Create',
            )),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Client client) {
    // TODO: Implementar modal de edição idêntico ao modal de motorista
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(
          context,
          'Editar Usuário',
          'Edit User',
        )),
        content: Text(TranslationHelper.translateSync(
          context,
          'Formulário de edição será implementado',
          'Edit form will be implemented',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(
              context,
              'Cancelar',
              'Cancel',
            )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadClients(page: _currentPage);
            },
            child: Text(TranslationHelper.translateSync(
              context,
              'Salvar',
              'Save',
            )),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(Client client) async {
    try {
      await _clientsService.setClientsActive(
        ids: [client.id],
        active: !client.active,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                client.active
                    ? 'Usuário desativado com sucesso'
                    : 'Usuário ativado com sucesso',
                client.active
                    ? 'User deactivated successfully'
                    : 'User activated successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadClients(page: _currentPage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao alterar status: $e',
                'Error changing status: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(
          context,
          'Confirmar Exclusão',
          'Confirm Deletion',
        )),
        content: Text(
          TranslationHelper.translateSync(
            context,
            'Tem certeza que deseja excluir o usuário ${client.name}? Esta ação não pode ser desfeita.',
            'Are you sure you want to delete user ${client.name}? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(
              context,
              'Cancelar',
              'Cancel',
            )),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(client);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              TranslationHelper.translateSync(
                context,
                'Excluir',
                'Delete',
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Client client) async {
    try {
      await _clientsService.deleteClient(client.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Usuário excluído com sucesso',
              'User deleted successfully',
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadClients(page: _currentPage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao excluir usuário: $e',
              'Error deleting user: $e',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
