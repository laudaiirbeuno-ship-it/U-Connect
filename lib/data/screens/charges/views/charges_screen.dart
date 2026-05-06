import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:uconnect/data/model/charge.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/utils/user_permissions.dart';
import '../widgets/charges_filter_widget.dart';
import '../widgets/charge_detail_modal.dart';
import '../widgets/create_charge_modal.dart';
import 'package:uconnect/utils/translation_helper.dart';

class ChargesScreen extends StatefulWidget {
  @override
  _ChargesScreenState createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  bool _isLoading = false;
  List<Charge> _charges = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Filtros
  String? _selectedGateway;
  String? _selectedStatus;
  int _currentPage = 1;
  int _perPage = 30;
  int _totalPages = 1;
  int _total = 0;
  
  // Permissões
  bool _isAdminOrManager = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Verificar permissões primeiro
    await _checkPermissions();
    // Depois carregar cobranças com o filtro correto
    _loadCharges();
  }

  Future<void> _checkPermissions() async {
    try {
      final isAdminOrManager = await UserPermissions.isAdminOrManager();
      print('🔍 [ChargesScreen] Verificação de permissões: $isAdminOrManager');
      if (mounted) {
        setState(() {
          _isAdminOrManager = isAdminOrManager;
        });
      }
    } catch (e) {
      print('❌ [ChargesScreen] Erro ao verificar permissões: $e');
      if (mounted) {
        setState(() {
          _isAdminOrManager = false;
        });
      }
    }
  }

  Future<void> _loadCharges({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Para admin e gerente, mostrar TODAS as cobranças criadas (sem filtro de usuário)
      // Para usuário comum, mostrar apenas cobranças a pagar (padrão da API)
      print('🔍 [ChargesScreen] Carregando cobranças...');
      print('🔍 [ChargesScreen] É admin/manager: $_isAdminOrManager');
      print('🔍 [ChargesScreen] Charge type: ${_isAdminOrManager ? 'created' : null}');
      
      final response = await gpsapis.getFinancialCharges(
        gateway: _selectedGateway,
        status: _selectedStatus,
        page: _currentPage,
        perPage: _perPage,
        chargeType: _isAdminOrManager ? 'created' : null, // 'created' = todas as cobranças criadas (admin/gerente veem todas)
      );
      
      print('🔍 [ChargesScreen] Resposta recebida: ${response != null ? 'OK' : 'NULL'}');

      if (response == null) {
        setState(() {
          _charges = [];
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Erro ao conectar com o servidor', 'Error connecting to server'),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      if (response['status'] == 1) {
        try {
          final items = response['items'];
          print('🔍 [DEBUG] Items type: ${items.runtimeType}');
          print('🔍 [DEBUG] Items is Map: ${items is Map<String, dynamic>}');
          
          if (items != null && items is Map<String, dynamic>) {
            print('🔍 [DEBUG] Processando items como Map');
            print('🔍 [DEBUG] Items keys: ${items.keys.toList()}');
            print('🔍 [DEBUG] Items data type: ${items['data']?.runtimeType}');
            print('🔍 [DEBUG] Items data length: ${items['data'] is List ? (items['data'] as List).length : 'N/A'}');
            
            try {
              final chargeItems = ChargeItems.fromJson(items);
              print('✅ [DEBUG] ChargeItems criado com sucesso');
              print('✅ [DEBUG] Total de cobranças: ${chargeItems.data.length}');
              
              setState(() {
                _charges = chargeItems.data;
                _currentPage = chargeItems.currentPage;
                _totalPages = chargeItems.lastPage;
                _total = chargeItems.total;
                _isLoading = false;
              });
            } catch (e, stackTrace) {
              print('❌ [DEBUG] Erro ao criar ChargeItems: $e');
              print('❌ [DEBUG] Stack trace: $stackTrace');
              print('❌ [DEBUG] Items completo: $items');
              
              // Tentar processar manualmente
              if (items['data'] != null && items['data'] is List) {
                print('🔍 [DEBUG] Tentando processar manualmente...');
                final dataList = items['data'] as List;
                final charges = <Charge>[];
                
                for (var i = 0; i < dataList.length; i++) {
                  try {
                    final item = dataList[i];
                    if (item is Map) {
                      final itemMap = item is Map<String, dynamic>
                          ? item
                          : Map<String, dynamic>.from(item);
                      print('🔍 [DEBUG] Processando cobrança ${i + 1}/${dataList.length}');
                      final charge = Charge.fromJson(itemMap);
                      charges.add(charge);
                    }
                  } catch (e2) {
                    print('❌ [DEBUG] Erro ao processar cobrança ${i + 1}: $e2');
                    print('❌ [DEBUG] Item: ${dataList[i]}');
                  }
                }
                
                setState(() {
                  _charges = charges;
                  _currentPage = items['current_page'] ?? 1;
                  _totalPages = items['last_page'] ?? 1;
                  _total = items['total'] ?? charges.length;
                  _isLoading = false;
                });
              } else {
                throw e;
              }
            }
          } else {
            // Se items não existe ou não é um Map, tentar processar diretamente
            print('🔍 [DEBUG] Items não é Map, tentando processar response diretamente');
            if (response['data'] != null && response['data'] is List) {
              final data = response['data'] as List;
              final charges = data.map((item) {
                try {
                  final itemMap = item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map);
                  return Charge.fromJson(itemMap);
                } catch (e) {
                  print('❌ Erro ao processar cobrança individual: $e');
                  print('❌ Item: $item');
                  return null;
                }
              }).whereType<Charge>().toList();
              
              setState(() {
                _charges = charges;
                _currentPage = response['current_page'] ?? 1;
                _totalPages = response['last_page'] ?? 1;
                _total = response['total'] ?? charges.length;
                _isLoading = false;
              });
            } else {
              print('⚠️ [DEBUG] Nenhum dado encontrado na resposta');
              setState(() {
                _charges = [];
                _isLoading = false;
              });
            }
          }
        } catch (parseError, stackTrace) {
          print('❌ [ChargesScreen] Erro ao processar resposta da API: $parseError');
          print('❌ [ChargesScreen] Stack trace: $stackTrace');
          print('📋 [ChargesScreen] Resposta recebida: $response');
          
          if (!mounted) return;
          
          setState(() {
            _charges = [];
            _isLoading = false;
          });
          
          if (mounted) {
            Fluttertoast.showToast(
              msg: TranslationHelper.translateSync(context, 'Erro ao processar dados das cobranças', 'Error processing charges data'),
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            );
          }
        }
      } else {
        print('⚠️ [ChargesScreen] Status != 1. Status: ${response['status']}');
        print('⚠️ [ChargesScreen] Mensagem: ${response['message']}');
        
        if (!mounted) return;
        
        setState(() {
          _charges = [];
          _isLoading = false;
        });
        
        // Não mostrar erro se for apenas lista vazia (status != 1 pode ser normal)
        final errorMsg = response['message'];
        if (errorMsg != null && errorMsg.toString().isNotEmpty && !errorMsg.toString().toLowerCase().contains('nenhum') && !errorMsg.toString().toLowerCase().contains('vazio')) {
          if (mounted) {
            Fluttertoast.showToast(
              msg: errorMsg.toString(),
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      print('❌ [ChargesScreen] Erro ao carregar cobranças: $e');
      print('❌ [ChargesScreen] Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _charges = [];
        _isLoading = false;
      });
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Erro ao carregar cobranças', 'Error loading charges'),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  void _onFilterChanged(String? gateway, String? status) {
    setState(() {
      _selectedGateway = gateway;
      _selectedStatus = status;
    });
    _loadCharges(refresh: true);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadCharges();
  }

  Future<void> _refreshCharge(int chargeId) async {
    try {
      final response = await gpsapis.getFinancialCharge(id: chargeId);
      if (response != null && response['status'] == 1) {
        final updatedCharge = Charge.fromJson(response['data']);
        setState(() {
          final index = _charges.indexWhere((c) => c.id == chargeId);
          if (index != -1) {
            _charges[index] = updatedCharge;
          }
        });
      }
    } catch (e) {
      print('❌ Erro ao atualizar cobrança: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Minhas Cobranças', 'My Charges'),
        icon: Icons.payment,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Column(
                children: [
                  ChargesFilterWidget(
                    selectedGateway: _selectedGateway,
                    selectedStatus: _selectedStatus,
                    onFilterChanged: _onFilterChanged,
                  ),
                  Expanded(
                    child: _buildContent(colorProvider),
                  ),
                  if (_totalPages > 1)
                    _buildPagination(colorProvider),
                ],
              );
            },
          ),
          // Botão flutuante para criar nova cobrança (apenas para admin/gerente)
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              if (!_isAdminOrManager) return SizedBox.shrink();
              
              return Positioned(
                bottom: 100,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showCreateChargeModal(),
                  backgroundColor: colorProvider.primaryColor,
                  child: Icon(Icons.add, color: Colors.white),
                  tooltip: TranslationHelper.translateSync(context, 'Criar Nova Cobrança', 'Create New Charge'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorProvider colorProvider) {
    if (_isLoading && _charges.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
        ),
      );
    }

    if (_charges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhuma cobrança encontrada', 'No charges found'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCharges(refresh: true),
      color: colorProvider.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _charges.length,
        itemBuilder: (context, index) {
          final charge = _charges[index];
          return _buildChargeCard(charge, colorProvider);
        },
      ),
    );
  }

  Widget _buildChargeCard(Charge charge, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    Color statusColor = _getStatusColor(charge.status);
    IconData statusIcon = _getStatusIcon(charge.status);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showChargeDetails(charge, colorProvider);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getGatewayColor(charge.gateway).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  charge.gateway.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getGatewayColor(charge.gateway),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      charge.description ?? TranslationHelper.translateSync(context, 'Cobrança #${charge.id}', 'Charge #${charge.id}'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        if (charge.isOneOff)
                                          Container(
                                            margin: EdgeInsets.only(right: 6),
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              TranslationHelper.translateSync(context, 'Avulsa', 'One-off'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          )
                                        else if (charge.planId != null)
                                          Container(
                                            margin: EdgeInsets.only(right: 6),
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.credit_card,
                                                  size: 10,
                                                  color: Colors.purple,
                                                ),
                                                SizedBox(width: 2),
                                                Flexible(
                                                  child: Text(
                                                    charge.planName != null && charge.planName!.isNotEmpty
                                                        ? charge.planName!
                                                        : '${TranslationHelper.translateSync(context, 'Plano', 'Plan')} #${charge.planId}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.purple,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Informação do destinatário (cliente)
                          if (charge.customer.name.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Para:', 'To:'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charge.customer.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else if (charge.customer.email != null && charge.customer.email!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Para:', 'To:'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charge.customer.email!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          // Informação de quem criou a cobrança
                          if (charge.createdByName != null && charge.createdByName!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Criado por:', 'Created by:'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charge.createdByName!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (charge.createdByEmail != null && charge.createdByEmail!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Criado por:', 'Created by:'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charge.createdByEmail!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (charge.billingTypeLabel != null && charge.billingTypeLabel!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  charge.billingTypeLabel!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (charge.planId != null && charge.planName != null && charge.planName!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 12,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    charge.planName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            charge.statusLabel ?? charge.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 12),
                // Primeira linha de informações
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (charge.dueDate != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          TranslationHelper.translateSync(context, 'Vencimento', 'Due Date'),
                          dateFormat.format(charge.dueDate!),
                          colorProvider,
                        ),
                      ),
                    if (charge.paidAt != null) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.check_circle,
                          TranslationHelper.translateSync(context, 'Pago em', 'Paid on'),
                          dateFormat.format(charge.paidAt!),
                          colorProvider,
                        ),
                      ),
                    ],
                  ],
                ),
                // Segunda linha de informações (se houver parcelas ou data de criação)
                if (charge.installmentCount != null && charge.totalInstallments != null || charge.createdAt != null) ...[
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (charge.installmentCount != null && charge.totalInstallments != null)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.receipt_long,
                            TranslationHelper.translateSync(context, 'Parcela', 'Installment'),
                            '${charge.installmentCount}/${charge.totalInstallments}',
                            colorProvider,
                          ),
                        ),
                      if (charge.createdAt != null) ...[
                        if (charge.installmentCount != null) SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoItem(
                            Icons.access_time,
                            TranslationHelper.translateSync(context, 'Criado em', 'Created on'),
                            dateFormat.format(charge.createdAt!),
                            colorProvider,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                // Informações adicionais do gateway
                if (charge.gatewayId != null && charge.gatewayId!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${TranslationHelper.translateSync(context, 'ID Gateway', 'Gateway ID')}: ${charge.gatewayId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: colorProvider.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        TranslationHelper.translateSync(context, 'Valor: ', 'Amount: '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        currencyFormat.format(charge.totalValue),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorProvider.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, ColorProvider colorProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorProvider.primaryColor,
              ),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            TranslationHelper.translateSync(context, 'Página $_currentPage de $_totalPages ($_total total)', 'Page $_currentPage of $_totalPages ($_total total)'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              if (_currentPage > 1)
                IconButton(
                  icon: Icon(Icons.chevron_left, color: colorProvider.primaryColor),
                  onPressed: () => _onPageChanged(_currentPage - 1),
                ),
              if (_currentPage < _totalPages)
                IconButton(
                  icon: Icon(Icons.chevron_right, color: colorProvider.primaryColor),
                  onPressed: () => _onPageChanged(_currentPage + 1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'RECEIVED':
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
      case 'EXPIRED':
        return Colors.red;
      case 'CANCELED':
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'RECEIVED':
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.pending;
      case 'OVERDUE':
      case 'EXPIRED':
        return Icons.error;
      case 'CANCELED':
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getGatewayColor(String gateway) {
    switch (gateway.toLowerCase()) {
      case 'asaas':
        return Colors.blue;
      case 'suitpay':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showChargeDetails(Charge charge, ColorProvider colorProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChargeDetailModal(
        charge: charge,
        isAdminOrManager: _isAdminOrManager,
        onSync: () async {
          await _syncCharge(charge.id);
        },
        onCancel: () async {
          await _cancelCharge(charge.id);
        },
        onRefresh: () => _refreshCharge(charge.id),
      ),
    );
  }

  void _showCreateChargeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateChargeModal(
        onChargeCreated: () {
          _loadCharges(refresh: true);
        },
      ),
    ).then((result) {
      if (result == true) {
        // Cobrança criada com sucesso - recarregar lista
        print('🔄 [ChargesScreen] Recarregando lista de cobranças após cadastro...');
        _loadCharges(refresh: true);
      }
    });
  }

  bool _isApiNotConfiguredError(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) return false;
    final lower = errorMessage.toLowerCase();
    return lower.contains('api key') ||
        lower.contains('não configurada') ||
        lower.contains('not configured') ||
        lower.contains('api key do') ||
        lower.contains('gateway não configurado');
  }

  void _showApiNotConfiguredDialog(String gateway) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(
                    context,
                    'Gateway Não Configurado',
                    'Gateway Not Configured',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TranslationHelper.translateSync(
                  context,
                  'A API do gateway ${gateway.toUpperCase()} não está configurada para este usuário.',
                  'The ${gateway.toUpperCase()} gateway API is not configured for this user.',
                ),
              ),
              SizedBox(height: 16),
              Text(
                TranslationHelper.translateSync(
                  context,
                  'Por favor, configure a API Key do gateway nas configurações antes de usar esta funcionalidade.',
                  'Please configure the gateway API Key in settings before using this feature.',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                TranslationHelper.translateSync(
                  context,
                  'Entendi',
                  'Got it',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncCharge(int chargeId) async {
    try {
      final response = await gpsapis.syncFinancialCharge(id: chargeId);
      if (response != null && response['status'] == 1) {
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Cobrança sincronizada com sucesso!', 'Charge synchronised successfully!'),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _loadCharges(refresh: true);
      } else {
        final errorMsg = response?['message'] ?? TranslationHelper.translateSync(context, 'Erro ao sincronizar cobrança', 'Error synchronising charge');
        
        // Verificar se é erro de API não configurada
        final charge = _charges.firstWhere((c) => c.id == chargeId, orElse: () => _charges.first);
        if (_isApiNotConfiguredError(errorMsg)) {
          _showApiNotConfiguredDialog(charge.gateway);
        } else {
          Fluttertoast.showToast(
            msg: errorMsg,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao sincronizar cobrança: $e');
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao sincronizar cobrança', 'Error synchronising charge'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _cancelCharge(int chargeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(context, 'Cancelar Cobrança', 'Cancel Charge')),
        content: Text(TranslationHelper.translateSync(context, 'Tem certeza que deseja cancelar esta cobrança?', 'Are you sure you want to cancel this charge?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationHelper.translateSync(context, 'Não', 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(TranslationHelper.translateSync(context, 'Sim', 'Yes'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await gpsapis.cancelFinancialCharge(id: chargeId);
      if (response != null && response['status'] == 1) {
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Cobrança cancelada com sucesso!', 'Charge cancelled successfully!'),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _loadCharges(refresh: true);
      } else {
        final errorMsg = response?['message'] ?? TranslationHelper.translateSync(context, 'Erro ao cancelar cobrança', 'Error cancelling charge');
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Erro ao cancelar cobrança: $e');
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao cancelar cobrança', 'Error cancelling charge'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
