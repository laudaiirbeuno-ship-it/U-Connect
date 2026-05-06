class Client {
  final int id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String status; // 'active', 'unactive', 'overdue', 'em_teste', 'closed'
  final bool active;
  final int devicesCount;
  final int subusersCount;
  final ClientManager? manager;
  final BillingPlan? billingPlan;
  final DateTime? createdAt;
  
  // Campos detalhados (apenas em show)
  final Address? address;
  final PaymentInfo? paymentInfo;
  final Subscription? subscription;

  Client({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.status,
    required this.active,
    required this.devicesCount,
    required this.subusersCount,
    this.manager,
    this.billingPlan,
    this.createdAt,
    this.address,
    this.paymentInfo,
    this.subscription,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      status: json['status'] ?? 'active',
      active: json['active'] ?? true,
      devicesCount: json['devices_count'] ?? 0,
      subusersCount: json['subusers_count'] ?? 0,
      manager: json['manager'] != null 
        ? ClientManager.fromJson(json['manager']) 
        : null,
      billingPlan: json['billing_plan'] != null
        ? BillingPlan.fromJson(json['billing_plan'])
        : null,
      createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString().replaceAll(' ', 'T'))
        : null,
      address: json['address'] != null
        ? Address.fromJson(json['address'])
        : null,
      paymentInfo: json['payment_info'] != null
        ? PaymentInfo.fromJson(json['payment_info'])
        : null,
      subscription: json['subscription'] != null
        ? Subscription.fromJson(json['subscription'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'status': status,
      'active': active,
      'devices_count': devicesCount,
      'subusers_count': subusersCount,
      'manager': manager?.toJson(),
      'billing_plan': billingPlan?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'address': address?.toJson(),
      'payment_info': paymentInfo?.toJson(),
      'subscription': subscription?.toJson(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'unactive':
        return 'Inativo';
      case 'overdue':
        return 'Inadimplente';
      case 'em_teste':
        return 'Em Teste';
      case 'closed':
        return 'Fechado';
      default:
        return status;
    }
  }
}

class ClientManager {
  final int id;
  final String email;

  ClientManager({required this.id, required this.email});

  factory ClientManager.fromJson(Map<String, dynamic> json) {
    return ClientManager(
      id: json['id'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
  };
}

class BillingPlan {
  final int id;
  final String title;

  BillingPlan({required this.id, required this.title});

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      id: json['id'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
  };
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  Address({
    this.street,
    this.city,
    this.state,
    this.zip,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zip: json['zip'],
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'state': state,
    'zip': zip,
  };
}

class PaymentInfo {
  final int? paymentDay;

  PaymentInfo({this.paymentDay});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      paymentDay: json['payment_day'],
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_day': paymentDay,
  };
}

class Subscription {
  final DateTime? expirationDate;

  Subscription({this.expirationDate});

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      expirationDate: json['expiration_date'] != null
        ? DateTime.tryParse(json['expiration_date'].toString().replaceAll(' ', 'T'))
        : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'expiration_date': expirationDate?.toIso8601String(),
  };
}

class ClientsResponse {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int? from;
  final int? to;
  final List<Client> data;
  final ClientsStatistics statistics;

  ClientsResponse({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.from,
    this.to,
    required this.data,
    required this.statistics,
  });

  factory ClientsResponse.fromJson(Map<String, dynamic> json) {
    return ClientsResponse(
      total: json['items']['total'] ?? 0,
      perPage: json['items']['per_page'] ?? 25,
      currentPage: json['items']['current_page'] ?? 1,
      lastPage: json['items']['last_page'] ?? 1,
      from: json['items']['from'],
      to: json['items']['to'],
      data: (json['items']['data'] as List?)
          ?.map((item) => Client.fromJson(item))
          .toList() ?? [],
      statistics: ClientsStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class ClientsStatistics {
  final int total;
  final int active;
  final int inactive;
  final int overdue;
  final int paid;
  final int contractSigned;

  ClientsStatistics({
    required this.total,
    required this.active,
    required this.inactive,
    required this.overdue,
    required this.paid,
    required this.contractSigned,
  });

  factory ClientsStatistics.fromJson(Map<String, dynamic> json) {
    return ClientsStatistics(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      overdue: json['overdue'] ?? 0,
      paid: json['paid'] ?? 0,
      contractSigned: json['contract_signed'] ?? 0,
    );
  }
}

class Device {
  final int id;
  final String imei;
  final String name;
  final DeviceGroup? group;

  Device({
    required this.id,
    required this.imei,
    required this.name,
    this.group,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      imei: json['imei'],
      name: json['name'],
      group: json['group'] != null
        ? DeviceGroup.fromJson(json['group'])
        : null,
    );
  }
}

class DeviceGroup {
  final int id;
  final String name;

  DeviceGroup({required this.id, required this.name});

  factory DeviceGroup.fromJson(Map<String, dynamic> json) {
    return DeviceGroup(
      id: json['id'],
      name: json['name'],
    );
  }
}
