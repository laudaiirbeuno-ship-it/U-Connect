/// Model para serviços de dispositivos
/// Baseado na API: https://gpswox.stoplight.io/docs/tracking-software/mgrl8cf74jwxy-get-services

class Service {
  final int? id;
  final int? userId;
  final int? deviceId;
  final String? name;
  final String? expirationBy;
  final int? interval;
  final String? lastService;
  final int? triggerEventLeft;
  final bool? renewAfterExpiration;
  final String? expires;
  final String? expiresDate;
  final int? remind;
  final int? remindDate;
  final bool? eventSent;
  final bool? expired;
  final String? email;
  final String? mobilePhone;
  final String? description;

  Service({
    this.id,
    this.userId,
    this.deviceId,
    this.name,
    this.expirationBy,
    this.interval,
    this.lastService,
    this.triggerEventLeft,
    this.renewAfterExpiration,
    this.expires,
    this.expiresDate,
    this.remind,
    this.remindDate,
    this.eventSent,
    this.expired,
    this.email,
    this.mobilePhone,
    this.description,
  });

  Service.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        userId = json['user_id'] is int ? json['user_id'] : (json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null),
        deviceId = json['device_id'] is int ? json['device_id'] : (json['device_id'] != null ? int.tryParse(json['device_id'].toString()) : null),
        name = json['name']?.toString(),
        expirationBy = json['expiration_by']?.toString(),
        interval = json['interval'] is int ? json['interval'] : (json['interval'] != null ? int.tryParse(json['interval'].toString()) : null),
        lastService = json['last_service']?.toString(),
        triggerEventLeft = json['trigger_event_left'] is int ? json['trigger_event_left'] : (json['trigger_event_left'] != null ? int.tryParse(json['trigger_event_left'].toString()) : null),
        renewAfterExpiration = json['renew_after_expiration'] is bool ? json['renew_after_expiration'] : (json['renew_after_expiration'] == 1 || json['renew_after_expiration'] == true),
        expires = json['expires']?.toString(),
        expiresDate = json['expires_date']?.toString(),
        remind = json['remind'] is int ? json['remind'] : (json['remind'] != null ? int.tryParse(json['remind'].toString()) : null),
        remindDate = json['remind_date'] is int ? json['remind_date'] : (json['remind_date'] != null ? int.tryParse(json['remind_date'].toString()) : null),
        eventSent = json['event_sent'] is bool ? json['event_sent'] : (json['event_sent'] == 1 || json['event_sent'] == true),
        expired = json['expired'] is bool ? json['expired'] : (json['expired'] == 1 || json['expired'] == true),
        email = json['email']?.toString(),
        mobilePhone = json['mobile_phone']?.toString(),
        description = json['description']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'name': name,
      'expiration_by': expirationBy,
      'interval': interval,
      'last_service': lastService,
      'trigger_event_left': triggerEventLeft,
      'renew_after_expiration': renewAfterExpiration,
      'expires': expires,
      'expires_date': expiresDate,
      'remind': remind,
      'remind_date': remindDate,
      'event_sent': eventSent,
      'expired': expired,
      'email': email,
      'mobile_phone': mobilePhone,
      'description': description,
    };
  }

  /// Verificar se o serviço está expirado
  bool get isExpired {
    if (expired == true) return true;
    if (expiresDate == null) return false;
    
    try {
      final expires = DateTime.parse(expiresDate!);
      return DateTime.now().isAfter(expires);
    } catch (e) {
      return false;
    }
  }

  /// Verificar se o serviço está próximo do vencimento
  bool get isExpiringSoon {
    if (expiresDate == null || isExpired) return false;
    
    try {
      final expires = DateTime.parse(expiresDate!);
      final daysUntilExpiration = expires.difference(DateTime.now()).inDays;
      return daysUntilExpiration <= (remind ?? 7) && daysUntilExpiration > 0;
    } catch (e) {
      return false;
    }
  }

  /// Obter data de expiração formatada
  String? get formattedExpiresDate {
    if (expiresDate == null) return null;
    
    try {
      final date = DateTime.parse(expiresDate!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return expiresDate;
    }
  }

  /// Obter data do último serviço formatada
  String? get formattedLastService {
    if (lastService == null) return null;
    
    try {
      final date = DateTime.parse(lastService!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return lastService;
    }
  }

  /// Obter status do serviço
  ServiceStatus get status {
    if (isExpired) return ServiceStatus.expired;
    if (isExpiringSoon) return ServiceStatus.expiringSoon;
    return ServiceStatus.active;
  }
}

enum ServiceStatus {
  active,
  expiringSoon,
  expired,
}

class ServicePagination {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String? url;

  ServicePagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
    this.url,
  });

  ServicePagination.fromJson(Map<String, dynamic> json)
      : total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) : null),
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) : null),
        currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) : null),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) : null),
        nextPageUrl = json['next_page_url']?.toString(),
        prevPageUrl = json['prev_page_url']?.toString(),
        url = json['url']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
      'url': url,
    };
  }
}

class ServiceResponse {
  final int? status;
  final List<Service> data;
  final ServicePagination? pagination;

  ServiceResponse({
    this.status,
    required this.data,
    this.pagination,
  });

  ServiceResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => Service.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['pagination'] != null
            ? ServicePagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : (json['total'] != null || json['current_page'] != null)
                ? ServicePagination.fromJson(json) // Se paginação está no nível raiz
                : null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

