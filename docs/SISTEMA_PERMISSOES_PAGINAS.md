# Documentação - Sistema de Permissões de Páginas

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Lista Completa de Páginas](#lista-completa-de-páginas)
3. [Estrutura de Dados](#estrutura-de-dados)
4. [Endpoints da API](#endpoints-da-api)
5. [Implementação no Cliente](#implementação-no-cliente)
6. [Interface de Administração](#interface-de-administração)
7. [Exemplos de Uso](#exemplos-de-uso)

---

## 🎯 Visão Geral

O sistema de permissões de páginas permite controlar quais funcionalidades do aplicativo cada usuário/cliente pode acessar. As permissões são gerenciadas no servidor através de uma interface administrativa e sincronizadas com o app durante o login.

### Funcionalidades
- ✅ Controle granular por página
- ✅ Gerenciamento via interface administrativa
- ✅ Sincronização automática no login
- ✅ Cache local para funcionamento offline
- ✅ Suporte a múltiplos clientes/usuários

### Fluxo de Funcionamento

1. **Administrador** configura permissões no servidor (interface web)
2. **Usuário** faz login no app
3. **App** busca permissões do servidor
4. **App** exibe apenas páginas permitidas
5. **App** oculta páginas não permitidas do menu e bottom navigation

---

## 📱 Lista Completa de Páginas

### Bottom Navigation (Navegação Inferior)

| ID | Nome | Ícone | Descrição | Localização |
|---|---|---|---|---|
| `bottom_nav_vehicles` | Veículos | `directions_car` | Lista de veículos | `listscreen()` |
| `bottom_nav_map` | Monitoramento | `map` | Mapa principal | `MainMapScreen()` |
| `bottom_nav_dashboard` | Dashboard | `dashboard_outlined` | Dashboard da frota | `FleetOverviewScreen()` |
| `bottom_nav_camera` | Câmera | `videocam` | Video Telemetria | `VideoTelemetryScreen()` |
| `bottom_nav_menu` | Menu | `menu` | Menu hambúrguer | `FloatingMenuDrawer()` |

### Menu Hambúrguer - Navegação Principal

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `nav_monitoring` | Monitoramento | `map` | Navegação | `BottomNavigation_01(initialIndex: 1)` |
| `nav_vehicle_list` | Lista de Veículos | `list_alt` | Navegação | `BottomNavigation_01(initialIndex: 0)` |
| `nav_fleet_dashboard` | Dashboard da Frota | `dashboard` | Navegação | `BottomNavigation_01(initialIndex: 2)` |

### Menu Hambúrguer - Administração (Admin/Manager)

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `admin_my_users` | Meus Usuários | `people` | Administração | `MyUsersScreen()` |
| `admin_charges_to_pay` | Cobranças para Pagar | `payment` | Administração | `AdminChargesScreen()` |

### Menu Hambúrguer - Serviços (Admin)

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `service_tow` | Chamar Reboque | `local_taxi` | Serviços | `TowServiceScreen()` |

### Menu Hambúrguer - Gestão de Frotas

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `fleet_drivers` | Meus Motoristas | `people_outline` | Gestão de Frotas | `DriversScreen()` |
| `fleet_maintenance` | Manutenção | `task` | Gestão de Frotas | `TasksScreen()` |
| `fleet_km_traveled` | Km Percorrida | `speed` | Gestão de Frotas | `KmTraveledScreen()` |
| `fleet_fuel_consumption` | Consumo de Combustível | `local_gas_station` | Gestão de Frotas | `FuelConsumptionScreen()` |
| `fleet_video_telemetry` | Video Telemetria | `videocam` | Gestão de Frotas | `VideoTelemetryScreen()` |
| `fleet_route_history` | Histórico de Rotas | `route` | Gestão de Frotas | `RouteHistoryScreen()` |
| `fleet_fuel_control` | Controle de Abastecimento | `local_gas_station` | Gestão de Frotas | `FuelControlScreen()` |
| `fleet_checklist` | Checklist da Frota | `checklist` | Gestão de Frotas | `FleetChecklistScreen()` |
| `fleet_reports` | Relatórios | `insert_chart` | Gestão de Frotas | `ReportsScreen()` |
| `fleet_sensors` | Sensores da Frota | `sensors` | Gestão de Frotas | `FleetSensorsScreen()` |
| `fleet_fuel_pump` | Controle de Bomba de Combustível | `local_gas_station` | Gestão de Frotas | `FuelPumpScreen()` |
| `fleet_documentation` | Documentação da Frota | `description` | Gestão de Frotas | `FleetDocumentationScreen()` |
| `fleet_advanced_telemetry` | Telemetria Avançada | `sensors` | Gestão de Frotas | `AdvancedTelemetryScreen()` |

### Menu Hambúrguer - Eventos

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `events_notifications` | Central de Notificações | `notifications` | Eventos | `NotificationsPage()` |
| `events_alerts` | Alertas | `warning_amber_outlined` | Eventos | `AlertListPage()` |

### Menu Hambúrguer - Financeiro

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `financial_my_charges` | Minhas Cobranças | `payment` | Financeiro | `ChargesScreen()` |
| `financial_dashboard` | Dashboard Financeiro | `dashboard` | Financeiro | `FinancialDashboardScreen()` |
| `financial_transactions` | Transações | `swap_horiz` | Financeiro | `TransactionsScreen()` |
| `financial_contracts` | Meus Contratos | `description` | Financeiro | `ContractsScreen()` |
| `financial_receipts` | Comprovantes | `receipt` | Financeiro | `ReceiptsScreen()` |

### Menu Hambúrguer - Contatos

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `contacts_emergency` | Contatos de Emergência | `emergency` | Contatos | `EmergencyContactsScreen()` |

### Menu Hambúrguer - Suporte

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `support_main` | Suporte | `support_agent` | Suporte | `SupportScreen()` |

### Menu Hambúrguer - Configurações

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `settings_main` | Configuração | `settings` | Configurações | `settingscreen()` |
| `settings_personalization` | Configuração da Personalização | `palette` | Configurações | `AppSettingsScreen()` |

### Menu Hambúrguer - Legais

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `legal_privacy` | Políticas e Privacidade | `privacy_tip_outlined` | Legais | `privacypolicy()` |
| `legal_terms` | Termos de Uso | `description_outlined` | Legais | `termsandconditions()` |

### Menu Hambúrguer - Logout

| ID | Nome | Ícone | Categoria | Localização |
|---|---|---|---|---|
| `logout` | Sair | `logout_outlined` | Logout | Função `_logout()` |

---

## 📊 Estrutura de Dados

### Modelo de Permissão de Página

```dart
class PagePermission {
  final String pageId;           // ID único da página
  final String pageName;         // Nome da página
  final String category;         // Categoria (ex: "Gestão de Frotas")
  final String icon;              // Nome do ícone (Material Icons)
  final bool isEnabled;           // Se a página está habilitada para o usuário
  final String? description;      // Descrição opcional
  final int? order;                // Ordem de exibição (opcional)
  final String? requiredRole;     // Role necessário (opcional: "admin", "manager")
}
```

### JSON Schema

```json
{
  "pageId": "string (único)",
  "pageName": "string",
  "category": "string",
  "icon": "string",
  "isEnabled": "boolean",
  "description": "string (opcional)",
  "order": "integer (opcional)",
  "requiredRole": "string (opcional: 'admin', 'manager', null)"
}
```

### Resposta de Permissões do Usuário

```json
{
  "status": 1,
  "message": "Permissões carregadas",
  "data": {
    "userId": 123,
    "clientId": 456,
    "permissions": [
      {
        "pageId": "bottom_nav_vehicles",
        "pageName": "Veículos",
        "category": "Navegação",
        "icon": "directions_car",
        "isEnabled": true,
        "description": "Lista de veículos da frota",
        "order": 0,
        "requiredRole": null
      },
      {
        "pageId": "fleet_fuel_control",
        "pageName": "Controle de Abastecimento",
        "category": "Gestão de Frotas",
        "icon": "local_gas_station",
        "isEnabled": true,
        "description": "Gerenciar abastecimentos",
        "order": 7,
        "requiredRole": null
      },
      {
        "pageId": "admin_my_users",
        "pageName": "Meus Usuários",
        "category": "Administração",
        "icon": "people",
        "isEnabled": false,
        "description": "Gerenciar usuários",
        "order": 1,
        "requiredRole": "admin"
      }
    ],
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

### Lista Completa de Páginas (Para Interface Admin)

```json
{
  "status": 1,
  "message": "Lista de páginas disponíveis",
  "data": {
    "pages": [
      {
        "pageId": "bottom_nav_vehicles",
        "pageName": "Veículos",
        "category": "Bottom Navigation",
        "icon": "directions_car",
        "description": "Lista de veículos da frota",
        "defaultEnabled": true,
        "order": 0
      },
      {
        "pageId": "bottom_nav_map",
        "pageName": "Monitoramento",
        "category": "Bottom Navigation",
        "icon": "map",
        "description": "Mapa principal de monitoramento",
        "defaultEnabled": true,
        "order": 1
      }
      // ... todas as outras páginas
    ]
  }
}
```

---

## 🔌 Endpoints da API

### Base URL
```
${UserRepository.getServerURL()}/api
```

### Autenticação
Todos os endpoints requerem autenticação via `user_api_hash`:
- Header: `Authorization: Bearer {user_api_hash}`
- Ou Query Parameter: `?user_api_hash={user_api_hash}`

---

### 1. Obter Permissões do Usuário

**GET** `/api/user/permissions`

Retorna todas as permissões de páginas do usuário logado.

#### Headers
```
Authorization: Bearer {user_api_hash}
Accept: application/json
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Permissões carregadas",
  "data": {
    "userId": 123,
    "clientId": 456,
    "permissions": [
      {
        "pageId": "bottom_nav_vehicles",
        "pageName": "Veículos",
        "category": "Bottom Navigation",
        "icon": "directions_car",
        "isEnabled": true,
        "description": "Lista de veículos da frota",
        "order": 0,
        "requiredRole": null
      }
      // ... outras permissões
    ],
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

#### Resposta de Erro (401/500)
```json
{
  "status": 0,
  "message": "Token inválido",
  "data": null
}
```

---

### 2. Listar Todas as Páginas Disponíveis (Admin)

**GET** `/api/admin/pages`

Retorna lista completa de todas as páginas do sistema (para interface administrativa).

#### Headers
```
Authorization: Bearer {user_api_hash}
Accept: application/json
```

#### Query Parameters
```
?category={category}    (opcional, filtrar por categoria)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Lista de páginas",
  "data": {
    "pages": [
      {
        "pageId": "bottom_nav_vehicles",
        "pageName": "Veículos",
        "category": "Bottom Navigation",
        "icon": "directions_car",
        "description": "Lista de veículos da frota",
        "defaultEnabled": true,
        "order": 0,
        "requiredRole": null
      }
      // ... todas as páginas
    ],
    "categories": [
      "Bottom Navigation",
      "Navegação",
      "Administração",
      "Serviços",
      "Gestão de Frotas",
      "Eventos",
      "Financeiro",
      "Contatos",
      "Suporte",
      "Configurações",
      "Legais",
      "Logout"
    ]
  }
}
```

---

### 3. Obter Permissões de um Cliente/Usuário (Admin)

**GET** `/api/admin/clients/{clientId}/permissions`

Retorna permissões configuradas para um cliente específico.

#### Headers
```
Authorization: Bearer {user_api_hash}
Accept: application/json
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Permissões do cliente",
  "data": {
    "clientId": 456,
    "clientName": "Empresa ABC",
    "permissions": [
      {
        "pageId": "bottom_nav_vehicles",
        "pageName": "Veículos",
        "isEnabled": true,
        "lastModified": "2024-01-15T10:30:00Z",
        "modifiedBy": 1
      }
      // ... outras permissões
    ],
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

---

### 4. Atualizar Permissões de um Cliente/Usuário (Admin)

**PUT** `/api/admin/clients/{clientId}/permissions`

Atualiza as permissões de páginas de um cliente.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "permissions": [
    {
      "pageId": "bottom_nav_vehicles",
      "isEnabled": true
    },
    {
      "pageId": "fleet_fuel_control",
      "isEnabled": true
    },
    {
      "pageId": "admin_my_users",
      "isEnabled": false
    }
    // ... outras permissões
  ]
}
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Permissões atualizadas com sucesso",
  "data": {
    "clientId": 456,
    "updatedPermissions": 35,
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

---

### 5. Atualizar Permissão Individual (Admin)

**PATCH** `/api/admin/clients/{clientId}/permissions/{pageId}`

Atualiza uma permissão específica.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "isEnabled": true
}
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Permissão atualizada",
  "data": {
    "pageId": "fleet_fuel_control",
    "isEnabled": true,
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

---

### 6. Aplicar Template de Permissões (Admin)

**POST** `/api/admin/clients/{clientId}/permissions/template`

Aplica um template pré-configurado de permissões.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "templateName": "basic" // ou "premium", "enterprise", "custom"
}
```

#### Templates Disponíveis
- `basic`: Apenas páginas essenciais (Veículos, Mapa, Dashboard)
- `premium`: Páginas básicas + Gestão de Frotas
- `enterprise`: Todas as páginas exceto Administração
- `full`: Todas as páginas

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Template aplicado com sucesso",
  "data": {
    "clientId": 456,
    "templateName": "premium",
    "permissionsApplied": 25,
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

---

## 💻 Implementação no Cliente

### 1. Criar Modelo de Permissão

Crie o arquivo `lib/data/model/page_permission.dart`:

```dart
class PagePermission {
  final String pageId;
  final String pageName;
  final String category;
  final String icon;
  final bool isEnabled;
  final String? description;
  final int? order;
  final String? requiredRole;

  PagePermission({
    required this.pageId,
    required this.pageName,
    required this.category,
    required this.icon,
    required this.isEnabled,
    this.description,
    this.order,
    this.requiredRole,
  });

  factory PagePermission.fromJson(Map<String, dynamic> json) {
    return PagePermission(
      pageId: json['pageId'] ?? '',
      pageName: json['pageName'] ?? '',
      category: json['category'] ?? '',
      icon: json['icon'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      description: json['description'],
      order: json['order'],
      requiredRole: json['requiredRole'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageId': pageId,
      'pageName': pageName,
      'category': category,
      'icon': icon,
      'isEnabled': isEnabled,
      'description': description,
      'order': order,
      'requiredRole': requiredRole,
    };
  }
}

class UserPermissions {
  final int userId;
  final int clientId;
  final List<PagePermission> permissions;
  final DateTime lastUpdated;

  UserPermissions({
    required this.userId,
    required this.clientId,
    required this.permissions,
    required this.lastUpdated,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      userId: json['userId'] ?? 0,
      clientId: json['clientId'] ?? 0,
      permissions: (json['permissions'] as List?)
          ?.map((p) => PagePermission.fromJson(p))
          .toList() ?? [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  bool hasPermission(String pageId) {
    final permission = permissions.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => PagePermission(
        pageId: pageId,
        pageName: '',
        category: '',
        icon: '',
        isEnabled: false,
      ),
    );
    return permission.isEnabled;
  }

  List<PagePermission> getEnabledPermissions() {
    return permissions.where((p) => p.isEnabled).toList();
  }

  List<PagePermission> getPermissionsByCategory(String category) {
    return permissions
        .where((p) => p.category == category && p.isEnabled)
        .toList();
  }
}
```

### 2. Adicionar Métodos na Classe `gpsapis`

Adicione em `lib/data/datasources.dart`:

```dart
// Obter permissões do usuário
static Future<UserPermissions?> getUserPermissions() async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getUserPermissions");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/user/permissions');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        return UserPermissions.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar permissões: $e");
    return null;
  }
}

// Cache local de permissões
static Future<void> savePermissionsToCache(UserPermissions permissions) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_permissions', jsonEncode(permissions.toJson()));
  } catch (e) {
    print("Erro ao salvar permissões no cache: $e");
  }
}

static Future<UserPermissions?> getPermissionsFromCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final permissionsJson = prefs.getString('user_permissions');
    if (permissionsJson != null) {
      final jsonData = json.decode(permissionsJson);
      return UserPermissions.fromJson(jsonData);
    }
  } catch (e) {
    print("Erro ao carregar permissões do cache: $e");
  }
  return null;
}
```

### 3. Criar Serviço de Permissões

Crie o arquivo `lib/services/permissions_service.dart`:

```dart
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/page_permission.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionsService {
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  UserPermissions? _permissions;
  bool _isLoading = false;

  UserPermissions? get permissions => _permissions;
  bool get isLoading => _isLoading;

  // Carregar permissões (com cache)
  Future<UserPermissions?> loadPermissions({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return _permissions;
    
    _isLoading = true;

    try {
      // Tentar carregar do cache primeiro (se não for refresh forçado)
      if (!forceRefresh) {
        final cachedPermissions = await gpsapis.getPermissionsFromCache();
        if (cachedPermissions != null) {
          _permissions = cachedPermissions;
          _isLoading = false;
          
          // Atualizar em background
          _refreshPermissionsInBackground();
          return _permissions;
        }
      }

      // Buscar da API
      final permissions = await gpsapis.getUserPermissions();
      if (permissions != null) {
        _permissions = permissions;
        await gpsapis.savePermissionsToCache(permissions);
      }
      
      return _permissions;
    } catch (e) {
      print("Erro ao carregar permissões: $e");
      
      // Tentar usar cache em caso de erro
      if (_permissions == null) {
        _permissions = await gpsapis.getPermissionsFromCache();
      }
      
      return _permissions;
    } finally {
      _isLoading = false;
    }
  }

  // Atualizar em background
  Future<void> _refreshPermissionsInBackground() async {
    try {
      final permissions = await gpsapis.getUserPermissions();
      if (permissions != null) {
        _permissions = permissions;
        await gpsapis.savePermissionsToCache(permissions);
      }
    } catch (e) {
      print("Erro ao atualizar permissões em background: $e");
    }
  }

  // Verificar se tem permissão
  bool hasPermission(String pageId) {
    if (_permissions == null) return false;
    return _permissions!.hasPermission(pageId);
  }

  // Obter permissões por categoria
  List<PagePermission> getPermissionsByCategory(String category) {
    if (_permissions == null) return [];
    return _permissions!.getPermissionsByCategory(category);
  }

  // Limpar permissões (no logout)
  Future<void> clearPermissions() async {
    _permissions = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_permissions');
  }
}
```

### 4. Atualizar FloatingMenuDrawer

Modifique `lib/ui/reusable/floating_menu_drawer.dart` para verificar permissões:

```dart
// No início do build, verificar permissões
final permissionsService = PermissionsService();

// Exemplo: Verificar antes de exibir item
if (permissionsService.hasPermission('fleet_fuel_control'))
  _buildItem(
    TranslationHelper.translateSync(context, 'Controle de Abastecimento', 'Fuel Control'),
    Icons.local_gas_station,
    () {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => FuelControlScreen()));
    },
    iconColor: colorProvider.primaryColor,
    backgroundColor: colorProvider.primaryColor.withOpacity(0.1),
  ),
```

### 5. Atualizar ReusableFluidBottomNav

Modifique `lib/ui/reusable/reusable_fluid_bottom_nav.dart`:

```dart
@override
Widget build(BuildContext context) {
  final colorProvider = Provider.of<ColorProvider>(context, listen: true);
  final permissionsService = PermissionsService();

  // Filtrar ícones baseado em permissões
  final availableIcons = <FluidNavBarIcon>[];
  
  if (permissionsService.hasPermission('bottom_nav_vehicles')) {
    availableIcons.add(
      FluidNavBarIcon(
        icon: Icons.directions_car,
        backgroundColor: colorProvider.primaryColor,
        extras: {"label": "Veículos", "index": 0},
      ),
    );
  }
  
  if (permissionsService.hasPermission('bottom_nav_map')) {
    availableIcons.add(
      FluidNavBarIcon(
        icon: Icons.map,
        backgroundColor: colorProvider.primaryColor,
        extras: {"label": "Mapa", "index": 1},
      ),
    );
  }
  
  // ... outros ícones com verificação de permissão

  return Container(
    height: 80,
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    decoration: BoxDecoration(
      color: colorProvider.primaryColor,
    ),
    child: FluidNavBar(
      icons: availableIcons,
      onChange: (index) => _handleNavigationChange(context, index),
      // ... resto do código
    ),
  );
}
```

### 6. Carregar Permissões no Login

No arquivo de login, após autenticação bem-sucedida:

```dart
// Após login bem-sucedido
final permissionsService = PermissionsService();
await permissionsService.loadPermissions(forceRefresh: true);
```

---

## 🖥️ Interface de Administração

### Estrutura da Tela de Permissões

A interface administrativa deve ter:

1. **Lista de Clientes/Usuários**
   - Busca e filtros
   - Lista paginada

2. **Aba de Permissões do Cliente**
   - Lista todas as páginas organizadas por categoria
   - Checkbox para cada página
   - Botão "Aplicar Template"
   - Botão "Salvar Alterações"

3. **Templates Pré-configurados**
   - Basic
   - Premium
   - Enterprise
   - Full

### Exemplo de Interface (HTML/React/Vue)

```html
<div class="permissions-tab">
  <h3>Permissões do App</h3>
  
  <!-- Templates -->
  <div class="templates-section">
    <label>Aplicar Template:</label>
    <select id="templateSelect">
      <option value="basic">Basic</option>
      <option value="premium">Premium</option>
      <option value="enterprise">Enterprise</option>
      <option value="full">Full</option>
    </select>
    <button onclick="applyTemplate()">Aplicar</button>
  </div>

  <!-- Categorias -->
  <div class="categories">
    <div class="category" v-for="category in categories" :key="category">
      <h4>{{ category }}</h4>
      <div class="pages-list">
        <label v-for="page in getPagesByCategory(category)" :key="page.pageId">
          <input 
            type="checkbox" 
            :checked="page.isEnabled"
            @change="togglePermission(page.pageId, $event.target.checked)"
          />
          <span>{{ page.pageName }}</span>
        </label>
      </div>
    </div>
  </div>

  <button onclick="savePermissions()">Salvar Alterações</button>
</div>
```

---

## 📝 Exemplos de Uso

### Exemplo 1: Verificar Permissão Antes de Navegar

```dart
void navigateToFuelControl(BuildContext context) {
  final permissionsService = PermissionsService();
  
  if (permissionsService.hasPermission('fleet_fuel_control')) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FuelControlScreen()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você não tem permissão para acessar esta página'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Exemplo 2: Filtrar Menu Baseado em Permissões

```dart
List<Widget> buildMenuItems(BuildContext context) {
  final permissionsService = PermissionsService();
  final items = <Widget>[];

  if (permissionsService.hasPermission('fleet_drivers')) {
    items.add(_buildItem('Meus Motoristas', Icons.people_outline, () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DriversScreen()));
    }));
  }

  if (permissionsService.hasPermission('fleet_fuel_control')) {
    items.add(_buildItem('Controle de Abastecimento', Icons.local_gas_station, () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FuelControlScreen()));
    }));
  }

  return items;
}
```

### Exemplo 3: Carregar Permissões no App Inicial

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Após login
  final permissionsService = PermissionsService();
  await permissionsService.loadPermissions(forceRefresh: true);
  
  runApp(MyApp());
}
```

---

## 🔄 Fluxo de Sincronização

1. **Login do Usuário**
   - App faz requisição para `/api/user/permissions`
   - Salva permissões no cache local
   - Atualiza interface

2. **Navegação no App**
   - App verifica permissões antes de exibir páginas
   - Oculta itens do menu sem permissão
   - Bloqueia acesso direto via rota

3. **Atualização de Permissões (Admin)**
   - Admin atualiza permissões no servidor
   - Próximo login do usuário sincroniza novas permissões
   - Ou implementar push notification para atualização imediata

---

## ⚠️ Notas Importantes

1. **Páginas Essenciais**: Algumas páginas devem sempre estar habilitadas:
   - `bottom_nav_menu` (Menu)
   - `settings_main` (Configurações)
   - `logout` (Sair)

2. **Cache Local**: Permissões são cacheadas localmente para funcionamento offline

3. **Validação no Servidor**: Sempre validar permissões no servidor também (não confiar apenas no cliente)

4. **Performance**: Carregar permissões uma vez no login, não a cada navegação

5. **Fallback**: Se API falhar, usar cache local. Se cache não existir, mostrar todas as páginas (ou nenhuma, dependendo da política de segurança)

---

## 🚀 Próximos Passos

1. ✅ Implementar endpoints no servidor
2. ✅ Criar interface administrativa
3. ✅ Implementar modelo e serviço no cliente
4. ✅ Atualizar menus para usar permissões
5. ✅ Testar fluxo completo
6. ✅ Adicionar logs de auditoria
7. ✅ Implementar notificações push para atualizações

---

**Última atualização:** 2024-01-15  
**Versão:** 1.0.0
