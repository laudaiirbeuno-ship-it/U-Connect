class ProtocolResponse {
  Map<String, ProtocolItem>? protocols;
  int? status;

  ProtocolResponse({this.protocols, this.status});

  factory ProtocolResponse.fromJson(Map<String, dynamic> json) {
    Map<String, ProtocolItem> protocolsMap = {};
    json.forEach((key, value) {
      if (key != 'status' && value is Map<String, dynamic>) {
        protocolsMap[key] = ProtocolItem.fromJson(value);
      }
    });
    return ProtocolResponse(
      protocols: protocolsMap,
      status: json['status'],
    );
  }
}

class ProtocolItem {
  int? id;
  ProtocolValue? value;

  ProtocolItem({this.id, this.value});

  factory ProtocolItem.fromJson(Map<String, dynamic> json) {
    return ProtocolItem(
      id: json['id'],
      value: json['value'] != null ? ProtocolValue.fromJson(json['value']) : null,
    );
  }
}

class ProtocolValue {
  int? type;
  List<ProtocolItemOption>? items;

  ProtocolValue({this.type, this.items});

  factory ProtocolValue.fromJson(Map<String, dynamic> json) {
    return ProtocolValue(
      type: json['type'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => ProtocolItemOption.fromJson(e)).toList()
          : null,
    );
  }
}

class ProtocolItemOption {
  String? id;
  String? value;

  ProtocolItemOption({this.id, this.value});

  factory ProtocolItemOption.fromJson(Map<String, dynamic> json) {
    return ProtocolItemOption(
      id: json['id']?.toString(),
      value: json['value']?.toString(),
    );
  }
}































