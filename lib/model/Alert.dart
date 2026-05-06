class Alert extends Object {
  dynamic id;
  dynamic user_id;
  dynamic active;
  dynamic name;
  dynamic type;
  dynamic schedules;
  Map<String, dynamic>? notifications;
  dynamic created_at;
  dynamic updated_at;
  dynamic zone;
  dynamic schedule;
  Map<String, dynamic>? command;
  List<dynamic>? devices;
  List<dynamic>? drivers;
  List<dynamic>? geofences;
  List<dynamic>? events_custom;
  // New fields from API
  String? email;
  String? mobile_phone;
  String? overspeed_speed;
  String? overspeed_distance;
  String? ac_alarm;
  dynamic overspeed;
  dynamic stop_duration;
  dynamic idle_duration;
  dynamic ignition_duration;
  dynamic offline_duration;
  dynamic move_duration;
  dynamic min_parking_duration;
  dynamic distance;
  dynamic distance_tolerance;
  dynamic time_duration;
  dynamic state;
  dynamic authorized;
  dynamic continuous_duration;
  dynamic period;
  List<dynamic>? task_status;
  List<dynamic>? zones;
  List<dynamic>? pois;

  Alert(
      {this.id,
      this.user_id,
      this.active,
      this.name,
      this.type,
      this.schedules,
      this.notifications,
      this.created_at,
      this.updated_at,
      this.zone,
      this.schedule,
      this.command,
      this.devices,
      this.drivers,
      this.geofences,
      this.events_custom,
      this.email,
      this.mobile_phone,
      this.overspeed_speed,
      this.overspeed_distance,
      this.ac_alarm,
      this.overspeed,
      this.stop_duration,
      this.idle_duration,
      this.ignition_duration,
      this.offline_duration,
      this.move_duration,
      this.min_parking_duration,
      this.distance,
      this.distance_tolerance,
      this.time_duration,
      this.state,
      this.authorized,
      this.continuous_duration,
      this.period,
      this.task_status,
      this.zones,
      this.pois});

  Alert.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    user_id = json["user_id"];
    active = json["active"];
    name = json["name"];
    type = json["type"];
    schedules = json["schedules"];
    notifications = json["notifications"];
    created_at = json["created_at"];
    updated_at = json["updated_at"];
    zone = json["zone"];
    schedule = json["schedule"];
    command = json["command"];
    devices = json["devices"];
    drivers = json["drivers"];
    geofences = json["geofences"];
    events_custom = json["events_custom"];
    // New fields
    email = json["email"]?.toString();
    mobile_phone = json["mobile_phone"]?.toString();
    overspeed_speed = json["overspeed_speed"]?.toString();
    overspeed_distance = json["overspeed_distance"]?.toString();
    ac_alarm = json["ac_alarm"]?.toString();
    overspeed = json["overspeed"];
    stop_duration = json["stop_duration"];
    idle_duration = json["idle_duration"];
    ignition_duration = json["ignition_duration"];
    offline_duration = json["offline_duration"];
    move_duration = json["move_duration"];
    min_parking_duration = json["min_parking_duration"];
    distance = json["distance"];
    distance_tolerance = json["distance_tolerance"];
    time_duration = json["time_duration"];
    state = json["state"];
    authorized = json["authorized"];
    continuous_duration = json["continuous_duration"];
    period = json["period"];
    task_status = json["task_status"];
    zones = json["zones"];
    pois = json["pois"];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': user_id,
        'active': active,
        'name': name,
        'type': type,
        'schedules': schedules,
        'notifications': notifications,
        'created_at': created_at,
        'updated_at': updated_at,
        'zone': zone,
        'schedule': schedule,
        'command': command,
        'devices': devices,
        'drivers': drivers,
        'geofences': geofences,
        'events_custom': events_custom,
        'email': email,
        'mobile_phone': mobile_phone,
        'overspeed_speed': overspeed_speed,
        'overspeed_distance': overspeed_distance,
        'ac_alarm': ac_alarm,
        'overspeed': overspeed,
        'stop_duration': stop_duration,
        'idle_duration': idle_duration,
        'ignition_duration': ignition_duration,
        'offline_duration': offline_duration,
        'move_duration': move_duration,
        'min_parking_duration': min_parking_duration,
        'distance': distance,
        'distance_tolerance': distance_tolerance,
        'time_duration': time_duration,
        'state': state,
        'authorized': authorized,
        'continuous_duration': continuous_duration,
        'period': period,
        'task_status': task_status,
        'zones': zones,
        'pois': pois,
      };
}
