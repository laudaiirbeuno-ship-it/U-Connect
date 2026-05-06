/// Modelos para API de Veículos/Dispositivos
/// Baseado na documentação da API /api/get_devices, /api/create_device, etc.

class DeviceListResponse {
  final int status;
  final DeviceListItems items;

  DeviceListResponse({
    required this.status,
    required this.items,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      status: json['status'] ?? 0,
      items: DeviceListItems.fromJson(json['items'] ?? {}),
    );
  }
}

class DeviceListItems {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;
  final List<DeviceItem> data;

  DeviceListItems({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
    required this.data,
  });

  factory DeviceListItems.fromJson(Map<String, dynamic> json) {
    List<DeviceItem> dataList = [];
    if (json['data'] != null && json['data'] is List) {
      dataList = (json['data'] as List)
          .map((item) => DeviceItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return DeviceListItems(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 30,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
      data: dataList,
    );
  }
}

class DeviceResponse {
  final int status;
  final String? message;
  final DeviceItem? item;

  DeviceResponse({
    required this.status,
    this.message,
    this.item,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      status: json['status'] ?? 0,
      message: json['message'],
      item: json['item'] != null
          ? DeviceItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DeviceItem {
  final int id;
  final String name;
  final String imei;
  final String? plateNumber;
  final String? deviceModel;
  final bool active;
  final String? vin;
  final String? registrationNumber;
  final String? objectOwner;
  final String? additionalNotes;
  final String? comment;
  final String? simNumber;
  final DeviceIcon? icon;
  final DeviceModel? model;
  final DeviceType? deviceType;
  final String? expirationDate;
  final String? expirationDateFormatted;
  final String? installationDate;
  final String? simActivationDate;
  final String? simExpirationDate;
  final String? brand;
  final String? color;
  final int? year;
  final double? fuelQuantity;
  final double? fuelPrice;
  final int? userId;
  final String? createdAt;
  final String? createdAtFormatted;
  final String? updatedAt;
  

  DeviceItem({
    required this.id,
    required this.name,
    required this.imei,
    this.plateNumber,
    this.deviceModel,
    required this.active,
    this.vin,
    this.registrationNumber,
    this.objectOwner,
    this.additionalNotes,
    this.comment,
    this.simNumber,
    this.icon,
    this.model,
    this.deviceType,
    this.expirationDate,
    this.expirationDateFormatted,
    this.installationDate,
    this.simActivationDate,
    this.simExpirationDate,
    this.brand,
    this.color,
    this.year,
    this.fuelQuantity,
    this.fuelPrice,
    this.userId,
    this.createdAt,
    this.createdAtFormatted,
    this.updatedAt,
  });

  factory DeviceItem.fromJson(Map<String, dynamic> json) {
    return DeviceItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imei: json['imei'] ?? '',
      plateNumber: json['plate_number'],
      deviceModel: json['device_model'],
      active: json['active'] ?? true,
      vin: json['vin'],
      registrationNumber: json['registration_number'],
      objectOwner: json['object_owner'],
      additionalNotes: json['additional_notes'],
      comment: json['comment'],
      simNumber: json['sim_number'],
      icon: json['icon'] != null
          ? DeviceIcon.fromJson(json['icon'] as Map<String, dynamic>)
          : null,
      model: json['model'] != null
          ? DeviceModel.fromJson(json['model'] as Map<String, dynamic>)
          : null,
      deviceType: json['device_type'] != null
          ? DeviceType.fromJson(json['device_type'] as Map<String, dynamic>)
          : null,
      expirationDate: json['expiration_date'],
      expirationDateFormatted: json['expiration_date_formatted'],
      installationDate: json['installation_date'],
      simActivationDate: json['sim_activation_date'],
      simExpirationDate: json['sim_expiration_date'],
      brand: json['brand'],
      color: json['color'],
      year: json['year'],
      fuelQuantity: json['fuel_quantity'] != null
          ? (json['fuel_quantity'] is int
              ? (json['fuel_quantity'] as int).toDouble()
              : json['fuel_quantity'] as double)
          : null,
      fuelPrice: json['fuel_price'] != null
          ? (json['fuel_price'] is int
              ? (json['fuel_price'] as int).toDouble()
              : json['fuel_price'] as double)
          : null,
      userId: json['user_id'],
      createdAt: json['created_at'],
      createdAtFormatted: json['created_at_formatted'],
      updatedAt: json['updated_at'],
    );
  }
}

class IconColors {
  final String? moving;
  final String? stopped;
  final String? offline;
  final String? engine;

  IconColors({
    this.moving,
    this.stopped,
    this.offline,
    this.engine,
  });

  factory IconColors.fromJson(Map<String, dynamic> json) {
    return IconColors(
      moving: json['moving']?.toString(),
      stopped: json['stopped']?.toString(),
      offline: json['offline']?.toString(),
      engine: json['engine']?.toString(),
    );
  }
}

class DeviceIcon {
  final int id;
  final String title;

  DeviceIcon({
    required this.id,
    required this.title,
  });

  factory DeviceIcon.fromJson(Map<String, dynamic> json) {
    return DeviceIcon(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class DeviceModel {
  final int id;
  final String name;

  DeviceModel({
    required this.id,
    required this.name,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class DeviceType {
  final int id;
  final String title;

  DeviceType({
    required this.id,
    required this.title,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

/// Request para criar veículo
class CreateDeviceRequest {
  final String imei;
  final String name;
  final int year;
  final String brand;
  final String color;
  final String? plateNumber;
  final String? deviceModel;
  final bool? active;
  final String? simNumber;
  final String? vin;
  final String? registrationNumber;
  final String? objectOwner;
  final String? additionalNotes;
  final String? comment;
  final String? expirationDate;
  final String? installationDate;
  final String? simActivationDate;
  final String? simExpirationDate;
  final double? fuelQuantity;
  final double? fuelPrice;
  final int? iconId;
  final int? modelId;

  CreateDeviceRequest({
    required this.imei,
    required this.name,
    required this.year,
    required this.brand,
    required this.color,
    this.plateNumber,
    this.deviceModel,
    this.active,
    this.simNumber,
    this.vin,
    this.registrationNumber,
    this.objectOwner,
    this.additionalNotes,
    this.comment,
    this.expirationDate,
    this.installationDate,
    this.simActivationDate,
    this.simExpirationDate,
    this.fuelQuantity,
    this.fuelPrice,
    this.iconId,
    this.modelId,
  });

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final Map<String, dynamic> json = {};

    // Campos obrigatórios apenas na criação
    if (!isUpdate) {
      json['imei'] = imei;
      json['name'] = name;
      json['year'] = year;
      json['brand'] = brand;
      json['color'] = color;
    } else {
      if (imei.isNotEmpty) json['imei'] = imei;
      if (name.isNotEmpty) json['name'] = name;
      if (year > 0) json['year'] = year;
      if (brand.isNotEmpty) json['brand'] = brand;
      if (color.isNotEmpty) json['color'] = color;
    }

    // Campos opcionais
    if (plateNumber != null && plateNumber!.isNotEmpty) json['plate_number'] = plateNumber;
    if (deviceModel != null && deviceModel!.isNotEmpty) json['device_model'] = deviceModel;
    if (active != null) json['active'] = active;
    if (simNumber != null && simNumber!.isNotEmpty) json['sim_number'] = simNumber;
    if (vin != null && vin!.isNotEmpty) json['vin'] = vin;
    if (registrationNumber != null && registrationNumber!.isNotEmpty)
      json['registration_number'] = registrationNumber;
    if (objectOwner != null && objectOwner!.isNotEmpty) json['object_owner'] = objectOwner;
    if (additionalNotes != null && additionalNotes!.isNotEmpty)
      json['additional_notes'] = additionalNotes;
    if (comment != null && comment!.isNotEmpty) json['comment'] = comment;
    if (expirationDate != null && expirationDate!.isNotEmpty)
      json['expiration_date'] = expirationDate;
    if (installationDate != null && installationDate!.isNotEmpty)
      json['installation_date'] = installationDate;
    if (simActivationDate != null && simActivationDate!.isNotEmpty)
      json['sim_activation_date'] = simActivationDate;
    if (simExpirationDate != null && simExpirationDate!.isNotEmpty)
      json['sim_expiration_date'] = simExpirationDate;
    if (fuelQuantity != null) json['fuel_quantity'] = fuelQuantity;
    if (fuelPrice != null) json['fuel_price'] = fuelPrice;
    if (iconId != null) json['icon_id'] = iconId;
    if (modelId != null) json['model_id'] = modelId;

    return json;
  }
}


