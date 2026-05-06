class DeviceHealthData {
  final int deviceId;
  final String deviceName;
  final String? deviceModel;
  final String imei;
  final String? simNumber;
  final String? plateNumber;
  
  // Status
  final bool isOnline;
  final String statusClass; // 'success', 'warning', 'danger'
  final String statusText; // 'Online', 'Offline', 'Online (GPS Fraco)'
  
  // Sinais
  final int gpsSignal; // Número de satélites GPS (0-20+)
  final int gsmSignal; // Sinal GSM/RSSI (0-31)
  final String signalQuality; // 'excellent', 'good', 'fair', 'poor'
  
  // Bateria e Temperatura
  final int? batteryLevel; // 0-100%
  final double? temperature; // Temperatura em °C
  
  // Estado do Veículo
  final bool? ignition; // true = ligada, false = desligada
  final bool? motion; // true = movendo, false = parado
  final bool? validPosition; // true = posição válida
  
  // Voltagem e Energia
  final double? powerVoltage; // Voltagem em V
  final bool? charge; // true = carregando
  
  // Quilometragem
  final double? odometer; // Odômetro em km
  final double? engineHours; // Horas motor
  final double? totalDistance; // Distância total em km
  final String? stopDuration; // Tempo parado
  final double? speed; // Velocidade em km/h
  final String? address; // Endereço atual

  // GPS
  final double? accuracy; // Precisão em metros (0 = máxima)
  
  // Status Adicional
  final bool? blocked; // true = bloqueado
  final double uptimePercentage; // Porcentagem de uptime (0-100)
  final int alertsCount; // Quantidade de alertas nas últimas 24h
  
  // Timestamps
  final DateTime? lastUpdate; // Última atualização
  
  // Auto-Reset
  final AutoResetInfo? lastReset;
  
  // Âncora Ativa
  final bool hasActiveAnchor;

  DeviceHealthData({
    required this.deviceId,
    required this.deviceName,
    this.deviceModel,
    required this.imei,
    this.simNumber,
    this.plateNumber,
    required this.isOnline,
    required this.statusClass,
    required this.statusText,
    required this.gpsSignal,
    required this.gsmSignal,
    required this.signalQuality,
    this.batteryLevel,
    this.temperature,
    this.ignition,
    this.motion,
    this.validPosition,
    this.powerVoltage,
    this.charge,
    this.odometer,
    this.engineHours,
    this.totalDistance,
    this.stopDuration,
    this.speed,
    this.address,
    this.accuracy,
    this.blocked,
    required this.uptimePercentage,
    required this.alertsCount,
    this.lastUpdate,
    this.lastReset,
    required this.hasActiveAnchor,
  });

  // Helper para converter valores para double (suporta int, double e string)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  factory DeviceHealthData.fromJson(Map<String, dynamic> json) {
    return DeviceHealthData(
      deviceId: json['device_id'] ?? json['id'] ?? 0,
      deviceName: json['device_name'] ?? json['name'] ?? '',
      deviceModel: json['device_model'] ?? json['model'],
      imei: json['imei'] ?? '',
      simNumber: json['sim_number'] ?? json['simNumber'],
      plateNumber: json['plate_number'] ?? json['plateNumber'],
      isOnline: json['is_online'] ?? false,
      statusClass: json['status_class'] ?? 'default',
      statusText: json['status_text'] ?? 'Desconhecido',
      gpsSignal: json['gps_signal'] ?? json['gpsSignal'] ?? 0,
      gsmSignal: json['gsm_signal'] ?? json['gsmSignal'] ?? 0,
      signalQuality: json['signal_quality'] ?? json['signalQuality'] ?? 'poor',
      batteryLevel: json['battery_level'] ?? json['batteryLevel'],
      temperature: _parseDouble(json['temperature']),
      ignition: json['ignition'] == 'true' || json['ignition'] == true || json['ignition'] == 1,
      motion: json['motion'] == 'true' || json['motion'] == true || json['motion'] == 1,
      validPosition: json['valid_position'] == 'true' || json['valid_position'] == true || json['validPosition'] == true,
      powerVoltage: _parseDouble(json['power_voltage'] ?? json['powerVoltage']),
      charge: json['charge'] == 'true' || json['charge'] == true || json['charge'] == 1,
      odometer: _parseDouble(json['odometer']),
      engineHours: _parseDouble(json['engine_hours'] ?? json['engineHours']),
      totalDistance: _parseDouble(json['total_distance'] ?? json['totalDistance']),
      stopDuration: json['stop_duration'] ?? json['stopDuration'],
      speed: _parseDouble(json['speed']),
      address: json['address'],
      accuracy: _parseDouble(json['accuracy']),
      blocked: json['blocked'] == 'true' || json['blocked'] == true || json['blocked'] == 1,
      uptimePercentage: (json['uptime_percentage'] ?? json['uptimePercentage'] ?? 0).toDouble(),
      alertsCount: json['alerts_count'] ?? json['alertsCount'] ?? 0,
      lastUpdate: json['last_update'] != null 
          ? DateTime.tryParse(json['last_update']) 
          : (json['lastUpdate'] != null ? DateTime.tryParse(json['lastUpdate']) : null),
      lastReset: json['last_reset'] != null 
          ? AutoResetInfo.fromJson(json['last_reset']) 
          : (json['lastReset'] != null ? AutoResetInfo.fromJson(json['lastReset']) : null),
      hasActiveAnchor: json['has_active_anchor'] ?? json['hasActiveAnchor'] ?? false,
    );
  }
}

