import 'device_data.dart';

/// id : 0
/// title : "Ungrouped"
/// items : [{"id":369,"alarm":0,"name":"PS BR22PA 1985","online":"ack","time":"18-10-2022 15:24:03","timestamp":1666089320,"lat":25.401708,"lng":86.339088,"course":186,"speed":0,"altitude":0,"power":"-","address":"-","protocol":"gt06","driver":"-","sensors":[{"id":1520,"type":"acc","name":"Vehicle","show_in_popup":0,"value":"On","val":true,"scale_value":null}],"ignition_duration":"0s","idle_duration":"0s","stop_duration":"2h 35min 13s","total_distance":25108.03}]

class Devices {
  Devices({
    dynamic id,
    String? title,
    List<deviceItems>? items,
  }) {
    _id = id;
    _title = title;
    _items = items;
  }

  Devices.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    if (json['items'] != null) {
      _items = [];
      json['items'].forEach((v) {
        _items?.add(deviceItems.fromJson(v));
      });
    }
  }
  dynamic _id;
  String? _title;
  List<deviceItems>? _items;

  dynamic get id => _id;
  String? get title => _title;
  List<deviceItems>? get items => _items;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    if (_items != null) {
      map['items'] = _items?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// id : 369
/// alarm : 0
/// name : "PS BR22PA 1985"
/// online : "ack"
/// time : "18-10-2022 15:24:03"
/// timestamp : 1666089320
/// lat : 25.401708
/// lng : 86.339088
/// course : 186
/// speed : 0
/// altitude : 0
/// power : "-"
/// address : "-"
/// protocol : "gt06"
/// driver : "-"
/// sensors : [{"id":1520,"type":"acc","name":"Vehicle","show_in_popup":0,"value":"On","val":true,"scale_value":null}]
/// ignition_duration : "0s"
/// idle_duration : "0s"
/// stop_duration : "2h 35min 13s"
/// total_distance : 25108.03

class deviceItems {
  String? _image;

  deviceItems({
    dynamic id,
    dynamic alarm,
    String? name,
    String? online,
    String? time,
    dynamic timestamp,
    dynamic lat,
    dynamic lng,
    dynamic course,
    dynamic speed,
    dynamic altitude,
    String? power,
    String? address,
    String? protocol,
    String? driver,
    DeviceIcon? icon,
    List<Sensors>? sensors,
    String? ignitionDuration,
    String? idleDuration,
    String? stopDuration,
    dynamic totalDistance,
    DeviceData? deviceData,
    String? image, // ✅ aqui o novo campo
    String? plateNumber, // ✅ novo campo para placa
    int? alert_id,
    int? geofence_id,
  }) {
    _id = id;
    _alarm = alarm;
    _name = name;
    _online = online;
    _time = time;
    _timestamp = timestamp;
    _lat = lat;
    _lng = lng;
    _course = course;
    _speed = speed;
    _altitude = altitude;
    _power = power;
    _address = address;
    _protocol = protocol;
    _driver = driver;
    _icon = icon;
    _sensors = sensors;
    _ignitionDuration = ignitionDuration;
    _idleDuration = idleDuration;
    _stopDuration = stopDuration;
    _totalDistance = totalDistance;
    _deviceData = deviceData;
    _image = image; // ✅ atribuição correta
    _plateNumber = plateNumber; // ✅ atribuição da placa
    _alert_id = alert_id;
    _geofence_id = geofence_id;
  }

  String? get image => _image;
  String? get plateNumber => _plateNumber; // ✅ getter para placa

  deviceItems.fromJson(dynamic json) {
    print(json);

    _id = json['id'];
    _alarm = json['alarm'];
    _name = json['name'];
    _online = json['online'];
    _image = json['image'];
    _time = json['time'];
    _timestamp = json['timestamp'];
    // Converter coordenadas e valores numéricos para double de forma segura
    _lat = json['lat'] != null ? (json['lat'] as num).toDouble() : null;
    _lng = json['lng'] != null ? (json['lng'] as num).toDouble() : null;
    _course = json['course'] != null ? (json['course'] as num).toDouble() : null;
    _speed = json['speed'] != null ? (json['speed'] as num).toDouble() : null;
    _altitude = json['altitude'] != null ? (json['altitude'] as num).toDouble() : null;
    _power = json['power'];
    _address = json['address'];
    _protocol = json['protocol'];
    _driver = json['driver'];
    _plateNumber = json['plate_number']; // ✅ capturar placa do JSON
    _brand = json['brand']; // ✅ Corrigido
    _year = json['year'];   // ✅ Corrigido
    _model = json['model'];
    _color = json['color'];
    _alert_id = json['alert_id'];
    _geofence_id = json['geofence_id'];
    _driverData = json['driver_data'] != null
        ? DriverData.fromJson(json['driver_data'])
        : null;
    _icon = json['icon'] != null ? DeviceIcon.fromJson(json['icon']) : null;
    if (json['sensors'] != null) {
      _sensors = [];
      json['sensors'].forEach((v) {
        _sensors?.add(Sensors.fromJson(v));
      });
    }
    _ignitionDuration = json['ignition_duration'];
    _idleDuration = json['idle_duration'];
    _stopDuration = json['stop_duration'];
    _totalDistance = json['total_distance'];
    _deviceData = json['device_data'] != null
        ? DeviceData.fromJson(json['device_data'])
        : null;
  }
  dynamic _id;
  dynamic _alarm;
  String? _name;
  String? _online;
  String? _time;
  dynamic _timestamp;
  dynamic _lat;
  dynamic _lng;
  dynamic _course;
  dynamic _speed;
  dynamic _altitude;
  String? _power;
  String? _address;
  String? _protocol;
  String? _driver;
  String? _plateNumber; // ✅ campo para placa
  String? _brand; // ✅ Novo
  String? _year;  // ✅ Novo
  String? _model;
  String? _color;
  int? _alert_id;
  int? _geofence_id;
  DriverData? _driverData;
  DeviceIcon? _icon;
  List<Sensors>? _sensors;
  String? _ignitionDuration;
  String? _idleDuration;
  String? _stopDuration;
  dynamic _totalDistance;
  DeviceData? _deviceData;

  dynamic get id => _id;
  dynamic get alarm => _alarm;
  String? get name => _name;
  String? get online => _online;
  String? get time => _time;
  dynamic get timestamp => _timestamp;
  dynamic get lat => _lat;
  dynamic get lng => _lng;
  dynamic get course => _course;
  dynamic get speed => _speed;
  dynamic get altitude => _altitude;
  String? get power => _power;
  String? get address => _address;
  String? get protocol => _protocol;
  String? get driver => _driver;
  String? get brand => _brand; // ✅ Novo
  String? get year => _year;   // ✅ Novo
  String? get model => model;
  String? get color => color;
  int? get alert_id => _alert_id;
  int? get geofence_id => _geofence_id;
  DriverData? get driverData => _driverData;
  DeviceIcon? get icon => _icon;
  List<Sensors>? get sensors => _sensors;
  String? get ignitionDuration => _ignitionDuration;
  String? get idleDuration => _idleDuration;
  String? get stopDuration => _stopDuration;
  dynamic get totalDistance => _totalDistance;
  DeviceData? get deviceData => _deviceData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_image != null) {
      map['image'] = _image;
    }
    map['id'] = _id;
    map['alarm'] = _alarm;
    map['name'] = _name;
    map['online'] = _online;
    map['time'] = _time;
    map['timestamp'] = _timestamp;
    map['lat'] = _lat;
    map['lng'] = _lng;
    map['course'] = _course;
    map['speed'] = _speed;
    map['altitude'] = _altitude;
    map['power'] = _power;
    map['address'] = _address;
    map['protocol'] = _protocol;
    map['driver'] = _driver;
    map['brand'] = _brand; // ✅ Novo
    map['year'] = _year;   // ✅ Novo
    map['model'] = _model;
    map['color'] = _color;
    map['alert_id'] = _alert_id;
    map['geofence_id'] = _geofence_id;
    if (_plateNumber != null) {
      map['plate_number'] = _plateNumber; // ✅ incluir placa no JSON
    }
    if (_driverData != null) {
      map['driver_data'] = _driverData?.toJson();
    }
    if (_icon != null) {
      map['icon'] = _icon?.toJson();
    }
    if (_sensors != null) {
      map['sensors'] = _sensors?.map((v) => v.toJson()).toList();
    }
    map['ignition_duration'] = _ignitionDuration;
    map['idle_duration'] = _idleDuration;
    map['stop_duration'] = _stopDuration;
    map['total_distance'] = _totalDistance;
    if (_deviceData != null) {
      map['device_data'] = _deviceData?.toJson();
    }
    return map;
  }
}

