/// Model para dados de comandos
/// Baseado na API: /api/send_command_data

class CommandData {
  final List<CommandDevice> devicesSms;
  final List<CommandDevice> devicesGprs;
  final List<CommandTemplate> smsTemplates;
  final List<CommandTemplate> gprsTemplates;
  final List<CommandItem> commands;
  final List<CommandUnit> units;
  final List<CommandNumberIndex> numberIndex;
  final List<CommandAction> actions;
  final Map<String, String> devicesProtocols;
  final Map<String, Map<String, String>> commandsAll;
  final int? status;

  CommandData({
    required this.devicesSms,
    required this.devicesGprs,
    required this.smsTemplates,
    required this.gprsTemplates,
    required this.commands,
    required this.units,
    required this.numberIndex,
    required this.actions,
    required this.devicesProtocols,
    required this.commandsAll,
    this.status,
  });

  CommandData.fromJson(Map<String, dynamic> json)
      : devicesSms = (json['devices_sms'] as List<dynamic>?)
                ?.map((item) => CommandDevice.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        devicesGprs = (json['devices_gprs'] as List<dynamic>?)
                ?.map((item) => CommandDevice.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        smsTemplates = (json['sms_templates'] as List<dynamic>?)
                ?.map((item) => CommandTemplate.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        gprsTemplates = (json['gprs_templates'] as List<dynamic>?)
                ?.map((item) => CommandTemplate.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        commands = (json['commands'] as List<dynamic>?)
                ?.map((item) => CommandItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        units = (json['units'] as List<dynamic>?)
                ?.map((item) => CommandUnit.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        numberIndex = (json['number_index'] as List<dynamic>?)
                ?.map((item) => CommandNumberIndex.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        actions = (json['actions'] as List<dynamic>?)
                ?.map((item) => CommandAction.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        devicesProtocols = (json['devices_protocols'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(key, value.toString())) ??
            {},
        commandsAll = (json['commands_all'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(
                      key,
                      (value as Map<String, dynamic>)
                          .map((k, v) => MapEntry(k, v.toString())),
                    )) ??
            {},
        status = json['status'] is int ? json['status'] : (json['status'] != null ? int.tryParse(json['status'].toString()) : null);

  Map<String, dynamic> toJson() {
    return {
      'devices_sms': devicesSms.map((item) => item.toJson()).toList(),
      'devices_gprs': devicesGprs.map((item) => item.toJson()).toList(),
      'sms_templates': smsTemplates.map((item) => item.toJson()).toList(),
      'gprs_templates': gprsTemplates.map((item) => item.toJson()).toList(),
      'commands': commands.map((item) => item.toJson()).toList(),
      'units': units.map((item) => item.toJson()).toList(),
      'number_index': numberIndex.map((item) => item.toJson()).toList(),
      'actions': actions.map((item) => item.toJson()).toList(),
      'devices_protocols': devicesProtocols,
      'commands_all': commandsAll,
      'status': status,
    };
  }
}

class CommandDevice {
  final int? id;
  final String? value;

  CommandDevice({
    this.id,
    this.value,
  });

  CommandDevice.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        value = json['value']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}

class CommandTemplate {
  final String? id;
  final String? title;
  final String? message;

  CommandTemplate({
    this.id,
    this.title,
    this.message,
  });

  CommandTemplate.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        title = json['title']?.toString(),
        message = json['message']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
    };
  }
}

class CommandItem {
  final String? id;
  final String? value;

  CommandItem({
    this.id,
    this.value,
  });

  CommandItem.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        value = json['value']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}

class CommandUnit {
  final String? id;
  final String? value;

  CommandUnit({
    this.id,
    this.value,
  });

  CommandUnit.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        value = json['value']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}

class CommandNumberIndex {
  final int? id;
  final String? value;

  CommandNumberIndex({
    this.id,
    this.value,
  });

  CommandNumberIndex.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        value = json['value']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}

class CommandAction {
  final int? id;
  final String? value;

  CommandAction({
    this.id,
    this.value,
  });

  CommandAction.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        value = json['value']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}





































