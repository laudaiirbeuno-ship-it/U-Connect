class DeviceData {
  DeviceData({
    num? id,
    num? userId,
    num? active,
    num? deleted,
    String? name,
    String? imei,
    String? fuelQuantity,
    String? fuelPrice,
    String? fuelPerKm,
    String? simNumber,
    String? deviceModel,
    dynamic expirationDate,
    String? plateNumber,
    String? registrationNumber,
    String? brand,           // ✅ Adicionado
    String? year,            // ✅ Adicionado
    String? model,
    String? color,
    int? alert_id,
    int? geofence_id,
  }) {
    _id = id;
    _userId = userId;
    _active = active;
    _deleted = deleted;
    _name = name;
    _imei = imei;
    _fuelQuantity = fuelQuantity;
    _fuelPrice = fuelPrice;
    _fuelPerKm = fuelPerKm;
    _simNumber = simNumber;
    _deviceModel = deviceModel;
    _expirationDate = expirationDate;
    _plateNumber = plateNumber;
    _registrationNumber = registrationNumber;
    _brand = brand;
    _year = year;
    _model = model;
    _color = color;
    _alert_id =  alert_id;
    _geofence_id = geofence_id;
  }

  DeviceData.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['user_id'];
    _active = json['active'];
    _deleted = json['deleted'];
    _name = json['name'];
    _imei = json['imei'];
    _fuelQuantity = json['fuel_quantity'];
    _fuelPrice = json['fuel_price'];
    _fuelPerKm = json['fuel_per_km'];
    _simNumber = json['sim_number'];
    _deviceModel = json['device_model'];
    _expirationDate = json['expiration_date'];
    _plateNumber = json['plate_number'];
    _registrationNumber = json['registration_number'];
    _brand = json['brand']; // ✅ Corrigido
    _year = json['year'];   // ✅ Corrigido
    _model = json['model'];
    _color = json['color'];
    _alert_id = json['alert_id'];
    _geofence_id = json['geofence_id'];

  }

  // 🔒 Campos privados
  num? _id;
  num? _userId;
  num? _active;
  num? _deleted;
  String? _name;
  String? _imei;
  String? _fuelQuantity;
  String? _fuelPrice;
  String? _fuelPerKm;
  String? _simNumber;
  String? _deviceModel;
  dynamic _expirationDate;
  String? _plateNumber;
  String? _registrationNumber;
  String? _brand; // ✅ Novo
  String? _year;  // ✅ Novo
  String? _model;
  String? _color;
  int? _alert_id;
  int? _geofence_id;

  // 🔓 Getters públicos
  num? get id => _id;
  num? get userId => _userId;
  num? get active => _active;
  num? get deleted => _deleted;
  String? get name => _name;
  String? get imei => _imei;
  String? get fuelQuantity => _fuelQuantity;
  String? get fuelPrice => _fuelPrice;
  String? get fuelPerKm => _fuelPerKm;
  String? get simNumber => _simNumber;
  String? get deviceModel => _deviceModel;
  dynamic get expirationDate => _expirationDate;
  String? get plateNumber => _plateNumber;
  String? get registrationNumber => _registrationNumber;
  String? get brand => _brand; // ✅ Novo
  String? get year => _year;   // ✅ Novo
  String? get model => model;
  String? get color => color;
  int? get alert_id => _alert_id;
  int? get geofence_id => _geofence_id;

  // 🔄 Serialização
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['active'] = _active;
    map['deleted'] = _deleted;
    map['name'] = _name;
    map['imei'] = _imei;
    map['fuel_quantity'] = _fuelQuantity;
    map['fuel_price'] = _fuelPrice;
    map['fuel_per_km'] = _fuelPerKm;
    map['sim_number'] = _simNumber;
    map['device_model'] = _deviceModel;
    map['expiration_date'] = _expirationDate;
    map['plate_number'] = _plateNumber;
    map['registration_number'] = _registrationNumber;
    map['brand'] = _brand; // ✅ Novo
    map['year'] = _year;   // ✅ Novo
    map['model'] = _model;
    map['color'] = _color;
    map['alert_id'] = _alert_id;
    map['geofence_id'] = _geofence_id;
    return map;
  }
}