class DeviceData {
  DeviceData({
    dynamic id,
    dynamic userId,
    dynamic active,
    dynamic deleted,
    String? name,
    String? imei,
    String? fuelQuantity,
    String? fuelPrice,
    String? fuelPerKm,
    String? simNumber,
    String? deviceModel,
    dynamic expirationDate,
    Traccar? traccar,
    String? plateNumber,
    String? registrationNumber,
    String? brand, // ✅
    String? year, // ✅
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
    _traccar = traccar;
    _plateNumber = plateNumber;
    _registrationNumber = registrationNumber;
    _brand = brand;
    _year = year;
    _model = model;
    _color = color;
    _alert_id = alert_id;
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
    _traccar =
        json['traccar'] != null ? Traccar.fromJson(json['traccar']) : null;
    _plateNumber = json['plate_number'];
    _registrationNumber = json['registration_number'];
    _brand = json['brand']; // ✅
    _year = json['year']; // ✅
    _model = json['model']; // ✅
    _color = json['color']; // ✅
    _alert_id = json['alert_id'];
    _geofence_id = json['geofence_id'];
  }

  dynamic _id;
  dynamic _userId;
  dynamic _active;
  dynamic _deleted;
  String? _name;
  String? _imei;
  String? _fuelQuantity;
  String? _fuelPrice;
  String? _fuelPerKm;
  String? _simNumber;
  String? _deviceModel;
  dynamic _expirationDate;
  Traccar? _traccar;
  String? _plateNumber;
  String? _registrationNumber;
  String? _brand; // ✅
  String? _year; // ✅
  String? _model; // ✅
  String? _color; // ✅
  int? _alert_id;
  int? _geofence_id;

  dynamic get id => _id;
  dynamic get userId => _userId;
  dynamic get active => _active;
  dynamic get deleted => _deleted;
  String? get name => _name;
  String? get imei => _imei;
  String? get fuelQuantity => _fuelQuantity;
  String? get fuelPrice => _fuelPrice;
  String? get fuelPerKm => _fuelPerKm;
  String? get simNumber => _simNumber;
  String? get deviceModel => _deviceModel;
  dynamic get expirationDate => _expirationDate;
  Traccar? get traccar => _traccar;
  String? get plateNumber => _plateNumber;
  String? get registrationNumber => _registrationNumber;
  String? get brand => _brand; // ✅
  String? get year => _year; // ✅
  String? get model => _model; // ✅
  String? get color => _color; // ✅
  int? get alert_id => _alert_id;
  int? get geofence_id => _geofence_id;

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
    map['brand'] = _brand; // ✅
    map['year'] = _year; // ✅
    map['model'] = _model; // ✅
    map['color'] = _color; // ✅
    map['alert_id'] = _alert_id;
    map['geofence_id'] = _geofence_id;
    if (_traccar != null) {
      map['traccar'] = _traccar?.toJson();
    }
    return map;
  }

