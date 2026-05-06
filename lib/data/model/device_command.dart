/// Model para comandos de dispositivo
/// Baseado na API: /api/get_device_commands

class DeviceCommand {
  final String? type;
  final String? title;
  final String? connection;
  final List<CommandAttribute> attributes;

  DeviceCommand({
    this.type,
    this.title,
    this.connection,
    required this.attributes,
  });

  DeviceCommand.fromJson(Map<String, dynamic> json)
      : type = json['type']?.toString(),
        title = json['title']?.toString(),
        connection = json['connection']?.toString(),
        attributes = (json['attributes'] as List<dynamic>?)
                ?.map((item) => CommandAttribute.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'connection': connection,
      'attributes': attributes.map((item) => item.toJson()).toList(),
    };
  }
}

class CommandAttribute {
  final String? name;
  final String? htmlName;
  final String? title;
  final String? type;
  final List<CommandOption> options;
  final String? defaultValue;
  final String? description;
  final String? validation;
  final bool required;

  CommandAttribute({
    this.name,
    this.htmlName,
    this.title,
    this.type,
    required this.options,
    this.defaultValue,
    this.description,
    this.validation,
    required this.required,
  });

  CommandAttribute.fromJson(Map<String, dynamic> json)
      : name = json['name']?.toString(),
        htmlName = json['html_name']?.toString(),
        title = json['title']?.toString(),
        type = json['type']?.toString(),
        options = (json['options'] as List<dynamic>?)
                ?.map((item) => CommandOption.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        defaultValue = json['default']?.toString(),
        description = json['description']?.toString(),
        validation = json['validation']?.toString(),
        required = json['required'] == true || json['required'] == 'true' || json['required'] == 1;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'html_name': htmlName,
      'title': title,
      'type': type,
      'options': options.map((item) => item.toJson()).toList(),
      'default': defaultValue,
      'description': description,
      'validation': validation,
      'required': required,
    };
  }
}

class CommandOption {
  final String? id;
  final String? title;

  CommandOption({
    this.id,
    this.title,
  });

  CommandOption.fromJson(Map<String, dynamic> json)
      : id = json['id']?.toString(),
        title = json['title']?.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}





































