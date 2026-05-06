class Charge {
  final int id;
  final String gateway;
  final String? gatewayId;
  final String status;
  final String statusLabel;
  final double value;
  final double totalValue;
  final String? billingType;
  final String? billingTypeLabel;
  final String? description;
  final DateTime? dueDate;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final ChargeCustomer customer;
  final ChargePayment payment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? installmentCount;
  final int? totalInstallments;
  final bool isOneOff;
  final int? planId;
  final String? planName;
  final int? createdById;
  final String? createdByName;
  final String? createdByEmail;

  Charge({
    required this.id,
    required this.gateway,
    this.gatewayId,
    required this.status,
    required this.statusLabel,
    required this.value,
    required this.totalValue,
    this.billingType,
    this.billingTypeLabel,
    this.description,
    this.dueDate,
    this.expiresAt,
    this.paidAt,
    required this.customer,
    required this.payment,
    this.createdAt,
    this.updatedAt,
    this.installmentCount,
    this.totalInstallments,
    this.isOneOff = false,
    this.planId,
    this.planName,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
  });

  factory Charge.fromJson(Map<String, dynamic> json) {
    try {
      // Converter value para double de forma segura
      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
        return 0.0;
      }
      
      // Converter para int de forma segura
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        if (value is double) return value.toInt();
        return null;
      }
      
      return Charge(
        id: parseInt(json['id']) ?? 0,
        gateway: json['gateway']?.toString() ?? 'asaas',
        gatewayId: json['gateway_id']?.toString(),
        status: json['status']?.toString() ?? 'PENDING',
        statusLabel: json['status_label']?.toString() ?? json['status']?.toString() ?? 'Pendente',
        value: parseDouble(json['value']),
        totalValue: parseDouble(json['total_value'] ?? json['value']),
        billingType: json['billing_type']?.toString(),
        billingTypeLabel: json['billing_type_label']?.toString(),
        description: json['description']?.toString(),
        dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
        expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
        paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
        customer: json['customer'] != null && json['customer'] is Map
            ? ChargeCustomer.fromJson(json['customer'] as Map<String, dynamic>)
            : ChargeCustomer.fromJson({}),
        payment: json['payment'] != null && json['payment'] is Map
            ? ChargePayment.fromJson(json['payment'] as Map<String, dynamic>)
            : ChargePayment.fromJson({}),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
        installmentCount: parseInt(json['installment_count']),
        totalInstallments: parseInt(json['total_installments']),
        isOneOff: json['is_one_off'] == true || json['is_one_off'] == 1 || json['is_one_off'] == '1',
        planId: parseInt(json['plan_id']),
        planName: json['plan_name']?.toString() ?? json['plan']?['name']?.toString() ?? json['plan']?['title']?.toString(),
        createdById: parseInt(json['created_by_id']) ?? parseInt(json['created_by']) ?? parseInt(json['user_id']),
        createdByName: json['created_by_name']?.toString() ?? json['created_by']?['name']?.toString() ?? json['user']?['name']?.toString() ?? json['creator']?['name']?.toString(),
        createdByEmail: json['created_by_email']?.toString() ?? json['created_by']?['email']?.toString() ?? json['user']?['email']?.toString() ?? json['creator']?['email']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌ [Charge.fromJson] Erro ao parsear: $e');
      print('❌ [Charge.fromJson] Stack: $stackTrace');
      print('❌ [Charge.fromJson] JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gateway': gateway,
      'gateway_id': gatewayId,
      'status': status,
      'status_label': statusLabel,
      'value': value,
      'total_value': totalValue,
      'billing_type': billingType,
      'billing_type_label': billingTypeLabel,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'expires_at': expiresAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'customer': customer.toJson(),
      'payment': payment.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'installment_count': installmentCount,
      'total_installments': totalInstallments,
      'is_one_off': isOneOff,
      'plan_id': planId,
      'plan_name': planName,
      'created_by_id': createdById,
      'created_by_name': createdByName,
      'created_by_email': createdByEmail,
    };
  }

  // Helpers
  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'RECEIVED' || status == 'CONFIRMED' || status == 'PAID';
  bool get isOverdue => status == 'OVERDUE' || status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED' || status == 'CANCELED';
  
  bool get canCancel => isPending || isOverdue;
  bool get canSync => gatewayId != null && !gatewayId!.startsWith('TEST_');
  bool get hasPix => payment.pixCode != null || payment.pixQrCode != null;
  bool get hasBoleto => payment.bankSlipUrl != null;
}

class ChargeCustomer {
  final String name;
  final String? email;
  final String? document;
  final String? phone;

  ChargeCustomer({
    required this.name,
    this.email,
    this.document,
    this.phone,
  });

  factory ChargeCustomer.fromJson(Map<String, dynamic> json) {
    try {
      return ChargeCustomer(
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString(),
        document: json['document']?.toString(),
        phone: json['phone']?.toString(),
      );
    } catch (e) {
      print('❌ [ChargeCustomer.fromJson] Erro: $e');
      return ChargeCustomer(name: '');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'document': document,
      'phone': phone,
    };
  }
}

class ChargePayment {
  final String? pixCode;
  final String? pixQrCode;
  final String? copyPasteCode;
  final String? bankSlipUrl;
  final String? invoiceUrl;

  ChargePayment({
    this.pixCode,
    this.pixQrCode,
    this.copyPasteCode,
    this.bankSlipUrl,
    this.invoiceUrl,
  });

