import 'dart:convert';

class AntifurtoModel {
  final int? id;
  final String name;
  final int deviceId;
  final double radius;
  final String polygonColor;
  final bool autoBlock;
  final bool alertIgnition;
  final bool alertMovement;
  final bool alertSpeed;
  final double? alertSpeedLimit;
  final double centerLat;
  final double centerLng;

  AntifurtoModel({
    this.id,
    required this.name,
    required this.deviceId,
    required this.radius,
    required this.polygonColor,
    required this.autoBlock,
    required this.alertIgnition,
    required this.alertMovement,
    required this.alertSpeed,
    this.alertSpeedLimit,
    required this.centerLat,
    required this.centerLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'circle',
      'is_anchor': 1,
      'device_id': deviceId,
      'name': name,
      'radius': radius,
      'polygon_color': polygonColor,
      'auto_block': autoBlock ? 1 : 0,
      'alert_ignition': alertIgnition ? 1 : 0,
      'alert_movement': alertMovement ? 1 : 0,
      'alert_speed': alertSpeed ? 1 : 0,
      'alert_speed_limit': alertSpeedLimit,
      'center[lat]': centerLat,
      'center[lng]': centerLng,
      'polygon': jsonEncode([{'lat': centerLat, 'lng': centerLng}]),
    };
  }
}

class ActiveAnchorModel {
  final int id;
  final String name;
  final int? deviceId;
  final String? deviceName;
  final double radius;
  final Map<String, double> center;
  final DateTime createdAt;

  ActiveAnchorModel({
    required this.id,
    required this.name,
    this.deviceId,
    this.deviceName,
    required this.radius,
    required this.center,
    required this.createdAt,
  });

  factory ActiveAnchorModel.fromJson(Map<String, dynamic> json) {
    return ActiveAnchorModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      deviceId: json['device_id'] is int 
          ? json['device_id'] 
          : (json['device_id'] != null ? int.tryParse(json['device_id'].toString()) : null),
      deviceName: json['device_name']?.toString(),
      radius: json['radius'] is num 
          ? (json['radius'] as num).toDouble() 
          : double.parse(json['radius'].toString()),
      center: {
        'lat': json['center'] is Map 
            ? (json['center']['lat'] is num 
                ? (json['center']['lat'] as num).toDouble() 
                : double.parse(json['center']['lat'].toString()))
            : 0.0,
        'lng': json['center'] is Map 
            ? (json['center']['lng'] is num 
                ? (json['center']['lng'] as num).toDouble() 
                : double.parse(json['center']['lng'].toString()))
            : 0.0,
      },
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
