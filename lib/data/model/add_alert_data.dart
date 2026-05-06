class AddAlertData {
  List<AlertOption>? devices;
  List<AlertOption>? geofences;
  List<AlertOption>? drivers;
  List<AlertOption>? alertZones;
  List<AlertOption>? alertFuelType;
  List<AlertOption>? alertDistance;
  List<AlertOption>? eventTypes;
  List<AlertOption>? eventProtocols;
  int? status;

  AddAlertData({
    this.devices,
    this.geofences,
    this.drivers,
    this.alertZones,
    this.alertFuelType,
    this.alertDistance,
    this.eventTypes,
    this.eventProtocols,
    this.status,
  });

  factory AddAlertData.fromJson(Map<String, dynamic> json) {
    return AddAlertData(
      devices: json['devices'] != null
          ? (json['devices'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      geofences: json['geofences'] != null
          ? (json['geofences'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      drivers: json['drivers'] != null
          ? (json['drivers'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      alertZones: json['alert_zones'] != null
          ? (json['alert_zones'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      alertFuelType: json['alert_fuel_type'] != null
          ? (json['alert_fuel_type'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      alertDistance: json['alert_distance'] != null
          ? (json['alert_distance'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      eventTypes: json['event_types'] != null
          ? (json['event_types'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      eventProtocols: json['event_protocols'] != null
          ? (json['event_protocols'] as List).map((e) => AlertOption.fromJson(e)).toList()
          : null,
      status: json['status'],
    );
  }
}

class AlertOption {
  dynamic id;
  String? value;

  AlertOption({this.id, this.value});

  factory AlertOption.fromJson(Map<String, dynamic> json) {
    return AlertOption(
      id: json['id'],
      value: json['value']?.toString(),
    );
  }
}































