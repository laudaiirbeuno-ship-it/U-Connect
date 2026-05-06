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
import 'package:uconnect/utils/translation_helper.dart';
import '../widgets/transactions_filter_widget.dart';
import '../../charges/widgets/charge_detail_modal.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  List<Charge> _transactions = [];
  
  // Filtros
  String? _selectedGateway;
  String? _selectedStatus;
  String? _selectedBillingType;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Paginação
  int _currentPage = 1;
  int _perPage = 30;
  int _totalPages = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await gpsapis.getFinancialCharges(
        gateway: _selectedGateway,
        status: _selectedStatus,
        billingType: _selectedBillingType,
        page: _currentPage,
        perPage: _perPage,
      );

      if (response == null) {
        if (!mounted) return;
        setState(() {
          _transactions = [];
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
          if (items != null && items is Map<String, dynamic>) {
            final chargeItems = ChargeItems.fromJson(items);
            List<Charge> filteredTransactions = chargeItems.data;
            
            // Aplicar filtros de data no cliente se necessário
            if (_startDate != null || _endDate != null) {
              filteredTransactions = filteredTransactions.where((charge) {
                final chargeDate = charge.createdAt ?? charge.dueDate;
                if (chargeDate == null) return false;
                
                if (_startDate != null && chargeDate.isBefore(_startDate!)) {
                  return false;
                }
                if (_endDate != null && chargeDate.isAfter(_endDate!.add(Duration(days: 1)))) {
                  return false;
                }
                return true;
              }).toList();
            }
            
            if (!mounted) return;
            setState(() {
              _transactions = filteredTransactions;
              _currentPage = chargeItems.currentPage;
              _totalPages = chargeItems.lastPage;
              _total = filteredTransactions.length; // Usar tamanho filtrado
              _isLoading = false;
            });
          } else {
            if (!mounted) return;
            setState(() {
              _transactions = [];
              _isLoading = false;
            });
          }
        } catch (parseError, stackTrace) {
          print('❌ [TransactionsScreen] Erro ao processar resposta: $parseError');
          print('❌ [TransactionsScreen] Stack: $stackTrace');
          if (!mounted) return;
          setState(() {
            _transactions = [];
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: TranslationHelper.translateSync(context, 'Erro ao processar dados', 'Error processing data'),
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      } else {
        if (!mounted) return;
        setState(() {
          _transactions = [];
          _isLoading = false;
        });
        final errorMsg = response['message'];
        if (errorMsg != null && errorMsg.toString().isNotEmpty) {
          Fluttertoast.showToast(
            msg: errorMsg.toString(),
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [TransactionsScreen] Erro: $e');
      print('❌ [TransactionsScreen] Stack: $stackTrace');
      if (!mounted) return;
      setState(() {
        _transactions = [];
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao carregar transações', 'Error loading transactions'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _onFilterChanged(String? gateway, String? status, String? billingType, DateTime? startDate, DateTime? endDate) {
    setState(() {
      _selectedGateway = gateway;
      _selectedStatus = status;
      _selectedBillingType = billingType;
      _startDate = startDate;
      _endDate = endDate;
    });
    _loadTransactions(refresh: true);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadTransactions();
  }

  void _showTransactionDetails(Charge transaction, ColorProvider colorProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChargeDetailModal(
        charge: transaction,
        onSync: () {
          Navigator.pop(context);
          _loadTransactions(refresh: true);
        },
        onCancel: () {
          Navigator.pop(context);
          _loadTransactions(refresh: true);
        },
        onRefresh: () {
          _loadTransactions(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Transações', 'Transactions'),
        icon: Icons.swap_horiz,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Column(
                children: [
                  TransactionsFilterWidget(
                    selectedGateway: _selectedGateway,
                    selectedStatus: _selectedStatus,
                    selectedBillingType: _selectedBillingType,
                    startDate: _startDate,
                    endDate: _endDate,
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
        ],
      ),
    );
  }

  Widget _buildContent(ColorProvider colorProvider) {
    if (_isLoading && _transactions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.translateSync(context, 'Nenhuma transação encontrada', 'No transactions found'),
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
      onRefresh: () => _loadTransactions(refresh: true),
      color: colorProvider.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction, colorProvider);
        },
      ),
    );
  }

  Widget _buildTransactionCard(Charge transaction, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    IconData statusIcon = _getStatusIcon(transaction.status);

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
          onTap: () => _showTransactionDetails(transaction, colorProvider),
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
                                  color: colorProvider.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  transaction.gateway.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: colorProvider.primaryColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  transaction.description ?? TranslationHelper.translateSync(context, 'Transação #${transaction.id}', 'Transaction #${transaction.id}'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (transaction.customer.name.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: colorProvider.primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Para:', 'To:'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    transaction.customer.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorProvider.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorProvider.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: colorProvider.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            transaction.statusLabel ?? transaction.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorProvider.primaryColor,
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
                    if (transaction.dueDate != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          TranslationHelper.translateSync(context, 'Vencimento', 'Due Date'),
                          dateFormat.format(transaction.dueDate!),
                          colorProvider,
                        ),
                      ),
                    if (transaction.paidAt != null) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.check_circle,
                          TranslationHelper.translateSync(context, 'Pago em', 'Paid on'),
                          dateFormat.format(transaction.paidAt!),
                          colorProvider,
                        ),
                      ),
                    ],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                            currencyFormat.format(transaction.totalValue),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                        ],
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
    return Column(
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
        return Icons.warning;
      case 'CANCELED':
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

}
