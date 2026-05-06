/// Modelos para API de Usuários
/// Baseado na documentação da API /api/get_users, /api/create_user, etc.

class UserListResponse {
  final int status;
  final UserListItems items;

  UserListResponse({
    required this.status,
    required this.items,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      status: json['status'] ?? 0,
      items: UserListItems.fromJson(json['items'] ?? {}),
    );
  }
}

class UserListItems {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;
  final List<UserItem> data;

  UserListItems({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
    required this.data,
  });

  factory UserListItems.fromJson(Map<String, dynamic> json) {
    List<UserItem> dataList = [];
    if (json['data'] != null && json['data'] is List) {
      dataList = (json['data'] as List)
          .map((item) => UserItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return UserListItems(
      total: json['total'] ?? 0,
      perPage: json['per_page'] ?? 30,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
      data: dataList,
    );
  }
}

class UserResponse {
  final int status;
  final String? message;
  final UserItem? item;

  UserResponse({
    required this.status,
    this.message,
    this.item,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      status: json['status'] ?? 0,
      message: json['message'],
      item: json['item'] != null
          ? UserItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserItem {
  final int id;
  final String email;
  final bool active;
  final int groupId;
  final int? devicesLimit;
  final String? subscriptionExpiration;
  final String? subscriptionExpirationFormatted;
  final int? managerId;
  final UserClient? client;
  final BillingPlan? billingPlan;
  final int? billingPlanId;
  final int? companyId;
  final String? phoneNumber;
  final UserAddress? address;
  final PaymentInfo? paymentInfo;
  final int? timezoneId;
  final String? lang;
  final String? createdAt;
  final String? createdAtFormatted;
  final String? updatedAt;

  UserItem({
    required this.id,
    required this.email,
    required this.active,
    required this.groupId,
    this.devicesLimit,
    this.subscriptionExpiration,
    this.subscriptionExpirationFormatted,
    this.managerId,
    this.client,
    this.billingPlan,
    this.billingPlanId,
    this.companyId,
    this.phoneNumber,
    this.address,
    this.paymentInfo,
    this.timezoneId,
    this.lang,
    this.createdAt,
    this.createdAtFormatted,
    this.updatedAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      active: json['active'] ?? true,
      groupId: json['group_id'] ?? 2,
      devicesLimit: json['devices_limit'],
      subscriptionExpiration: json['subscription_expiration'],
      subscriptionExpirationFormatted: json['subscription_expiration_formatted'],
      managerId: json['manager_id'],
      client: json['client'] != null
          ? UserClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      billingPlan: json['billing_plan'] != null
          ? BillingPlan.fromJson(json['billing_plan'] as Map<String, dynamic>)
          : null,
      billingPlanId: json['billing_plan_id'],
      companyId: json['company_id'],
      phoneNumber: json['phone_number'],
      address: json['address'] != null
          ? UserAddress.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'] as Map<String, dynamic>)
          : null,
      timezoneId: json['timezone_id'],
      lang: json['lang'],
      createdAt: json['created_at'],
      createdAtFormatted: json['created_at_formatted'],
      updatedAt: json['updated_at'],
    );
  }
}

class UserClient {
  final int id;
  final String firstName;
  final String lastName;
  final String name;
  final String? personalCode;
  final String? birthDate;
  final String? whatsapp;
  final String? address;
  final String? comment;

  UserClient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    this.personalCode,
    this.birthDate,
    this.whatsapp,
    this.address,
    this.comment,
  });

  factory UserClient.fromJson(Map<String, dynamic> json) {
    return UserClient(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      name: json['name'] ?? '',
      personalCode: json['personal_code'],
      birthDate: json['birth_date'],
      whatsapp: json['whatsapp'],
      address: json['address'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'personal_code': personalCode,
      'birth_date': birthDate,
      'whatsapp': whatsapp,
      'address': address,
      'comment': comment,
    };
  }
}

class BillingPlan {
  final int id;
  final String name;

  BillingPlan({
    required this.id,
    required this.name,
  });

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class UserAddress {
  final int id;
  final String? zipCode;
  final String? street;
  final String? number;
  final String? district;
  final String? city;
  final String? state;
  final String? complement;

  UserAddress({
    required this.id,
    this.zipCode,
    this.street,
    this.number,
    this.district,
    this.city,
    this.state,
    this.complement,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] ?? 0,
      zipCode: json['zip_code'],
      street: json['street'],
      number: json['number'],
      district: json['district'],
      city: json['city'],
      state: json['state'],
      complement: json['complement'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zip_code': zipCode,
      'street': street,
      'number': number,
      'district': district,
      'city': city,
      'state': state,
      'complement': complement,
    };
  }
}

class PaymentInfo {
  final int id;
  final double? monthlyFee;
  final int? paymentDay;
  final String? contractSignDate;
  final String? contractExpiryDate;

  PaymentInfo({
    required this.id,
    this.monthlyFee,
    this.paymentDay,
    this.contractSignDate,
    this.contractExpiryDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] ?? 0,
      monthlyFee: json['monthly_fee'] != null
          ? (json['monthly_fee'] is int
              ? (json['monthly_fee'] as int).toDouble()
              : json['monthly_fee'] as double)
          : null,
      paymentDay: json['payment_day'],
      contractSignDate: json['contract_sign_date'],
      contractExpiryDate: json['contract_expiry_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_fee': monthlyFee,
      'payment_day': paymentDay,
      'contract_sign_date': contractSignDate,
      'contract_expiry_date': contractExpiryDate,
    };
  }
}

/// Request para criar usuário
class CreateUserRequest {
  final String email;
  final String password;
  final int? groupId;
  final bool? active;
  final int? devicesLimit;
  final String? subscriptionExpiration;
  final String? phoneNumber;
  final int? billingPlanId;
  final int? companyId;
  final UserClientRequest? client;
  final UserAddressRequest? address;
  final PaymentInfoRequest? paymentInfo;

  CreateUserRequest({
    required this.email,
    required this.password,
    this.groupId,
    this.active,
    this.devicesLimit,
    this.subscriptionExpiration,
    this.phoneNumber,
    this.billingPlanId,
    this.companyId,
    this.client,
    this.address,
    this.paymentInfo,
  });

  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final Map<String, dynamic> json = {
      'email': email,
    };

    // Password só é obrigatório na criação, na atualização é opcional
    if (!isUpdate || password.isNotEmpty) {
      if (password != 'NO_CHANGE') {
        json['password'] = password;
      }
    }

    if (groupId != null) json['group_id'] = groupId;
    if (active != null) json['active'] = active;
    if (devicesLimit != null) json['devices_limit'] = devicesLimit;
    if (subscriptionExpiration != null)
      json['subscription_expiration'] = subscriptionExpiration;
    if (phoneNumber != null) json['phone_number'] = phoneNumber;
    if (billingPlanId != null) json['billing_plan_id'] = billingPlanId;
    if (companyId != null) json['company_id'] = companyId;
    if (client != null) json['client'] = client!.toJson();
    if (address != null) json['address'] = address!.toJson();
    if (paymentInfo != null) json['paymentInfo'] = paymentInfo!.toJson();

    return json;
  }
}

class UserClientRequest {
  final String firstName;
  final String lastName;
  final String? personalCode;
  final String? birthDate;
  final String? whatsapp;
  final String? address;
  final String? comment;

  UserClientRequest({
    required this.firstName,
    required this.lastName,
    this.personalCode,
    this.birthDate,
    this.whatsapp,
    this.address,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'first_name': firstName,
      'last_name': lastName,
    };

    if (personalCode != null) json['personal_code'] = personalCode;
    if (birthDate != null) json['birth_date'] = birthDate;
    if (whatsapp != null) json['whatsapp'] = whatsapp;
    if (address != null) json['address'] = address;
    if (comment != null) json['comment'] = comment;

    return json;
  }
}

class UserAddressRequest {
  final String? zipCode;
  final String? street;
  final String? number;
  final String? district;
  final String? city;
  final String? state;
  final String? complement;

  UserAddressRequest({
    this.zipCode,
    this.street,
    this.number,
    this.district,
    this.city,
    this.state,
    this.complement,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (zipCode != null) json['zip_code'] = zipCode;
    if (street != null) json['street'] = street;
    if (number != null) json['number'] = number;
    if (district != null) json['district'] = district;
    if (city != null) json['city'] = city;
    if (state != null) json['state'] = state;
    if (complement != null) json['complement'] = complement;

    return json;
  }
}

class PaymentInfoRequest {
  final double? monthlyFee;
  final int? paymentDay;
  final String? contractSignDate;
  final String? contractExpiryDate;

  PaymentInfoRequest({
    this.monthlyFee,
    this.paymentDay,
    this.contractSignDate,
    this.contractExpiryDate,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (monthlyFee != null) json['monthly_fee'] = monthlyFee;
    if (paymentDay != null) json['payment_day'] = paymentDay;
    if (contractSignDate != null)
      json['contract_sign_date'] = contractSignDate;
    if (contractExpiryDate != null)
      json['contract_expiry_date'] = contractExpiryDate;

    return json;
  }
}