  String? completeName() {
    return '$brand $model - $year - $color';
  }
}

/// id : 1520
/// type : "acc"
/// name : "Vehicle"
/// show_in_popup : 0
/// value : "On"
/// val : true
/// scale_value : null

class Sensors {
  Sensors({
    dynamic id,
    dynamic userId,
    dynamic deviceId,
    String? name,
    String? type,
    String? tagName,
    dynamic addToHistory,
    dynamic onValue,
    dynamic offValue,
    dynamic shownValueBy,
    String? fuelTankName,
    dynamic fullTank,
    dynamic fullTankValue,
    dynamic minValue,
    dynamic maxValue,
    String? formula,
    dynamic odometerValueBy,
    dynamic odometerValue,
    String? odometerValueUnit,
    dynamic temperatureMax,
    dynamic temperatureMaxValue,
    dynamic temperatureMin,
    dynamic temperatureMinValue,
    String? value,
    dynamic valueFormula,
    dynamic showInPopup,
    String? unitOfMeasurement,
    String? onTagValue,
    String? offTagValue,
    dynamic onType,
    dynamic offType,
    dynamic data,
    dynamic calibrations,
    dynamic skipCalibration,
    dynamic skipEmpty,
    dynamic decbin,
    dynamic hexbin,
    String? typeTitle,
  }) {
    _id = id;
    _userId = userId;
    _deviceId = deviceId;
    _name = name;
    _type = type;
    _tagName = tagName;
    _addToHistory = addToHistory;
    _onValue = onValue;
    _offValue = offValue;
    _shownValueBy = shownValueBy;
    _fuelTankName = fuelTankName;
    _fullTank = fullTank;
    _fullTankValue = fullTankValue;
    _minValue = minValue;
    _maxValue = maxValue;
    _formula = formula;
    _odometerValueBy = odometerValueBy;
    _odometerValue = odometerValue;
    _odometerValueUnit = odometerValueUnit;
    _temperatureMax = temperatureMax;
    _temperatureMaxValue = temperatureMaxValue;
    _temperatureMin = temperatureMin;
    _temperatureMinValue = temperatureMinValue;
    _value = value;
    _valueFormula = valueFormula;
    _showInPopup = showInPopup;
    _unitOfMeasurement = unitOfMeasurement;
    _onTagValue = onTagValue;
    _offTagValue = offTagValue;
    _onType = onType;
    _offType = offType;
    _data = data;
    _calibrations = calibrations;
    _skipCalibration = skipCalibration;
    _skipEmpty = skipEmpty;
    _decbin = decbin;
    _hexbin = hexbin;
    _typeTitle = typeTitle;
  }

