# Documentação de Integração - Checklist da Frota

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Estrutura de Dados](#estrutura-de-dados)
3. [Endpoints da API](#endpoints-da-api)
4. [Implementação no Cliente](#implementação-no-cliente)
5. [Exemplos de Requisições](#exemplos-de-requisições)
6. [Tratamento de Erros](#tratamento-de-erros)
7. [Validações](#validações)
8. [Fluxos de Uso](#fluxos-de-uso)

---

## 🎯 Visão Geral

O módulo de **Checklist da Frota** permite gerenciar checklists de inspeção de veículos, incluindo:
- Templates de checklist (Pré-Viagem, Pós-Viagem, Manutenção)
- Registros de checklist por veículo
- Controle de itens verificados
- Histórico de checklists
- Estatísticas de conclusão
- Filtros por veículo e período

**Localização no código:**
- View: `lib/data/screens/fleet_checklist/views/fleet_checklist_screen.dart`
- Controller: `lib/data/screens/fleet_checklist/controllers/fleet_checklist_controller.dart`
- Models: `ChecklistTemplate`, `ChecklistRecord`, `ChecklistItem`, `ChecklistItemResult`

---

## 📊 Estrutura de Dados

### ChecklistTemplate

Modelo que representa um template de checklist (modelo pré-definido).

```dart
class ChecklistTemplate {
  final String id;                    // ID único do template
  final String name;                  // Nome do template (ex: "Pré-Viagem")
  final String? description;          // Descrição do template
  final List<ChecklistItem> items;    // Lista de itens do checklist
  final String? category;             // Categoria (ex: "Viagem", "Manutenção")
  final bool isActive;                // Se o template está ativo
  final DateTime? createdAt;          // Data de criação
  final DateTime? updatedAt;          // Data de atualização
}
```

### ChecklistItem

Item individual de um template de checklist.

```dart
class ChecklistItem {
  final String id;                    // ID único do item
  final String name;                  // Nome do item (ex: "Verificar nível de óleo")
  final bool required;                // Se o item é obrigatório
  final String? description;          // Descrição adicional do item
  final int order;                    // Ordem de exibição
  final String? category;             // Categoria do item (opcional)
}
```

### ChecklistRecord

Registro de checklist preenchido para um veículo.

```dart
class ChecklistRecord {
  final String id;                    // ID único do registro
  final int? vehicleId;               // ID do veículo
  final String vehicleName;           // Nome do veículo
  final int? deviceId;                // ID do dispositivo GPS vinculado
  final String? deviceName;           // Nome do dispositivo
  final int? driverId;                // ID do motorista (opcional)
  final String? driverName;           // Nome do motorista (opcional)
  final String templateId;            // ID do template usado
  final String templateName;          // Nome do template
  final DateTime date;                // Data e hora do checklist
  final bool completed;               // Se o checklist foi concluído
  final List<ChecklistItemResult> items; // Resultados dos itens verificados
  final String inspectorName;         // Nome do inspetor/preenchido por
  final String? notes;                // Observações gerais
  final String? location;             // Localização onde foi preenchido (opcional)
  final double? latitude;             // Latitude (opcional)
  final double? longitude;           // Longitude (opcional)
  final List<String>? images;        // URLs das imagens anexadas (opcional)
  final DateTime? createdAt;          // Data de criação
  final DateTime? updatedAt;          // Data de atualização
}
```

### ChecklistItemResult

Resultado de verificação de um item do checklist.

```dart
class ChecklistItemResult {
  final String itemId;                // ID do item do template
  final String itemName;              // Nome do item
  final bool checked;                 // Se foi verificado/OK
  final String? notes;                // Observações específicas do item
  final String? status;               // Status: "ok", "nok", "na" (não aplicável)
  final List<String>? images;         // URLs das imagens do item (opcional)
}
```

### JSON Schema

#### ChecklistTemplate JSON
```json
{
  "id": "string (UUID)",
  "name": "string",
  "description": "string (opcional)",
  "items": [
    {
      "id": "string",
      "name": "string",
      "required": "boolean",
      "description": "string (opcional)",
      "order": "integer",
      "category": "string (opcional)"
    }
  ],
  "category": "string (opcional)",
  "isActive": "boolean",
  "createdAt": "string (ISO 8601, opcional)",
  "updatedAt": "string (ISO 8601, opcional)"
}
```

#### ChecklistRecord JSON
```json
{
  "id": "string (UUID)",
  "vehicleId": "integer",
  "vehicleName": "string",
  "deviceId": "integer (opcional)",
  "deviceName": "string (opcional)",
  "driverId": "integer (opcional)",
  "driverName": "string (opcional)",
  "templateId": "string",
  "templateName": "string",
  "date": "string (ISO 8601: YYYY-MM-DDTHH:mm:ss)",
  "completed": "boolean",
  "items": [
    {
      "itemId": "string",
      "itemName": "string",
      "checked": "boolean",
      "notes": "string (opcional)",
      "status": "string (opcional: 'ok', 'nok', 'na')",
      "images": ["string (opcional)"]
    }
  ],
  "inspectorName": "string",
  "notes": "string (opcional)",
  "location": "string (opcional)",
  "latitude": "number (opcional)",
  "longitude": "number (opcional)",
  "images": ["string (opcional)"],
  "createdAt": "string (ISO 8601, opcional)",
  "updatedAt": "string (ISO 8601, opcional)"
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

### 1. Listar Templates de Checklist

**GET** `/api/checklist_templates`

Retorna lista de templates de checklist disponíveis.

#### Query Parameters
```
?user_api_hash={hash}
&category={category}        (opcional, filtrar por categoria)
&is_active={true|false}     (opcional, filtrar por status)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Templates encontrados",
  "data": {
    "templates": [
      {
        "id": "pre_trip",
        "name": "Pré-Viagem",
        "description": "Checklist de inspeção antes da viagem",
        "items": [
          {
            "id": "1",
            "name": "Verificar nível de óleo",
            "required": true,
            "description": "Verificar se o nível de óleo está adequado",
            "order": 1,
            "category": "Motor"
          },
          {
            "id": "2",
            "name": "Verificar nível de água",
            "required": true,
            "order": 2,
            "category": "Motor"
          }
        ],
        "category": "Viagem",
        "isActive": true,
        "createdAt": "2024-01-01T00:00:00Z",
        "updatedAt": "2024-01-01T00:00:00Z"
      }
    ]
  }
}
```

---

### 2. Obter Template por ID

**GET** `/api/checklist_templates/{id}`

Retorna um template específico.

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Template encontrado",
  "data": {
    "id": "pre_trip",
    "name": "Pré-Viagem",
    "description": "Checklist de inspeção antes da viagem",
    "items": [...],
    "category": "Viagem",
    "isActive": true
  }
}
```

---

### 3. Criar Template de Checklist (Admin)

**POST** `/api/checklist_templates`

Cria um novo template de checklist.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "name": "Checklist Personalizado",
  "description": "Template personalizado para inspeções",
  "items": [
    {
      "name": "Verificar pneus",
      "required": true,
      "description": "Verificar pressão e estado dos pneus",
      "order": 1,
      "category": "Pneus"
    }
  ],
  "category": "Manutenção",
  "isActive": true
}
```

#### Resposta de Sucesso (201)
```json
{
  "status": 1,
  "message": "Template criado com sucesso",
  "data": {
    "id": "custom_123",
    "name": "Checklist Personalizado",
    ...
  }
}
```

---

### 4. Atualizar Template de Checklist (Admin)

**PUT** `/api/checklist_templates/{id}`

Atualiza um template existente.

#### Body
```json
{
  "name": "Checklist Personalizado Atualizado",
  "isActive": false
}
```

Apenas os campos enviados serão atualizados.

---

### 5. Deletar Template de Checklist (Admin)

**DELETE** `/api/checklist_templates/{id}`

Remove um template (soft delete recomendado).

---

### 6. Listar Registros de Checklist

**GET** `/api/checklist_records`

Retorna lista de registros de checklist com filtros opcionais.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}      (opcional)
&template_id={templateId}    (opcional)
&from_date={YYYY-MM-DD}      (opcional)
&to_date={YYYY-MM-DD}        (opcional)
&completed={true|false}      (opcional)
&page={number}               (opcional, padrão: 1)
&limit={number}              (opcional, padrão: 50)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Registros encontrados",
  "data": {
    "records": [
      {
        "id": "1234567890",
        "vehicleId": 42,
        "vehicleName": "Veículo ABC-1234",
        "deviceId": 42,
        "deviceName": "GPS-001",
        "driverId": 5,
        "driverName": "João Silva",
        "templateId": "pre_trip",
        "templateName": "Pré-Viagem",
        "date": "2024-01-15T14:30:00",
        "completed": true,
        "items": [
          {
            "itemId": "1",
            "itemName": "Verificar nível de óleo",
            "checked": true,
            "notes": "Nível adequado",
            "status": "ok"
          },
          {
            "itemId": "2",
            "itemName": "Verificar nível de água",
            "checked": false,
            "notes": "Necessita reposição",
            "status": "nok"
          }
        ],
        "inspectorName": "Carlos Mendes",
        "notes": "Veículo em boas condições",
        "location": "Garagem Principal",
        "latitude": -23.5505,
        "longitude": -46.6333,
        "images": [
          "https://servidor.com/images/checklist_123.jpg"
        ],
        "createdAt": "2024-01-15T14:30:00Z",
        "updatedAt": "2024-01-15T14:35:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalRecords": 250,
      "perPage": 50
    },
    "statistics": {
      "totalRecords": 250,
      "completedRecords": 200,
      "pendingRecords": 50,
      "completionRate": 80.0
    }
  }
}
```

---

### 7. Criar Registro de Checklist

**POST** `/api/checklist_records`

Cria um novo registro de checklist.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "vehicleId": 42,
  "deviceId": 42,
  "driverId": 5,
  "templateId": "pre_trip",
  "date": "2024-01-15T14:30:00",
  "items": [
    {
      "itemId": "1",
      "itemName": "Verificar nível de óleo",
      "checked": true,
      "notes": "Nível adequado",
      "status": "ok"
    },
    {
      "itemId": "2",
      "itemName": "Verificar nível de água",
      "checked": false,
      "notes": "Necessita reposição",
      "status": "nok"
    }
  ],
  "inspectorName": "Carlos Mendes",
  "notes": "Veículo em boas condições",
  "location": "Garagem Principal",
  "latitude": -23.5505,
  "longitude": -46.6333
}
```

**Campos Obrigatórios:**
- `vehicleId`
- `templateId`
- `date`
- `items` (array não vazio)
- `inspectorName`

**Campos Opcionais:**
- `deviceId`
- `driverId`
- `notes`
- `location`
- `latitude`
- `longitude`

#### Resposta de Sucesso (201)
```json
{
  "status": 1,
  "message": "Registro criado com sucesso",
  "data": {
    "id": "1234567890",
    "vehicleId": 42,
    "vehicleName": "Veículo ABC-1234",
    "templateId": "pre_trip",
    "templateName": "Pré-Viagem",
    "date": "2024-01-15T14:30:00",
    "completed": false,
    "items": [...],
    "inspectorName": "Carlos Mendes",
    "createdAt": "2024-01-15T14:30:00Z"
  }
}
```

**Nota:** O servidor deve calcular automaticamente:
- `completed` = `true` se todos os itens obrigatórios estão `checked: true`
- `vehicleName` = nome do veículo baseado no `vehicleId`
- `templateName` = nome do template baseado no `templateId`

---

### 8. Atualizar Registro de Checklist

**PUT** `/api/checklist_records/{id}`

Atualiza um registro existente.

#### Body
```json
{
  "items": [
    {
      "itemId": "1",
      "checked": true,
      "notes": "Atualizado"
    }
  ],
  "completed": true,
  "notes": "Checklist finalizado"
}
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Registro atualizado com sucesso",
  "data": {
    "id": "1234567890",
    ...
  }
}
```

---

### 9. Deletar Registro de Checklist

**DELETE** `/api/checklist_records/{id}`

Remove um registro de checklist.

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Registro deletado com sucesso",
  "data": null
}
```

---

### 10. Obter Estatísticas de Checklist

**GET** `/api/checklist_records/statistics`

Retorna estatísticas agregadas de checklists.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}      (opcional)
&from_date={YYYY-MM-DD}      (opcional)
&to_date={YYYY-MM-DD}        (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Estatísticas calculadas",
  "data": {
    "totalRecords": 250,
    "completedRecords": 200,
    "pendingRecords": 50,
    "completionRate": 80.0,
    "recordsByTemplate": {
      "pre_trip": 150,
      "post_trip": 80,
      "maintenance": 20
    },
    "recordsByVehicle": {
      "42": 50,
      "43": 30
    },
    "averageCompletionTime": 15.5,
    "itemsMostFailed": [
      {
        "itemId": "2",
        "itemName": "Verificar nível de água",
        "failureCount": 25
      }
    ]
  }
}
```

---

### 11. Upload de Imagem para Checklist

**POST** `/api/checklist_records/{id}/images`

Faz upload de imagem para um registro de checklist.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: multipart/form-data
```

#### Body (Form Data)
```
file: [arquivo de imagem]
item_id: "1" (opcional, se a imagem é de um item específico)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Imagem enviada com sucesso",
  "data": {
    "imageUrl": "https://servidor.com/images/checklist_123_item_1.jpg",
    "thumbnailUrl": "https://servidor.com/images/checklist_123_item_1_thumb.jpg"
  }
}
```

---

## 💻 Implementação no Cliente

### 1. Adicionar Métodos na Classe `gpsapis`

Adicione os seguintes métodos em `lib/data/datasources.dart`:

```dart
// Listar templates de checklist
static Future<List<ChecklistTemplate>?> getChecklistTemplates({
  String? category,
  bool? isActive,
}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getChecklistTemplates");
      return null;
    }

    final queryParams = <String, String>{
      'user_api_hash': userApiHash,
    };

    if (category != null) {
      queryParams['category'] = category;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_templates')
        .replace(queryParameters: queryParams);

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
        final templates = jsonData['data']['templates'] as List;
        return templates.map((t) => ChecklistTemplate.fromJson(t)).toList();
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar templates de checklist: $e");
    return null;
  }
}

// Listar registros de checklist
static Future<List<ChecklistRecord>?> getChecklistRecords({
  String? vehicleId,
  String? templateId,
  DateTime? fromDate,
  DateTime? toDate,
  bool? completed,
  int page = 1,
  int limit = 50,
}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getChecklistRecords");
      return null;
    }

    final queryParams = <String, String>{
      'user_api_hash': userApiHash,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (vehicleId != null) {
      queryParams['vehicle_id'] = vehicleId;
    }
    if (templateId != null) {
      queryParams['template_id'] = templateId;
    }
    if (fromDate != null) {
      queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
    }
    if (completed != null) {
      queryParams['completed'] = completed.toString();
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_records')
        .replace(queryParameters: queryParams);

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
        final records = jsonData['data']['records'] as List;
        return records.map((r) => ChecklistRecord.fromJson(r)).toList();
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar registros de checklist: $e");
    return null;
  }
}

// Criar registro de checklist
static Future<ChecklistRecord?> createChecklistRecord(Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em createChecklistRecord");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_records');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        return ChecklistRecord.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao criar registro de checklist: $e");
    return null;
  }
}

// Atualizar registro de checklist
static Future<ChecklistRecord?> updateChecklistRecord(String id, Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em updateChecklistRecord");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_records/$id');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        return ChecklistRecord.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao atualizar registro de checklist: $e");
    return null;
  }
}

// Deletar registro de checklist
static Future<bool> deleteChecklistRecord(String id) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em deleteChecklistRecord");
      return false;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_records/$id');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['status'] == 1;
    }
    
    return false;
  } catch (e) {
    print("Erro ao deletar registro de checklist: $e");
    return false;
  }
}

// Upload de imagem
static Future<String?> uploadChecklistImage(String recordId, File imageFile, {String? itemId}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em uploadChecklistImage");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/checklist_records/$recordId/images');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $userApiHash';
    
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    
    if (itemId != null) {
      request.fields['item_id'] = itemId;
    }

    final streamedResponse = await request.send().timeout(Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        return jsonData['data']['imageUrl'];
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao fazer upload de imagem: $e");
    return null;
  }
}
```

### 2. Adicionar Métodos `fromJson` e `toJson` nos Models

Adicione em `lib/data/screens/fleet_checklist/controllers/fleet_checklist_controller.dart`:

```dart
// ChecklistTemplate
class ChecklistTemplate {
  // ... campos existentes ...

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      items: (json['items'] as List?)
          ?.map((i) => ChecklistItem.fromJson(i))
          .toList() ?? [],
      category: json['category'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((i) => i.toJson()).toList(),
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// ChecklistItem
class ChecklistItem {
  // ... campos existentes ...

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      required: json['required'] ?? false,
      description: json['description'],
      order: json['order'] ?? 0,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'required': required,
      'description': description,
      'order': order,
      'category': category,
    };
  }
}

// ChecklistRecord
class ChecklistRecord {
  // ... campos existentes ...

  factory ChecklistRecord.fromJson(Map<String, dynamic> json) {
    return ChecklistRecord(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] as int?,
      vehicleName: json['vehicleName'] ?? '',
      deviceId: json['deviceId'] as int?,
      deviceName: json['deviceName'] as String?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      templateId: json['templateId'] ?? '',
      templateName: json['templateName'] ?? '',
      date: DateTime.parse(json['date']),
      completed: json['completed'] ?? false,
      items: (json['items'] as List?)
          ?.map((i) => ChecklistItemResult.fromJson(i))
          .toList() ?? [],
      inspectorName: json['inspectorName'] ?? '',
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'driverId': driverId,
      'driverName': driverName,
      'templateId': templateId,
      'templateName': templateName,
      'date': date.toIso8601String(),
      'completed': completed,
      'items': items.map((i) => i.toJson()).toList(),
      'inspectorName': inspectorName,
      'notes': notes,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

// ChecklistItemResult
class ChecklistItemResult {
  // ... campos existentes ...

  factory ChecklistItemResult.fromJson(Map<String, dynamic> json) {
    return ChecklistItemResult(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      checked: json['checked'] ?? false,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'checked': checked,
      'notes': notes,
      'status': status,
      'images': images,
    };
  }
}
```

### 3. Atualizar `FleetChecklistController`

Atualize o método `_loadTemplates()`:

```dart
Future<void> _loadTemplates() async {
  try {
    final templates = await gpsapis.getChecklistTemplates();
    if (templates != null) {
      _templates = templates;
    } else {
      // Fallback para templates padrão se API não retornar
      _templates = [
        ChecklistTemplate(
          id: 'pre_trip',
          name: 'Pré-Viagem',
          items: [
            ChecklistItem(id: '1', name: 'Verificar nível de óleo', required: true),
            ChecklistItem(id: '2', name: 'Verificar nível de água', required: true),
            ChecklistItem(id: '3', name: 'Verificar pneus', required: true),
            ChecklistItem(id: '4', name: 'Verificar freios', required: true),
            ChecklistItem(id: '5', name: 'Verificar faróis', required: true),
            ChecklistItem(id: '6', name: 'Verificar documentos', required: true),
          ],
        ),
        // ... outros templates padrão
      ];
    }
  } catch (e) {
    print('Erro ao carregar templates: $e');
    // Usar templates padrão em caso de erro
    _loadDefaultTemplates();
  }
}
```

Atualize o método `_loadChecklistRecords()`:

```dart
Future<void> _loadChecklistRecords() async {
  try {
    final records = await gpsapis.getChecklistRecords(
      vehicleId: _selectedVehicleId,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    
    if (records != null) {
      _checklistRecords = records;
    } else {
      _checklistRecords = [];
    }
    
    // Aplicar filtros de data
    _checklistRecords = _checklistRecords
        .where((r) => r.date.isAfter(_fromDate.subtract(Duration(days: 1))) &&
                     r.date.isBefore(_toDate.add(Duration(days: 1))))
        .toList();
    
    _checklistRecords.sort((a, b) => b.date.compareTo(a.date));
  } catch (e) {
    print('Erro ao carregar registros de checklist: $e');
    _checklistRecords = [];
  }
}
```

Atualize o método `addChecklistRecord()`:

```dart
Future<void> addChecklistRecord(ChecklistRecord record) async {
  try {
    // Preparar dados para envio
    final data = {
      'vehicleId': record.vehicleId,
      'deviceId': record.deviceId,
      'driverId': record.driverId,
      'templateId': record.templateId,
      'date': record.date.toIso8601String(),
      'items': record.items.map((i) => i.toJson()).toList(),
      'inspectorName': record.inspectorName,
      'notes': record.notes,
      'location': record.location,
      'latitude': record.latitude,
      'longitude': record.longitude,
    };

    final createdRecord = await gpsapis.createChecklistRecord(data);
    
    if (createdRecord != null) {
      _checklistRecords.insert(0, createdRecord);
      _calculateStatistics();
      notifyListeners();
    } else {
      throw Exception('Falha ao criar registro na API');
    }
  } catch (e) {
    print('Erro ao adicionar registro de checklist: $e');
    rethrow;
  }
}
```

Atualize o método `updateChecklistRecord()`:

```dart
Future<void> updateChecklistRecord(ChecklistRecord record) async {
  try {
    final data = {
      'items': record.items.map((i) => i.toJson()).toList(),
      'completed': record.completed,
      'notes': record.notes,
    };

    final updatedRecord = await gpsapis.updateChecklistRecord(record.id, data);
    
    if (updatedRecord != null) {
      final index = _checklistRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _checklistRecords[index] = updatedRecord;
        _calculateStatistics();
        notifyListeners();
      }
    } else {
      throw Exception('Falha ao atualizar registro na API');
    }
  } catch (e) {
    print('Erro ao atualizar registro de checklist: $e');
    rethrow;
  }
}
```

Atualize o método `deleteChecklistRecord()`:

```dart
Future<void> deleteChecklistRecord(String recordId) async {
  try {
    final success = await gpsapis.deleteChecklistRecord(recordId);
    
    if (success) {
      _checklistRecords.removeWhere((r) => r.id == recordId);
      _calculateStatistics();
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar registro na API');
    }
  } catch (e) {
    print('Erro ao deletar registro de checklist: $e');
    rethrow;
  }
}
```

---

## 📝 Exemplos de Requisições

### Exemplo 1: Listar todos os registros

```bash
curl -X GET "https://api.exemplo.com/api/checklist_records?user_api_hash=abc123" \
  -H "Authorization: Bearer abc123" \
  -H "Accept: application/json"
```

### Exemplo 2: Criar novo registro

```bash
curl -X POST "https://api.exemplo.com/api/checklist_records" \
  -H "Authorization: Bearer abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 42,
    "templateId": "pre_trip",
    "date": "2024-01-15T14:30:00",
    "items": [
      {
        "itemId": "1",
        "itemName": "Verificar nível de óleo",
        "checked": true,
        "status": "ok"
      }
    ],
    "inspectorName": "Carlos Mendes"
  }'
```

### Exemplo 3: Filtrar por veículo e período

```bash
curl -X GET "https://api.exemplo.com/api/checklist_records?user_api_hash=abc123&vehicle_id=42&from_date=2024-01-01&to_date=2024-01-31" \
  -H "Authorization: Bearer abc123" \
  -H "Accept: application/json"
```

---

## ⚠️ Tratamento de Erros

### Códigos de Status HTTP

- **200 OK**: Requisição bem-sucedida
- **201 Created**: Registro criado com sucesso
- **400 Bad Request**: Dados inválidos
- **401 Unauthorized**: Token inválido ou ausente
- **404 Not Found**: Recurso não encontrado
- **500 Internal Server Error**: Erro no servidor

### Formato de Erro

```json
{
  "status": 0,
  "message": "Mensagem de erro descritiva",
  "errors": {
    "field": ["Mensagem de erro específica do campo"]
  }
}
```

### Exemplos de Mensagens de Erro

- `"vehicleId é obrigatório"`
- `"templateId é obrigatório"`
- `"items não pode estar vazio"`
- `"inspectorName é obrigatório"`
- `"Template não encontrado"`
- `"Veículo não encontrado"`
- `"Registro não encontrado"`
- `"Não autorizado"`

---

## ✅ Validações

### Validações no Cliente (Flutter)

O cliente já implementa as seguintes validações:
- ✅ `vehicleId` obrigatório
- ✅ `templateId` obrigatório
- ✅ `items` não pode estar vazio
- ✅ `inspectorName` obrigatório
- ✅ `date` não pode ser no futuro

### Validações no Servidor (Recomendadas)

O servidor deve implementar:

1. **Validação de Autenticação**
   - Verificar `user_api_hash` válido
   - Verificar permissões do usuário

2. **Validação de Dados**
   - `vehicleId`: deve existir e pertencer ao usuário
   - `templateId`: deve existir e estar ativo
   - `deviceId`: se fornecido, deve existir e estar vinculado ao veículo
   - `driverId`: se fornecido, deve existir e pertencer ao usuário
   - `items`: array não vazio, cada item deve ter `itemId` válido do template
   - `date`: não pode ser no futuro (com tolerância de 1 hora)
   - `inspectorName`: não pode estar vazio
   - `latitude`/`longitude`: se fornecidos, devem ser coordenadas válidas

3. **Validação de Negócio**
   - Todos os itens obrigatórios do template devem estar presentes
   - `completed` deve ser calculado automaticamente baseado nos itens obrigatórios
   - Não permitir criar registro com template inativo

---

## 🔄 Fluxos de Uso

### Fluxo 1: Criar Checklist Completo

1. Usuário seleciona veículo e template
2. App carrega template da API
3. Usuário preenche itens do checklist
4. App valida itens obrigatórios
5. App envia registro para API
6. Servidor calcula `completed` automaticamente
7. App atualiza lista local

### Fluxo 2: Atualizar Checklist Pendente

1. Usuário abre checklist pendente
2. Usuário marca itens restantes
3. App atualiza registro na API
4. Servidor recalcula `completed`
5. App atualiza interface

### Fluxo 3: Visualizar Histórico

1. Usuário aplica filtros (veículo, período)
2. App busca registros da API
3. App exibe lista com status (concluído/pendente)
4. Usuário pode ver detalhes de cada registro

---

## 📱 Notas de Implementação

- O cálculo de `completed` pode ser feito no servidor ou no cliente
- Recomenda-se calcular no servidor para garantir consistência
- Imagens podem ser enviadas separadamente após criar o registro
- Suporte a múltiplas imagens por item e por registro
- Histórico de checklists é ordenado por data (mais recente primeiro)

---

## 🚀 Próximos Passos

1. Implementar endpoints no servidor conforme esta documentação
2. Adicionar métodos na classe `gpsapis` conforme exemplos
3. Atualizar `FleetChecklistController` para usar a API
4. Implementar upload de imagens
5. Testar integração completa
6. Implementar cache local para offline
7. Adicionar sincronização automática

---

**Última atualização:** 2024-01-15  
**Versão:** 1.0.0
