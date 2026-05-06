import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/ReportModel.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================
// MODELOS
// ============================================

class GeneratedReport {
  final String id;
  final String title;
  final String type;
  final String? url;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int? deviceId;
  final String? deviceName;
  final DateTime? startDate;
  final DateTime? endDate;

  GeneratedReport({
    required this.id,
    required this.title,
    required this.type,
    this.url,
    this.data,
    required this.createdAt,
    this.deviceId,
    this.deviceName,
    this.startDate,
    this.endDate,
  });

  factory GeneratedReport.fromJson(Map<String, dynamic> json) {
    return GeneratedReport(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'url': url,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'deviceId': deviceId,
      'deviceName': deviceName,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

// ============================================
// SERVIÇO DE API
// ============================================

class ReportsApiService {
  late final String baseUrl;
  String? token;

  ReportsApiService({String? baseUrl}) {
    this.baseUrl = (baseUrl == null || baseUrl.isEmpty) ? UserRepository.getServerURL() : baseUrl;
  }

  Future<List<ReportType>> getReportTypes({String lang = 'pt'}) async {
    if (token == null || token!.isEmpty) {
      throw Exception('Token não configurado');
    }

    try {
      final url = Uri.parse('$baseUrl/api/get_reports_types?lang=$lang&user_api_hash=$token');
      
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.get(url, headers: headers).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('A requisição demorou mais de 30 segundos.', Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && (data['status'] == 0 || data['status'] == false)) {
          throw Exception(data['message'] ?? 'Erro ao buscar tipos de relatório');
        }

        List<ReportType> types = [];
        
        // Tentar diferentes estruturas de resposta
        if (data is Map) {
          // Estrutura 1: data['items']['types']
          if (data['items'] != null && data['items'] is Map) {
            final items = data['items'];
            if (items['types'] != null && items['types'] is List) {
              for (var type in items['types']) {
                try {
                  types.add(ReportType.fromJson(Map<String, dynamic>.from(type)));
                } catch (e) {
                  print('Erro ao parsear tipo de relatório: $e');
                }
              }
            }
          }
          // Estrutura 2: data['types'] diretamente
          else if (data['types'] != null && data['types'] is List) {
            for (var type in data['types']) {
              try {
                types.add(ReportType.fromJson(Map<String, dynamic>.from(type)));
              } catch (e) {
                print('Erro ao parsear tipo de relatório: $e');
              }
            }
          }
          // Estrutura 3: data['data']['types']
          else if (data['data'] != null && data['data'] is Map) {
            final dataMap = data['data'];
            if (dataMap['types'] != null && dataMap['types'] is List) {
              for (var type in dataMap['types']) {
                try {
                  types.add(ReportType.fromJson(Map<String, dynamic>.from(type)));
                } catch (e) {
                  print('Erro ao parsear tipo de relatório: $e');
                }
              }
            }
          }
          // Estrutura 4: data['items'] como lista (estrutura real da API)
          else if (data['items'] != null && data['items'] is List) {
            for (var type in data['items']) {
              try {
                types.add(ReportType.fromJson(Map<String, dynamic>.from(type)));
              } catch (e) {
                print('Erro ao parsear tipo de relatório: $e');
              }
            }
          }
        }
        // Estrutura 5: Lista direta
        else if (data is List) {
          for (var type in data) {
            try {
              types.add(ReportType.fromJson(Map<String, dynamic>.from(type)));
            } catch (e) {
              print('Erro ao parsear tipo de relatório: $e');
            }
          }
        }

        // Se não encontrou tipos mas a resposta foi 200, não é erro
        if (types.isEmpty && response.statusCode == 200) {
          print('⚠️ [DEBUG] Nenhum tipo de relatório encontrado na resposta');
        }

        return types;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar tipos de relatório: $e');
      rethrow;
    }
  }

  Future<GeneratedReport> generateReport({
    required int reportTypeId,
    required int deviceId,
    required DateTime fromDate,
    required DateTime toDate,
    String format = 'json',
    String lang = 'pt',
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('Token não configurado');
    }

    try {
      // Formatar datas no formato esperado pela API
      final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate);
      final fromTimeStr = DateFormat('HH:mm:ss').format(fromDate);
      final toDateStr = DateFormat('yyyy-MM-dd').format(toDate);
      final toTimeStr = DateFormat('HH:mm:ss').format(toDate);

      final url = Uri.parse('$baseUrl/api/generate_report?lang=$lang&user_api_hash=$token');
      
      // Payload conforme a API espera (testado e validado)
      final body = jsonEncode({
        'type': reportTypeId,
        'devices': [deviceId],
        'date_from': fromDateStr,
        'from_time': fromTimeStr,
        'date_to': toDateStr,
        'to_time': toTimeStr,
        'format': format,
      });

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      print('🔍 [DEBUG] Gerando relatório:');
      print('   Tipo: $reportTypeId');
      print('   Dispositivo: $deviceId');
      print('   De: $fromDateStr $fromTimeStr');
      print('   Até: $toDateStr $toTimeStr');
      print('   Formato: $format');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            'A requisição demorou mais de 90 segundos. Tente um período menor ou verifique sua conexão.',
            Duration(seconds: 90),
          );
        },
      );

      print('🔍 [DEBUG] Status Code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('❌ [DEBUG] Erro HTTP ${response.statusCode}');
        print('🔍 [DEBUG] Response Body: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      // Verificar se há erro na resposta
      if (data is Map && (data['status'] == 0 || data['status'] == false)) {
        final errorMsg = data['message'] ?? 'Erro ao gerar relatório';
        print('❌ [DEBUG] Erro na resposta da API: $errorMsg');
        throw Exception(errorMsg);
      }

      // Extrair dados diretamente da resposta
      Map<String, dynamic>? reportData;
      String? reportUrl;

      if (data is Map) {
        // A API pode retornar apenas status e url, ou os dados diretamente
        reportUrl = data['url']?.toString();
        
        // Verificar se os dados já estão na resposta
        if (data.containsKey('items') || data.containsKey('totals') || data.containsKey('data')) {
          // Dados estão diretamente na resposta
          reportData = Map<String, dynamic>.from(data);
          reportData.remove('url');
          reportData.remove('status');
          reportData.remove('message');
          
          // Se houver 'data' dentro da resposta, usar esse como dados principais
          if (reportData.containsKey('data') && reportData['data'] is Map) {
            final innerData = reportData['data'] as Map<String, dynamic>;
            reportData = Map<String, dynamic>.from(innerData);
          }
        } else if (reportUrl != null && reportUrl.isNotEmpty) {
          // A API retorna apenas URL - precisamos acessar a URL para obter os dados
          print('🔍 [DEBUG] Acessando URL retornada para obter dados do relatório...');
          
          try {
            final urlResponse = await http.get(
              Uri.parse(reportUrl),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ).timeout(Duration(seconds: 30));
            
            print('📊 [DEBUG] Status Code da URL: ${urlResponse.statusCode}');
            
            if (urlResponse.statusCode == 200) {
              try {
                final urlData = jsonDecode(urlResponse.body);
                
                if (urlData is Map) {
                  print('✅ [DEBUG] Dados obtidos da URL!');
                  print('📊 [DEBUG] Chaves: ${urlData.keys.toList()}');
                  reportData = Map<String, dynamic>.from(urlData);
                } else if (urlData is List) {
                  print('✅ [DEBUG] Lista obtida da URL com ${urlData.length} itens');
                  reportData = {'items': urlData};
                } else {
                  print('⚠️ [DEBUG] Formato de dados inesperado da URL');
                  reportData = null;
                }
              } catch (e) {
                print('❌ [DEBUG] Erro ao decodificar JSON da URL: $e');
                // Tentar verificar se é HTML ou outro formato
                final contentType = urlResponse.headers['content-type'] ?? '';
                if (contentType.contains('text/html')) {
                  print('⚠️ [DEBUG] Resposta é HTML, não JSON');
                }
                reportData = null;
              }
            } else {
              print('❌ [DEBUG] Erro ao acessar URL: ${urlResponse.statusCode}');
              reportData = null;
            }
          } catch (e) {
            print('❌ [DEBUG] Exceção ao acessar URL: $e');
            reportData = null;
          }
        } else {
          // Resposta vazia ou sem estrutura conhecida
          print('⚠️ [DEBUG] Resposta sem URL e sem dados');
          reportData = null;
        }
        
        if (reportData != null) {
          print('📊 [DEBUG] Dados do relatório extraídos: ${reportData.length} campos');
          print('📊 [DEBUG] Chaves: ${reportData.keys.toList()}');
          
          // Verificar se há dados válidos
          bool hasValidData = false;
          if (reportData.containsKey('items') && reportData['items'] is List) {
            hasValidData = (reportData['items'] as List).isNotEmpty;
          } else if (reportData.containsKey('totals') && reportData['totals'] is List) {
            hasValidData = (reportData['totals'] as List).isNotEmpty;
          } else {
            // Verificar se há outros campos com dados (excluindo metadados)
            final dataKeys = reportData.keys.where((key) => 
              !['url', 'status', 'message', 'meta'].contains(key.toLowerCase())
            ).toList();
            hasValidData = dataKeys.isNotEmpty && reportData.values.any((v) => 
              v != null && v.toString().isNotEmpty && v.toString() != 'null'
            );
          }
          
          if (!hasValidData) {
            print('⚠️ [DEBUG] Nenhum dado válido encontrado na resposta');
            reportData = null;
          }
        }
      } else if (data is List) {
        // Se a resposta for uma lista, converter para Map
        reportData = {'items': data};
        print('📊 [DEBUG] Resposta é uma lista com ${data.length} itens');
      }

      return GeneratedReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Relatório Gerado',
        type: reportTypeId.toString(),
        url: reportUrl,
        data: reportData,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Erro ao gerar relatório: $e');
      rethrow;
    }
  }

}

// ============================================
// TELA PRINCIPAL
// ============================================

class ReportsScreen extends StatefulWidget {
  // Função pública para abrir modal de relatório (usada pelo UnnicaBot)
  static void showReportModalFromBot(BuildContext context, ColorProvider colorProvider, {
    required GeneratedReport report,
    required ReportType reportType,
    required String deviceName,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportViewModal(
        report: report,
        reportType: reportType,
        deviceName: deviceName,
        startDate: startDate,
        endDate: endDate,
        colorProvider: colorProvider,
      ),
    );
  }
  final int? deviceId;
  final String? deviceName;

