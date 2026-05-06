class RouteResponse {
  final List<RouteItem> data;
  final RoutePagination pagination;

  RouteResponse({
    required this.data,
    required this.pagination,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    // Processar dados
    List<RouteItem> dataList = [];
    if (json['data'] != null && json['data'] is List) {
      dataList = (json['data'] as List<dynamic>)
          .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    // Processar paginação (pode estar em 'pagination' ou no nível raiz)
    Map<String, dynamic> paginationData = {};
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = json['pagination'] as Map<String, dynamic>;
    } else if (json['total'] != null || json['current_page'] != null) {
      // Paginação no nível raiz
      paginationData = {
        'total': json['total'],
        'per_page': json['per_page'],
        'current_page': json['current_page'],
        'last_page': json['last_page'],
        'next_page_url': json['next_page_url'],
        'prev_page_url': json['prev_page_url'],
        'url': json['url'] ?? '',
      };
    }
    
    return RouteResponse(
      data: dataList,
      pagination: RoutePagination.fromJson(paginationData),
    );
  }
}

class RouteItem {
  final int id;
  final int groupId;
  final int active;
  final String name;
  final String color;
  final List<RouteCoordinate> coordinates;

  RouteItem({
    required this.id,
    required this.groupId,
    required this.active,
    required this.name,
    required this.color,
    required this.coordinates,
  });

  factory RouteItem.fromJson(Map<String, dynamic> json) {
    return RouteItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      groupId: (json['group_id'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#000000',
      coordinates: (json['coordinates'] as List<dynamic>?)
              ?.map((coord) => RouteCoordinate.fromJson(coord as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isActive => active == 1;
}

class RouteCoordinate {
  final double lat;
  final double lng;

  RouteCoordinate({
    required this.lat,
    required this.lng,
  });

  factory RouteCoordinate.fromJson(Map<String, dynamic> json) {
    return RouteCoordinate(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RoutePagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final String url;

  RoutePagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
    required this.url,
  });

  factory RoutePagination.fromJson(Map<String, dynamic> json) {
    return RoutePagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      perPage: (json['per_page'] as num?)?.toInt() ?? 0,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 0,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 0,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
      url: json['url'] as String? ?? '',
    );
  }

  bool get hasNextPage => nextPageUrl != null && nextPageUrl!.isNotEmpty;
  bool get hasPrevPage => prevPageUrl != null && prevPageUrl!.isNotEmpty;
}

