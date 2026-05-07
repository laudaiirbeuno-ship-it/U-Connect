# Documentação de Integração - Documentação da Frota

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Estrutura de Dados](#estrutura-de-dados)
3. [Endpoints da API](#endpoints-da-api)
4. [Implementação no Cliente](#implementação-no-cliente)
5. [Exemplos de Requisições](#exemplos-de-requisições)
6. [Tratamento de Erros](#tratamento-de-erros)
7. [Validações](#validações)
8. [Fluxos de Uso](#fluxos-de-uso)
9. [Upload de Arquivos](#upload-de-arquivos)

---

## 🎯 Visão Geral

O módulo de **Documentação da Frota** permite gerenciar documentos dos veículos, incluindo:
- CRLV (Certificado de Registro e Licenciamento de Veículo)
- Seguro
- IPVA
- Licenciamento
- Vistoria
- Outros documentos personalizados
- Controle de vencimento
- Alertas de documentos próximos do vencimento
- Upload de imagens/documentos
- Compartilhamento via WhatsApp

**Localização no código:**
- View: `lib/data/screens/fleet_documentation/views/fleet_documentation_screen.dart`
- Controller: `lib/data/screens/fleet_documentation/controllers/fleet_documentation_controller.dart`
- Model: `VehicleDocument`

---

## 📊 Estrutura de Dados

### VehicleDocument

Modelo principal que representa um documento de veículo.

```dart
class VehicleDocument {
  final String id;                    // ID único do documento
  final int? vehicleId;               // ID do veículo
  final String vehicleName;           // Nome do veículo
  final String documentType;          // Tipo: "CRLV", "Seguro", "IPVA", "Licenciamento", "Vistoria", "Outro"
  final String documentNumber;        // Número do documento
  final DateTime issueDate;           // Data de emissão
  final DateTime expiryDate;          // Data de vencimento
  final String issuingAgency;        // Órgão emissor
  final String? notes;                // Observações
  final String? filePath;             // Caminho do arquivo anexado (URL)
  final String? fileUrl;              // URL completa do arquivo
  final String? thumbnailUrl;         // URL da miniatura (se imagem)
  final String? fileName;             // Nome original do arquivo
  final int? fileSize;                // Tamanho do arquivo em bytes
  final String? mimeType;             // Tipo MIME do arquivo
  final DateTime? createdAt;           // Data de criação
  final DateTime? updatedAt;           // Data de atualização
  final String? createdBy;             // Usuário que criou
  final String? updatedBy;             // Usuário que atualizou
  
  // Propriedades calculadas
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon {
    final thirtyDaysFromNow = DateTime.now().add(Duration(days: 30));
    return expiryDate.isBefore(thirtyDaysFromNow) && !isExpired;
  }
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}
```

### JSON Schema

```json
{
  "id": "string (UUID)",
  "vehicleId": "integer",
  "vehicleName": "string",
  "documentType": "string (enum: 'CRLV', 'Seguro', 'IPVA', 'Licenciamento', 'Vistoria', 'Outro')",
  "documentNumber": "string",
  "issueDate": "string (ISO 8601: YYYY-MM-DD)",
  "expiryDate": "string (ISO 8601: YYYY-MM-DD)",
  "issuingAgency": "string",
  "notes": "string (opcional)",
  "fileUrl": "string (opcional, URL completa)",
  "thumbnailUrl": "string (opcional, URL da miniatura)",
  "fileName": "string (opcional)",
  "fileSize": "integer (opcional, bytes)",
  "mimeType": "string (opcional, ex: 'image/jpeg', 'application/pdf')",
  "createdAt": "string (ISO 8601, opcional)",
  "updatedAt": "string (ISO 8601, opcional)",
  "createdBy": "string (opcional)",
  "updatedBy": "string (opcional)"
}
```

### Tipos de Documento Suportados

| Tipo | Descrição | Obrigatório |
|------|-----------|-------------|
| `CRLV` | Certificado de Registro e Licenciamento de Veículo | Sim |
| `Seguro` | Apólice de Seguro | Sim |
| `IPVA` | Imposto sobre Propriedade de Veículos Automotores | Sim |
| `Licenciamento` | Licenciamento Anual | Sim |
| `Vistoria` | Vistoria Técnica | Depende |
| `Outro` | Outros documentos | Não |

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

### 1. Listar Documentos

**GET** `/api/vehicle_documents`

Retorna lista de documentos com filtros opcionais.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}        (opcional)
&document_type={type}           (opcional: CRLV, Seguro, IPVA, etc.)
&expiring_soon={true|false}     (opcional, próximos 30 dias)
&expired={true|false}            (opcional, documentos vencidos)
&page={number}                   (opcional, padrão: 1)
&limit={number}                  (opcional, padrão: 50)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Documentos encontrados",
  "data": {
    "documents": [
      {
        "id": "1234567890",
        "vehicleId": 42,
        "vehicleName": "Veículo ABC-1234",
        "documentType": "CRLV",
        "documentNumber": "12345678901",
        "issueDate": "2024-01-15",
        "expiryDate": "2025-01-15",
        "issuingAgency": "DETRAN-SP",
        "notes": "Documento em dia",
        "fileUrl": "https://servidor.com/documents/crlv_123.pdf",
        "thumbnailUrl": "https://servidor.com/documents/crlv_123_thumb.jpg",
        "fileName": "CRLV_ABC1234.pdf",
        "fileSize": 245678,
        "mimeType": "application/pdf",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalRecords": 250,
      "perPage": 50
    },
    "statistics": {
      "totalDocuments": 250,
      "expiredDocuments": 5,
      "expiringSoonDocuments": 12,
      "validDocuments": 233,
      "documentsByType": {
        "CRLV": 50,
        "Seguro": 50,
        "IPVA": 50,
        "Licenciamento": 50,
        "Vistoria": 30,
        "Outro": 20
      }
    }
  }
}
```

---

### 2. Obter Documento por ID

**GET** `/api/vehicle_documents/{id}`

Retorna um documento específico.

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Documento encontrado",
  "data": {
    "id": "1234567890",
    "vehicleId": 42,
    "vehicleName": "Veículo ABC-1234",
    "documentType": "CRLV",
    "documentNumber": "12345678901",
    "issueDate": "2024-01-15",
    "expiryDate": "2025-01-15",
    "issuingAgency": "DETRAN-SP",
    "notes": "Documento em dia",
    "fileUrl": "https://servidor.com/documents/crlv_123.pdf",
    "thumbnailUrl": "https://servidor.com/documents/crlv_123_thumb.jpg",
    "fileName": "CRLV_ABC1234.pdf",
    "fileSize": 245678,
    "mimeType": "application/pdf",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
}
```

---

### 3. Criar Documento

**POST** `/api/vehicle_documents`

Cria um novo documento.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "vehicleId": 42,
  "documentType": "CRLV",
  "documentNumber": "12345678901",
  "issueDate": "2024-01-15",
  "expiryDate": "2025-01-15",
  "issuingAgency": "DETRAN-SP",
  "notes": "Documento em dia"
}
```

**Campos Obrigatórios:**
- `vehicleId`
- `documentType`
- `documentNumber`
- `expiryDate`
- `issuingAgency`

**Campos Opcionais:**
- `issueDate` (padrão: data atual)
- `notes`

**Nota:** O arquivo deve ser enviado separadamente usando o endpoint de upload.

#### Resposta de Sucesso (201)
```json
{
  "status": 1,
  "message": "Documento criado com sucesso",
  "data": {
    "id": "1234567890",
    "vehicleId": 42,
    "vehicleName": "Veículo ABC-1234",
    "documentType": "CRLV",
    "documentNumber": "12345678901",
    "issueDate": "2024-01-15",
    "expiryDate": "2025-01-15",
    "issuingAgency": "DETRAN-SP",
    "notes": "Documento em dia",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

---

### 4. Atualizar Documento

**PUT** `/api/vehicle_documents/{id}`

Atualiza um documento existente.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: application/json
```

#### Body
```json
{
  "documentNumber": "12345678902",
  "expiryDate": "2026-01-15",
  "notes": "Documento renovado"
}
```

Apenas os campos enviados serão atualizados.

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Documento atualizado com sucesso",
  "data": {
    "id": "1234567890",
    ...
  }
}
```

---

### 5. Deletar Documento

**DELETE** `/api/vehicle_documents/{id}`

Remove um documento (e o arquivo associado, se houver).

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Documento deletado com sucesso",
  "data": null
}
```

---

### 6. Upload de Arquivo

**POST** `/api/vehicle_documents/{id}/upload`

Faz upload de arquivo (imagem ou PDF) para um documento.

#### Headers
```
Authorization: Bearer {user_api_hash}
Content-Type: multipart/form-data
```

#### Body (Form Data)
```
file: [arquivo]
```

**Formatos Suportados:**
- Imagens: JPG, PNG, WEBP (máx. 10MB)
- PDF: PDF (máx. 20MB)

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Arquivo enviado com sucesso",
  "data": {
    "fileUrl": "https://servidor.com/documents/crlv_123.pdf",
    "thumbnailUrl": "https://servidor.com/documents/crlv_123_thumb.jpg",
    "fileName": "CRLV_ABC1234.pdf",
    "fileSize": 245678,
    "mimeType": "application/pdf"
  }
}
```

---

### 7. Download de Arquivo

**GET** `/api/vehicle_documents/{id}/download`

Baixa o arquivo do documento.

#### Query Parameters
```
?user_api_hash={hash}
&thumbnail={true|false}        (opcional, retornar miniatura se disponível)
```

#### Resposta
- **200 OK**: Arquivo binário
- **Content-Type**: Baseado no `mimeType` do documento
- **Content-Disposition**: `attachment; filename="nome_arquivo.ext"`

---

### 8. Obter Documentos Próximos do Vencimento

**GET** `/api/vehicle_documents/expiring`

Retorna documentos que vencem em breve.

#### Query Parameters
```
?user_api_hash={hash}
&days={number}                  (opcional, padrão: 30)
&vehicle_id={vehicleId}         (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Documentos próximos do vencimento",
  "data": {
    "documents": [
      {
        "id": "1234567890",
        "vehicleId": 42,
        "vehicleName": "Veículo ABC-1234",
        "documentType": "CRLV",
        "expiryDate": "2024-02-15",
        "daysUntilExpiry": 15
      }
    ],
    "totalExpiring": 12,
    "expiredCount": 5,
    "expiringIn30Days": 7
  }
}
```

---

### 9. Obter Estatísticas de Documentos

**GET** `/api/vehicle_documents/statistics`

Retorna estatísticas agregadas de documentos.

#### Query Parameters
```
?user_api_hash={hash}
&vehicle_id={vehicleId}         (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Estatísticas calculadas",
  "data": {
    "totalDocuments": 250,
    "expiredDocuments": 5,
    "expiringSoonDocuments": 12,
    "validDocuments": 233,
    "documentsByType": {
      "CRLV": 50,
      "Seguro": 50,
      "IPVA": 50,
      "Licenciamento": 50,
      "Vistoria": 30,
      "Outro": 20
    },
    "expiringByType": {
      "CRLV": 2,
      "Seguro": 3,
      "IPVA": 1,
      "Licenciamento": 4,
      "Vistoria": 1,
      "Outro": 1
    },
    "averageDaysUntilExpiry": 180.5
  }
}
```

---

### 10. Buscar Documentos

**GET** `/api/vehicle_documents/search`

Busca documentos por texto.

#### Query Parameters
```
?user_api_hash={hash}
&q={searchQuery}                (obrigatório, termo de busca)
&vehicle_id={vehicleId}         (opcional)
&document_type={type}           (opcional)
```

#### Resposta de Sucesso (200)
```json
{
  "status": 1,
  "message": "Busca realizada",
  "data": {
    "documents": [...],
    "totalResults": 5
  }
}
```

---

## 💻 Implementação no Cliente

### 1. Adicionar Métodos na Classe `gpsapis`

Adicione os seguintes métodos em `lib/data/datasources.dart`:

```dart
// Listar documentos
static Future<List<VehicleDocument>?> getVehicleDocuments({
  String? vehicleId,
  String? documentType,
  bool? expiringSoon,
  bool? expired,
  int page = 1,
  int limit = 50,
}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getVehicleDocuments");
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
    if (documentType != null) {
      queryParams['document_type'] = documentType;
    }
    if (expiringSoon != null) {
      queryParams['expiring_soon'] = expiringSoon.toString();
    }
    if (expired != null) {
      queryParams['expired'] = expired.toString();
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents')
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
        final documents = jsonData['data']['documents'] as List;
        return documents.map((d) => VehicleDocument.fromJson(d)).toList();
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar documentos: $e");
    return null;
  }
}

// Criar documento
static Future<VehicleDocument?> createVehicleDocument(Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em createVehicleDocument");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents');

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
        return VehicleDocument.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao criar documento: $e");
    return null;
  }
}

// Atualizar documento
static Future<VehicleDocument?> updateVehicleDocument(String id, Map<String, dynamic> data) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em updateVehicleDocument");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents/$id');

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
        return VehicleDocument.fromJson(jsonData['data']);
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao atualizar documento: $e");
    return null;
  }
}

// Deletar documento
static Future<bool> deleteVehicleDocument(String id) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em deleteVehicleDocument");
      return false;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents/$id');

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
    print("Erro ao deletar documento: $e");
    return false;
  }
}

// Upload de arquivo
static Future<String?> uploadDocumentFile(String documentId, File file) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em uploadDocumentFile");
      return null;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents/$documentId/upload');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $userApiHash';
    
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send().timeout(Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 1 && jsonData['data'] != null) {
        return jsonData['data']['fileUrl'];
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao fazer upload de arquivo: $e");
    return null;
  }
}

// Obter documentos próximos do vencimento
static Future<List<VehicleDocument>?> getExpiringDocuments({
  int days = 30,
  String? vehicleId,
}) async {
  try {
    final userApiHash = StaticVarMethod.user_api_hash;
    if (userApiHash == null || userApiHash.isEmpty) {
      print("❌ user_api_hash é null ou vazio em getExpiringDocuments");
      return null;
    }

    final queryParams = <String, String>{
      'user_api_hash': userApiHash,
      'days': days.toString(),
    };

    if (vehicleId != null) {
      queryParams['vehicle_id'] = vehicleId;
    }

    final url = Uri.parse('${UserRepository.getServerURL()}/api/vehicle_documents/expiring')
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
        final documents = jsonData['data']['documents'] as List;
        return documents.map((d) => VehicleDocument.fromJson(d)).toList();
      }
    }
    
    return null;
  } catch (e) {
    print("Erro ao buscar documentos próximos do vencimento: $e");
    return null;
  }
}
```

### 2. Adicionar Métodos `fromJson` e `toJson` no Model

Adicione em `lib/data/screens/fleet_documentation/controllers/fleet_documentation_controller.dart`:

```dart
class VehicleDocument {
  // ... campos existentes ...

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] as int?,
      vehicleName: json['vehicleName'] ?? '',
      documentType: json['documentType'] ?? '',
      documentNumber: json['documentNumber'] ?? '',
      issueDate: DateTime.parse(json['issueDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      issuingAgency: json['issuingAgency'] ?? '',
      notes: json['notes'] as String?,
      filePath: json['fileUrl'] as String?, // Mapear fileUrl para filePath
      fileUrl: json['fileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'issueDate': issueDate.toIso8601String().split('T')[0],
      'expiryDate': expiryDate.toIso8601String().split('T')[0],
      'issuingAgency': issuingAgency,
      'notes': notes,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
```

### 3. Atualizar `FleetDocumentationController`

Atualize o método `_loadDocuments()`:

```dart
Future<void> _loadDocuments() async {
  try {
    final documents = await gpsapis.getVehicleDocuments(
      vehicleId: _selectedVehicleId,
      documentType: _selectedDocumentType,
    );
    
    if (documents != null) {
      _documents = documents;
    } else {
      _documents = [];
    }
    
    // Aplicar filtros locais (se necessário)
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
  } catch (e) {
    print('Erro ao carregar documentos: $e');
    _documents = [];
  }
}
```

Atualize o método `addDocument()`:

```dart
Future<void> addDocument(VehicleDocument document) async {
  try {
    // Preparar dados para envio (sem filePath)
    final data = {
      'vehicleId': document.vehicleId,
      'documentType': document.documentType,
      'documentNumber': document.documentNumber,
      'issueDate': document.issueDate.toIso8601String().split('T')[0],
      'expiryDate': document.expiryDate.toIso8601String().split('T')[0],
      'issuingAgency': document.issuingAgency,
      'notes': document.notes,
    };

    final createdDocument = await gpsapis.createVehicleDocument(data);
    
    if (createdDocument != null) {
      // Se houver arquivo local, fazer upload
      if (document.filePath != null && File(document.filePath!).existsSync()) {
        final file = File(document.filePath!);
        final fileUrl = await gpsapis.uploadDocumentFile(createdDocument.id, file);
        
        if (fileUrl != null) {
          // Atualizar documento com URL do arquivo
          final updatedDoc = VehicleDocument(
            id: createdDocument.id,
            vehicleId: createdDocument.vehicleId,
            vehicleName: createdDocument.vehicleName,
            documentType: createdDocument.documentType,
            documentNumber: createdDocument.documentNumber,
            issueDate: createdDocument.issueDate,
            expiryDate: createdDocument.expiryDate,
            issuingAgency: createdDocument.issuingAgency,
            notes: createdDocument.notes,
            filePath: fileUrl,
            fileUrl: fileUrl,
          );
          
          _documents.insert(0, updatedDoc);
        } else {
          _documents.insert(0, createdDocument);
        }
      } else {
        _documents.insert(0, createdDocument);
      }
      
      _calculateStatistics();
      notifyListeners();
    } else {
      throw Exception('Falha ao criar documento na API');
    }
  } catch (e) {
    print('Erro ao adicionar documento: $e');
    rethrow;
  }
}
```

Atualize o método `deleteDocument()`:

```dart
Future<void> deleteDocument(String documentId) async {
  try {
    final success = await gpsapis.deleteVehicleDocument(documentId);
    
    if (success) {
      _documents.removeWhere((d) => d.id == documentId);
      _calculateStatistics();
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar documento na API');
    }
  } catch (e) {
    print('Erro ao deletar documento: $e');
    rethrow;
  }
}
```

---

## 📝 Exemplos de Requisições

### Exemplo 1: Listar todos os documentos

```bash
curl -X GET "https://api.exemplo.com/api/vehicle_documents?user_api_hash=abc123" \
  -H "Authorization: Bearer abc123" \
  -H "Accept: application/json"
```

### Exemplo 2: Criar novo documento

```bash
curl -X POST "https://api.exemplo.com/api/vehicle_documents" \
  -H "Authorization: Bearer abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 42,
    "documentType": "CRLV",
    "documentNumber": "12345678901",
    "issueDate": "2024-01-15",
    "expiryDate": "2025-01-15",
    "issuingAgency": "DETRAN-SP",
    "notes": "Documento em dia"
  }'
```

### Exemplo 3: Upload de arquivo

```bash
curl -X POST "https://api.exemplo.com/api/vehicle_documents/1234567890/upload" \
  -H "Authorization: Bearer abc123" \
  -F "file=@/caminho/para/documento.pdf"
```

### Exemplo 4: Filtrar documentos próximos do vencimento

```bash
curl -X GET "https://api.exemplo.com/api/vehicle_documents/expiring?user_api_hash=abc123&days=30" \
  -H "Authorization: Bearer abc123" \
  -H "Accept: application/json"
```

---

## ⚠️ Tratamento de Erros

### Códigos de Status HTTP

- **200 OK**: Requisição bem-sucedida
- **201 Created**: Documento criado com sucesso
- **400 Bad Request**: Dados inválidos
- **401 Unauthorized**: Token inválido ou ausente
- **404 Not Found**: Recurso não encontrado
- **413 Payload Too Large**: Arquivo muito grande
- **415 Unsupported Media Type**: Formato de arquivo não suportado
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
- `"documentType é obrigatório"`
- `"documentNumber é obrigatório"`
- `"expiryDate é obrigatório"`
- `"expiryDate não pode ser anterior à issueDate"`
- `"issuingAgency é obrigatório"`
- `"Arquivo muito grande (máximo 20MB)"`
- `"Formato de arquivo não suportado"`
- `"Documento não encontrado"`
- `"Não autorizado"`

---

## ✅ Validações

### Validações no Cliente (Flutter)

O cliente já implementa as seguintes validações:
- ✅ `vehicleId` obrigatório
- ✅ `documentType` obrigatório
- ✅ `documentNumber` obrigatório
- ✅ `expiryDate` obrigatório
- ✅ `issuingAgency` obrigatório

### Validações no Servidor (Recomendadas)

O servidor deve implementar:

1. **Validação de Autenticação**
   - Verificar `user_api_hash` válido
   - Verificar permissões do usuário

2. **Validação de Dados**
   - `vehicleId`: deve existir e pertencer ao usuário
   - `documentType`: enum válido
   - `documentNumber`: não pode estar vazio, máximo 100 caracteres
   - `issueDate`: não pode ser no futuro
   - `expiryDate`: não pode ser anterior à `issueDate`
   - `issuingAgency`: não pode estar vazio, máximo 200 caracteres
   - `notes`: máximo 1000 caracteres

3. **Validação de Arquivo (Upload)**
   - Tamanho máximo: 20MB para PDF, 10MB para imagens
   - Formatos permitidos: PDF, JPG, PNG, WEBP
   - Verificar tipo MIME real do arquivo (não confiar apenas na extensão)
   - Validar que o arquivo não está corrompido

4. **Validação de Negócio**
   - Não permitir documentos duplicados (mesmo tipo + veículo + número)
   - Alertar sobre documentos próximos do vencimento
   - Manter histórico de versões do documento (opcional)

---

## 🔄 Fluxos de Uso

### Fluxo 1: Adicionar Documento com Foto

1. Usuário tira foto do documento
2. Usuário preenche dados do documento
3. App cria documento na API
4. App faz upload da foto
5. Servidor processa e armazena arquivo
6. App atualiza documento com URL do arquivo
7. App atualiza lista local

### Fluxo 2: Visualizar Documentos Próximos do Vencimento

1. App busca documentos próximos do vencimento (30 dias)
2. App exibe alertas na interface
3. Usuário pode filtrar por veículo
4. Usuário pode ver detalhes de cada documento

### Fluxo 3: Renovar Documento

1. Usuário seleciona documento vencido
2. Usuário atualiza data de vencimento
3. Usuário faz upload do novo documento
4. App atualiza registro na API
5. App remove alerta de vencimento

---

## 📤 Upload de Arquivos

### Processo de Upload

1. **Criar documento primeiro** (sem arquivo)
2. **Obter ID do documento criado**
3. **Fazer upload do arquivo** usando o ID
4. **Atualizar documento** com URL do arquivo (opcional, pode ser automático)

### Formatos Suportados

- **PDF**: Máximo 20MB
- **Imagens**: JPG, PNG, WEBP - Máximo 10MB

### Geração de Miniatura

O servidor deve gerar automaticamente:
- Miniatura para imagens (200x200px)
- Primeira página como miniatura para PDFs

### Armazenamento

- Arquivos devem ser armazenados de forma segura
- URLs devem ser acessíveis apenas com autenticação
- Implementar CDN para melhor performance (opcional)

---

## 📱 Notas de Implementação

- Documentos podem ter múltiplos arquivos (histórico de versões) - implementação futura
- Alertas de vencimento são calculados no servidor
- Estatísticas são calculadas em tempo real
- Suporte a busca por texto nos campos do documento
- Compartilhamento via WhatsApp usa dados do documento

---

## 🚀 Próximos Passos

1. Implementar endpoints no servidor conforme esta documentação
2. Adicionar métodos na classe `gpsapis` conforme exemplos
3. Atualizar `FleetDocumentationController` para usar a API
4. Implementar upload de arquivos
5. Implementar download de arquivos
6. Testar integração completa
7. Implementar cache local para offline
8. Adicionar sincronização automática
9. Implementar notificações push para documentos próximos do vencimento

---

**Última atualização:** 2024-01-15  
**Versão:** 1.0.0
