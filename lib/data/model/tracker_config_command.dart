/// Model para comandos de configuração de rastreadores
/// Contém comandos dos principais rastreadores do mercado

class TrackerConfigCommand {
  final String id;
  final String name;
  final String command;
  final String? description;

  TrackerConfigCommand({
    required this.id,
    required this.name,
    required this.command,
    this.description,
  });
}

class TrackerDevice {
  final String id;
  final String model;
  final String manufacturer;
  final String protocol;
  final String port;
  final List<TrackerConfigCommand> commands;

  TrackerDevice({
    required this.id,
    required this.model,
    required this.manufacturer,
    required this.protocol,
    required this.port,
    required this.commands,
  });
}

class TrackerConfigData {
  static const String SERVER_IP = '91.108.125.56';

  /// Lista completa de rastreadores e seus comandos de configuração
  static List<TrackerDevice> getAllTrackers() {
    return [
      // TK103 / TK103B
      TrackerDevice(
        id: 'tk103',
        model: 'TK103',
        manufacturer: 'Queclink',
        protocol: 'osmand',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'apn,APN_NAME,USERNAME,PASSWORD',
            description: 'Configura o APN da operadora',
          ),
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'server,${TrackerConfigData.SERVER_IP},5027',
            description: 'Configura o servidor e porta',
          ),
          TrackerConfigCommand(
            id: 'timezone',
            name: 'Configurar Timezone',
            command: 'timezone,3',
            description: 'Configura o fuso horário (3 = UTC-3)',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'interval,60',
            description: 'Intervalo de envio em segundos',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'sos,5511999999999',
            description: 'Configura número de emergência',
          ),
        ],
      ),
      TrackerDevice(
        id: 'tk103b',
        model: 'TK103B',
        manufacturer: 'Queclink',
        protocol: 'osmand',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'apn,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'server,${TrackerConfigData.SERVER_IP},5027',
          ),
          TrackerConfigCommand(
            id: 'timezone',
            name: 'Configurar Timezone',
            command: 'timezone,3',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'interval,30',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'sos,5511999999999',
          ),
        ],
      ),

      // GT06 / GT06N
      TrackerDevice(
        id: 'gt06',
        model: 'GT06',
        manufacturer: 'Concox',
        protocol: 'gt06',
        port: '5023',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5023#',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD#',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60#',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'SOS1,5511999999999#',
          ),
          TrackerConfigCommand(
            id: 'timezone',
            name: 'Configurar Timezone',
            command: 'TIMEZONE,3#',
          ),
        ],
      ),
      TrackerDevice(
        id: 'gt06n',
        model: 'GT06N',
        manufacturer: 'Concox',
        protocol: 'gt06',
        port: '5023',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5023#',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD#',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,30#',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'SOS1,5511999999999#',
          ),
        ],
      ),

      // VT200 / VT300
      TrackerDevice(
        id: 'vt200',
        model: 'VT200',
        manufacturer: 'Calamp',
        protocol: 'totem',
        port: '5005',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'AT+GTIP=${TrackerConfigData.SERVER_IP},5005',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'AT+GTAPN=APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'AT+GTINT=60',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'AT+GTSOS=5511999999999',
          ),
        ],
      ),
      TrackerDevice(
        id: 'vt300',
        model: 'VT300',
        manufacturer: 'Calamp',
        protocol: 'totem',
        port: '5005',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'AT+GTIP=${TrackerConfigData.SERVER_IP},5005',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'AT+GTAPN=APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'AT+GTINT=30',
          ),
        ],
      ),

      // H02 / H03
      TrackerDevice(
        id: 'h02',
        model: 'H02',
        manufacturer: 'Meiligao',
        protocol: 'meiligao',
        port: '5008',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5008',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'SOS,5511999999999',
          ),
        ],
      ),
      TrackerDevice(
        id: 'h03',
        model: 'H03',
        manufacturer: 'Meiligao',
        protocol: 'meiligao',
        port: '5008',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5008',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,30',
          ),
        ],
      ),

      // T55 / T333
      TrackerDevice(
        id: 't55',
        model: 'T55',
        manufacturer: 'Teltonika',
        protocol: 'teltonika',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: '00000000000000C0${TrackerConfigData.SERVER_IP}:5027',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: '00000000000000C1APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: '00000000000000C260',
          ),
        ],
      ),
      TrackerDevice(
        id: 't333',
        model: 'T333',
        manufacturer: 'Teltonika',
        protocol: 'teltonika',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: '00000000000000C0${TrackerConfigData.SERVER_IP}:5027',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: '00000000000000C1APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: '00000000000000C230',
          ),
        ],
      ),

      // Xexun / XT26
      TrackerDevice(
        id: 'xt26',
        model: 'XT26',
        manufacturer: 'Xexun',
        protocol: 'xexun',
        port: '5002',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: '*HQ,IMEI,SERVER,${TrackerConfigData.SERVER_IP},5002#',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: '*HQ,IMEI,APN,APN_NAME,USERNAME,PASSWORD#',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: '*HQ,IMEI,INTERVAL,60#',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: '*HQ,IMEI,SOS,5511999999999#',
          ),
        ],
      ),

      // Totem / Totem Mini
      TrackerDevice(
        id: 'totem',
        model: 'Totem',
        manufacturer: 'Totem',
        protocol: 'totem',
        port: '5005',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'AT+GTIP=${TrackerConfigData.SERVER_IP},5005',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'AT+GTAPN=APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'AT+GTINT=60',
          ),
        ],
      ),

      // Ruptela / Eco4
      TrackerDevice(
        id: 'eco4',
        model: 'Eco4',
        manufacturer: 'Ruptela',
        protocol: 'ruptela',
        port: '5025',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5025',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // Garmin / GTU10
      TrackerDevice(
        id: 'gtu10',
        model: 'GTU10',
        manufacturer: 'Garmin',
        protocol: 'garmin',
        port: '5013',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5013',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // Laipac / S920
      TrackerDevice(
        id: 's920',
        model: 'S920',
        manufacturer: 'Laipac',
        protocol: 'laipac',
        port: '5001',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5001',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // Coban / TK303
      TrackerDevice(
        id: 'tk303',
        model: 'TK303',
        manufacturer: 'Coban',
        protocol: 'osmand',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'server,${TrackerConfigData.SERVER_IP},5027',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'apn,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'interval,60',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'sos,5511999999999',
          ),
        ],
      ),

      // JIMI / JIMI-01
      TrackerDevice(
        id: 'jimi01',
        model: 'JIMI-01',
        manufacturer: 'JIMI',
        protocol: 'jimi',
        port: '5009',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5009',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // Enfora / MTX
      TrackerDevice(
        id: 'mtx',
        model: 'MTX',
        manufacturer: 'Enfora',
        protocol: 'enfora',
        port: '5007',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5007',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // Navisys / NT-100
      TrackerDevice(
        id: 'nt100',
        model: 'NT-100',
        manufacturer: 'Navisys',
        protocol: 'navisys',
        port: '5006',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5006',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
        ],
      ),

      // OSMAND (Protocolo genérico)
      TrackerDevice(
        id: 'osmand',
        model: 'OSMAND',
        manufacturer: 'Genérico',
        protocol: 'osmand',
        port: '5027',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'server,${TrackerConfigData.SERVER_IP},5027',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'apn,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'interval,60',
          ),
          TrackerConfigCommand(
            id: 'timezone',
            name: 'Configurar Timezone',
            command: 'timezone,3',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'sos,5511999999999',
          ),
        ],
      ),

      // HOMTECS
      TrackerDevice(
        id: 'homtecs',
        model: 'HOMTECS',
        manufacturer: 'HOMTECS',
        protocol: 'homtecs',
        port: '5004',
        commands: [
          TrackerConfigCommand(
            id: 'server',
            name: 'Configurar Servidor',
            command: 'SERVER,${TrackerConfigData.SERVER_IP},5004',
          ),
          TrackerConfigCommand(
            id: 'apn',
            name: 'Configurar APN',
            command: 'APN,APN_NAME,USERNAME,PASSWORD',
          ),
          TrackerConfigCommand(
            id: 'interval',
            name: 'Intervalo de Envio',
            command: 'INTERVAL,60',
          ),
          TrackerConfigCommand(
            id: 'sos',
            name: 'Número SOS',
            command: 'SOS,5511999999999',
          ),
        ],
      ),
    ];
  }
}

