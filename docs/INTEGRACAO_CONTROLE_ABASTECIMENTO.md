# Documentação de Integração - Controle de Abastecimento

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Estrutura de Dados](#estrutura-de-dados)
3. [Endpoints da API](#endpoints-da-api)
4. [Implementação no Cliente](#implementação-no-cliente)
5. [Exemplos de Requisições](#exemplos-de-requisições)
6. [Tratamento de Erros](#tratamento-de-erros)
7. [Validações](#validações)

---

## 🎯 Visão Geral

O módulo de **Controle de Abastecimento** permite gerenciar registros de abastecimento de veículos da frota, incluindo:
- Cadastro de abastecimentos
- Histórico de abastecimentos
- Cálculo de consumo (km/litro)
- Estatísticas e relatórios
- Filtros por veículo e período

**Localização no código:**
- View: `lib/data/screens/fuel_control/views/fuel_control_screen.dart`
- Controller: `lib/data/screens/fuel_control/controllers/fuel_control_controller.dart`
- Model: `FuelRecord` (definido no controller)

---

## 📊 Estrutura de Dados

### FuelRecord

Modelo principal que representa um registro de abastecimento.

```dart
class FuelRecord {
  final String id;                    // ID único do registro
  final int? vehicleId;               // ID do veículo
  final String vehicleName;          // Nome do veículo
  final int? deviceId;                // ID do dispositivo GPS vinculado
  final String? deviceName;           // Nome do dispositivo
  final int? driverId;                // ID do motorista (opcional)
  final String? driverName;           // Nome do motorista (opcional)
  final DateTime date;                // Data e hora do abastecimento
  final double fuelAmount;             // Quantidade em litros
  final double fuelPrice;              // Preço por litro
  final double totalCost;              // Custo total (fuelAmount * fuelPrice)
  final double odometer;               // Odômetro no momento do abastecimento
  final double currentOdometer;        // Odômetro atual do veículo
  final String fuelType;               // Tipo: "Gasolina" ou "Diesel"
  final String station;                // Nome do posto
  final String? notes;                 // Observações
  final String? invoiceNumber;         // Número da nota fiscal
  final String? paymentMethod;         // Método: "Dinheiro", "Cartão de Débito", "Cartão de Crédito", "PIX", "Vale Combustível"
  final double? previousOdometer;       // Odômetro do último abastecimento
  final double? distanceSinceLastFuel; // Distância desde último abastecimento (km)
  final double? consumptionSinceLastFuel; // Consumo desde último abastecimento (km/L)
  final String? fuelQuality;           // Qualidade: "Comum", "Aditivada", "Premium"
}
```

### JSON Schema

```json
{
  "id": "string (UUID ou timestamp)",
  "vehicleId": "integer (opcional)",
  "vehicleName": "string",
  "deviceId": "integer (opcional)",
  "deviceName": "string (opcional)",
  "driverId": "integer (opcional)",
  "driverName": "string (opcional)",
  "date": "string (ISO 8601: YYYY-MM-DDTHH:mm:ss)",
  "fuelAmount": "number (decimal, > 0)",
  "fuelPrice": "number (decimal, > 0)",
  "totalCost": "number (decimal, calculado)",
  "odometer": "number (decimal, >= 0)",
  "currentOdometer": "number (decimal, >= 0)",
  "fuelType": "string (enum: 'Gasolina', 'Diesel')",
  "station": "string",
  "notes": "string (opcional)",
  "invoiceNumber": "string (opcional)",
  "paymentMethod": "string (opcional, enum: 'Dinheiro', 'Cartão de Débito', 'Cartão de Crédito', 'PIX', 'Vale Combustível')",
  "previousOdometer": "number (opcional, decimal)",
  "distanceSinceLastFuel": "number (opcional, decimal)",
  "consumptionSinceLastFuel": "number (opcional, decimal)",
  "fuelQuality": "string (opcional, enum: 'Comum', 'Aditivada', 'Premium')"
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

### 1. Listar Registros de Abastecimento

**GET** `/api/fuel_records`

Retorna lista de registros de abastecimento com filtros opcionais.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}        (opcional)
&from_date={YYYY-MM-DD}        (opcional)
&to_date={YYYY-MM-DD}          (opcional)
&page={number}                 (opcional, padrão: 1)
&limit={number}                (opcional, padrão: 50)
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
        "date": "2024-01-15T14:30:00",
        "fuelAmount": 50.5,
        "fuelPrice": 5.89,
        "totalCost": 297.45,
        "odometer": 125000.0,
        "currentOdometer": 125500.0,
        "fuelType": "Gasolina",
        "station": "Posto Shell - Av. Paulista",
        "notes": "Abastecimento completo",
        "invoiceNumber": "NF-123456",
        "paymentMethod": "Cartão de Crédito",
        "previousOdometer": 124500.0,
        "distanceSinceLastFuel": 500.0,
        "consumptionSinceLastFuel": 9.90,
        "fuelQuality": "Aditivada"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalRecords": 250,
      "perPage": 50
    },
    "statistics": {
      "totalFuel": 12500.5,
      "totalCost": 73629.45,
      "averagePrice": 5.89,
      "totalRecords": 250,
      "averageConsumption": 9.85
    }
  }
}
```

#### Resposta de Erro (400/401/500)
```json
{
  "status": 0,
  "message": "Mensagem de erro",
  "data": null
}
```

---

### 2. Criar Registro de Abastecimento

**POST** `/api/fuel_records`

Cria um novo registro de abastecimento.

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
  "date": "2024-01-15T14:30:00",
  "fuelAmount": 50.5,
  "fuelPrice": 5.89,
  "odometer": 125000.0,
  "fuelType": "Gasolina",
  "station": "Posto Shell - Av. Paulista",
  "notes": "Abastecimento completo",
  "invoiceNumber": "NF-123456",
  "paymentMethod": "Cartão de Crédito",
  "fuelQuality": "Aditivada"
}
```

**Campos Obrigatórios:**
- `vehicleId`
- `deviceId`
- `date`
- `fuelAmount` (> 0)
- `fuelPrice` (> 0)
- `odometer` (>= 0)
- `fuelType`

**Campos Opcionais:**
- `driverId`
- `station`
- `notes`
- `invoiceNumber`
- `paymentMethod`
- `fuelQuality`

#### Resposta de Sucesso (201)
```json
{
  "status": 1,
  "message": "Registro criado com sucesso",
  "data": {
    "id": "1234567890",
    "vehicleId": 42,
    "vehicleName": "Veículo ABC-1234",
    "deviceId": 42,
    "deviceName": "GPS-001",
    "driverId": 5,
    "driverName": "João Silva",
    "date": "2024-01-15T14:30:00",
    "fuelAmount": 50.5,
    "fuelPrice": 5.89,
    "totalCost": 297.45,
    "odometer": 125000.0,
    "currentOdometer": 125500.0,
    "fuelType": "Gasolina",
    "station": "Posto Shell - Av. Paulista",
    "notes": "Abastecimento completo",
    "invoiceNumber": "NF-123456",
    "paymentMethod": "Cartão de Crédito",
    "previousOdometer": 124500.0,
    "distanceSinceLastFuel": 500.0,
    "consumptionSinceLastFuel": 9.90,
    "fuelQuality": "Aditivada"
  }
}
```

**Nota:** O servidor deve calcular automaticamente:
- `totalCost` = `fuelAmount * fuelPrice`
- `currentOdometer` = odômetro atual do veículo
- `previousOdometer` = odômetro do último abastecimento do veículo
- `distanceSinceLastFuel` = `odometer - previousOdometer`
- `consumptionSinceLastFuel` = `distanceSinceLastFuel / fuelAmount` (se > 0)

---

### 3. Atualizar Registro de Abastecimento

**PUT** `/api/fuel_records/{id}`

Atualiza um registro existente.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "fuelAmount": 55.0,
  "fuelPrice": 5.95,
  "odometer": 125100.0,
  "station": "Posto Ipiranga - Av. Faria Lima",
  "notes": "Atualizado"
}
```

Apenas os campos enviados serão atualizados.

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

### 4. Deletar Registro de Abastecimento

**DELETE** `/api/fuel_records/{id}`

Remove um registro de abastecimento.

#### Headers
```
Authorization: Bearer {user_api_hash}
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Registro deletado com sucesso",
  "data": null
}
```

---

### 5. Obter Estatísticas de Abastecimento

**GET** `/api/fuel_records/statistics`

Retorna estatísticas agregadas de abastecimento.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}        (opcional)
&from_date={YYYY-MM-DD}        (opcional)
&to_date={YYYY-MM-DD}          (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Estatísticas calculadas",
  "data": {
    "totalFuel": 12500.5,
    "totalCost": 73629.45,
    "averagePrice": 5.89,
    "totalRecords": 250,
    "averageConsumption": 9.85,
    "totalDistance": 123125.0,
    "vehicleConsumption": {
      "42": 9.90,
      "43": 8.50
    },
    "periodExpenses": {
      "weekly": 1500.00,
      "biweekly": 3000.00,
      "monthly": 6000.00,
      "yearly": 72000.00
    }
  }
}
```

---

### 6. Obter Histórico de Consumo

**GET** `/api/fuel_records/consumption_history`

Retorna histórico de consumo por veículo.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}        (obrigatório)
&from_date={YYYY-MM-DD}        (opcional)
&to_date={YYYY-MM-DD}          (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Histórico de consumo",
  "data": {
    "vehicleId": 42,
    "consumptionHistory": [
      {
        "date": "2024-01-15T14:30:00",
        "consumption": 9.90,
        "distance": 500.0,
        "fuelAmount": 50.5
      },
      {
        "date": "2024-01-10T10:00:00",
        "consumption": 10.20,
        "distance": 510.0,
        "fuelAmount": 50.0
      }
    ],
    "averageConsumption": 10.05,
    "minConsumption": 9.50,
    "maxConsumption": 10.50
  }
}
```

---

## 💻 Implementação no Cliente

### 1. Adicionar Métodos na Classe `gpsapis`

Adicione os seguintes métodos em `lib/data/datasources.dart`:

```dart
// Listar registros de abastecimento
static Future<List<FuelRecord>?> getFuelRecords({
  String? vehicleId,
  DateTime? fromDate,
  DateTime? toDate,
  int page = 1,
  int limit = 50,
}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getFuelRecords");
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
    if (fromDate != null) {
      queryParams['from_date'] = fromDate.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      queryParams['to_date'] = toDate.toIso8601String().split('T')[0];
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/fuel_records')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $userApiHash',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        final records = jsonData['data']['records'] as List;
        return records.map((r) => FuelRecord.fromJson(r)).toList();
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar registros de abastecimento: $e");
    return null;
  }
}

// Criar registro de abastecimento
static Future<FuelRecord?> createFuelRecord(Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em createFuelRecord");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/fuel_records');

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
        return FuelRecord.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao criar registro de abastecimento: $e");
    return null;
  }
}

// Atualizar registro de abastecimento
static Future<FuelRecord?> updateFuelRecord(String id, Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em updateFuelRecord");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/fuel_records/$id');

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
        return FuelRecord.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao atualizar registro de abastecimento: $e");
    return null;
  }
}

// Deletar registro de abastecimento
static Future<bool> deleteFuelRecord(String id) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em deleteFuelRecord");
      return false;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/fuel_records/$id');

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
    print("Erro ao deletar registro de abastecimento: $e");
    return false;
  }
}
```

### 2. Adicionar Método `fromJson` na Classe `FuelRecord`

Adicione em `lib/data/screens/fuel_control/controllers/fuel_control_controller.dart`:

```dart
class FuelRecord {
  // ... campos existentes ...

  factory FuelRecord.fromJson(Map<String, dynamic> json) {
    return FuelRecord(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId'] as int?,
      vehicleName: json['vehicleName'] ?? '',
      deviceId: json['deviceId'] as int?,
      deviceName: json['deviceName'] as String?,
      driverId: json['driverId'] as int?,
      driverName: json['driverName'] as String?,
      date: DateTime.parse(json['date']),
      fuelAmount: (json['fuelAmount'] as num).toDouble(),
      fuelPrice: (json['fuelPrice'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      odometer: (json['odometer'] as num).toDouble(),
      currentOdometer: (json['currentOdometer'] as num).toDouble(),
      fuelType: json['fuelType'] ?? 'Gasolina',
      station: json['station'] ?? '',
      notes: json['notes'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      previousOdometer: json['previousOdometer'] != null 
          ? (json['previousOdometer'] as num).toDouble() 
          : null,
      distanceSinceLastFuel: json['distanceSinceLastFuel'] != null 
          ? (json['distanceSinceLastFuel'] as num).toDouble() 
          : null,
      consumptionSinceLastFuel: json['consumptionSinceLastFuel'] != null 
          ? (json['consumptionSinceLastFuel'] as num).toDouble() 
          : null,
      fuelQuality: json['fuelQuality'] as String?,
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
      'date': date.toIso8601String(),
      'fuelAmount': fuelAmount,
      'fuelPrice': fuelPrice,
      'totalCost': totalCost,
      'odometer': odometer,
      'currentOdometer': currentOdometer,
      'fuelType': fuelType,
      'station': station,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
      'paymentMethod': paymentMethod,
      'previousOdometer': previousOdometer,
      'distanceSinceLastFuel': distanceSinceLastFuel,
      'consumptionSinceLastFuel': consumptionSinceLastFuel,
      'fuelQuality': fuelQuality,
    };
  }
}
```

### 3. Atualizar `FuelControlController`

Atualize o método `_loadFuelRecords()` em `lib/data/screens/fuel_control/controllers/fuel_control_controller.dart`:

```dart
Future<void> _loadFuelRecords() async {
  try {
    final records = await gpsapis.getFuelRecords(
      vehicleId: _selectedVehicleId,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    
    if (records != null) {
      _fuelRecords = records;
    } else {
      _fuelRecords = [];
    }
    
    // Ordenar por data (mais recente primeiro)
    _fuelRecords.sort((a, b) => b.date.compareTo(a.date));
    
    // Atualizar serviço compartilhado
    FleetManagementService().updateFuelRecords(_fuelRecords);
    
    // Calcular histórico de consumo
    _calculateConsumptionHistory();
  } catch (e) {
    print('Erro ao carregar registros de abastecimento: $e');
    _fuelRecords = [];
  }
}
```

Atualize o método `addFuelRecord()`:

```dart
Future<void> addFuelRecord(FuelRecord record) async {
  try {
    // Preparar dados para envio (sem campos calculados)
    final data = {
      'vehicleId': record.vehicleId,
      'deviceId': record.deviceId,
      'driverId': record.driverId,
      'date': record.date.toIso8601String(),
      'fuelAmount': record.fuelAmount,
      'fuelPrice': record.fuelPrice,
      'odometer': record.odometer,
      'fuelType': record.fuelType,
      'station': record.station,
      'notes': record.notes,
      'invoiceNumber': record.invoiceNumber,
      'paymentMethod': record.paymentMethod,
      'fuelQuality': record.fuelQuality,
    };

    final createdRecord = await gpsapis.createFuelRecord(data);
    
    if (createdRecord != null) {
      _fuelRecords.insert(0, createdRecord);
      FleetManagementService().addFuelRecord(createdRecord);
      _calculateStatistics();
      notifyListeners();
    } else {
      throw Exception('Falha ao criar registro na API');
    }
  } catch (e) {
    print('Erro ao adicionar registro de abastecimento: $e');
    rethrow;
  }
}
```

Atualize o método `deleteFuelRecord()`:

```dart
Future<void> deleteFuelRecord(String recordId) async {
  try {
    final success = await gpsapis.deleteFuelRecord(recordId);
    
    if (success) {
      _fuelRecords.removeWhere((r) => r.id == recordId);
      _calculateStatistics();
      _calculateConsumptionHistory();
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar registro na API');
    }
  } catch (e) {
    print('Erro ao deletar registro de abastecimento: $e');
    rethrow;
  }
}
```

---

## 📝 Exemplos de Requisições

### Exemplo 1: Listar todos os registros

```bash
curl -X GET "https://api.exemplo.com/api/fuel_records?user_api_hash=abc123" \
  -H "Authorization: Bearer abc123" \
  -H "Accept: application/json"
```

### Exemplo 2: Criar novo registro

```bash
curl -X POST "https://api.exemplo.com/api/fuel_records" \
  -H "Authorization: Bearer abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 42,
    "deviceId": 42,
    "date": "2024-01-15T14:30:00",
    "fuelAmount": 50.5,
    "fuelPrice": 5.89,
    "odometer": 125000.0,
    "fuelType": "Gasolina",
    "station": "Posto Shell",
    "paymentMethod": "Cartão de Crédito"
  }'
```

### Exemplo 3: Filtrar por veículo e período

```bash
curl -X GET "https://api.exemplo.com/api/fuel_records?user_api_hash=abc123&vehicle_id=42&from_date=2024-01-01&to_date=2024-01-31" \
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
- `"fuelAmount deve ser maior que zero"`
- `"fuelPrice deve ser maior que zero"`
- `"odometer não pode ser negativo"`
- `"fuelType deve ser 'Gasolina' ou 'Diesel'"`
- `"Registro não encontrado"`
- `"Não autorizado"`

---

## ✅ Validações

### Validações no Cliente (Flutter)

O cliente já implementa as seguintes validações:
- ✅ `vehicleId` obrigatório
- ✅ `deviceId` obrigatório
- ✅ `fuelAmount` > 0
- ✅ `fuelPrice` > 0
- ✅ `fuelType` deve ser "Gasolina" ou "Diesel"

### Validações no Servidor (Recomendadas)

O servidor deve implementar:

1. **Validação de Autenticação**
   - Verificar `user_api_hash` válido
   - Verificar permissões do usuário

2. **Validação de Dados**
   - `vehicleId`: deve existir e pertencer ao usuário
   - `deviceId`: deve existir e estar vinculado ao veículo
   - `driverId`: se fornecido, deve existir e pertencer ao usuário
   - `fuelAmount`: > 0, máximo 1000 litros
   - `fuelPrice`: > 0, máximo 50.00
   - `odometer`: >= 0, não pode ser menor que o último registro
   - `date`: não pode ser no futuro
   - `fuelType`: enum válido
   - `paymentMethod`: enum válido (se fornecido)
   - `fuelQuality`: enum válido (se fornecido)

3. **Validação de Negócio**
   - Odômetro não pode diminuir entre registros do mesmo veículo
   - Data não pode ser anterior ao último registro do veículo (com tolerância de 1 dia)

---

## 🔄 Fluxo de Sincronização

1. **Ao abrir a tela**: Carregar registros da API
2. **Ao criar registro**: Enviar para API e atualizar lista local
3. **Ao deletar registro**: Deletar na API e remover da lista local
4. **Pull-to-refresh**: Recarregar da API
5. **Ao filtrar**: Buscar da API com filtros aplicados

---

## 📱 Notas de Implementação

- O cálculo de `consumptionSinceLastFuel` e `distanceSinceLastFuel` pode ser feito no servidor ou no cliente
- Recomenda-se calcular no servidor para garantir consistência
- O `currentOdometer` deve ser obtido do dispositivo GPS em tempo real
- Histórico de consumo é calculado no cliente baseado nos registros retornados

---

## 🚀 Próximos Passos

1. Implementar endpoints no servidor conforme esta documentação
2. Adicionar métodos na classe `gpsapis` conforme exemplos
3. Atualizar `FuelControlController` para usar a API
4. Testar integração completa
5. Implementar cache local para offline
6. Adicionar sincronização automática

---

**Última atualização:** 2024-01-15  
**Versão:** 1.0.0
