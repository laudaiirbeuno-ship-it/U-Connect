import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/chat_floating_button.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:uconnect/data/model/charge.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/utils/user_permissions.dart';
import '../widgets/charges_filter_widget.dart';
import '../widgets/charge_detail_modal.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

/// Página de cobranças para administração
/// Mostra cobranças para pagar (não as criadas)
class AdminChargesScreen extends StatefulWidget {
  @override
  _AdminChargesScreenState createState() => _AdminChargesScreenState();
}

class _AdminChargesScreenState extends State<AdminChargesScreen> {
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
    final isAdminOrManager = await UserPermissions.isAdminOrManager();
    setState(() {
      _isAdminOrManager = isAdminOrManager;
    });
  }

  Future<void> _loadCharges({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Para admin e gerente na página de administração, mostrar cobranças para pagar
      // Não passar chargeType ou passar null = mostra cobranças a pagar (padrão da API)
      final response = await gpsapis.getFinancialCharges(
        gateway: _selectedGateway,
        status: _selectedStatus,
        page: _currentPage,
        perPage: _perPage,
        chargeType: null, // null = cobranças para pagar (não criadas)
      );

      if (response['status'] == 1) {
        final items = response['items'];
        if (items != null) {
          final chargeItems = ChargeItems.fromJson(items);
          setState(() {
            _charges = chargeItems.data;
            _currentPage = chargeItems.currentPage;
            _totalPages = chargeItems.lastPage;
            _total = chargeItems.total;
            _isLoading = false;
          });
        } else {
          setState(() {
            _charges = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _charges = [];
          _isLoading = false;
        });
        final errorMsg = (response['message'] as String?) ?? TranslationHelper.translateSync(context, 'Erro ao carregar cobranças', 'Error loading charges');
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Erro ao carregar cobranças: $e');
      setState(() {
        _charges = [];
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao carregar cobranças', 'Error loading charges'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
      if (response['status'] == 1) {
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
        title: TranslationHelper.translateSync(context, 'Cobranças para Pagar', 'Charges to Pay'),
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
          // Botão de chat global
          ChatFloatingButton(alignLeft: true),
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
              size: ResponsiveHelper.iconSize(64),
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhuma cobrança encontrada', 'No charges found'),
              style: TextStyle(
                fontSize: ResponsiveHelper.fontSize(18),
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
        padding: ResponsiveHelper.padding(all: 16),
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
      margin: ResponsiveHelper.margin(bottom: 16),
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
            padding: ResponsiveHelper.padding(all: 16),
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
                                padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getGatewayColor(charge.gateway).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  charge.gateway.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: ResponsiveHelper.fontSize(10),
                                    fontWeight: FontWeight.bold,
                                    color: _getGatewayColor(charge.gateway),
                                  ),
                                ),
                              ),
                              ResponsiveHelper.horizontalSpace(8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      charge.description ?? TranslationHelper.translateSync(context, 'Cobrança #${charge.id}', 'Charge #${charge.id}'),
                                      style: TextStyle(
                                        fontSize: ResponsiveHelper.fontSize(16),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (charge.isOneOff)
                                      Container(
                                        margin: ResponsiveHelper.margin(top: 4),
                                        padding: ResponsiveHelper.padding(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          TranslationHelper.translateSync(context, 'Avulsa', 'One-off'),
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.fontSize(10),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      )
                                    else if (charge.planId != null)
                                      Container(
                                        margin: ResponsiveHelper.margin(top: 4),
                                        padding: ResponsiveHelper.padding(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          TranslationHelper.translateSync(context, 'Plano', 'Plan'),
                                          style: TextStyle(
                                            fontSize: ResponsiveHelper.fontSize(10),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                                    if (charge.billingTypeLabel?.isNotEmpty ?? false)
                            Text(
                              charge.billingTypeLabel!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
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
                            charge.statusLabel,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (charge.dueDate != null)
                      _buildInfoItem(
                        Icons.calendar_today,
                        TranslationHelper.translateSync(context, 'Vencimento', 'Due Date'),
                        dateFormat.format(charge.dueDate!),
                        colorProvider,
                      ),
                    if (charge.paidAt != null)
                      _buildInfoItem(
                        Icons.check_circle,
                        TranslationHelper.translateSync(context, 'Pago em', 'Paid on'),
                        dateFormat.format(charge.paidAt!),
                        colorProvider,
                      ),
                    if (charge.installmentCount != null && charge.totalInstallments != null)
                      _buildInfoItem(
                        Icons.receipt_long,
                        TranslationHelper.translateSync(context, 'Parcela', 'Installment'),
                        '${charge.installmentCount}/${charge.totalInstallments}',
                        colorProvider,
                      ),
                  ],
                ),
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

  Future<void> _syncCharge(int chargeId) async {
    try {
      final response = await gpsapis.syncFinancialCharge(id: chargeId);
      if (response['status'] == 1) {
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Cobrança sincronizada com sucesso!', 'Charge synchronised successfully!'),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _loadCharges(refresh: true);
      } else {
        final errorMsg = response['message'] as String? ?? TranslationHelper.translateSync(context, 'Erro ao sincronizar cobrança', 'Error synchronising charge');
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
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
      if (response['status'] == 1) {
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, 'Cobrança cancelada com sucesso!', 'Charge cancelled successfully!'),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        _loadCharges(refresh: true);
      } else {
        final errorMsg = response['message'] as String? ?? TranslationHelper.translateSync(context, 'Erro ao cancelar cobrança', 'Error cancelling charge');
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