  Sensors.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['user_id'];
    _deviceId = json['device_id'];
    _name = json['name'];
    _type = json['type'];
    _tagName = json['tag_name'];
    _addToHistory = json['add_to_history'];
    _onValue = json['on_value'];
    _offValue = json['off_value'];
    _shownValueBy = json['shown_value_by'];
    _fuelTankName = json['fuel_tank_name'];
    _fullTank = json['full_tank'];
    _fullTankValue = json['full_tank_value'];
    _minValue = json['min_value'];
    _maxValue = json['max_value'];
    _formula = json['formula'];
    _odometerValueBy = json['odometer_value_by'];
    _odometerValue = json['odometer_value'];
    _odometerValueUnit = json['odometer_value_unit'];
    _temperatureMax = json['temperature_max'];
    _temperatureMaxValue = json['temperature_max_value'];
    _temperatureMin = json['temperature_min'];
    _temperatureMinValue = json['temperature_min_value'];
    _value = json['value']?.toString();
    _valueFormula = json['value_formula'];
    _showInPopup = json['show_in_popup'];
    _unitOfMeasurement = json['unit_of_measurement'];
    _onTagValue = json['on_tag_value']?.toString();
    _offTagValue = json['off_tag_value']?.toString();
    _onType = json['on_type'];
    _offType = json['off_type'];
    _data = json['data'];
    _calibrations = json['calibrations'];
    _skipCalibration = json['skip_calibration'];
    _skipEmpty = json['skip_empty'];
    _decbin = json['decbin'];
    _hexbin = json['hexbin'];
    _typeTitle = json['type_title'];
  }
  
  dynamic _id;
  dynamic _userId;
  dynamic _deviceId;
  String? _name;
  String? _type;
  String? _tagName;
  dynamic _addToHistory;
  dynamic _onValue;
  dynamic _offValue;
  dynamic _shownValueBy;
  String? _fuelTankName;
  dynamic _fullTank;
  dynamic _fullTankValue;
  dynamic _minValue;
  dynamic _maxValue;
  String? _formula;
  dynamic _odometerValueBy;
  dynamic _odometerValue;
  String? _odometerValueUnit;
  dynamic _temperatureMax;
  dynamic _temperatureMaxValue;
  dynamic _temperatureMin;
  dynamic _temperatureMinValue;
  String? _value;
  dynamic _valueFormula;
  dynamic _showInPopup;
  String? _unitOfMeasurement;
  String? _onTagValue;
  String? _offTagValue;
  dynamic _onType;
  dynamic _offType;
  dynamic _data;
  dynamic _calibrations;
  dynamic _skipCalibration;
  dynamic _skipEmpty;
  dynamic _decbin;
  dynamic _hexbin;
  String? _typeTitle;

  dynamic get id => _id;
  dynamic get userId => _userId;
  dynamic get deviceId => _deviceId;
  String? get name => _name;
  String? get type => _type;
  String? get tagName => _tagName;
  dynamic get addToHistory => _addToHistory;
  dynamic get onValue => _onValue;
  dynamic get offValue => _offValue;
  dynamic get shownValueBy => _shownValueBy;
  String? get fuelTankName => _fuelTankName;
  dynamic get fullTank => _fullTank;
  dynamic get fullTankValue => _fullTankValue;
  dynamic get minValue => _minValue;
  dynamic get maxValue => _maxValue;
  String? get formula => _formula;
  dynamic get odometerValueBy => _odometerValueBy;
  dynamic get odometerValue => _odometerValue;
  String? get odometerValueUnit => _odometerValueUnit;
  dynamic get temperatureMax => _temperatureMax;
  dynamic get temperatureMaxValue => _temperatureMaxValue;
  dynamic get temperatureMin => _temperatureMin;
  dynamic get temperatureMinValue => _temperatureMinValue;
  String? get value => _value;
  dynamic get valueFormula => _valueFormula;
  dynamic get showInPopup => _showInPopup;
  String? get unitOfMeasurement => _unitOfMeasurement;
  String? get onTagValue => _onTagValue;
  String? get offTagValue => _offTagValue;
  dynamic get onType => _onType;
  dynamic get offType => _offType;
  dynamic get data => _data;
  dynamic get calibrations => _calibrations;
  dynamic get skipCalibration => _skipCalibration;
  dynamic get skipEmpty => _skipEmpty;
  dynamic get decbin => _decbin;
  dynamic get hexbin => _hexbin;
  String? get typeTitle => _typeTitle;

  // Getters de compatibilidade (para código existente)
  dynamic get val => _value; // Para compatibilidade
  dynamic get scaleValue => null; // Não existe mais na nova estrutura

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['device_id'] = _deviceId;
    map['name'] = _name;
    map['type'] = _type;
    map['tag_name'] = _tagName;
    map['add_to_history'] = _addToHistory;
    map['on_value'] = _onValue;
    map['off_value'] = _offValue;
    map['shown_value_by'] = _shownValueBy;
    map['fuel_tank_name'] = _fuelTankName;
    map['full_tank'] = _fullTank;
    map['full_tank_value'] = _fullTankValue;
    map['min_value'] = _minValue;
    map['max_value'] = _maxValue;
    map['formula'] = _formula;
    map['odometer_value_by'] = _odometerValueBy;
    map['odometer_value'] = _odometerValue;
    map['odometer_value_unit'] = _odometerValueUnit;
    map['temperature_max'] = _temperatureMax;
    map['temperature_max_value'] = _temperatureMaxValue;
    map['temperature_min'] = _temperatureMin;
    map['temperature_min_value'] = _temperatureMinValue;
    map['value'] = _value;
    map['value_formula'] = _valueFormula;
    map['show_in_popup'] = _showInPopup;
    map['unit_of_measurement'] = _unitOfMeasurement;
    map['on_tag_value'] = _onTagValue;
    map['off_tag_value'] = _offTagValue;
    map['on_type'] = _onType;
    map['off_type'] = _offType;
    map['data'] = _data;
    map['calibrations'] = _calibrations;
    map['skip_calibration'] = _skipCalibration;
    map['skip_empty'] = _skipEmpty;
    map['decbin'] = _decbin;
    map['hexbin'] = _hexbin;
    map['type_title'] = _typeTitle;
    return map;
  }
}

