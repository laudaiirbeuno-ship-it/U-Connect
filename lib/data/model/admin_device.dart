/// Model para dispositivo admin
/// Baseado nas APIs: /api/admin/devices, /api/admin/device

class DeviceListResponse {
  final int? status;
  final List<DeviceItem> data;
  final Pagination pagination;

  DeviceListResponse({
    this.status,
    required this.data,
    required this.pagination,
  });

  DeviceListResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => DeviceItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['pagination'] != null
            ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : Pagination();

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  bool get hasNextPage => pagination.nextPageUrl != null;
  int get currentPage => pagination.currentPage ?? 1;
  int get lastPage => pagination.lastPage ?? 1;
}

class DeviceItem {
  final int? id;
  final bool? active;
  final String? name;
  final String? imei;
  final String? simNumber;
  final String? deviceModel;
  final String? plateNumber;
  final String? vin;
  final String? registrationNumber;
  final String? objectOwner;
  final String? additionalNotes;
  final String? protocol;
  final String? expirationDate;

  // Campos adicionais do get-device
  final IconColors? iconColors;
  final int? iconId;
  final int? timezoneId;
  final int? fuelMeasurementId;
  final double? fuelQuantity;
  final double? fuelPrice;
  final int? tailLength;
  final String? tailColor;
  final int? minMovingSpeed;
  final int? minFuelFillings;
  final int? minFuelThefts;
  final int? gprsTemplatesOnly;
  final String? detectEngine;
  final String? engineHours;
  final String? engineStatus;
  final String? stopDuration;
  final int? stopDurationSec;
  final double? totalDistance;
  final int? movedTimestamp;
  final dynamic inaccuracy;

  DeviceItem({
    this.id,
    this.active,
    this.name,
    this.imei,
    this.simNumber,
    this.deviceModel,
    this.plateNumber,
    this.vin,
    this.registrationNumber,
    this.objectOwner,
    this.additionalNotes,
    this.protocol,
    this.expirationDate,
    this.iconColors,
    this.iconId,
    this.timezoneId,
    this.fuelMeasurementId,
    this.fuelQuantity,
    this.fuelPrice,
    this.tailLength,
    this.tailColor,
    this.minMovingSpeed,
    this.minFuelFillings,
    this.minFuelThefts,
    this.gprsTemplatesOnly,
    this.detectEngine,
    this.engineHours,
    this.engineStatus,
    this.stopDuration,
    this.stopDurationSec,
    this.totalDistance,
    this.movedTimestamp,
    this.inaccuracy,
  });

  DeviceItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        active = json['active'] is bool ? json['active'] : (json['active'] != null ? (json['active'] == 1 || json['active'] == true) : null),
        name = json['name']?.toString(),
        imei = json['imei']?.toString(),
        simNumber = json['sim_number']?.toString(),
        deviceModel = json['device_model']?.toString(),
        plateNumber = json['plate_number']?.toString(),
        vin = json['vin']?.toString(),
        registrationNumber = json['registration_number']?.toString(),
        objectOwner = json['object_owner']?.toString(),
        additionalNotes = json['additional_notes']?.toString(),
        protocol = json['protocol']?.toString(),
        expirationDate = json['expiration_date']?.toString(),
        iconColors = json['icon_colors'] != null
            ? IconColors.fromJson(json['icon_colors'] as Map<String, dynamic>)
            : null,
        iconId = json['icon_id'] is int ? json['icon_id'] : (json['icon_id'] != null ? int.tryParse(json['icon_id'].toString()) : null),
        timezoneId = json['timezone_id'] is int ? json['timezone_id'] : (json['timezone_id'] != null ? int.tryParse(json['timezone_id'].toString()) : null),
        fuelMeasurementId = json['fuel_measurement_id'] is int ? json['fuel_measurement_id'] : (json['fuel_measurement_id'] != null ? int.tryParse(json['fuel_measurement_id'].toString()) : null),
        fuelQuantity = json['fuel_quantity'] is num ? (json['fuel_quantity'] as num).toDouble() : (json['fuel_quantity'] != null ? double.tryParse(json['fuel_quantity'].toString()) : null),
        fuelPrice = json['fuel_price'] is num ? (json['fuel_price'] as num).toDouble() : (json['fuel_price'] != null ? double.tryParse(json['fuel_price'].toString()) : null),
        tailLength = json['tail_length'] is int ? json['tail_length'] : (json['tail_length'] != null ? int.tryParse(json['tail_length'].toString()) : null),
        tailColor = json['tail_color']?.toString(),
        minMovingSpeed = json['min_moving_speed'] is int ? json['min_moving_speed'] : (json['min_moving_speed'] != null ? int.tryParse(json['min_moving_speed'].toString()) : null),
        minFuelFillings = json['min_fuel_fillings'] is int ? json['min_fuel_fillings'] : (json['min_fuel_fillings'] != null ? int.tryParse(json['min_fuel_fillings'].toString()) : null),
        minFuelThefts = json['min_fuel_thefts'] is int ? json['min_fuel_thefts'] : (json['min_fuel_thefts'] != null ? int.tryParse(json['min_fuel_thefts'].toString()) : null),
        gprsTemplatesOnly = json['gprs_templates_only'] is int ? json['gprs_templates_only'] : (json['gprs_templates_only'] != null ? int.tryParse(json['gprs_templates_only'].toString()) : null),
        detectEngine = json['detect_engine']?.toString(),
        engineHours = json['engine_hours']?.toString(),
        engineStatus = json['engine_status']?.toString(),
        stopDuration = json['stop_duration']?.toString(),
        stopDurationSec = json['stop_duration_sec'] is int ? json['stop_duration_sec'] : (json['stop_duration_sec'] != null ? int.tryParse(json['stop_duration_sec'].toString()) : null),
        totalDistance = json['total_distance'] is num ? (json['total_distance'] as num).toDouble() : (json['total_distance'] != null ? double.tryParse(json['total_distance'].toString()) : null),
        movedTimestamp = json['moved_timestamp'] is int ? json['moved_timestamp'] : (json['moved_timestamp'] != null ? int.tryParse(json['moved_timestamp'].toString()) : null),
        inaccuracy = json['inaccuracy'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active': active,
      'name': name,
      'imei': imei,
      'sim_number': simNumber,
      'device_model': deviceModel,
      'plate_number': plateNumber,
      'vin': vin,
      'registration_number': registrationNumber,
      'object_owner': objectOwner,
      'additional_notes': additionalNotes,
      'protocol': protocol,
      'expiration_date': expirationDate,
      'icon_colors': iconColors?.toJson(),
      'icon_id': iconId,
      'timezone_id': timezoneId,
      'fuel_measurement_id': fuelMeasurementId,
      'fuel_quantity': fuelQuantity,
      'fuel_price': fuelPrice,
      'tail_length': tailLength,
      'tail_color': tailColor,
      'min_moving_speed': minMovingSpeed,
      'min_fuel_fillings': minFuelFillings,
      'min_fuel_thefts': minFuelThefts,
      'gprs_templates_only': gprsTemplatesOnly,
      'detect_engine': detectEngine,
      'engine_hours': engineHours,
      'engine_status': engineStatus,
      'stop_duration': stopDuration,
      'stop_duration_sec': stopDurationSec,
      'total_distance': totalDistance,
      'moved_timestamp': movedTimestamp,
      'inaccuracy': inaccuracy,
    };
  }

  bool get isActive => active ?? false;
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

  IconColors.fromJson(Map<String, dynamic> json)
      : moving = json['moving']?.toString(),
        stopped = json['stopped']?.toString(),
        offline = json['offline']?.toString(),
        engine = json['engine']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'moving': moving,
      'stopped': stopped,
      'offline': offline,
      'engine': engine,
    };
  }
}