  const ReportsScreen({
    Key? key,
    this.deviceId,
    this.deviceName,
  }) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final ReportsApiService _api = ReportsApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  
  List<ReportType> _reportTypes = [];
  ReportType? _selectedReportType;
  GeneratedReport? _generatedReport;
  bool _isGenerating = false;
  bool _isLoadingTypes = true;
  String? _error;
  
  DateTime _startDate = DateTime.now().subtract(Duration(days: 1));
  DateTime _endDate = DateTime.now();
  int? _selectedDeviceId;
  String? _selectedDeviceName;
  
  // Histórico salvo
  List<GeneratedReport> _savedReports = [];
  bool _isLoadingHistory = false;
  String? _reportFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _savedReports.isEmpty) {
        _loadSavedReports();
      }
      // Atualizar estado quando a aba mudar para atualizar o ícone no cabeçalho
      if (mounted) {
        setState(() {});
      }
    });
    
    _api.token = StaticVarMethod.user_api_hash ?? '';
    _selectedDeviceId = widget.deviceId;
    _selectedDeviceName = widget.deviceName;
    
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(Duration(days: 1));
    
    _loadReportTypes();
    _loadSavedReports();
    
    // Se já tiver dispositivo e tipo selecionado, gerar automaticamente
    if (_selectedDeviceId != null && _selectedReportType != null) {
      _generateReport();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Traduz o nome do tipo de relatório para português brasileiro ou inglês britânico
  String _translateReportTypeName(String originalName) {
    final nameLower = originalName.toLowerCase();
    
    // Mapa de traduções comuns
    final translations = {
      // Informações Gerais
      'general information': TranslationHelper.translateSync(context, 'Informações Gerais', 'General Information'),
      'informações gerais': TranslationHelper.translateSync(context, 'Informações Gerais', 'General Information'),
      'informação geral': TranslationHelper.translateSync(context, 'Informações Gerais', 'General Information'),
      
      // Histórico de Viagem / Folha da Viagem
      'travel history': TranslationHelper.translateSync(context, 'Histórico de Viagem', 'Travel History'),
      'histórico de viagem': TranslationHelper.translateSync(context, 'Histórico de Viagem', 'Travel History'),
      'vehicle history': TranslationHelper.translateSync(context, 'Histórico do Veículo', 'Vehicle History'),
      'histórico do veículo': TranslationHelper.translateSync(context, 'Histórico do Veículo', 'Vehicle History'),
      'daily travel report': TranslationHelper.translateSync(context, 'Folha da Viagem', 'Travel Sheet'),
      'relatório diário de viagem': TranslationHelper.translateSync(context, 'Folha da Viagem', 'Travel Sheet'),
      'travel sheet': TranslationHelper.translateSync(context, 'Folha da Viagem', 'Travel Sheet'),
      'folha da viagem': TranslationHelper.translateSync(context, 'Folha da Viagem', 'Travel Sheet'),
      'folha de viagem': TranslationHelper.translateSync(context, 'Folha da Viagem', 'Travel Sheet'),
      
      // Resumo de Viagem
      'travel summary': TranslationHelper.translateSync(context, 'Resumo de Viagem', 'Travel Summary'),
      'resumo de viagem': TranslationHelper.translateSync(context, 'Resumo de Viagem', 'Travel Summary'),
      'travel summary bulk': TranslationHelper.translateSync(context, 'Resumo de Viagem em Lote', 'Travel Summary Bulk'),
      'resumo de viagem em lote': TranslationHelper.translateSync(context, 'Resumo de Viagem em Lote', 'Travel Summary Bulk'),
      'travel summary with playback image': TranslationHelper.translateSync(context, 'Resumo de Viagem com Imagem', 'Travel Summary with Playback Image'),
      'resumo de viagem com imagem': TranslationHelper.translateSync(context, 'Resumo de Viagem com Imagem', 'Travel Summary with Playback Image'),
      
      // Paradas e Condução
      'drives and stops': TranslationHelper.translateSync(context, 'Condução e Paradas', 'Drives and Stops'),
      'condução e paradas': TranslationHelper.translateSync(context, 'Condução e Paradas', 'Drives and Stops'),
      'stops': TranslationHelper.translateSync(context, 'Paradas', 'Stops'),
      'paradas': TranslationHelper.translateSync(context, 'Paradas', 'Stops'),
      
      // Eventos
      'events': TranslationHelper.translateSync(context, 'Eventos', 'Events'),
      'eventos': TranslationHelper.translateSync(context, 'Eventos', 'Events'),
      'event report': TranslationHelper.translateSync(context, 'Relatório de Eventos', 'Event Report'),
      'relatório de eventos': TranslationHelper.translateSync(context, 'Relatório de Eventos', 'Event Report'),
      
      // Horas de Trabalho
      'work hours daily': TranslationHelper.translateSync(context, 'Horas de Trabalho Diárias', 'Work Hours Daily'),
      'horas de trabalho diárias': TranslationHelper.translateSync(context, 'Horas de Trabalho Diárias', 'Work Hours Daily'),
      'work hours': TranslationHelper.translateSync(context, 'Horas de Trabalho', 'Work Hours'),
      'horas de trabalho': TranslationHelper.translateSync(context, 'Horas de Trabalho', 'Work Hours'),
      
      // Tarefas
      'task report': TranslationHelper.translateSync(context, 'Relatório de Tarefas', 'Task Report'),
      'relatório de tarefas': TranslationHelper.translateSync(context, 'Relatório de Tarefas', 'Task Report'),
      'tasks': TranslationHelper.translateSync(context, 'Tarefas', 'Tasks'),
      'tarefas': TranslationHelper.translateSync(context, 'Tarefas', 'Tasks'),
      
      // Velocidade
      'speed report': TranslationHelper.translateSync(context, 'Relatório de Velocidade', 'Speed Report'),
      'relatório de velocidade': TranslationHelper.translateSync(context, 'Relatório de Velocidade', 'Speed Report'),
      'overspeed': TranslationHelper.translateSync(context, 'Excesso de Velocidade', 'Overspeed'),
      'excesso de velocidade': TranslationHelper.translateSync(context, 'Excesso de Velocidade', 'Overspeed'),
      
      // Combustível
      'fuel report': TranslationHelper.translateSync(context, 'Relatório de Combustível', 'Fuel Report'),
      'relatório de combustível': TranslationHelper.translateSync(context, 'Relatório de Combustível', 'Fuel Report'),
      'fuel consumption': TranslationHelper.translateSync(context, 'Consumo de Combustível', 'Fuel Consumption'),
      'consumo de combustível': TranslationHelper.translateSync(context, 'Consumo de Combustível', 'Fuel Consumption'),
      
      // Distância
      'distance report': TranslationHelper.translateSync(context, 'Relatório de Distância', 'Distance Report'),
      'relatório de distância': TranslationHelper.translateSync(context, 'Relatório de Distância', 'Distance Report'),
      'total distance': TranslationHelper.translateSync(context, 'Distância Total', 'Total Distance'),
      'distância total': TranslationHelper.translateSync(context, 'Distância Total', 'Total Distance'),
      
      // Tempo
      'time report': TranslationHelper.translateSync(context, 'Relatório de Tempo', 'Time Report'),
      'relatório de tempo': TranslationHelper.translateSync(context, 'Relatório de Tempo', 'Time Report'),
      'total time': TranslationHelper.translateSync(context, 'Tempo Total', 'Total Time'),
      'tempo total': TranslationHelper.translateSync(context, 'Tempo Total', 'Total Time'),
      
      // Manutenção
      'maintenance report': TranslationHelper.translateSync(context, 'Relatório de Manutenção', 'Maintenance Report'),
      'relatório de manutenção': TranslationHelper.translateSync(context, 'Relatório de Manutenção', 'Maintenance Report'),
      'maintenance': TranslationHelper.translateSync(context, 'Manutenção', 'Maintenance'),
      'manutenção': TranslationHelper.translateSync(context, 'Manutenção', 'Maintenance'),
      
      // Rotas
      'routes': TranslationHelper.translateSync(context, 'Rotas', 'Routes'),
      'rotas': TranslationHelper.translateSync(context, 'Rotas', 'Routes'),
      'route': TranslationHelper.translateSync(context, 'Rotas', 'Routes'),
      'route history': TranslationHelper.translateSync(context, 'Rotas', 'Routes'),
      'histórico de rotas': TranslationHelper.translateSync(context, 'Rotas', 'Routes'),
      
      // Geofences (mantém tradução mesmo que não seja exibido)
      'geofence in/out': TranslationHelper.translateSync(context, 'Entrada/Saída de Geocerca', 'Geofence In/Out'),
      'entrada/saída de geocerca': TranslationHelper.translateSync(context, 'Entrada/Saída de Geocerca', 'Geofence In/Out'),
      'geofence': TranslationHelper.translateSync(context, 'Geocerca', 'Geofence'),
      'geocerca': TranslationHelper.translateSync(context, 'Geocerca', 'Geofence'),
    };
    
    // Tentar encontrar tradução exata
    if (translations.containsKey(nameLower)) {
      return translations[nameLower]!;
    }
    
    // Tentar encontrar tradução parcial
    for (var entry in translations.entries) {
      if (nameLower.contains(entry.key) || entry.key.contains(nameLower)) {
        return entry.value;
      }
    }
    
    // Se não encontrar, retornar o nome original capitalizado
    return originalName.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  /// Extrai o primeiro nome (primeira palavra) do título
  String _getFirstName(String title) {
    if (title.isEmpty) return '';
    final parts = title.trim().split(' ');
    return parts.isNotEmpty ? parts.first : title;
  }

  /// Extrai o sobrenome (resto do título) do título
  String _getLastName(String title) {
    if (title.isEmpty) return '';
    final parts = title.trim().split(' ');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ');
  }

  Future<void> _loadReportTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _error = null;
    });

    try {
      final types = await _api.getReportTypes(lang: 'pt');
      // Exibir todos os tipos de relatórios sem filtro (como originalmente)
      // Apenas aplicar tradução se necessário, mas manter todos os tipos
      final allTypes = types.map((type) {
        // Manter o título original, apenas capitalizar se necessário
        final title = type.title ?? 'Relatório ${type.id}';
        return ReportType(
          id: type.id,
          title: title,
          value: type.value,
        );
      }).toList();
      
      setState(() {
        _reportTypes = allTypes;
        _isLoadingTypes = false;
      });
      
      print('📊 [DEBUG] Total de tipos recebidos: ${types.length}');
      print('📊 [DEBUG] Tipos exibidos: ${allTypes.length}');
      allTypes.forEach((type) {
        print('   - ${type.title} (ID: ${type.id})');
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingTypes = false;
      });
      // Não mostrar erro como snackbar se for apenas lista vazia
      if (!e.toString().contains('Nenhum') && !e.toString().contains('vazio')) {
        _showError(TranslationHelper.translateSync(context, 'Erro ao carregar tipos de relatório', 'Error loading report types'));
      }
    }
  }

  Future<void> _generateReport() async {
    if (_selectedDeviceId == null) {
      _showError(TranslationHelper.translateSync(context, 'Selecione um dispositivo primeiro', 'Select a device first'));
      return;
    }

    if (_selectedReportType == null) {
      _showError(TranslationHelper.translateSync(context, 'Selecione um tipo de relatório primeiro', 'Select a report type first'));
      return;
    }

    // Validar período muito grande
    final periodDuration = _endDate.difference(_startDate);
    if (periodDuration.inDays > 30) {
      _showError(TranslationHelper.translateSync(context, 'Período muito grande. Selecione no máximo 30 dias.', 'Period too large. Select maximum 30 days.'));
      return;
    }

    print('\n🔄 [DEBUG] ========== GERANDO RELATÓRIO ==========');
    print('📱 Device ID: $_selectedDeviceId');
    print('📋 Tipo de Relatório: ${_selectedReportType!.title} (ID: ${_selectedReportType!.id})');
    print('📅 Data Início: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate)}');
    print('📅 Data Fim: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate)}');

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedReport = null;
    });

    try {
      final report = await _api.generateReport(
        reportTypeId: _selectedReportType!.id!,
        deviceId: _selectedDeviceId!,
        fromDate: _startDate,
        toDate: _endDate,
        format: 'json',
        lang: 'pt',
      );
      
      // Verificar se há dados válidos no relatório
      if (report.data == null || report.data!.isEmpty) {
        setState(() {
          _generatedReport = null;
          _isGenerating = false;
          _error = TranslationHelper.translateSync(
            context,
            'Não há dados para o período selecionado.',
            'No data available for the selected period.'
          );
        });
        _showError(_error!);
        return;
      }
      
      // Verificar se há dados válidos dentro do objeto
      bool hasValidData = false;
      if (report.data!.containsKey('items') && report.data!['items'] is List) {
        hasValidData = (report.data!['items'] as List).isNotEmpty;
      } else if (report.data!.containsKey('totals') && report.data!['totals'] is List) {
        hasValidData = (report.data!['totals'] as List).isNotEmpty;
      } else {
        // Verificar outros campos
        final dataKeys = report.data!.keys.where((key) => 
          !['url', 'status', 'message', 'meta'].contains(key.toLowerCase())
        ).toList();
        hasValidData = dataKeys.isNotEmpty && report.data!.values.any((v) => 
          v != null && v.toString().isNotEmpty && v.toString() != 'null'
        );
      }
      
      if (!hasValidData) {
        setState(() {
          _generatedReport = null;
          _isGenerating = false;
          _error = TranslationHelper.translateSync(
            context,
            'Não há dados para o período selecionado.',
            'No data available for the selected period.'
          );
        });
        _showError(_error!);
        return;
      }
      
      // Adicionar informações adicionais ao relatório
      final reportWithInfo = GeneratedReport(
        id: report.id,
        title: report.title,
        type: report.type,
        url: report.url,
        data: report.data,
        createdAt: report.createdAt,
        deviceId: _selectedDeviceId,
        deviceName: _selectedDeviceName,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      setState(() {
        _generatedReport = reportWithInfo;
        _isGenerating = false;
      });
      
      // Salvar relatório no histórico
      _saveReport(reportWithInfo);
      
      print('✅ [DEBUG] Relatório gerado com sucesso');
    } catch (e) {
      String errorMessage = TranslationHelper.translateSync(context, 'Erro ao gerar relatório', 'Error generating report');
      
      if (e is TimeoutException) {
        errorMessage = TranslationHelper.translateSync(context, 'A requisição demorou muito. Tente um período menor ou verifique sua conexão.', 'Request took too long. Try a shorter period or check your connection.');
      } else if (e.toString().contains('connection') || e.toString().contains('Connection')) {
        errorMessage = TranslationHelper.translateSync(context, 'Erro de conexão. Verifique sua internet.', 'Connection error. Check your internet.');
      } else if (e.toString().contains('401') || e.toString().contains('authentication')) {
        errorMessage = TranslationHelper.translateSync(context, 'Erro de autenticação. Faça login novamente.', 'Authentication error. Please login again.');
      } else {
        errorMessage = '${TranslationHelper.translateSync(context, 'Erro', 'Error')}: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }
      
      setState(() {
        _error = errorMessage;
        _isGenerating = false;
      });
      
      _showError(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _selectDevice() async {
    try {
      final url = Uri.parse('${UserRepository.getServerURL()}/api/get_devices');
      
      final body = jsonEncode({});
      
      final headers = {
        'Authorization': 'Bearer ${StaticVarMethod.user_api_hash ?? ''}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw TimeoutException(
            TranslationHelper.translateSync(context, 'A requisição demorou mais de 90 segundos. Tente um período menor ou verifique sua conexão.', 'Request took more than 90 seconds. Try a shorter period or check your connection.'),
            Duration(seconds: 90),
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map && (data['status'] == 0 || data['status'] == false)) {
          _showError(data['message'] ?? TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices'));
          return;
        }

        List<Map<String, dynamic>> devices = [];
        
        if (data is List) {
          for (var group in data) {
            if (group is Map && group['items'] != null && group['items'] is List) {
              final groupItems = group['items'] as List;
              for (var item in groupItems) {
                if (item is Map<String, dynamic>) {
                  devices.add(item);
                } else if (item is Map) {
                  devices.add(Map<String, dynamic>.from(item));
                }
              }
            }
          }
        } else if (data is Map && data['items'] != null && data['items'] is List) {
          for (var item in data['items']) {
            if (item is Map<String, dynamic>) {
              devices.add(item);
            } else if (item is Map) {
              devices.add(Map<String, dynamic>.from(item));
            }
          }
        }

        if (devices.isEmpty) {
          _showError(TranslationHelper.translateSync(context, 'Nenhum dispositivo disponível', 'No devices available'));
          return;
        }

        final colorProvider = Provider.of<ColorProvider>(context, listen: false);
        
        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.devices, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Lista de dispositivos
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final deviceId = device['id'];
                      final deviceIdStr = deviceId?.toString() ?? '';
                      final deviceName = device['name'] ?? device['display'] ?? 'Dispositivo $deviceIdStr';
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                          title: Text(
                            deviceName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: device['plate'] != null 
                              ? Text('${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${device['plate']}')
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: colorProvider.primaryColor,
                            size: 18,
                          ),
                          onTap: () => Navigator.pop(context, device),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );

        if (selected != null) {
          final deviceId = selected['id'];
          int? deviceIdInt;
          
          if (deviceId is int) {
            deviceIdInt = deviceId;
          } else if (deviceId is String) {
            deviceIdInt = int.tryParse(deviceId);
          } else if (deviceId != null) {
            deviceIdInt = int.tryParse(deviceId.toString());
          }
          
          if (deviceIdInt != null) {
            setState(() {
              _selectedDeviceId = deviceIdInt;
              _selectedDeviceName = selected['name'] ?? selected['display'] ?? 'Dispositivo $deviceIdInt';
            });
            
            // Gerar relatório automaticamente se tipo já estiver selecionado
            if (_selectedReportType != null) {
              _generateReport();
            }
          } else {
            _showError(TranslationHelper.translateSync(context, 'ID do dispositivo inválido', 'Invalid device ID'));
          }
        }
      } else {
        _showError('${TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices')}: ${response.statusCode}');
      }
    } catch (e) {
      _showError('${TranslationHelper.translateSync(context, 'Erro ao buscar dispositivos', 'Error fetching devices')}: $e');
    }
  }

  Future<void> _selectReportType() async {
    if (_isLoadingTypes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Carregando tipos de relatório...', 'Loading report types...')),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    if (_reportTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Nenhum tipo de relatório disponível. Tente novamente mais tarde.', 'No report types available. Please try again later.')),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      // Tentar recarregar os tipos
      _loadReportTypes();
      return;
    }

    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    
    final selected = await showModalBottomSheet<ReportType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TranslationHelper.translateSync(context, 'Selecionar Tipo de Relatório', 'Select Report Type'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Lista de tipos de relatório (sem duplicatas)
            Expanded(
              child: Builder(
                builder: (context) {
                  // Remover duplicatas baseado no ID
                  final uniqueTypes = <int, ReportType>{};
                  for (var type in _reportTypes) {
                    if (type.id != null && !uniqueTypes.containsKey(type.id)) {
                      uniqueTypes[type.id!] = type;
                    }
                  }
                  final uniqueTypesList = uniqueTypes.values.toList();
                  
                  return ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: uniqueTypesList.length,
                    itemBuilder: (context, index) {
                      final reportType = uniqueTypesList[index];
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insert_chart,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                          title: Text(
                            reportType.title ?? 'Relatório ${reportType.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: colorProvider.primaryColor,
                            size: 18,
                          ),
                          onTap: () => Navigator.pop(context, reportType),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedReportType = selected;
      });
      
      // Gerar relatório automaticamente se dispositivo já estiver selecionado
      if (_selectedDeviceId != null) {
        _generateReport();
      }
    }
  }

  Future<void> _selectPeriod() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      final startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        0,
        0,
        0,
      );
      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      
      setState(() {
        _startDate = startDate;
        _endDate = endDate;
      });
      
      // Gerar relatório automaticamente se dispositivo e tipo já estiverem selecionados
      if (_selectedDeviceId != null && _selectedReportType != null) {
        _generateReport();
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colorProvider.secondaryColor, // Cor secundária no fundo do cabeçalho
        flexibleSpace: SafeArea(
          child: Column(
            children: [
              // Cabeçalho principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Ícone da página
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insert_chart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    // Título
                    Expanded(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Relatórios', 'Reports'),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Ícone para alternar entre abas
                    IconButton(
                      icon: Icon(
                        _tabController.index == 0 ? Icons.history : Icons.insert_chart,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _tabController.animateTo(_tabController.index == 0 ? 1 : 0);
                        });
                      },
                      tooltip: _tabController.index == 0
                          ? TranslationHelper.translateSync(context, 'Histórico de Relatórios', 'Report History')
                          : TranslationHelper.translateSync(context, 'Gerar Relatório', 'Generate Report'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Aba 1: Gerar Relatório
                  Column(
                    children: [
                      _buildFiltersSection(colorProvider),
                      
                      if (_selectedDeviceId != null && _selectedReportType != null && _generatedReport != null) ...[
                        _buildReportDescription(colorProvider),
                      ],
                      
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_selectedDeviceId == null || _selectedReportType == null)
                                _buildEmptyState(colorProvider, 
                                    _selectedDeviceId == null 
                                        ? TranslationHelper.translateSync(context, 'Selecione um dispositivo primeiro', 'Select a device first')
                                        : TranslationHelper.translateSync(context, 'Selecione um tipo de relatório primeiro', 'Select a report type first'),
                                    _selectedDeviceId == null ? Icons.devices : Icons.description,
                                    _selectedDeviceId == null ? _selectDevice : _selectReportType)
                              else if (_error != null)
                                _buildErrorState(colorProvider)
                              else if (_isGenerating)
                                _buildLoadingState(colorProvider)
                              else if (_generatedReport == null)
                                _buildEmptyState(colorProvider, 
                                    TranslationHelper.translateSync(context, 'Nenhum relatório gerado ainda', 'No report generated yet'),
                                    Icons.insert_chart,
                                    null)
                              else
                                _buildReportResult(colorProvider),
                              
                              // Botão de visualizar no final do conteúdo scrollável
                              if (_selectedDeviceId != null && _selectedReportType != null && _generatedReport != null) ...[
                                SizedBox(height: 16),
                                _buildViewReportButton(colorProvider),
                                SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Aba 2: Histórico de Relatórios
                  _buildHistoryTab(colorProvider),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildReportTypeSelector(colorProvider),
          SizedBox(height: 8),
          _buildDeviceSelector(colorProvider),
          SizedBox(height: 8),
          _buildPeriodSelector(colorProvider),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(ColorProvider colorProvider) {
    return InkWell(
      onTap: _isLoadingTypes ? null : _selectReportType,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorProvider.primaryColor.withOpacity(0.1),
              colorProvider.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorProvider.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoadingTypes
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                      ),
                    )
                  : Icon(Icons.description, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingTypes)
                    Text(
                      TranslationHelper.translateSync(context, 'Carregando tipos...', 'Loading types...'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    )
                  else if (_selectedReportType == null)
                    Text(
                      TranslationHelper.translateSync(context, 'Selecionar Tipo de Relatório', 'Select Report Type'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome (primeira palavra)
                        Text(
                          _getFirstName(_selectedReportType!.title ?? 'Relatório ${_selectedReportType!.id}'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2),
                        // Sobrenome (resto)
                        Text(
                          _getLastName(_selectedReportType!.title ?? 'Relatório ${_selectedReportType!.id}'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  if (_isLoadingTypes) ...[
                    SizedBox(height: 4),
                    Text(
                      TranslationHelper.translateSync(context, 'Aguarde enquanto carregamos os tipos', 'Please wait while we load types'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else if (_selectedReportType == null) ...[
                    SizedBox(height: 4),
                    Text(
                      (_reportTypes.isEmpty 
                          ? TranslationHelper.translateSync(context, 'Nenhum tipo disponível', 'No types available')
                          : TranslationHelper.translateSync(context, 'Toque para escolher um tipo de relatório', 'Tap to choose a report type')),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_isLoadingTypes)
              Icon(Icons.arrow_forward_ios, color: colorProvider.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelector(ColorProvider colorProvider) {
    return InkWell(
      onTap: _selectDevice,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorProvider.primaryColor.withOpacity(0.1),
              colorProvider.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorProvider.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.devices, color: colorProvider.primaryColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDeviceId == null 
                        ? TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device')
                        : TranslationHelper.translateSync(context, 'Dispositivo Selecionado', 'Device Selected'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedDeviceId == null
                        ? TranslationHelper.translateSync(context, 'Toque para escolher um veículo', 'Tap to choose a vehicle')
                        : (_selectedDeviceName ?? 'Dispositivo $_selectedDeviceId'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colorProvider.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ColorProvider colorProvider) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _selectPeriod,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today, color: colorProvider.primaryColor, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationHelper.translateSync(context, 'Período', 'Period'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.grey[600], size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildReportDescription(ColorProvider colorProvider) {

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorProvider.primaryColor.withOpacity(0.1),
            colorProvider.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorProvider.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorProvider.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: colorProvider.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Descrição do Relatório', 'Report Description'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Builder(
            builder: (context) {
              // Calcular total de registros/dados
              int totalRecords = 0;
              String totalText = '';
              
              if (_generatedReport?.data != null) {
                final data = _generatedReport!.data!;
                
                // Verificar se há items (lista de registros)
                if (data.containsKey('items') && data['items'] is List) {
                  totalRecords = (data['items'] as List).length;
                  totalText = TranslationHelper.translateSync(
                    context,
                    'Total: $totalRecords ${totalRecords == 1 ? 'registro' : 'registros'}',
                    'Total: $totalRecords ${totalRecords == 1 ? 'record' : 'records'}',
                  );
                }
                // Verificar se há totals
                else if (data.containsKey('totals') && data['totals'] is List) {
                  totalRecords = (data['totals'] as List).length;
                  totalText = TranslationHelper.translateSync(
                    context,
                    'Total: $totalRecords ${totalRecords == 1 ? 'item' : 'itens'}',
                    'Total: $totalRecords ${totalRecords == 1 ? 'item' : 'items'}',
                  );
                }
                // Contar campos de dados disponíveis
                else if (data.isNotEmpty) {
                  // Contar campos que não são metadados
                  final dataFields = data.keys.where((key) => 
                    !['url', 'status', 'message', 'meta'].contains(key.toLowerCase())
                  ).length;
                  totalText = TranslationHelper.translateSync(
                    context,
                    'Total: $dataFields ${dataFields == 1 ? 'campo de dados' : 'campos de dados'}',
                    'Total: $dataFields ${dataFields == 1 ? 'data field' : 'data fields'}',
                  );
                }
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translateSync(
                      context,
                      'Relatório de ${_selectedReportType?.title ?? 'relatório'} do veículo ${_selectedDeviceName ?? 'N/A'} no período de ${DateFormat('dd/MM/yyyy').format(_startDate)} a ${DateFormat('dd/MM/yyyy').format(_endDate)}.',
                      'Report of ${_selectedReportType?.title ?? 'report'} for vehicle ${_selectedDeviceName ?? 'N/A'} in the period from ${DateFormat('dd/MM/yyyy').format(_startDate)} to ${DateFormat('dd/MM/yyyy').format(_endDate)}.',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  if (totalText.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        totalText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewReportButton(ColorProvider colorProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _generatedReport != null ? () => _showReportModal(context, colorProvider) : null,
              icon: Icon(Icons.visibility, color: Colors.white),
              label: Text(TranslationHelper.translateSync(context, 'Visualizar Relatório', 'View Report')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportResult(ColorProvider colorProvider) {
    if (_generatedReport == null) {
      return _buildEmptyState(colorProvider, 
          TranslationHelper.translateSync(context, 'Nenhum relatório gerado ainda', 'No report generated yet'),
          Icons.insert_chart,
          null);
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.insert_chart, color: colorProvider.primaryColor, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedReportType?.title ?? TranslationHelper.translateSync(context, 'Relatório Gerado', 'Generated Report'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_generatedReport!.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showReportModal(context, colorProvider),
                icon: Icon(Icons.visibility, color: Colors.white),
                label: Text(TranslationHelper.translateSync(context, 'Visualizar Relatório', 'View Report')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorProvider colorProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            TranslationHelper.translateSync(context, 'Gerando relatório...', 'Generating report...'),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorProvider colorProvider, String message, IconData icon, VoidCallback? onTap) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: colorProvider.primaryColor.withOpacity(0.6)),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (onTap != null) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.add),
                label: Text(message.contains('dispositivo') || message.contains('device')
                    ? TranslationHelper.translateSync(context, 'Selecionar Dispositivo', 'Select Device')
                    : TranslationHelper.translateSync(context, 'Selecionar Tipo de Relatório', 'Select Report Type')),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: colorProvider.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorProvider colorProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            ),
            SizedBox(height: 24),
            Text(
              TranslationHelper.translateSync(context, 'Erro ao gerar relatório', 'Error generating report'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: Icon(Icons.refresh),
              label: Text(TranslationHelper.translateSync(context, 'Tentar Novamente', 'Try Again')),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: colorProvider.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportModal(BuildContext context, ColorProvider colorProvider, {GeneratedReport? report, ReportType? reportType}) {
    final reportToShow = report ?? _generatedReport;
    final reportTypeToShow = reportType ?? _selectedReportType;
    
    if (reportToShow == null || reportTypeToShow == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportViewModal(
        report: reportToShow,
        reportType: reportTypeToShow,
        deviceName: reportToShow.deviceName ?? _selectedDeviceName ?? 'N/A',
        startDate: reportToShow.startDate ?? _startDate,
        endDate: reportToShow.endDate ?? _endDate,
        colorProvider: colorProvider,
      ),
    );
  }

  Future<void> _saveReport(GeneratedReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList('saved_reports') ?? [];
      reportsJson.insert(0, jsonEncode(report.toJson()));
      
      // Limitar a 50 relatórios salvos
      if (reportsJson.length > 50) {
        reportsJson.removeRange(50, reportsJson.length);
      }
      
      await prefs.setStringList('saved_reports', reportsJson);
    } catch (e) {
      print('Erro ao salvar relatório: $e');
    }
  }

  Future<void> _loadSavedReports() async {
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList('saved_reports') ?? [];
      
      final reports = reportsJson.map((json) {
        try {
          return GeneratedReport.fromJson(jsonDecode(json));
        } catch (e) {
          print('Erro ao parsear relatório: $e');
          return null;
        }
      }).whereType<GeneratedReport>().toList();
      
      setState(() {
        _savedReports = reports;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Widget _buildHistoryTab(ColorProvider colorProvider) {
    final filteredReports = _reportFilter != null && _reportFilter!.isNotEmpty
        ? _savedReports.where((r) => 
            (r.deviceName ?? '').toLowerCase().contains(_reportFilter!.toLowerCase()) ||
            r.title.toLowerCase().contains(_reportFilter!.toLowerCase()) ||
            r.type.toLowerCase().contains(_reportFilter!.toLowerCase()) ||
            r.id.contains(_reportFilter!)
          ).toList()
        : _savedReports;

    return Column(
      children: [
        // Filtro
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            decoration: InputDecoration(
              hintText: TranslationHelper.translateSync(context, 'Filtrar por veículo, tipo ou ID...', 'Filter by vehicle, type or ID...'),
              prefixIcon: Icon(Icons.search, color: colorProvider.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorProvider.primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorProvider.primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _reportFilter = value;
              });
            },
          ),
        ),
        
        // Lista de relatórios
        Expanded(
          child: _isLoadingHistory
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
                  ),
                )
              : filteredReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            TranslationHelper.translateSync(context, 'Nenhum relatório salvo', 'No saved reports'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _buildHistoryCard(report, colorProvider);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(GeneratedReport report, ColorProvider colorProvider) {
    // Encontrar o tipo de relatório correspondente
    ReportType? reportType;
    try {
      reportType = _reportTypes.firstWhere(
        (type) => type.id?.toString() == report.type || type.title?.toLowerCase() == report.type.toLowerCase(),
        orElse: () => ReportType(id: null, title: report.type, value: report.type),
      );
    } catch (e) {
      reportType = ReportType(id: null, title: report.title, value: report.type);
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAtStr = dateFormat.format(report.createdAt);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showReportModal(context, colorProvider, report: report, reportType: reportType);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.insert_chart,
                      color: colorProvider.primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        if (report.deviceName != null)
                          Text(
                            report.deviceName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    createdAtStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (report.startDate != null && report.endDate != null) ...[
                    SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${DateFormat('dd/MM/yyyy').format(report.startDate!)} - ${DateFormat('dd/MM/yyyy').format(report.endDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// MODAL DE VISUALIZAÇÃO DO RELATÓRIO
// ============================================

class _ReportViewModal extends StatefulWidget {
  final GeneratedReport report;
  final ReportType reportType;
  final String deviceName;
  final DateTime startDate;
  final DateTime endDate;
  final ColorProvider colorProvider;

  const _ReportViewModal({
    required this.report,
    required this.reportType,
    required this.deviceName,
    required this.startDate,
    required this.endDate,
    required this.colorProvider,
  });

  @override
  State<_ReportViewModal> createState() => _ReportViewModalState();
}

class _ReportViewModalState extends State<_ReportViewModal> {
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _reportData;
  bool _isLoadingData = true;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    // Usar diretamente os dados retornados pela API generate_report
    // Não fazer chamadas adicionais - os dados já vêm na resposta
    if (mounted) {
      setState(() {
        _isLoadingData = false;
        
        if (widget.report.data != null && widget.report.data!.isNotEmpty) {
          // Verificar se há dados válidos
          bool hasValidData = false;
          
          if (widget.report.data!.containsKey('items') && widget.report.data!['items'] is List) {
            hasValidData = (widget.report.data!['items'] as List).isNotEmpty;
          } else if (widget.report.data!.containsKey('totals') && widget.report.data!['totals'] is List) {
            hasValidData = (widget.report.data!['totals'] as List).isNotEmpty;
          } else {
            // Verificar se há outros campos com dados (excluindo metadados)
            final dataKeys = widget.report.data!.keys.where((key) => 
              !['url', 'status', 'message', 'meta'].contains(key.toLowerCase())
            ).toList();
            hasValidData = dataKeys.isNotEmpty && widget.report.data!.values.any((v) => 
              v != null && v.toString().isNotEmpty && v.toString() != 'null'
            );
          }
          
          if (hasValidData) {
            _reportData = widget.report.data;
            print('📊 [DEBUG] Dados do relatório carregados: ${_reportData!.length} campos');
          } else {
            _loadingError = TranslationHelper.translateSync(
              context,
              'Não há dados para o período selecionado.',
              'No data available for the selected period.'
            );
          }
        } else {
          _loadingError = TranslationHelper.translateSync(
            context,
            'Não há dados para o período selecionado.',
            'No data available for the selected period.'
          );
        }
      });
    }
  }

  Future<void> _shareOnWhatsApp() async {
    try {
      final periodText = '${DateFormat('dd/MM/yyyy').format(widget.startDate)} a ${DateFormat('dd/MM/yyyy').format(widget.endDate)}';
      
      // Construir mensagem com todos os dados do relatório
      StringBuffer messageBuffer = StringBuffer();
      messageBuffer.writeln('📊 *RELATÓRIO DE RASTREAMENTO*');
      messageBuffer.writeln('');
      messageBuffer.writeln('📋 *Tipo:* ${widget.reportType.title ?? 'N/A'}');
      messageBuffer.writeln('🚗 *Veículo:* ${widget.deviceName}');
      messageBuffer.writeln('📅 *Período:* $periodText');
      messageBuffer.writeln('🕐 *Gerado em:* ${DateFormat('dd/MM/yyyy HH:mm').format(widget.report.createdAt)}');
      messageBuffer.writeln('');
      
      // Adicionar dados do relatório se disponíveis
      if (_reportData != null && _reportData!.isNotEmpty) {
        messageBuffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        messageBuffer.writeln('📈 *DADOS DO RELATÓRIO*');
        messageBuffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        messageBuffer.writeln('');
        
        // Processar items se existirem
        if (_reportData!.containsKey('items') && _reportData!['items'] is List) {
          final items = _reportData!['items'] as List;
          
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            if (item is Map) {
              final itemMap = item as Map<String, dynamic>;
              
              // Processar totals dentro de cada item
              if (itemMap.containsKey('totals') && itemMap['totals'] is Map) {
                final totals = itemMap['totals'] as Map<String, dynamic>;
                
                // Adicionar campos importantes primeiro
                final importantFields = [
                  'position_count', 'duration', 'distance',
                  'speed_max', 'speed_avg', 'drive_distance',
                  'stop_count', 'stop_duration', 'engine_hours',
                  'overspeed_count', 'start', 'end'
                ];
                
                // Adicionar campos importantes
                for (var fieldKey in importantFields) {
                  if (totals.containsKey(fieldKey)) {
                    final field = totals[fieldKey];
                    if (field is Map) {
                      final title = field['title']?.toString() ?? fieldKey;
                      final value = field['value'];
                      if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
                        messageBuffer.writeln('• *$title:* $value');
                      }
                    } else if (field != null && field.toString().isNotEmpty && field.toString() != 'null') {
                      messageBuffer.writeln('• *$fieldKey:* $field');
                    }
                  }
                }
                
                // Adicionar outros campos
                totals.forEach((key, value) {
                  if (!importantFields.contains(key)) {
                    if (value is Map) {
                      final title = value['title']?.toString() ?? key;
                      final val = value['value'];
                      if (val != null && val.toString().isNotEmpty && val.toString() != 'null') {
                        messageBuffer.writeln('• *$title:* $val');
                      }
                    } else if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
                      messageBuffer.writeln('• *$key:* $value');
                    }
                  }
                });
              }
              
              if (items.length > 1) {
                messageBuffer.writeln('');
                messageBuffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              }
            }
          }
        } else {
          // Se não houver items, tentar processar outros campos
            _reportData!.forEach((key, value) {
              final keyLower = key.toLowerCase();
              if (!['url', 'status', 'message', 'meta'].contains(keyLower)) {
                if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
                  messageBuffer.writeln('• *${_formatKeyForShare(key)}:* $value');
                }
              }
            });
        }
      }
      
      final message = messageBuffer.toString();
      
      // Limitar tamanho da mensagem (WhatsApp tem limite de ~4096 caracteres)
      final finalMessage = message.length > 4000 
          ? message.substring(0, 4000) + '\n\n... (mensagem truncada)'
          : message;

      final link = WhatsAppUnilink(
        phoneNumber: '', // Número será preenchido pelo app
        text: finalMessage,
      );

      await launchUrl(link.asUri());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao compartilhar no WhatsApp', 'Error sharing on WhatsApp')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _formatKeyForShare(String key) {
    // Converter chaves para formato legível (versão para compartilhamento)
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  Future<void> _downloadPdf() async {
    if (widget.report.url == null || widget.report.url!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'URL do relatório não disponível', 'Report URL not available')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final url = widget.report.url!;
      
      // Adicionar parâmetro format=pdf se não estiver presente
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      if (!queryParams.containsKey('format') || queryParams['format'] != 'pdf') {
        queryParams['format'] = 'pdf';
        final newUri = uri.replace(queryParameters: queryParams);
        final response = await http.get(
          newUri,
          headers: {
            'Authorization': 'Bearer ${StaticVarMethod.user_api_hash ?? ''}',
            'Accept': 'application/pdf',
          },
        );
        
        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'] ?? '';
          
          // Verificar se realmente é PDF
          if (contentType.contains('pdf') || response.bodyBytes.length > 0) {
            final directory = await getApplicationDocumentsDirectory();
            final fileName = 'relatorio_${widget.reportType.title?.replaceAll(' ', '_') ?? 'relatorio'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
            final file = File('${directory.path}/$fileName');
            
            await file.writeAsBytes(response.bodyBytes);
            
            // Criar mensagem descritiva para compartilhar
            final periodText = '${DateFormat('dd/MM/yyyy').format(widget.startDate)} a ${DateFormat('dd/MM/yyyy').format(widget.endDate)}';
            final shareText = TranslationHelper.translateSync(
              context,
              'Relatório: ${widget.reportType.title}\nVeículo: ${widget.deviceName}\nPeríodo: $periodText',
              'Report: ${widget.reportType.title}\nVehicle: ${widget.deviceName}\nPeriod: $periodText',
            );
            
            await Share.shareXFiles(
              [XFile(file.path)],
              text: shareText,
            );
          } else {
            throw Exception('Resposta não é um PDF válido. Content-Type: $contentType');
          }
        } else {
          throw Exception('Erro ao baixar PDF: ${response.statusCode}');
        }
      } else {
        // URL já tem format=pdf, usar diretamente
        final response = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer ${StaticVarMethod.user_api_hash ?? ''}',
            'Accept': 'application/pdf',
          },
        );
        
        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'relatorio_${widget.reportType.title?.replaceAll(' ', '_') ?? 'relatorio'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
          final file = File('${directory.path}/$fileName');
          
          await file.writeAsBytes(response.bodyBytes);
          
          final periodText = '${DateFormat('dd/MM/yyyy').format(widget.startDate)} a ${DateFormat('dd/MM/yyyy').format(widget.endDate)}';
          final shareText = TranslationHelper.translateSync(
            context,
            'Relatório: ${widget.reportType.title}\nVeículo: ${widget.deviceName}\nPeríodo: $periodText',
            'Report: ${widget.reportType.title}\nVehicle: ${widget.deviceName}\nPeriod: $periodText',
          );
          
          await Share.shareXFiles(
            [XFile(file.path)],
            text: shareText,
          );
        } else {
          throw Exception('Erro ao baixar PDF: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ [DEBUG] Erro ao baixar PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao baixar PDF', 'Error downloading PDF')}: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: widget.colorProvider.primaryColor,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Ícone da página
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.insert_chart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.reportType.title ?? TranslationHelper.translateSync(context, 'Relatório', 'Report'),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botão fechar
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: TranslationHelper.translateSync(context, 'Fechar', 'Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Conteúdo com scroll
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: _buildReportContent(),
            ),
          ),
          
          // Botões de ação
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _shareOnWhatsApp,
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text(TranslationHelper.translateSync(context, 'Compartilhar', 'Share')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _downloadPdf,
                    icon: _isGeneratingPdf
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(_isGeneratingPdf 
                        ? TranslationHelper.translateSync(context, 'Gerando...', 'Generating...')
                        : TranslationHelper.translateSync(context, 'Baixar PDF', 'Download PDF')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_isLoadingData) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.colorProvider.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Carregando dados do relatório...', 'Loading report data...'),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                _loadingError!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
                label: Text(TranslationHelper.translateSync(context, 'Fechar', 'Close')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colorProvider.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_reportData == null || _reportData!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(context, 'Não há dados para o período selecionado.', 'No data available for the selected period.'),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Converter dados do relatório em cards
    print('📊 [DEBUG] Convertendo dados para cards. Total de campos: ${_reportData!.length}');
    final cards = _convertDataToCards(_reportData!);
    print('📊 [DEBUG] Cards gerados: ${cards.length}');

    // Sempre mostrar informações gerais, mesmo se não houver outros dados

    // Cards de informações gerais
    final infoCards = [
      _buildDataCard(TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'), widget.deviceName),
      _buildDataCard(TranslationHelper.translateSync(context, 'Tipo de Relatório', 'Report Type'), widget.reportType.title ?? 'N/A'),
      _buildDataCard(TranslationHelper.translateSync(context, 'Data Início', 'Start Date'), DateFormat('dd/MM/yyyy HH:mm').format(widget.startDate)),
      _buildDataCard(TranslationHelper.translateSync(context, 'Data Fim', 'End Date'), DateFormat('dd/MM/yyyy HH:mm').format(widget.endDate)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informações gerais com 2 cards por linha
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.colorProvider.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.colorProvider.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationHelper.translateSync(context, 'Informações Gerais', 'General Information'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.colorProvider.primaryColor,
                ),
              ),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: infoCards.length,
                itemBuilder: (context, index) {
                  return infoCards[index];
                },
              ),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Dados do relatório em grid
        if (cards.isNotEmpty) ...[
          Text(
            TranslationHelper.translateSync(context, 'Dados do Relatório', 'Report Data'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return cards[index];
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _convertDataToCards(Map<String, dynamic> data) {
    List<Widget> cards = [];
    
    // Filtrar chaves que não devem ser exibidas (já estão em Informações Gerais ou são metadados)
    final excludedKeys = [
      'vehicle', 'veiculo', 'device', 'dispositivo', 
      'type', 'tipo', 'report_type', 'tipo_relatorio',
      'start_date', 'end_date', 'data_inicio', 'data_fim',
      'created_at', 'updated_at', 'url', 'status'
    ];
    
    print('📊 [DEBUG] Processando ${data.length} campos do relatório');
    print('📊 [DEBUG] Chaves disponíveis: ${data.keys.toList()}');
    
    // Função auxiliar para processar um Map recursivamente
    void processMap(Map<String, dynamic> map, String prefix) {
      map.forEach((key, value) {
        final keyLower = key.toLowerCase();
        final fullKey = prefix.isEmpty ? key : '$prefix $key';
        
        // Ignorar chaves excluídas
        // NOTA: 'totals' dentro de items[] NÃO deve ser ignorado aqui,
        // pois é processado especificamente na função _convertDataToCards
        if (excludedKeys.contains(keyLower) || 
            keyLower == 'meta' || 
            keyLower == 'items') {
          return;
        }
        
        // Ignorar 'totals' apenas se estiver no nível raiz (não dentro de items)
        // Isso é verificado pelo contexto - se estamos processando items[].totals,
        // não devemos ignorar
        if (keyLower == 'totals' && prefix.isEmpty) {
          return;
        }
        
        // Ignorar URLs muito longas
        if (keyLower.contains('url') && value.toString().length > 100) {
          return;
        }
        
        if (value == null || value.toString().isEmpty || value.toString() == 'null') {
          return;
        }
        
        // Se for um Map, processar recursivamente
        if (value is Map) {
          processMap(value as Map<String, dynamic>, fullKey);
        } 
        // Se for uma List, processar itens ou mostrar contagem
        else if (value is List) {
          if (value.isEmpty) {
            return;
          }
          
          // Se a lista contém Maps, processar o primeiro como exemplo
          if (value.isNotEmpty && value[0] is Map) {
            // Processar apenas o primeiro item para não sobrecarregar
            processMap(value[0] as Map<String, dynamic>, fullKey);
            
            // Se houver mais de um item, adicionar contagem
            if (value.length > 1) {
              cards.add(_buildDataCard(
                _formatKey(fullKey),
                '${value.length} ${TranslationHelper.translateSync(context, 'itens', 'items')}'
              ));
            }
          } else {
            // Lista de valores simples, mostrar contagem
            cards.add(_buildDataCard(
              _formatKey(fullKey),
              '${value.length} ${TranslationHelper.translateSync(context, 'itens', 'items')}'
            ));
          }
        }
        // Valor simples
        else {
          String displayKey = _formatKey(fullKey);
          String displayValue = _formatValue(value);
          
          // Truncar valores muito longos
          if (displayValue.length > 100) {
            displayValue = displayValue.substring(0, 97) + '...';
          }
          
          if (displayKey.isNotEmpty && displayValue.isNotEmpty && displayValue != 'null') {
            print('📊 [DEBUG] Adicionando card: $displayKey = $displayValue');
            cards.add(_buildDataCard(displayKey, displayValue));
          }
        }
      });
    }
    
    // Processar estrutura específica da API (meta, items, totals)
    if (data.containsKey('meta') && data['meta'] is Map) {
      final meta = data['meta'] as Map<String, dynamic>;
      print('📊 [DEBUG] Processando meta: ${meta.length} campos');
      processMap(meta, '');
    }
    
    // Processar 'totals' se existir
    if (data.containsKey('totals') && data['totals'] is List) {
      final totals = data['totals'] as List;
      print('📊 [DEBUG] Processando totals: ${totals.length} itens');
      
      for (var total in totals) {
        if (total is Map) {
          processMap(total as Map<String, dynamic>, 'Total');
        }
      }
    }
    
    // Processar 'items' se existir
    if (data.containsKey('items') && data['items'] is List) {
      final items = data['items'] as List;
      print('📊 [DEBUG] Processando items: ${items.length} registros');
      
      if (items.isNotEmpty) {
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          if (item is Map) {
            final itemMap = item as Map<String, dynamic>;
            
            // Processar especificamente o campo 'totals' dentro de cada item
            // que contém os dados estatísticos reais
            if (itemMap.containsKey('totals') && itemMap['totals'] is Map) {
              final totals = itemMap['totals'] as Map<String, dynamic>;
              print('📊 [DEBUG] Processando totals do item ${i + 1}: ${totals.length} campos');
              
              // Processar cada campo de totals
              totals.forEach((key, value) {
                if (value is Map) {
                  // Estrutura: {title: "...", value: ...}
                  final title = value['title']?.toString() ?? key;
                  final val = value['value'];
                  
                  if (val != null && val.toString().isNotEmpty && val.toString() != 'null') {
                    String displayKey = _formatKey(title.isNotEmpty ? title : key);
                    String displayValue = _formatValue(val);
                    
                    print('📊 [DEBUG] Adicionando card de total: $displayKey = $displayValue');
                    cards.add(_buildDataCard(displayKey, displayValue));
                  }
                } else if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
                  // Valor direto (não é um Map com title/value)
                  String displayKey = _formatKey(key);
                  String displayValue = _formatValue(value);
                  
                  print('📊 [DEBUG] Adicionando card: $displayKey = $displayValue');
                  cards.add(_buildDataCard(displayKey, displayValue));
                }
              });
            }
            
            // Processar outros campos do item (exceto meta e totals que já foram processados)
            itemMap.forEach((key, value) {
              final keyLower = key.toLowerCase();
              if (keyLower != 'meta' && keyLower != 'totals') {
                if (value is Map) {
                  processMap(value as Map<String, dynamic>, key);
                } else if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
                  String displayKey = _formatKey(key);
                  String displayValue = _formatValue(value);
                  cards.add(_buildDataCard(displayKey, displayValue));
                }
              }
            });
          }
        }
        
        // Adicionar contagem se houver múltiplos itens
        if (items.length > 1) {
          cards.add(_buildDataCard(
            TranslationHelper.translateSync(context, 'Total de Registros', 'Total Records'),
            items.length.toString()
          ));
        }
      }
    }
    
    // Processar outros campos no nível raiz (exceto os já processados)
    data.forEach((key, value) {
      final keyLower = key.toLowerCase();
      
      // Ignorar chaves já processadas ou excluídas
      if (keyLower == 'meta' || keyLower == 'items' || keyLower == 'totals') {
        return;
      }
      
      if (excludedKeys.contains(keyLower)) {
        return;
      }
      
      if (value == null || value.toString().isEmpty || value.toString() == 'null') {
        return;
      }
      
      // Processar recursivamente
      if (value is Map) {
        processMap(value as Map<String, dynamic>, key);
      } else if (value is List) {
        if (value.isNotEmpty) {
          if (value[0] is Map) {
            processMap(value[0] as Map<String, dynamic>, key);
            if (value.length > 1) {
              cards.add(_buildDataCard(
                _formatKey(key),
                '${value.length} ${TranslationHelper.translateSync(context, 'itens', 'items')}'
              ));
            }
          } else {
            cards.add(_buildDataCard(
              _formatKey(key),
              '${value.length} ${TranslationHelper.translateSync(context, 'itens', 'items')}'
            ));
          }
        }
      } else {
        String displayKey = _formatKey(key);
        String displayValue = _formatValue(value);
        
        if (displayValue.length > 100) {
          displayValue = displayValue.substring(0, 97) + '...';
        }
        
        if (displayKey.isNotEmpty && displayValue.isNotEmpty && displayValue != 'null') {
          print('📊 [DEBUG] Adicionando card: $displayKey = $displayValue');
          cards.add(_buildDataCard(displayKey, displayValue));
        }
      }
    });
    
    print('📊 [DEBUG] Total de cards gerados: ${cards.length}');
    return cards;
  }

  String _formatKey(String key) {
    // Converter chaves para formato legível
    final keyMap = {
      'total_distance': TranslationHelper.translateSync(context, 'Distância Total', 'Total Distance'),
      'total_time': TranslationHelper.translateSync(context, 'Tempo Total', 'Total Time'),
      'average_speed': TranslationHelper.translateSync(context, 'Velocidade Média', 'Average Speed'),
      'max_speed': TranslationHelper.translateSync(context, 'Velocidade Máxima', 'Max Speed'),
      'stops_count': TranslationHelper.translateSync(context, 'Paradas', 'Stops'),
      'fuel_consumption': TranslationHelper.translateSync(context, 'Consumo de Combustível', 'Fuel Consumption'),
      'engine_hours': TranslationHelper.translateSync(context, 'Horas de Motor', 'Engine Hours'),
    };
    
    return keyMap[key] ?? key.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is num) {
      if (value is double && value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }


  Widget _buildDataCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
