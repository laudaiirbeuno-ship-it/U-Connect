/// Model para cliente admin
/// Baseado nas APIs: /api/admin/client, /api/admin/clients

class ClientResponse {
  final int? status;
  final ClientItem? item;

  ClientResponse({
    this.status,
    this.item,
  });

  ClientResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        item = json['item'] != null
            ? ClientItem.fromJson(json['item'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'item': item?.toJson(),
    };
  }
}

class ClientItem {
  final int? id;
  final int? active;
  final int? groupId;
  final int? managerId;
  final int? billingPlanId;
  final int? mapId;
  final int? devicesLimit;
  final String? email;
  final String? phoneNumber;
  final String? subscriptionExpiration;
  final String? logedAt;
  final String? apiHashExpire;
  final List<String> availableMaps;
  final String? smsGatewayAppDate;
  final Map<String, dynamic>? smsGatewayParams;
  final Map<String, dynamic>? ungroupedOpen;
  final int? weekStartDay;
  final int? topToolbarOpen;
  final List<dynamic>? mapControls;
  final String? createdAt;
  final String? updatedAt;
  final String? unitOfAltitude;
  final String? lang;
  final String? unitOfDistance;
  final String? unitOfCapacity;
  final String? durationFormat;
  final int? timezoneId;
  final int? smsGateway;
  final String? smsGatewayUrl;
  final Map<String, dynamic>? settings;
  final dynamic loginPeriods;
  final String? emailVerifiedAt;
  final int? clientId;
  final int? companyId;
  final int? onlyOneSession;
  final int? subusersCount;
  final int? devicesCount;
  final dynamic manager;
  final dynamic billingPlan;

  ClientItem({
    this.id,
    this.active,
    this.groupId,
    this.managerId,
    this.billingPlanId,
    this.mapId,
    this.devicesLimit,
    this.email,
    this.phoneNumber,
    this.subscriptionExpiration,
    this.logedAt,
    this.apiHashExpire,
    required this.availableMaps,
    this.smsGatewayAppDate,
    this.smsGatewayParams,
    this.ungroupedOpen,
    this.weekStartDay,
    this.topToolbarOpen,
    this.mapControls,
    this.createdAt,
    this.updatedAt,
    this.unitOfAltitude,
    this.lang,
    this.unitOfDistance,
    this.unitOfCapacity,
    this.durationFormat,
    this.timezoneId,
    this.smsGateway,
    this.smsGatewayUrl,
    this.settings,
    this.loginPeriods,
    this.emailVerifiedAt,
    this.clientId,
    this.companyId,
    this.onlyOneSession,
    this.subusersCount,
    this.devicesCount,
    this.manager,
    this.billingPlan,
  });

  ClientItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        active = json['active'] is int ? json['active'] : (json['active'] != null ? int.tryParse(json['active'].toString()) : null),
        groupId = json['group_id'] is int ? json['group_id'] : (json['group_id'] != null ? int.tryParse(json['group_id'].toString()) : null),
        managerId = json['manager_id'] is int ? json['manager_id'] : (json['manager_id'] != null ? int.tryParse(json['manager_id'].toString()) : null),
        billingPlanId = json['billing_plan_id'] is int ? json['billing_plan_id'] : (json['billing_plan_id'] != null ? int.tryParse(json['billing_plan_id'].toString()) : null),
        mapId = json['map_id'] is int ? json['map_id'] : (json['map_id'] != null ? int.tryParse(json['map_id'].toString()) : null),
        devicesLimit = json['devices_limit'] is int ? json['devices_limit'] : (json['devices_limit'] != null ? int.tryParse(json['devices_limit'].toString()) : null),
        email = json['email']?.toString(),
        phoneNumber = json['phone_number']?.toString(),
        subscriptionExpiration = json['subscription_expiration']?.toString(),
        logedAt = json['loged_at']?.toString(),
        apiHashExpire = json['api_hash_expire']?.toString(),
        availableMaps = (json['available_maps'] as List<dynamic>?)
                ?.map((item) => item.toString())
                .toList() ??
            [],
        smsGatewayAppDate = json['sms_gateway_app_date']?.toString(),
        smsGatewayParams = json['sms_gateway_params'] as Map<String, dynamic>?,
        ungroupedOpen = json['ungrouped_open'] as Map<String, dynamic>?,
        weekStartDay = json['week_start_day'] is int ? json['week_start_day'] : (json['week_start_day'] != null ? int.tryParse(json['week_start_day'].toString()) : null),
        topToolbarOpen = json['top_toolbar_open'] is int ? json['top_toolbar_open'] : (json['top_toolbar_open'] != null ? int.tryParse(json['top_toolbar_open'].toString()) : null),
        mapControls = json['map_controls'] as List<dynamic>?,
        createdAt = json['created_at']?.toString(),
        updatedAt = json['updated_at']?.toString(),
        unitOfAltitude = json['unit_of_altitude']?.toString(),
        lang = json['lang']?.toString(),
        unitOfDistance = json['unit_of_distance']?.toString(),
        unitOfCapacity = json['unit_of_capacity']?.toString(),
        durationFormat = json['duration_format']?.toString(),
        timezoneId = json['timezone_id'] is int ? json['timezone_id'] : (json['timezone_id'] != null ? int.tryParse(json['timezone_id'].toString()) : null),
        smsGateway = json['sms_gateway'] is int ? json['sms_gateway'] : (json['sms_gateway'] != null ? int.tryParse(json['sms_gateway'].toString()) : null),
        smsGatewayUrl = json['sms_gateway_url']?.toString(),
        settings = json['settings'] as Map<String, dynamic>?,
        loginPeriods = json['login_periods'],
        emailVerifiedAt = json['email_verified_at']?.toString(),
        clientId = json['client_id'] is int ? json['client_id'] : (json['client_id'] != null ? int.tryParse(json['client_id'].toString()) : null),
        companyId = json['company_id'] is int ? json['company_id'] : (json['company_id'] != null ? int.tryParse(json['company_id'].toString()) : null),
        onlyOneSession = json['only_one_session'] is int ? json['only_one_session'] : (json['only_one_session'] != null ? int.tryParse(json['only_one_session'].toString()) : null),
        subusersCount = json['subusers_count'] is int ? json['subusers_count'] : (json['subusers_count'] != null ? int.tryParse(json['subusers_count'].toString()) : null),
        devicesCount = json['devices_count'] is int ? json['devices_count'] : (json['devices_count'] != null ? int.tryParse(json['devices_count'].toString()) : null),
        manager = json['manager'],
        billingPlan = json['billing_plan'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active': active,
      'group_id': groupId,
      'manager_id': managerId,
      'billing_plan_id': billingPlanId,
      'map_id': mapId,
      'devices_limit': devicesLimit,
      'email': email,
      'phone_number': phoneNumber,
      'subscription_expiration': subscriptionExpiration,
      'loged_at': logedAt,
      'api_hash_expire': apiHashExpire,
      'available_maps': availableMaps,
      'sms_gateway_app_date': smsGatewayAppDate,
      'sms_gateway_params': smsGatewayParams,
      'ungrouped_open': ungroupedOpen,
      'week_start_day': weekStartDay,
      'top_toolbar_open': topToolbarOpen,
      'map_controls': mapControls,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'unit_of_altitude': unitOfAltitude,
      'lang': lang,
      'unit_of_distance': unitOfDistance,
      'unit_of_capacity': unitOfCapacity,
      'duration_format': durationFormat,
      'timezone_id': timezoneId,
      'sms_gateway': smsGateway,
      'sms_gateway_url': smsGatewayUrl,
      'settings': settings,
      'login_periods': loginPeriods,
      'email_verified_at': emailVerifiedAt,
      'client_id': clientId,
      'company_id': companyId,
      'only_one_session': onlyOneSession,
      'subusers_count': subusersCount,
      'devices_count': devicesCount,
      'manager': manager,
      'billing_plan': billingPlan,
    };
  }

  bool get isActive => active == 1;
}

class ClientListResponse {
  final int currentPage;
  final List<ClientItem> data;
  final String? firstPageUrl;
  final int from;
  final int lastPage;
  final String? lastPageUrl;
  final List<ClientPaginationLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  ClientListResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    required this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  ClientListResponse.fromJson(Map<String, dynamic> json)
      : currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) ?? 1 : 1),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => ClientItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        firstPageUrl = json['first_page_url']?.toString(),
        from = json['from'] is int ? json['from'] : (json['from'] != null ? int.tryParse(json['from'].toString()) ?? 0 : 0),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) ?? 1 : 1),
        lastPageUrl = json['last_page_url']?.toString(),
        links = (json['links'] as List<dynamic>?)
                ?.map((item) => ClientPaginationLink.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageUrl = json['next_page_url']?.toString(),
        path = json['path']?.toString() ?? '',
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) ?? 10 : 10),
        prevPageUrl = json['prev_page_url']?.toString(),
        to = json['to'] is int ? json['to'] : (json['to'] != null ? int.tryParse(json['to'].toString()) ?? 0 : 0),
        total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) ?? 0 : 0);

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((item) => item.toJson()).toList(),
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links.map((item) => item.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
    };
  }

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get hasPrevPage => prevPageUrl != null && prevPageUrl!.isNotEmpty;
}

class ClientPaginationLink {
  final String? url;
  final String? label;
  final bool active;

  ClientPaginationLink({
    this.url,
    this.label,
    required this.active,
  });

  ClientPaginationLink.fromJson(Map<String, dynamic> json)
      : url = json['url']?.toString(),
        label = json['label']?.toString(),
        active = json['active'] == true || json['active'] == 'true' || json['active'] == 1;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}

