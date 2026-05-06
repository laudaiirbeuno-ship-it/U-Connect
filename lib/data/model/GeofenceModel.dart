import 'dart:convert';

class GeofenceModel extends Object {
  List<Geofence>? items;
  dynamic status;

  GeofenceModel({this.items, this.status});

  GeofenceModel.fromJson(Map<String, dynamic> json) {
    if (json["items"] != null && json["items"] is Map && json["items"]["geofences"] != null) {
      final geofencesList = json["items"]["geofences"] as List;
      items = geofencesList.map((item) => Geofence.fromJson(Map<String, dynamic>.from(item))).toList();
    } else {
      items = [];
    }
    status = json["status"];
  }

  Map<String, dynamic> toJson() => {'items': items, 'status': status};
}

class GeofenceCenter {
  double lat;
  double lng;

  GeofenceCenter({required this.lat, required this.lng});

  GeofenceCenter.fromJson(Map<String, dynamic> json)
      : lat = (json["lat"] is num ? json["lat"] : double.parse(json["lat"].toString())).toDouble(),
        lng = (json["lng"] is num ? json["lng"] : double.parse(json["lng"].toString())).toDouble();

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}

class Geofence extends Object {
  int? id;
  String? type;
  int? user_id;
  int? group_id;
  int? device_id;
  bool? active; // true ou false
  String? name;
  GeofenceCenter? center;
  double? radius;
  int? speed_limit;
  bool? movement_allowed;
  String? anchor_status; // "inside", "outside", etc.
  String? polygon_color;
  String? created_at;
  String? updated_at;
  int? is_anchor; // Campo da API que indica se é uma âncora (1 = sim, 0 = não)

  Geofence({
    this.id,
    this.type,
    this.user_id,
    this.group_id,
    this.device_id,
    this.active,
    this.name,
    this.center,
    this.radius,
    this.speed_limit,
    this.movement_allowed,
    this.anchor_status,
    this.polygon_color,
    this.created_at,
    this.updated_at,
    this.is_anchor,
  });

  Geofence.fromJson(Map<String, dynamic> json) {
    id = json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? '');
    type = json["type"]?.toString();
    user_id = json["user_id"] is int ? json["user_id"] : int.tryParse(json["user_id"]?.toString() ?? '');
    group_id = json["group_id"] is int ? json["group_id"] : int.tryParse(json["group_id"]?.toString() ?? '');
    device_id = json["device_id"] is int ? json["device_id"] : int.tryParse(json["device_id"]?.toString() ?? '');
    
    // Parse active (pode ser bool ou int 0/1)
    if (json["active"] is bool) {
      active = json["active"] as bool;
    } else if (json["active"] is int) {
      active = (json["active"] as int) == 1;
    } else if (json["active"] is String) {
      active = json["active"] == "1" || json["active"]?.toLowerCase() == "true";
    } else {
      active = false;
    }
    
    name = json["name"]?.toString();
    radius = json["radius"] is num ? (json["radius"] as num).toDouble() : double.tryParse(json["radius"]?.toString() ?? '');
    speed_limit = json["speed_limit"] is int ? json["speed_limit"] : int.tryParse(json["speed_limit"]?.toString() ?? '');
    movement_allowed = json["movement_allowed"] is bool ? json["movement_allowed"] : (json["movement_allowed"]?.toString().toLowerCase() == "true");
    anchor_status = json["anchor_status"]?.toString();
    polygon_color = json["polygon_color"]?.toString();
    created_at = json["created_at"]?.toString();
    updated_at = json["updated_at"]?.toString();
    
    // Parse is_anchor (pode ser int 0/1 ou bool)
    if (json["is_anchor"] is int) {
      is_anchor = json["is_anchor"] as int;
    } else if (json["is_anchor"] is bool) {
      is_anchor = (json["is_anchor"] as bool) ? 1 : 0;
    } else if (json["is_anchor"] != null) {
      is_anchor = int.tryParse(json["is_anchor"].toString());
    } else {
      is_anchor = null;
    }

    // Parse center
    if (json["center"] != null) {
      if (json["center"] is Map) {
        center = GeofenceCenter.fromJson(Map<String, dynamic>.from(json["center"]));
      } else if (json["center"] is String) {
        try {
          final centerMap = jsonDecode(json["center"]);
          center = GeofenceCenter.fromJson(Map<String, dynamic>.from(centerMap));
        } catch (e) {
          center = null;
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'user_id': user_id,
        'group_id': group_id,
        'device_id': device_id,
        'active': active,
        'name': name,
        'center': center?.toJson(),
        'radius': radius,
        'speed_limit': speed_limit,
        'movement_allowed': movement_allowed,
        'anchor_status': anchor_status,
        'polygon_color': polygon_color,
        'created_at': created_at,
        'updated_at': updated_at,
        'is_anchor': is_anchor,
      };

  // Helper para verificar se é uma âncora
  // Verifica primeiro o campo is_anchor da API, depois o nome
  bool get isAnchor {
    // Se a API retornou is_anchor = 1, é uma âncora
    if (is_anchor == 1) {
      return true;
    }
    
    // Se não, verifica se o nome contém palavras relacionadas
    final nameLower = name?.toLowerCase() ?? '';
    return nameLower.contains('âncora') || 
           nameLower.contains('ancora') ||
           nameLower.contains('antifurto') ||
           nameLower.contains('anti-furto');
  }

  // Helper para verificar se está ativa
  bool get isActive => active == true;
}
