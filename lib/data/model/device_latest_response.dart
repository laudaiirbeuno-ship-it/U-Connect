import 'dart:convert';

class DeviceLatestResponse {
  final List<DeviceLatestItem> items;
  final List<dynamic> events;
  final int time;
  final String version;

  DeviceLatestResponse({
    required this.items,
    required this.events,
    required this.time,
    required this.version,
  });

  factory DeviceLatestResponse.fromJson(Map<String, dynamic> json) {
    return DeviceLatestResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => DeviceLatestItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      events: json['events'] as List<dynamic>? ?? [],
      time: (json['time'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
    );
  }
}

class DeviceLatestItem {
  final int id;
  final String name;
  final String online;
  final String alarm;
  final String time;
  final int timestamp;
  final int acktimestamp;
  final double speed;
  final double lat;
  final double lng;
  final String course;
  final String power;
  final double altitude;
  final String address;
  final String protocol;
  final String driver;
  final String sensors; // JSON string
  final String services; // JSON string
  final String tail; // JSON string
  final String distanceUnitHour;
  final DeviceLatestData deviceData;

  DeviceLatestItem({
    required this.id,
    required this.name,
    required this.online,
    required this.alarm,
    required this.time,
    required this.timestamp,
    required this.acktimestamp,
    required this.speed,
    required this.lat,
    required this.lng,
    required this.course,
    required this.power,
    required this.altitude,
    required this.address,
    required this.protocol,
    required this.driver,
    required this.sensors,
    required this.services,
    required this.tail,
    required this.distanceUnitHour,
    required this.deviceData,
  });

