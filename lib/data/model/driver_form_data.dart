/// Modelo para dados do formulário de motorista (criar/editar)
class DriverFormData {
  final int? id; // null para criar, preenchido para editar
  final String? name;
  final String? phone;
  final String? email;
  final String? rfid;
  final String? description;
  final int? deviceId;
  final String? devicePort;
  final String? photo; // Foto do motorista

  DriverFormData({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.rfid,
    this.description,
    this.deviceId,
    this.devicePort,
    this.photo,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (id != null) json['id'] = id;
    if (name != null && name!.isNotEmpty) json['name'] = name;
    if (phone != null && phone!.isNotEmpty) json['phone'] = phone;
    if (email != null && email!.isNotEmpty) json['email'] = email;
    if (rfid != null && rfid!.isNotEmpty) json['rfid'] = rfid;
    if (description != null && description!.isNotEmpty) json['description'] = description;
    // Só enviar device_id se for um valor válido (não null e não 0)
    if (deviceId != null && deviceId! > 0) json['device_id'] = deviceId;
    if (devicePort != null && devicePort!.isNotEmpty) json['device_port'] = devicePort;
    if (photo != null && photo!.isNotEmpty) json['photo'] = photo;
    return json;
  }

  factory DriverFormData.fromDriverData(dynamic driverData) {
    return DriverFormData(
      id: driverData.id is int ? driverData.id : int.tryParse(driverData.id?.toString() ?? ''),
      name: driverData.name?.toString(),
      phone: driverData.phone?.toString(),
      email: driverData.email?.toString(),
      rfid: driverData.rfid?.toString(),
      description: driverData.description?.toString(),
      deviceId: driverData.deviceId is int ? driverData.deviceId : int.tryParse(driverData.deviceId?.toString() ?? ''),
      devicePort: driverData.devicePort?.toString(),
      photo: driverData.photo?.toString(),
    );
  }
}

/// Resposta da API add_user_driver_data (GET)
class AddDriverDataResponse {
  final Map<String, String> devices;
  final int status;

  AddDriverDataResponse({
    required this.devices,
    required this.status,
  });

  factory AddDriverDataResponse.fromJson(Map<String, dynamic> json) {
    final devicesMap = json['devices'] as Map<String, dynamic>? ?? {};
    final devices = devicesMap.map((key, value) => MapEntry(key, value.toString()));
    
    return AddDriverDataResponse(
      devices: devices,
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Resposta da API add_user_driver (POST)
class AddDriverResponse {
  final int status;
  final DriverItem? item;

  AddDriverResponse({
    required this.status,
    this.item,
  });

  factory AddDriverResponse.fromJson(Map<String, dynamic> json) {
    return AddDriverResponse(
      status: (json['status'] as num?)?.toInt() ?? 0,
      item: json['item'] != null
          ? DriverItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Item de motorista retornado pela API
class DriverItem {
  final int id;
  final String name;
  final String userId;
  final String updatedAt;
  final String createdAt;

  DriverItem({
    required this.id,
    required this.name,
    required this.userId,
    required this.updatedAt,
    required this.createdAt,
  });

  factory DriverItem.fromJson(Map<String, dynamic> json) {
    return DriverItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      userId: json['user_id']?.toString() ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

/// Resposta da API edit_user_driver_data (GET)
class EditDriverDataResponse {
  final DriverEditItem? item;
  final Map<String, String> devices;
  final int status;

  EditDriverDataResponse({
    this.item,
    required this.devices,
    required this.status,
  });

  factory EditDriverDataResponse.fromJson(Map<String, dynamic> json) {
    final devicesMap = json['devices'] as Map<String, dynamic>? ?? {};
    final devices = devicesMap.map((key, value) => MapEntry(key, value.toString()));
    
    return EditDriverDataResponse(
      item: json['item'] != null
          ? DriverEditItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
      devices: devices,
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Item completo de motorista para edição
class DriverEditItem {
  final int id;
  final int userId;
  final int deviceId;
  final String? devicePort;
  final String name;
  final String rfid;
  final String phone;
  final String email;
  final String description;
  final String createdAt;
  final String updatedAt;

  DriverEditItem({
    required this.id,
    required this.userId,
    required this.deviceId,
    this.devicePort,
    required this.name,
    required this.rfid,
    required this.phone,
    required this.email,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverEditItem.fromJson(Map<String, dynamic> json) {
    return DriverEditItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      deviceId: (json['device_id'] as num?)?.toInt() ?? 0,
      devicePort: json['device_port']?.toString(),
      name: json['name'] as String? ?? '',
      rfid: json['rfid'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

/// Resposta da API edit_user_driver (POST)
class EditDriverResponse {
  final int status;

  EditDriverResponse({
    required this.status,
  });

  factory EditDriverResponse.fromJson(Map<String, dynamic> json) {
    return EditDriverResponse(
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Resposta da API destroy_user_driver (GET)
class DestroyDriverResponse {
  final int status;

  DestroyDriverResponse({
    required this.status,
  });

  factory DestroyDriverResponse.fromJson(Map<String, dynamic> json) {
    return DestroyDriverResponse(
      status: (json['status'] as num?)?.toInt() ?? 0,
    );
  }
}