class DeviceIcon {
  DeviceIcon({
    dynamic id,
    dynamic userId,
    String? type,
    dynamic order,
    dynamic width,
    dynamic height,
    String? path,
    dynamic byStatus,
  }) {
    _id = id;
    _userId = userId;
    _type = type;
    _order = order;
    _width = width;
    _height = height;
    _path = path;
    _byStatus = byStatus;
  }

  DeviceIcon.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['user_id'];
    _type = json['type'];
    _order = json['order'];
    _width = json['width'];
    _height = json['height'];
    _path = json['path'];
    _byStatus = json['by_status'];
  }
  dynamic _id;
  dynamic _userId;
  String? _type;
  dynamic _order;
  dynamic _width;
  dynamic _height;
  String? _path;
  dynamic _byStatus;

  dynamic get id => _id;
  dynamic get userId => _userId;
  String? get type => _type;
  dynamic get order => _order;
  dynamic get width => _width;
  dynamic get height => _height;
  String? get path => _path;
  dynamic get byStatus => _byStatus;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['type'] = _type;
    map['order'] = _order;
    map['width'] = _width;
    map['height'] = _height;
    map['path'] = _path;
    map['by_status'] = _byStatus;
    return map;
  }
}

class DriverData {
  DriverData({
    dynamic id,
    dynamic userId,
    dynamic deviceId,
    dynamic devicePort,
    dynamic name,
    dynamic rfid,
    dynamic phone,
    dynamic email,
    dynamic description,
    dynamic createdAt,
    dynamic updatedAt,
    DeviceData? device,
    String? photo, // Campo para foto do motorista
  }) {
    _id = id;
    _userId = userId;
    _deviceId = deviceId;
    _devicePort = devicePort;
    _name = name;
    _rfid = rfid;
    _phone = phone;
    _email = email;
    _description = description;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _device = device;
    _photo = photo;
  }