  factory DeviceLatestItem.fromJson(Map<String, dynamic> json) {
    return DeviceLatestItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      online: json['online'] as String? ?? 'offline',
      alarm: json['alarm'] as String? ?? '',
      time: json['time'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      acktimestamp: (json['acktimestamp'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      course: json['course']?.toString() ?? '0',
      power: json['power'] as String? ?? '-',
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '-',
      protocol: json['protocol'] as String? ?? '',
      driver: json['driver'] as String? ?? '',
      sensors: json['sensors'] as String? ?? '[]',
      services: json['services'] as String? ?? '[]',
      tail: json['tail'] as String? ?? '[]',
      distanceUnitHour: json['distance_unit_hour'] as String? ?? 'kph',
      deviceData: DeviceLatestData.fromJson(
          json['device_data'] as Map<String, dynamic>? ?? {}),
    );
  }

  List<SensorItem> get parsedSensors {
    try {
      if (sensors.isEmpty || sensors == '[]') return [];
      final decoded = json.decode(sensors) as List<dynamic>;
      return decoded.map((item) => SensorItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  List<ServiceItem> get parsedServices {
    try {
      if (services.isEmpty || services == '[]') return [];
      final decoded = json.decode(services) as List<dynamic>;
      return decoded.map((item) => ServiceItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  List<TailCoordinate> get parsedTail {
    try {
      if (tail.isEmpty || tail == '[]') return [];
      final decoded = json.decode(tail) as List<dynamic>;
      return decoded.map((item) => TailCoordinate.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

class DeviceLatestData {
  final String id;
  final String traccarDeviceId;
  final String iconId;
  final String active;
  final String deleted;
  final String name;
  final String imei;
  final String fuelMeasurementId;
  final String fuelQuantity;
  final String fuelPrice;
  final String fuelPerKm;
  final String simNumber;
  final String deviceModel;
  final String plateNumber;
  final String vin;
  final String registrationNumber;
  final String objectOwner;
  final String expirationDate;
  final String tailColor;
  final String tailLength;
  final String engineHours;
  final String detectEngine;
  final String minMovingSpeed;
  final String minFuelFillings;
  final String minFuelThefts;
  final String snapToRoad;
  final String createdAt;
  final String updatedAt;
  final DevicePivot? pivot;
  final String? groupId;
  final String? currentDriverId;

  DeviceLatestData({
    required this.id,
    required this.traccarDeviceId,
    required this.iconId,
    required this.active,
    required this.deleted,
    required this.name,
    required this.imei,
    required this.fuelMeasurementId,
    required this.fuelQuantity,
    required this.fuelPrice,
    required this.fuelPerKm,
    required this.simNumber,
    required this.deviceModel,
    required this.plateNumber,
    required this.vin,
    required this.registrationNumber,
    required this.objectOwner,
    required this.expirationDate,
    required this.tailColor,
    required this.tailLength,
    required this.engineHours,
    required this.detectEngine,
    required this.minMovingSpeed,
    required this.minFuelFillings,
    required this.minFuelThefts,
    required this.snapToRoad,
    required this.createdAt,
    required this.updatedAt,
    this.pivot,
    this.groupId,
    this.currentDriverId,
  });

  factory DeviceLatestData.fromJson(Map<String, dynamic> json) {
    return DeviceLatestData(
      id: json['id']?.toString() ?? '',
      traccarDeviceId: json['traccar_device_id']?.toString() ?? '',
      iconId: json['icon_id']?.toString() ?? '',
      active: json['active']?.toString() ?? '0',
      deleted: json['deleted']?.toString() ?? '0',
      name: json['name'] as String? ?? '',
      imei: json['imei'] as String? ?? '',
      fuelMeasurementId: json['fuel_measurement_id']?.toString() ?? '',
      fuelQuantity: json['fuel_quantity']?.toString() ?? '0.00',
      fuelPrice: json['fuel_price']?.toString() ?? '0.00',
      fuelPerKm: json['fuel_per_km']?.toString() ?? '0.00',
      simNumber: json['sim_number'] as String? ?? '',
      deviceModel: json['device_model'] as String? ?? '',
      plateNumber: json['plate_number'] as String? ?? '',
      vin: json['vin'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? '',
      objectOwner: json['object_owner'] as String? ?? '',
      expirationDate: json['expiration_date'] as String? ?? '0000-00-00',
      tailColor: json['tail_color'] as String? ?? '#000000',
      tailLength: json['tail_length']?.toString() ?? '5',
      engineHours: json['engine_hours'] as String? ?? 'gps',
      detectEngine: json['detect_engine'] as String? ?? 'gps',
      minMovingSpeed: json['min_moving_speed']?.toString() ?? '6',
      minFuelFillings: json['min_fuel_fillings']?.toString() ?? '10',
      minFuelThefts: json['min_fuel_thefts']?.toString() ?? '10',
      snapToRoad: json['snap_to_road']?.toString() ?? '0',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      pivot: json['pivot'] != null
          ? DevicePivot.fromJson(json['pivot'] as Map<String, dynamic>)
          : null,
      groupId: json['group_id']?.toString(),
      currentDriverId: json['current_driver_id']?.toString(),
    );
  }
}

class DevicePivot {
  final String userId;
  final String deviceId;
  final String? groupId;
  final String? currentDriverId;
  final String active;
  final String? timezoneId;

  DevicePivot({
    required this.userId,
    required this.deviceId,
    this.groupId,
    this.currentDriverId,
    required this.active,
    this.timezoneId,
  });

  factory DevicePivot.fromJson(Map<String, dynamic> json) {
    return DevicePivot(
      userId: json['user_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      groupId: json['group_id']?.toString(),
      currentDriverId: json['current_driver_id']?.toString(),
      active: json['active']?.toString() ?? '0',
      timezoneId: json['timezone_id']?.toString(),
    );
  }
}

class SensorItem {
  final String name;
  final String value;
  final String showInPopup;

  SensorItem({
    required this.name,
    required this.value,
    required this.showInPopup,
  });

  factory SensorItem.fromJson(Map<String, dynamic> json) {
    return SensorItem(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      showInPopup: json['show_in_popup']?.toString() ?? '0',
    );
  }
}

class ServiceItem {
  final String name;
  final String value;

  ServiceItem({
    required this.name,
    required this.value,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class TailCoordinate {
  final double lat;
  final double lng;

  TailCoordinate({
    required this.lat,
    required this.lng,
  });

  factory TailCoordinate.fromJson(Map<String, dynamic> json) {
    return TailCoordinate(
      lat: (json['lat'] is String) 
          ? double.tryParse(json['lat'] as String) ?? 0.0
          : (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] is String)
          ? double.tryParse(json['lng'] as String) ?? 0.0
          : (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

