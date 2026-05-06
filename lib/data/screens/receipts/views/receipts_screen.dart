import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:uconnect/data/model/charge.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/utils/translation_helper.dart';

class ReceiptsScreen extends StatefulWidget {
  @override
  _ReceiptsScreenState createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  bool _isLoading = false;
  List<Charge> _receipts = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Como o endpoint /api/charges/receipts não está disponível,
      // usar o endpoint de cobranças filtrando por status RECEIVED, CONFIRMED ou PAID
      final response = await gpsapis.getFinancialCharges(
        status: 'RECEIVED', // Cobranças pagas
        page: 1,
        perPage: 30,
      );

      if (response != null && response['status'] == 1 && response['items'] != null) {
        final items = response['items'];
        final chargeItems = ChargeItems.fromJson(items as Map<String, dynamic>);

        // Filtrar apenas cobranças pagas (RECEIVED, CONFIRMED, PAID)
        final paidCharges = chargeItems.data.where((charge) {
          final status = charge.status.toUpperCase();
          return status == 'RECEIVED' || status == 'CONFIRMED' || status == 'PAID';
        }).toList();

        setState(() {
          _receipts = paidCharges;
          _isLoading = false;
        });
      } else {
        // Tentar buscar todas as cobranças e filtrar no cliente
        final allChargesResponse = await gpsapis.getFinancialCharges(
          page: 1,
          perPage: 30,
        );

        if (allChargesResponse != null && allChargesResponse['status'] == 1 && allChargesResponse['items'] != null) {
          final items = allChargesResponse['items'];
          final chargeItems = ChargeItems.fromJson(items as Map<String, dynamic>);

          // Filtrar apenas cobranças pagas
          final paidCharges = chargeItems.data.where((charge) {
            final status = charge.status.toUpperCase();
            return status == 'RECEIVED' || status == 'CONFIRMED' || status == 'PAID';
          }).toList();

          setState(() {
            _receipts = paidCharges;
            _isLoading = false;
          });
        } else {
          setState(() {
            _receipts = [];
            _isLoading = false;
          });

          final errorMsg = allChargesResponse?['message'] ?? TranslationHelper.translateSync(context, 'Erro ao carregar comprovantes', 'Error loading receipts');
          Fluttertoast.showToast(
            msg: errorMsg,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar comprovantes: $e');
      setState(() {
        _receipts = [];
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao carregar comprovantes', 'Error loading receipts'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Meus Comprovantes', 'My Receipts'),
        icon: Icons.receipt,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          // Fundo animado
          AnimatedBackground(opacity: 0.03),
          // Conteúdo
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              if (_isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorProvider.primaryColor,
                    ),
                  ),
                );
              }

              if (_receipts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translateSync(context, 'Nenhum comprovante encontrado', 'No receipts found'),
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
                onRefresh: _loadReceipts,
                color: colorProvider.primaryColor,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = _receipts[index];
                    return _buildReceiptCard(receipt, colorProvider);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Charge receipt, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Data do comprovante: preferir data de pagamento, depois atualização, depois vencimento
    DateTime? receiptDate = receipt.paidAt;
    receiptDate ??= receipt.updatedAt;
    receiptDate ??= receipt.dueDate;

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
            _showReceiptDetails(receipt, colorProvider);
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
                              Expanded(
                                child: Text(
                                  receipt.description ?? TranslationHelper.translateSync(context, 'Comprovante #${receipt.id}', 'Receipt #${receipt.id}'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  receipt.gateway.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              if (receipt.isOneOff)
                                Container(
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
                              else if (receipt.planId != null)
                                Container(
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
                                          receipt.planName != null && receipt.planName!.isNotEmpty
                                              ? receipt.planName!
                                              : '${TranslationHelper.translateSync(context, 'Plano', 'Plan')} #${receipt.planId}',
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
                          SizedBox(height: 6),
                          // Destinatário
                          if (receipt.customer.name.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 12,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Para:', 'To:'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    receipt.customer.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else if (receipt.customer.email != null && receipt.customer.email!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 12,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Para:', 'To:'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    receipt.customer.email!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          // Criado por
                          if (receipt.createdByName != null && receipt.createdByName!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Criado por:', 'Created by:'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    receipt.createdByName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (receipt.createdByEmail != null && receipt.createdByEmail!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  TranslationHelper.translateSync(context, 'Criado por:', 'Created by:'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    receipt.createdByEmail!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
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
                    Icon(
                      Icons.picture_as_pdf,
                      color: colorProvider.primaryColor,
                      size: 32,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        TranslationHelper.translateSync(context, 'Data', 'Date'),
                        receiptDate != null ? dateFormat.format(receiptDate) : '-',
                        colorProvider,
                      ),
                    ),
                    if (receipt.dueDate != null) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.event,
                          TranslationHelper.translateSync(context, 'Vencimento', 'Due Date'),
                          dateFormat.format(receipt.dueDate!),
                          colorProvider,
                        ),
                      ),
                    ],
                  ],
                ),
                if (receipt.paidAt != null && receipt.paidAt != receiptDate) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.check_circle,
                          TranslationHelper.translateSync(context, 'Pago em', 'Paid on'),
                          dateFormat.format(receipt.paidAt!),
                          colorProvider,
                        ),
                      ),
                    ],
                  ),
                ],
                if (receipt.installmentCount != null && receipt.totalInstallments != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.receipt_long,
                          TranslationHelper.translateSync(context, 'Parcela', 'Installment'),
                          '${receipt.installmentCount}/${receipt.totalInstallments}',
                          colorProvider,
                        ),
                      ),
                    ],
                  ),
                ],
                if (receipt.gatewayId != null && receipt.gatewayId!.isNotEmpty) ...[
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
                          '${TranslationHelper.translateSync(context, 'ID Gateway', 'Gateway ID')}: ${receipt.gatewayId}',
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
                if (receipt.billingTypeLabel != null && receipt.billingTypeLabel!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 16,
                        color: colorProvider.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          receipt.billingTypeLabel!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (receipt.planId != null && receipt.planName != null && receipt.planName!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 16,
                        color: Colors.purple,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          receipt.planName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
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
                            currencyFormat.format(receipt.totalValue),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _downloadReceipt(receipt);
                        },
                        icon: Icon(Icons.download, size: 18),
                        label: Text(TranslationHelper.translateSync(context, 'Baixar', 'Download')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Future<void> _downloadReceipt(Charge receipt) async {
    try {
      // Buscar comprovante específico da cobrança
      final response = await gpsapis.getFinancialChargeReceipt(id: receipt.id);
      
      if (response != null && response['status'] == 1 && response['data'] != null) {
        final receiptData = response['data'];
        final receiptUrl = receiptData['receipt_url'];
        
        if (receiptUrl != null && receiptUrl.isNotEmpty) {
          // Abrir URL no navegador
          final url = Uri.parse(receiptUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            // Se não conseguir abrir, copiar para clipboard
            Clipboard.setData(ClipboardData(text: receiptUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TranslationHelper.translateSync(context, 'Link do comprovante copiado. Cole no navegador para abrir.', 'Receipt link copied. Paste in browser to open.')),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Fallback para invoiceUrl ou bankSlipUrl
          final url = receipt.payment.invoiceUrl ?? receipt.payment.bankSlipUrl;
          if (url != null && url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationHelper.translateSync(context, 'Link do comprovante copiado. Cole no navegador para abrir.', 'Receipt link copied. Paste in browser to open.')),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TranslationHelper.translateSync(context, 'Nenhum link de comprovante disponível para esta cobrança.', 'No receipt link available for this charge.')),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // Fallback para invoiceUrl ou bankSlipUrl
        final url = receipt.payment.invoiceUrl ?? receipt.payment.bankSlipUrl;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TranslationHelper.translateSync(context, 'Link do comprovante copiado. Cole no navegador para abrir.', 'Receipt link copied. Paste in browser to open.')),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Nenhum link de comprovante disponível para esta cobrança.', 'No receipt link available for this charge.')),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao baixar comprovante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao baixar comprovante', 'Error downloading receipt')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReceiptDetails(Charge receipt, ColorProvider colorProvider) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    DateTime? receiptDate = receipt.paidAt;
    receiptDate ??= receipt.updatedAt;
    receiptDate ??= receipt.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TranslationHelper.translateSync(context, 'Detalhes do Comprovante', 'Receipt Details'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      TranslationHelper.translateSync(context, 'Número', 'Number'),
                      TranslationHelper.translateSync(context, 'Comprovante #${receipt.id}', 'Receipt #${receipt.id}'),
                      colorProvider,
                    ),
                    if (receipt.description != null && receipt.description!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Descrição', 'Description'),
                        receipt.description!,
                        colorProvider,
                      ),
                    _buildDetailRow(
                      TranslationHelper.translateSync(context, 'Gateway', 'Gateway'),
                      receipt.gateway.toUpperCase(),
                      colorProvider,
                    ),
                    _buildDetailRow(
                      TranslationHelper.translateSync(context, 'Status', 'Status'),
                      receipt.statusLabel ?? receipt.status,
                      colorProvider,
                    ),
                    if (receipt.isOneOff)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Tipo', 'Type'),
                        TranslationHelper.translateSync(context, 'Avulsa', 'One-off'),
                        colorProvider,
                      )
                    else if (receipt.planId != null)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Plano', 'Plan'),
                        receipt.planName != null && receipt.planName!.isNotEmpty
                            ? receipt.planName!
                            : '${TranslationHelper.translateSync(context, 'Plano', 'Plan')} #${receipt.planId}',
                        colorProvider,
                      ),
                    _buildDetailRow(
                      TranslationHelper.translateSync(context, 'Data', 'Date'),
                      receiptDate != null ? dateFormat.format(receiptDate) : '-',
                      colorProvider,
                    ),
                    if (receipt.dueDate != null)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Vencimento', 'Due Date'),
                        dateFormat.format(receipt.dueDate!),
                        colorProvider,
                      ),
                    if (receipt.paidAt != null)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Pago em', 'Paid on'),
                        dateFormat.format(receipt.paidAt!),
                        colorProvider,
                      ),
                    if (receipt.createdByName != null && receipt.createdByName!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Criado por', 'Created by'),
                        receipt.createdByName!,
                        colorProvider,
                      )
                    else if (receipt.createdByEmail != null && receipt.createdByEmail!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Criado por', 'Created by'),
                        receipt.createdByEmail!,
                        colorProvider,
                      ),
                    if (receipt.customer.name.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Destinatário', 'Recipient'),
                        receipt.customer.name,
                        colorProvider,
                      ),
                    if (receipt.customer.email != null && receipt.customer.email!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Email do Destinatário', 'Recipient Email'),
                        receipt.customer.email!,
                        colorProvider,
                      ),
                    if (receipt.customer.document != null && receipt.customer.document!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Documento', 'Document'),
                        receipt.customer.document!,
                        colorProvider,
                      ),
                    if (receipt.customer.phone != null && receipt.customer.phone!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Telefone', 'Phone'),
                        receipt.customer.phone!,
                        colorProvider,
                      ),
                    if (receipt.billingTypeLabel != null && receipt.billingTypeLabel!.isNotEmpty)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Forma de Pagamento', 'Payment Method'),
                        receipt.billingTypeLabel!,
                        colorProvider,
                      ),
                    _buildDetailRow(
                      TranslationHelper.translateSync(context, 'Valor', 'Amount'),
                      currencyFormat.format(receipt.totalValue),
                      colorProvider,
                    ),
                    if (receipt.installmentCount != null && receipt.totalInstallments != null)
                      _buildDetailRow(
                        TranslationHelper.translateSync(context, 'Parcela', 'Installment'),
                        '${receipt.installmentCount}/${receipt.totalInstallments}',
                        colorProvider,
                      ),
                    if (receipt.payment.invoiceUrl != null &&
                        receipt.payment.invoiceUrl!.isNotEmpty)
                      _buildDetailRow(TranslationHelper.translateSync(context, 'Link da Fatura', 'Invoice Link'), receipt.payment.invoiceUrl!, colorProvider),
                    if (receipt.payment.bankSlipUrl != null &&
                        receipt.payment.bankSlipUrl!.isNotEmpty)
                      _buildDetailRow(TranslationHelper.translateSync(context, 'Link do Boleto', 'Bank Slip Link'), receipt.payment.bankSlipUrl!, colorProvider),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _downloadReceipt(receipt);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.download),
                        label: Text(TranslationHelper.translateSync(context, 'Baixar Comprovante', 'Download Receipt')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorProvider colorProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

