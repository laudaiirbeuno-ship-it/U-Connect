import 'devices.dart';

/// Model para resposta da API de sensores com paginação
class SensorResponse {
  final int? status;
  final List<Sensors> data;
  final SensorPagination? pagination;

  SensorResponse({
    this.status,
    required this.data,
    this.pagination,
  });

  SensorResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null),
        data = (json['data'] as List<dynamic>?)
                ?.map((item) => Sensors.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        pagination = json['current_page'] != null || json['total'] != null
            ? SensorPagination.fromJson(json)
            : null;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((item) => item.toJson()).toList(),
      if (pagination != null) ...pagination!.toJson(),
    };
  }
}

class SensorPagination {
  final int? currentPage;
  final String? firstPageUrl;
  final int? from;
  final int? lastPage;
  final String? lastPageUrl;
  final List<SensorPaginationLink>? links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int? total;
  final String? url;

  SensorPagination({
    this.currentPage,
    this.firstPageUrl,
    this.lastPageUrl,
    this.from,
    this.lastPage,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
    this.url,
  });

  SensorPagination.fromJson(Map<String, dynamic> json)
      : currentPage = json['current_page'] is int ? json['current_page'] : (json['current_page'] != null ? int.tryParse(json['current_page'].toString()) : null),
        firstPageUrl = json['first_page_url']?.toString(),
        from = json['from'] is int ? json['from'] : (json['from'] != null ? int.tryParse(json['from'].toString()) : null),
        lastPage = json['last_page'] is int ? json['last_page'] : (json['last_page'] != null ? int.tryParse(json['last_page'].toString()) : null),
        lastPageUrl = json['last_page_url']?.toString(),
        links = (json['links'] as List<dynamic>?)
                ?.map((item) => SensorPaginationLink.fromJson(item as Map<String, dynamic>))
                .toList(),
        nextPageUrl = json['next_page_url']?.toString(),
        path = json['path']?.toString(),
        perPage = json['per_page'] is int ? json['per_page'] : (json['per_page'] != null ? int.tryParse(json['per_page'].toString()) : null),
        prevPageUrl = json['prev_page_url']?.toString(),
        to = json['to'] is int ? json['to'] : (json['to'] != null ? int.tryParse(json['to'].toString()) : null),
        total = json['total'] is int ? json['total'] : (json['total'] != null ? int.tryParse(json['total'].toString()) : null),
        url = json['url']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links?.map((item) => item.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
      'url': url,
    };
  }
}

class SensorPaginationLink {
  final String? url;
  final String? label;
  final bool? active;

  SensorPaginationLink({
    this.url,
    this.label,
    this.active,
  });

  SensorPaginationLink.fromJson(Map<String, dynamic> json)
      : url = json['url']?.toString(),
        label = json['label']?.toString(),
        active = json['active'] is bool ? json['active'] : (json['active'] == 1 || json['active'] == true);

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}





































