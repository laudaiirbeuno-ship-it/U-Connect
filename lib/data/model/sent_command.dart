import 'package:flutter/material.dart';

/// Model para comandos enviados
/// Baseado na API: /api/sent_commands

class SentCommandResponse {
  final List<SentCommand> data;
  final SentCommandPagination pagination;

  SentCommandResponse({
    required this.data,
    required this.pagination,
  });

  SentCommandResponse.fromJson(Map<String, dynamic> json)
      : data = (json['data'] as List<dynamic>?)
                ?.map((item) => SentCommand.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['pagination'] != null
            ? SentCommandPagination.fromJson(json['pagination'] as Map<String, dynamic>)
            : SentCommandPagination(
                total: 0,
                perPage: 0,
                currentPage: 0,
                lastPage: 0,
              );

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class SentCommand {
  final int? id;
  final int? userId;
  final String? imei;
  final String? connection;
  final String? commandTitle;
  final dynamic parameters;
  final String? response;
  final bool status;
  final String? createdAt;
  final String? updatedAt;
  final SentCommandDevice? device;
  final SentCommandUser? user;

  SentCommand({
    this.id,
    this.userId,
    this.imei,
    this.connection,
    this.commandTitle,
    this.parameters,
    this.response,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.device,
    this.user,
  });

  SentCommand.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        userId = json['user_id'] is int ? json['user_id'] : (json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null),
        imei = json['imei']?.toString(),
        connection = json['connection']?.toString(),
        commandTitle = json['command_title']?.toString(),
        parameters = json['parameters'],
        response = json['response']?.toString(),
        status = json['status'] == true || json['status'] == 'true' || json['status'] == 1,
        createdAt = json['created_at']?.toString(),
        updatedAt = json['updated_at']?.toString(),
        device = json['device'] != null
            ? SentCommandDevice.fromJson(json['device'] as Map<String, dynamic>)
            : null,
        user = json['user'] != null
            ? SentCommandUser.fromJson(json['user'] as Map<String, dynamic>)
            : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'imei': imei,
      'connection': connection,
      'command_title': commandTitle,
      'parameters': parameters,
      'response': response,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'device': device?.toJson(),
      'user': user?.toJson(),
    };
  }

  String get statusText => status ? 'Sucesso' : 'Falha';
  Color get statusColor => status ? Colors.green : Colors.red;
}

class SentCommandDevice {
  final int? id;
  final String? name;

  SentCommandDevice({
    this.id,
    this.name,
  });

  SentCommandDevice.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        name = json['name']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class SentCommandUser {
  final int? id;
  final String? email;
  final bool active;

  SentCommandUser({
    this.id,
    this.email,
    required this.active,
  });

  SentCommandUser.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        email = json['email']?.toString(),
        active = json['active'] == true || json['active'] == 'true' || json['active'] == 1;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'active': active,
    };
  }
}

class SentCommandPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String? url;

  SentCommandPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
    this.url,
  });

  SentCommandPagination.fromJson(Map<String, dynamic> json)
      : total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) ?? 0 : 0),
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) ?? 0 : 0),
        currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) ?? 0 : 0),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) ?? 0 : 0),
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

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get hasPrevPage => prevPageUrl != null && prevPageUrl!.isNotEmpty;
}