  DriverData.fromJson(dynamic json) {
    _id = json['id'];
    _userId = json['user_id'];
    _deviceId = json['device_id'];
    _devicePort = json['device_port'];
    _name = json['name'];
    _rfid = json['rfid'];
    _phone = json['phone'];
    _email = json['email'];
    _description = json['description'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _photo = json['photo'] ?? json['photo_url'] ?? json['image'] ?? json['image_url'];
    // Processar objeto 'device' aninhado se disponível
    if (json['device'] != null) {
      _device = DeviceData.fromJson(json['device']);
    }
  }
  dynamic _id;
  dynamic _userId;
  dynamic _deviceId;
  dynamic _devicePort;
  dynamic _name;
  dynamic _rfid;
  dynamic _phone;
  dynamic _email;
  dynamic _description;
  dynamic _createdAt;
  dynamic _updatedAt;
  DeviceData? _device;
  String? _photo;

  dynamic get id => _id;
  dynamic get userId => _userId;
  dynamic get deviceId => _deviceId;
  dynamic get devicePort => _devicePort;
  dynamic get name => _name;
  dynamic get rfid => _rfid;
  dynamic get phone => _phone;
  dynamic get email => _email;
  dynamic get description => _description;
  dynamic get createdAt => _createdAt;
  dynamic get updatedAt => _updatedAt;
  DeviceData? get device => _device;
  String? get photo => _photo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['device_id'] = _deviceId;
    map['device_port'] = _devicePort;
    map['name'] = _name;
    map['rfid'] = _rfid;
    map['phone'] = _phone;
    map['email'] = _email;
    map['description'] = _description;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_photo != null) map['photo'] = _photo;
    if (_device != null) {
      map['device'] = _device!.toJson();
    }
    return map;
  }
}

