class ReportModel {
  String? id;
  String? user_id;
  String? title;
  String? type;
  String? format;
  String? show_addresses;
  String? zones_instead;
  String? stops;
  String? speed_limit;
  String? daily;
  String? weekly;
  String? email;
  String? weekly_email_sent;
  String? daily_email_sent;
  List<int>? devices;
  List<int>? geofences;
  String? date_from;
  String? date_to;
  String? from_time;
  String? to_time;
  String? send_to_email;

  ReportModel({
    this.id,
    this.user_id,
    this.title,
    this.type,
    this.format,
    this.show_addresses,
    this.zones_instead,
    this.stops,
    this.speed_limit,
    this.daily,
    this.weekly,
    this.email,
    this.weekly_email_sent,
    this.daily_email_sent,
    this.devices,
    this.geofences,
    this.date_from,
    this.date_to,
    this.from_time,
    this.to_time,
    this.send_to_email,
  });

  ReportModel.fromJson(Map<String, dynamic> json) {
    id = json["id"]?.toString();
    user_id = json["user_id"]?.toString();
    title = json["title"]?.toString();
    type = json["type"]?.toString();
    format = json["format"]?.toString();
    show_addresses = json["show_addresses"]?.toString();
    zones_instead = json["zones_instead"]?.toString();
    stops = json["stops"]?.toString();
    speed_limit = json["speed_limit"]?.toString();
    daily = json["daily"]?.toString();
    weekly = json["weekly"]?.toString();
    email = json["email"]?.toString();
    weekly_email_sent = json["weekly_email_sent"]?.toString();
    daily_email_sent = json["daily_email_sent"]?.toString();
    
    if (json["devices"] != null) {
      if (json["devices"] is List) {
        devices = (json["devices"] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
    }
    
    if (json["geofences"] != null) {
      if (json["geofences"] is List) {
        geofences = (json["geofences"] as List).map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
    }
    
    date_from = json["date_from"]?.toString();
    date_to = json["date_to"]?.toString();
    from_time = json["from_time"]?.toString();
    to_time = json["to_time"]?.toString();
    send_to_email = json["send_to_email"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': user_id,
        'title': title,
        'type': type,
        'format': format,
        'show_addresses': show_addresses,
        'zones_instead': zones_instead,
        'stops': stops,
        'speed_limit': speed_limit,
        'daily': daily,
        'weekly': weekly,
        'email': email,
        'weekly_email_sent': weekly_email_sent,
        'daily_email_sent': daily_email_sent,
        'devices': devices,
        'geofences': geofences,
        'date_from': date_from,
        'date_to': date_to,
        'from_time': from_time,
        'to_time': to_time,
        'send_to_email': send_to_email,
      };
}

class ReportType {
  int? id;
  String? title;
  String? value;

  ReportType({
    this.id,
    this.title,
    this.value,
  });

  ReportType.fromJson(Map<String, dynamic> json) {
    // A API usa 'type' como ID, não 'id'
    if (json["type"] != null) {
      id = json["type"] is int ? json["type"] : int.tryParse(json["type"]?.toString() ?? '');
    } else if (json["id"] != null) {
      id = json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? '');
    }
    // A API usa 'name' como título, não 'title'
    title = json["name"]?.toString() ?? json["title"]?.toString();
    value = json["value"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'value': value,
      };
}

class ReportFormat {
  String? id;
  String? value;

  ReportFormat({
    this.id,
    this.value,
  });

  ReportFormat.fromJson(Map<String, dynamic> json) {
    id = json["id"]?.toString();
    value = json["value"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
      };
}

class ReportStop {
  int? id;
  String? value;

  ReportStop({
    this.id,
    this.value,
  });

  ReportStop.fromJson(Map<String, dynamic> json) {
    id = json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? '');
    value = json["value"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
      };
}

class ReportFilter {
  int? id;
  String? value;

  ReportFilter({
    this.id,
    this.value,
  });

  ReportFilter.fromJson(Map<String, dynamic> json) {
    id = json["id"] is int ? json["id"] : int.tryParse(json["id"]?.toString() ?? '');
    value = json["value"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
      };
}

class ReportsResponse {
  int? status;
  ReportsData? items;

  ReportsResponse({
    this.status,
    this.items,
  });

  ReportsResponse.fromJson(Map<String, dynamic> json) {
    status = json["status"] is int ? json["status"] : int.tryParse(json["status"]?.toString() ?? '');
    if (json["items"] != null) {
      items = ReportsData.fromJson(Map<String, dynamic>.from(json["items"]));
    }
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'items': items?.toJson(),
      };
}

class ReportsData {
  ReportsList? reports;
  List<ReportType>? types;
  List<ReportFormat>? formats;
  List<ReportStop>? stops;
  List<ReportFilter>? filters;

  ReportsData({
    this.reports,
    this.types,
    this.formats,
    this.stops,
    this.filters,
  });

  ReportsData.fromJson(Map<String, dynamic> json) {
    if (json["reports"] != null) {
      reports = ReportsList.fromJson(Map<String, dynamic>.from(json["reports"]));
    }
    
    if (json["types"] != null && json["types"] is List) {
      types = (json["types"] as List).map((e) => ReportType.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["formats"] != null && json["formats"] is List) {
      formats = (json["formats"] as List).map((e) => ReportFormat.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["stops"] != null && json["stops"] is List) {
      stops = (json["stops"] as List).map((e) => ReportStop.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["filters"] != null && json["filters"] is List) {
      filters = (json["filters"] as List).map((e) => ReportFilter.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Map<String, dynamic> toJson() => {
        'reports': reports?.toJson(),
        'types': types?.map((e) => e.toJson()).toList(),
        'formats': formats?.map((e) => e.toJson()).toList(),
        'stops': stops?.map((e) => e.toJson()).toList(),
        'filters': filters?.map((e) => e.toJson()).toList(),
      };
}

class ReportsList {
  int? total;
  int? per_page;
  int? current_page;
  int? last_page;
  String? next_page_url;
  String? prev_page_url;
  int? from;
  int? to;
  List<ReportModel>? data;
  String? url;

  ReportsList({
    this.total,
    this.per_page,
    this.current_page,
    this.last_page,
    this.next_page_url,
    this.prev_page_url,
    this.from,
    this.to,
    this.data,
    this.url,
  });

  ReportsList.fromJson(Map<String, dynamic> json) {
    total = json["total"] is int ? json["total"] : int.tryParse(json["total"]?.toString() ?? '');
    per_page = json["per_page"] is int ? json["per_page"] : int.tryParse(json["per_page"]?.toString() ?? '');
    current_page = json["current_page"] is int ? json["current_page"] : int.tryParse(json["current_page"]?.toString() ?? '');
    last_page = json["last_page"] is int ? json["last_page"] : int.tryParse(json["last_page"]?.toString() ?? '');
    next_page_url = json["next_page_url"]?.toString();
    prev_page_url = json["prev_page_url"]?.toString();
    from = json["from"] is int ? json["from"] : int.tryParse(json["from"]?.toString() ?? '');
    to = json["to"] is int ? json["to"] : int.tryParse(json["to"]?.toString() ?? '');
    url = json["url"]?.toString();
    
    if (json["data"] != null && json["data"] is List) {
      data = (json["data"] as List).map((e) => ReportModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'per_page': per_page,
        'current_page': current_page,
        'last_page': last_page,
        'next_page_url': next_page_url,
        'prev_page_url': prev_page_url,
        'from': from,
        'to': to,
        'data': data?.map((e) => e.toJson()).toList(),
        'url': url,
      };
}

class AddReportDataResponse {
  List<dynamic>? devices;
  List<dynamic>? geofences;
  List<ReportFormat>? formats;
  List<ReportStop>? stops;
  List<ReportFilter>? filters;
  List<ReportType>? types;
  ReportsList? reports;
  int? status;

  AddReportDataResponse({
    this.devices,
    this.geofences,
    this.formats,
    this.stops,
    this.filters,
    this.types,
    this.reports,
    this.status,
  });

  AddReportDataResponse.fromJson(Map<String, dynamic> json) {
    devices = json["devices"];
    geofences = json["geofences"];
    
    if (json["formats"] != null && json["formats"] is List) {
      formats = (json["formats"] as List).map((e) => ReportFormat.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["stops"] != null && json["stops"] is List) {
      stops = (json["stops"] as List).map((e) => ReportStop.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["filters"] != null && json["filters"] is List) {
      filters = (json["filters"] as List).map((e) => ReportFilter.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["types"] != null && json["types"] is List) {
      types = (json["types"] as List).map((e) => ReportType.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    
    if (json["reports"] != null) {
      reports = ReportsList.fromJson(Map<String, dynamic>.from(json["reports"]));
    }
    
    status = json["status"] is int ? json["status"] : int.tryParse(json["status"]?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {
        'devices': devices,
        'geofences': geofences,
        'formats': formats?.map((e) => e.toJson()).toList(),
        'stops': stops?.map((e) => e.toJson()).toList(),
        'filters': filters?.map((e) => e.toJson()).toList(),
        'types': types?.map((e) => e.toJson()).toList(),
        'reports': reports?.toJson(),
        'status': status,
      };
}

class GenerateReportResponse {
  int? status;
  String? url;

  GenerateReportResponse({
    this.status,
    this.url,
  });

  GenerateReportResponse.fromJson(Map<String, dynamic> json) {
    status = json["status"] is int ? json["status"] : int.tryParse(json["status"]?.toString() ?? '');
    url = json["url"]?.toString();
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'url': url,
      };
}

