class ClientDevice {
  final int? id;
  final String? name;

  ClientDevice({
    this.id,
    this.name,
  });

  ClientDevice.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        name = json['name']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ClientDeviceResponse {
  final int? status;
  final List<ClientDevice> data;
  final ClientDevicePagination pagination;

  ClientDeviceResponse({
    this.status,
    required this.data,
    required this.pagination,
  });

  ClientDeviceResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => ClientDevice.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['pagination'] != null
            ? ClientDevicePagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : ClientDevicePagination(
                total: 0,
                perPage: 0,
                currentPage: 0,
                lastPage: 0,
              );

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class ClientDevicePagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;

  ClientDevicePagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  ClientDevicePagination.fromJson(Map<String, dynamic> json)
      : total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) ?? 0 : 0),
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) ?? 0 : 0),
        currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) ?? 0 : 0),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) ?? 0 : 0),
        nextPageUrl = json['next_page_url']?.toString(),
        prevPageUrl = json['prev_page_url']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
    };
  }

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get hasPrevPage => prevPageUrl != null && prevPageUrl!.isNotEmpty;
}

class UserClientData {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? birthDate;
  final String? personalCode;
  final String? address;
  final String? comment;

  UserClientData({
    this.id,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.personalCode,
    this.address,
    this.comment,
  });

  UserClientData.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        firstName = json['first_name']?.toString(),
        lastName = json['last_name']?.toString(),
        birthDate = json['birth_date']?.toString(),
        personalCode = json['personal_code']?.toString(),
        address = json['address']?.toString(),
        comment = json['comment']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'personal_code': personalCode,
      'address': address,
      'comment': comment,
    };
  }
}

class UserClientResponse {
  final UserClientData? data;

  UserClientResponse({
    this.data,
  });

  UserClientResponse.fromJson(Map<String, dynamic> json)
      : data = json['data'] != null
            ? UserClientData.fromJson(json['data'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
    };
  }
}

/// Model para criar/atualizar cliente
class CreateClientRequest {
  final bool? active;
  final String? email;
  final String? phoneNumber;
  final int? managerId;
  final int? billingPlanId;
  final Map<String, Map<String, bool>>? perms;
  final List<int>? objects;
  final bool? accountCreated;
  final bool? emailVerification;
  final bool? passwordGenerate;
  final String? password;
  final String? passwordConfirmation;
  final List<int>? availableMaps;
  final int? groupId;
  final bool? enableExpirationDate;
  final String? expirationDate;
  final bool? enableDevicesLimit;
  final int? devicesLimit;
  final int? id; // Para atualização

  CreateClientRequest({
    this.active,
    this.email,
    this.phoneNumber,
    this.managerId,
    this.billingPlanId,
    this.perms,
    this.objects,
    this.accountCreated,
    this.emailVerification,
    this.passwordGenerate,
    this.password,
    this.passwordConfirmation,
    this.availableMaps,
    this.groupId,
    this.enableExpirationDate,
    this.expirationDate,
    this.enableDevicesLimit,
    this.devicesLimit,
    this.id,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    // Campos obrigatórios sempre enviados
    if (email != null) map['email'] = email;
    if (availableMaps != null && availableMaps!.isNotEmpty) {
      map['available_maps'] = availableMaps;
    } else {
      map['available_maps'] = [2]; // Mapa padrão obrigatório
    }
    if (groupId != null) {
      map['group_id'] = groupId;
    } else {
      map['group_id'] = 1; // Group ID padrão obrigatório
    }
    
    // Campos opcionais
    if (id != null) map['id'] = id;
    if (active != null) map['active'] = active;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) map['phone_number'] = phoneNumber;
    if (managerId != null) map['manager_id'] = managerId;
    if (billingPlanId != null) map['billing_plan_id'] = billingPlanId;
    if (perms != null) map['perms'] = perms;
    if (objects != null && objects!.isNotEmpty) map['objects'] = objects;
    if (accountCreated != null) map['account_created'] = accountCreated;
    if (emailVerification != null) map['email_verification'] = emailVerification;
    if (passwordGenerate != null) map['password_generate'] = passwordGenerate;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (passwordConfirmation != null && passwordConfirmation!.isNotEmpty) {
      map['password_confirmation'] = passwordConfirmation;
    }
    if (enableExpirationDate != null) map['enable_expiration_date'] = enableExpirationDate;
    if (expirationDate != null && expirationDate!.isNotEmpty) map['expiration_date'] = expirationDate;
    if (enableDevicesLimit != null) map['enable_devices_limit'] = enableDevicesLimit;
    if (devicesLimit != null) map['devices_limit'] = devicesLimit;
    return map;
  }
}

/// Model para atualizar status do cliente
class UpdateClientStatusRequest {
  final int id;
  final String email;
  final bool status;

  UpdateClientStatusRequest({
    required this.id,
    required this.email,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'status': status,
    };
  }
}