class AutoResetInfo {
  final String time; // Formato: 'dd/MM HH:mm'
  final String status; // 'Sucesso' ou 'Falha'
  final String command;

  AutoResetInfo({
    required this.time,
    required this.status,
    required this.command,
  });

  factory AutoResetInfo.fromJson(Map<String, dynamic> json) {
    return AutoResetInfo(
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      command: json['command'] ?? '',
    );
  }
}

class HealthStats {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int poorSignalDevices;
  final int lowBatteryDevices;
  final int recentAlerts;
  final double uptimeAverage;
  final int ignitionOnDevices;
  final int motionDevices;
  final int validPositionDevices;
  final int highTemperatureDevices;
  final int chargingDevices;
  final int activeAnchors;

  HealthStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.poorSignalDevices,
    required this.lowBatteryDevices,
    required this.recentAlerts,
    required this.uptimeAverage,
    required this.ignitionOnDevices,
    required this.motionDevices,
    required this.validPositionDevices,
    required this.highTemperatureDevices,
    required this.chargingDevices,
    required this.activeAnchors,
  });

  factory HealthStats.fromJson(Map<String, dynamic> json) {
    return HealthStats(
      totalDevices: json['total_devices'] ?? json['totalDevices'] ?? 0,
      onlineDevices: json['online_devices'] ?? json['onlineDevices'] ?? 0,
      offlineDevices: json['offline_devices'] ?? json['offlineDevices'] ?? 0,
      poorSignalDevices: json['poor_signal_devices'] ?? json['poorSignalDevices'] ?? 0,
      lowBatteryDevices: json['low_battery_devices'] ?? json['lowBatteryDevices'] ?? 0,
      recentAlerts: json['recent_alerts'] ?? json['recentAlerts'] ?? 0,
      uptimeAverage: (json['uptime_average'] ?? json['uptimeAverage'] ?? 0).toDouble(),
      ignitionOnDevices: json['ignition_on_devices'] ?? json['ignitionOnDevices'] ?? 0,
      motionDevices: json['motion_devices'] ?? json['motionDevices'] ?? 0,
      validPositionDevices: json['valid_position_devices'] ?? json['validPositionDevices'] ?? 0,
      highTemperatureDevices: json['high_temperature_devices'] ?? json['highTemperatureDevices'] ?? 0,
      chargingDevices: json['charging_devices'] ?? json['chargingDevices'] ?? 0,
      activeAnchors: json['active_anchors'] ?? json['activeAnchors'] ?? 0,
    );
  }
}