class DeviceResponse {
  final int? status;
  final DeviceItem? data;

  DeviceResponse({
    this.status,
    this.data,
  });

  DeviceResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = json['data'] != null
            ? DeviceItem.fromJson(json['data'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
    };
  }
}

class DeviceUsersResponse {
  final int? status;
  final List<DeviceUser> data;
  final Pagination pagination;

  DeviceUsersResponse({
    this.status,
    required this.data,
    required this.pagination,
  });

  DeviceUsersResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => DeviceUser.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['pagination'] != null
            ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : Pagination();

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class DeviceUser {
  final int? id;
  final String? email;
  final int? active;

  DeviceUser({
    this.id,
    this.email,
    this.active,
  });

  DeviceUser.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        email = json['email']?.toString(),
        active = json['active'] is int ? json['active'] : (json['active'] != null ? int.tryParse(json['active'].toString()) : null);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'active': active,
    };
  }
}

class Pagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String? firstPageUrl;
  final String? lastPageUrl;
  final String? path;
  final int? from;
  final int? to;
  final List<dynamic>? links;

  Pagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
    this.firstPageUrl,
    this.lastPageUrl,
    this.path,
    this.from,
    this.to,
    this.links,
  });

  Pagination.fromJson(Map<String, dynamic> json)
      : total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) : null),
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) : null),
        currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) : null),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) : null),
        nextPageUrl = json['next_page_url']?.toString(),
        prevPageUrl = json['prev_page_url']?.toString(),
        firstPageUrl = json['first_page_url']?.toString(),
        lastPageUrl = json['last_page_url']?.toString(),
        path = json['path']?.toString(),
        from = json['from'] is int ? json['from'] : (json['from'] != null ? int.tryParse(json['from'].toString()) : null),
        to = json['to'] is int ? json['to'] : (json['to'] != null ? int.tryParse(json['to'].toString()) : null),
        links = json['links'] as List<dynamic>?;

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
      'first_page_url': firstPageUrl,
      'last_page_url': lastPageUrl,
      'path': path,
      'from': from,
      'to': to,
      'links': links,
    };
  }
}

// Request models
class CreateDeviceRequest {
  final String name;
  final String imei;
  final String? simNumber;
  final String? deviceModel;
  final String? plateNumber;
  final String? vin;
  final String? registrationNumber;
  final String? objectOwner;
  final String? additionalNotes;
  final String? protocol;
  final String? expirationDate;
  final bool? active;

  CreateDeviceRequest({
    required this.name,
    required this.imei,
    this.simNumber,
    this.deviceModel,
    this.plateNumber,
    this.vin,
    this.registrationNumber,
    this.objectOwner,
    this.additionalNotes,
    this.protocol,
    this.expirationDate,
    this.active,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imei': imei,
      'sim_number': simNumber,
      'device_model': deviceModel,
      'plate_number': plateNumber,
      'vin': vin,
      'registration_number': registrationNumber,
      'object_owner': objectOwner,
      'additional_notes': additionalNotes,
      'protocol': protocol,
      'expiration_date': expirationDate,
      'active': active,
    };
  }
}

class UpdateDeviceStatusRequest {
  final int deviceId;
  final bool active;

  UpdateDeviceStatusRequest({
    required this.deviceId,
    required this.active,
  });

  Map<String, dynamic> toJson() {
    return {
      'active': active ? 1 : 0,
    };
  }
}

class UpdateDeviceExpirationRequest {
  final int deviceId;
  final String? expirationDate;

  UpdateDeviceExpirationRequest({
    required this.deviceId,
    this.expirationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'expiration_date': expirationDate,
    };
  }
}


class AssignUserToDeviceRequest {
  final int? userId;
  final String? email;

  AssignUserToDeviceRequest({
    this.userId,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
    };
  }
}






