class Traccar {
  Traccar({
    dynamic id,
    String? name,
    String? uniqueId,
    dynamic latestPositionId,
    dynamic lastValidLatitude,
    dynamic lastValidLongitude,
    String? other,
    String? speed,
    String? time,
    String? deviceTime,
    String? serverTime,
    dynamic ackTime,
    dynamic altitude,
    dynamic course,
    dynamic power,
    dynamic address,
    String? protocol,
    String? latestPositions,
    String? movedAt,
    String? stopedAt,
    String? engineOnAt,
    String? engineOffAt,
    String? engineChangedAt,
    dynamic databaseId,
  }) {
    _id = id;
    _name = name;
    _uniqueId = uniqueId;
    _latestPositionId = latestPositionId;
    _lastValidLatitude = lastValidLatitude;
    _lastValidLongitude = lastValidLongitude;
    _other = other;
    _speed = speed;
    _time = time;
    _deviceTime = deviceTime;
    _serverTime = serverTime;
    _ackTime = ackTime;
    _altitude = altitude;
    _course = course;
    _power = power;
    _address = address;
    _protocol = protocol;
    _latestPositions = latestPositions;
    _movedAt = movedAt;
    _stopedAt = stopedAt;
    _engineOnAt = engineOnAt;
    _engineOffAt = engineOffAt;
    _engineChangedAt = engineChangedAt;
    _databaseId = databaseId;
  }