  factory ChargePayment.fromJson(Map<String, dynamic> json) {
    try {
      return ChargePayment(
        pixCode: json['pix_code']?.toString(),
        pixQrCode: json['pix_qr_code']?.toString(),
        copyPasteCode: json['copy_paste_code']?.toString() ?? json['copy_paste']?.toString(),
        bankSlipUrl: json['bank_slip_url']?.toString(),
        invoiceUrl: json['invoice_url']?.toString(),
      );
    } catch (e) {
      print('❌ [ChargePayment.fromJson] Erro: $e');
      return ChargePayment();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'pix_code': pixCode,
      'pix_qr_code': pixQrCode,
      'copy_paste_code': copyPasteCode,
      'bank_slip_url': bankSlipUrl,
      'invoice_url': invoiceUrl,
    };
  }
}

class ChargeResponse {
  final int status;
  final ChargeItems? items;
  final Charge? data;
  final String? message;
  final Map<String, dynamic>? errors;

  ChargeResponse({
    required this.status,
    this.items,
    this.data,
    this.message,
    this.errors,
  });

  factory ChargeResponse.fromJson(Map<String, dynamic> json) {
    return ChargeResponse(
      status: json['status'] ?? 0,
      items: json['items'] != null ? ChargeItems.fromJson(json['items']) : null,
      data: json['data'] != null ? Charge.fromJson(json['data']) : null,
      message: json['message'],
      errors: json['errors'],
    );
  }
}

class ChargeItems {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int? from;
  final int? to;
  final List<Charge> data;
  final String? url;

  ChargeItems({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.from,
    this.to,
    required this.data,
    this.url,
  });

  factory ChargeItems.fromJson(Map<String, dynamic> json) {
    try {
      // Converter para int de forma segura
      int parseInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is double) return value.toInt();
        return defaultValue;
      }
      
      final dataList = json['data'];
      final List<Charge> charges = [];
      
      if (dataList != null && dataList is List) {
        for (var i = 0; i < dataList.length; i++) {
          try {
            final item = dataList[i];
            if (item is Map) {
              final itemMap = item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item);
              final charge = Charge.fromJson(itemMap);
              charges.add(charge);
            }
          } catch (e) {
            print('❌ [ChargeItems.fromJson] Erro ao processar item $i: $e');
            print('❌ [ChargeItems.fromJson] Item: ${dataList[i]}');
          }
        }
      }
      
      return ChargeItems(
        total: parseInt(json['total'], 0),
        perPage: parseInt(json['per_page'], 30),
        currentPage: parseInt(json['current_page'], 1),
        lastPage: parseInt(json['last_page'], 1),
        from: json['from'] != null ? parseInt(json['from'], 0) : null,
        to: json['to'] != null ? parseInt(json['to'], 0) : null,
        data: charges,
        url: json['url']?.toString(),
      );
    } catch (e, stackTrace) {
      print('❌ [ChargeItems.fromJson] Erro: $e');
      print('❌ [ChargeItems.fromJson] Stack: $stackTrace');
      print('❌ [ChargeItems.fromJson] JSON: $json');
      rethrow;
    }
  }
}

// Modelo para resposta de lista de cobranças (compatível com ChargesResponse da documentação)
class ChargesResponse {
  final List<Charge> charges;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int? from;
  final int? to;

  ChargesResponse({
    required this.charges,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.from,
    this.to,
  });

  factory ChargesResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] ?? json;
    final data = items['data'] ?? [];
    
    return ChargesResponse(
      charges: (data as List)
          .map((item) => Charge.fromJson(item))
          .toList(),
      total: items['total'] ?? 0,
      perPage: items['per_page'] ?? 30,
      currentPage: items['current_page'] ?? 1,
      lastPage: items['last_page'] ?? 1,
      from: items['from'],
      to: items['to'],
    );
  }
}

// Modelos de estatísticas
class ChargesStatistics {
  final int total;
  final int pending;
  final int paid;
  final int overdue;
  final ChargesStatisticsValues values;

  ChargesStatistics({
    required this.total,
    required this.pending,
    required this.paid,
    required this.overdue,
    required this.values,
  });

  factory ChargesStatistics.fromJson(Map<String, dynamic> json) {
    return ChargesStatistics(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      paid: json['paid'] ?? 0,
      overdue: json['overdue'] ?? 0,
      values: ChargesStatisticsValues.fromJson(json['values'] ?? {}),
    );
  }
}

class ChargesStatisticsValues {
  final double total;
  final double pending;
  final double paid;
  final double overdue;

  ChargesStatisticsValues({
    required this.total,
    required this.pending,
    required this.paid,
    required this.overdue,
  });

  factory ChargesStatisticsValues.fromJson(Map<String, dynamic> json) {
    return ChargesStatisticsValues(
      total: (json['total'] ?? 0).toDouble(),
      pending: (json['pending'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      overdue: (json['overdue'] ?? 0).toDouble(),
    );
  }
}

class ChargeQrCodeResponse {
  final int status;
  final ChargeQrCodeData? data;

  ChargeQrCodeResponse({
    required this.status,
    this.data,
  });

  factory ChargeQrCodeResponse.fromJson(Map<String, dynamic> json) {
    return ChargeQrCodeResponse(
      status: json['status'] ?? 0,
      data: json['data'] != null ? ChargeQrCodeData.fromJson(json['data']) : null,
    );
  }
}

class ChargeQrCodeData {
  final String? qrcode;
  final String? code;
  final String? copyPaste;

  ChargeQrCodeData({
    this.qrcode,
    this.code,
    this.copyPaste,
  });

  factory ChargeQrCodeData.fromJson(Map<String, dynamic> json) {
    return ChargeQrCodeData(
      qrcode: json['qrcode'],
      code: json['code'],
      copyPaste: json['copy_paste'],
    );
  }
}