  Traccar.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _uniqueId = json['uniqueId'];
    _latestPositionId = json['latestPosition_id'];
    _lastValidLatitude = json['lastValidLatitude'];
    _lastValidLongitude = json['lastValidLongitude'];
    _other = json['other'];
    _speed = json['speed'];
    _time = json['time'];
    _deviceTime = json['device_time'];
    _serverTime = json['server_time'];
    _ackTime = json['ack_time'];
    _altitude = json['altitude'];
    _course = json['course'];
    _power = json['power'];
    _address = json['address'];
    _protocol = json['protocol'];
    _latestPositions = json['latest_positions'];
    _movedAt = json['moved_at'];
    _stopedAt = json['stoped_at'];
    _engineOnAt = json['engine_on_at'];
    _engineOffAt = json['engine_off_at'];
    _engineChangedAt = json['engine_changed_at'];
    _databaseId = json['database_id'];
  }
  dynamic _id;
  String? _name;
  String? _uniqueId;
  dynamic _latestPositionId;
  dynamic _lastValidLatitude;
  dynamic _lastValidLongitude;
  String? _other;
  String? _speed;
  String? _time;
  String? _deviceTime;
  String? _serverTime;
  dynamic _ackTime;
  dynamic _altitude;
  dynamic _course;
  dynamic _power;
  dynamic _address;
  String? _protocol;
  String? _latestPositions;
  String? _movedAt;
  String? _stopedAt;
  String? _engineOnAt;
  String? _engineOffAt;
  String? _engineChangedAt;
  dynamic _databaseId;
  Traccar copyWith({
    dynamic id,
    String? name,
    String? uniqueId,
    dynamic latestPositionId,
    dynamic lastValidLatitude,
    dynamic lastValidLongitude,
    String? other,
    String? speed,
    String? time,
    String? deviceTime,
    String? serverTime,
    dynamic ackTime,
    dynamic altitude,
    dynamic course,
    dynamic power,
    dynamic address,
    String? protocol,
    String? latestPositions,
    String? movedAt,
    String? stopedAt,
    String? engineOnAt,
    String? engineOffAt,
    String? engineChangedAt,
    dynamic databaseId,
  }) =>
      Traccar(
        id: id ?? _id,
        name: name ?? _name,
        uniqueId: uniqueId ?? _uniqueId,
        latestPositionId: latestPositionId ?? _latestPositionId,
        lastValidLatitude: lastValidLatitude ?? _lastValidLatitude,
        lastValidLongitude: lastValidLongitude ?? _lastValidLongitude,
        other: other ?? _other,
        speed: speed ?? _speed,
        time: time ?? _time,
        deviceTime: deviceTime ?? _deviceTime,
        serverTime: serverTime ?? _serverTime,
        ackTime: ackTime ?? _ackTime,
        altitude: altitude ?? _altitude,
        course: course ?? _course,
        power: power ?? _power,
        address: address ?? _address,
        protocol: protocol ?? _protocol,
        latestPositions: latestPositions ?? _latestPositions,
        movedAt: movedAt ?? _movedAt,
        stopedAt: stopedAt ?? _stopedAt,
        engineOnAt: engineOnAt ?? _engineOnAt,
        engineOffAt: engineOffAt ?? _engineOffAt,
        engineChangedAt: engineChangedAt ?? _engineChangedAt,
        databaseId: databaseId ?? _databaseId,
      );
  dynamic get id => _id;
  String? get name => _name;
  String? get uniqueId => _uniqueId;
  dynamic get latestPositionId => _latestPositionId;
  dynamic get lastValidLatitude => _lastValidLatitude;
  dynamic get lastValidLongitude => _lastValidLongitude;
  String? get other => _other;
  String? get speed => _speed;
  String? get time => _time;
  String? get deviceTime => _deviceTime;
  String? get serverTime => _serverTime;
  dynamic get ackTime => _ackTime;
  dynamic get altitude => _altitude;
  dynamic get course => _course;
  dynamic get power => _power;
  dynamic get address => _address;
  String? get protocol => _protocol;
  String? get latestPositions => _latestPositions;
  String? get movedAt => _movedAt;
  String? get stopedAt => _stopedAt;
  String? get engineOnAt => _engineOnAt;
  String? get engineOffAt => _engineOffAt;
  String? get engineChangedAt => _engineChangedAt;
  dynamic get databaseId => _databaseId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['uniqueId'] = _uniqueId;
    map['latestPosition_id'] = _latestPositionId;
    map['lastValidLatitude'] = _lastValidLatitude;
    map['lastValidLongitude'] = _lastValidLongitude;
    map['other'] = _other;
    map['speed'] = _speed;
    map['time'] = _time;
    map['device_time'] = _deviceTime;
    map['server_time'] = _serverTime;
    map['ack_time'] = _ackTime;
    map['altitude'] = _altitude;
    map['course'] = _course;
    map['power'] = _power;
    map['address'] = _address;
    map['protocol'] = _protocol;
    map['latest_positions'] = _latestPositions;
    map['moved_at'] = _movedAt;
    map['stoped_at'] = _stopedAt;
    map['engine_on_at'] = _engineOnAt;
    map['engine_off_at'] = _engineOffAt;
    map['engine_changed_at'] = _engineChangedAt;
    map['database_id'] = _databaseId;
    return map;
  }
}
