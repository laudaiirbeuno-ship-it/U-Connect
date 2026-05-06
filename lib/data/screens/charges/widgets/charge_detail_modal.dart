import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/charge.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'dart:convert';

class ChargeDetailModal extends StatefulWidget {
  final Charge charge;
  final bool isAdminOrManager;
  final VoidCallback onSync;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;

  const ChargeDetailModal({
    Key? key,
    required this.charge,
    this.isAdminOrManager = false,
    required this.onSync,
    required this.onCancel,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _ChargeDetailModalState createState() => _ChargeDetailModalState();
}

class _ChargeDetailModalState extends State<ChargeDetailModal> {
  bool _isLoadingQrCode = false;
  String? _qrCodeImage;
  String? _copyPasteCode;

  @override
  void initState() {
    super.initState();
    if (widget.charge.billingType == 'PIX' && 
        (widget.charge.status == 'PENDING' || widget.charge.status == 'OVERDUE')) {
      _loadQrCode();
    } else if (widget.charge.payment.pixQrCode != null) {
      _qrCodeImage = widget.charge.payment.pixQrCode;
      _copyPasteCode = widget.charge.payment.copyPasteCode;
    }
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

  bool _isApiNotConfiguredError(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) return false;
    final lower = errorMessage.toLowerCase();
    return lower.contains('api key') ||
        lower.contains('não configurada') ||
        lower.contains('not configured') ||
        lower.contains('api key do') ||
        lower.contains('gateway não configurado');
  }

  Future<void> _loadQrCode() async {
    if (_qrCodeImage != null) return;

    setState(() {
      _isLoadingQrCode = true;
    });

    try {
      final response = await gpsapis.getFinancialChargeQrCode(id: widget.charge.id);
      if (response != null && response['status'] == 1) {
        final data = response['data'];
        setState(() {
          _qrCodeImage = data['qrcode'];
          _copyPasteCode = data['copy_paste'];
        });
      } else {
        final errorMsg = response?['message'] ?? '';
        if (_isApiNotConfiguredError(errorMsg)) {
          _showApiNotConfiguredDialog(widget.charge.gateway);
        } else {
          Fluttertoast.showToast(
            msg: errorMsg.isNotEmpty 
                ? errorMsg 
                : TranslationHelper.translateSync(context, 'Erro ao carregar QR Code', 'Error loading QR Code'),
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar QR Code: $e');
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao carregar QR Code', 'Error loading QR Code'),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoadingQrCode = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: 'Código copiado!',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.charge.description ?? 'Cobrança #${widget.charge.id}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status e Gateway
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Status',
                          widget.charge.statusLabel ?? widget.charge.status,
                          _getStatusColor(widget.charge.status),
                          colorProvider,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Gateway',
                          widget.charge.gateway.toUpperCase(),
                          _getGatewayColor(widget.charge.gateway),
                          colorProvider,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Informações da Cobrança
                  _buildSectionTitle('Informações da Cobrança', colorProvider),
                  SizedBox(height: 8),
                  _buildDetailRow('Valor Total', currencyFormat.format(widget.charge.totalValue), colorProvider),
                  if (widget.charge.billingType != null && widget.charge.billingType!.isNotEmpty)
                    _buildDetailRow('Tipo de Pagamento', widget.charge.billingTypeLabel?.isNotEmpty == true ? widget.charge.billingTypeLabel! : widget.charge.billingType!, colorProvider),
                  if (widget.charge.dueDate != null)
                    _buildDetailRow('Vencimento', dateFormat.format(widget.charge.dueDate!), colorProvider),
                  if (widget.charge.expiresAt != null)
                    _buildDetailRow('Expira em', dateFormat.format(widget.charge.expiresAt!), colorProvider),
                  if (widget.charge.paidAt != null)
                    _buildDetailRow('Pago em', dateFormat.format(widget.charge.paidAt!), colorProvider),
                  if (widget.charge.description != null && widget.charge.description!.isNotEmpty)
                    _buildDetailRow('Descrição', widget.charge.description!, colorProvider),
                  if (widget.charge.installmentCount != null && widget.charge.totalInstallments != null)
                    _buildDetailRow('Parcela', '${widget.charge.installmentCount}/${widget.charge.totalInstallments}', colorProvider),
                  if (widget.charge.isOneOff)
                    _buildDetailRow('Tipo', 'Cobrança Avulsa', colorProvider)
                  else if (widget.charge.planId != null)
                    _buildDetailRow('Tipo', 'Cobrança de Plano (ID: ${widget.charge.planId})', colorProvider),
                  SizedBox(height: 16),
                  // Cliente
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Cliente', colorProvider),
                      SizedBox(height: 8),
                      _buildDetailRow('Nome', widget.charge.customer.name, colorProvider),
                      if (widget.charge.customer.email != null)
                        _buildDetailRow('Email', widget.charge.customer.email!, colorProvider),
                      if (widget.charge.customer.document != null)
                        _buildDetailRow('Documento', widget.charge.customer.document!, colorProvider),
                      if (widget.charge.customer.phone != null)
                        _buildDetailRow('Telefone', widget.charge.customer.phone!, colorProvider),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Informações Adicionais
                  _buildSectionTitle('Informações Adicionais', colorProvider),
                  SizedBox(height: 8),
                  _buildDetailRow('ID da Cobrança', '#${widget.charge.id}', colorProvider),
                  if (widget.charge.gatewayId != null && widget.charge.gatewayId!.isNotEmpty)
                    _buildDetailRow('Gateway ID', widget.charge.gatewayId!, colorProvider),
                  if (widget.charge.value > 0 && widget.charge.value != widget.charge.totalValue)
                    _buildDetailRow('Valor da Parcela', currencyFormat.format(widget.charge.value), colorProvider),
                  if (widget.charge.createdAt != null)
                    _buildDetailRow('Criado em', dateFormat.format(widget.charge.createdAt!), colorProvider),
                  if (widget.charge.updatedAt != null)
                    _buildDetailRow('Atualizado em', dateFormat.format(widget.charge.updatedAt!), colorProvider),
                  // QR Code PIX
                  if (widget.charge.billingType == 'PIX' && 
                      (widget.charge.status == 'PENDING' || 
                       widget.charge.status == 'OVERDUE' || 
                       widget.charge.status == 'EXPIRED' ||
                       (widget.charge.payment.pixQrCode != null && 
                        widget.charge.status != 'PAID' &&
                        widget.charge.status != 'RECEIVED' &&
                        widget.charge.status != 'CONFIRMED')))
                    _buildPixSection(colorProvider),
                  // Links
                  if (widget.charge.payment.invoiceUrl != null)
                    _buildLinkSection('Fatura', widget.charge.payment.invoiceUrl!, colorProvider),
                  if (widget.charge.payment.bankSlipUrl != null)
                    _buildLinkSection('Boleto', widget.charge.payment.bankSlipUrl!, colorProvider),
                  // Comprovante (apenas para cobranças pagas)
                  if (widget.charge.isPaid)
                    _buildReceiptSection(colorProvider),
                  // Ações (apenas Admin/Gerente)
                  if (widget.isAdminOrManager)
                    _buildActionsSection(colorProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ColorProvider colorProvider) {
    final canCancel = widget.charge.status == 'PENDING' || 
                     widget.charge.status == 'EXPIRED' || 
                     widget.charge.status == 'OVERDUE';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        _buildSectionTitle('Ações', colorProvider),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onSync,
                icon: Icon(Icons.sync, color: Colors.white),
                label: Text('Sincronizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            if (canCancel)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.cancel, color: Colors.white),
                  label: Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, Color color, ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorProvider colorProvider) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorProvider.primaryColor,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorProvider colorProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixSection(ColorProvider colorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        _buildSectionTitle('QR Code PIX', colorProvider),
        SizedBox(height: 8),
        if (_isLoadingQrCode)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
              ),
            ),
          )
        else if (_qrCodeImage != null)
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Image.memory(
                  base64Decode(_qrCodeImage!.split(',')[1]),
                  width: 250,
                  height: 250,
                ),
              ),
              SizedBox(height: 16),
              if (_copyPasteCode != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código PIX (Copiar e Colar)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _copyPasteCode!,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: colorProvider.primaryColor),
                            onPressed: () => _copyToClipboard(_copyPasteCode!),
                            tooltip: 'Copiar código',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          )
        else
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR Code não disponível',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLinkSection(String label, String url, ColorProvider colorProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            Clipboard.setData(ClipboardData(text: url));
            Fluttertoast.showToast(
              msg: 'Link copiado! Cole no navegador para abrir.',
              backgroundColor: Colors.green,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorProvider.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.link, color: colorProvider.primaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorProvider.primaryColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorProvider.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptSection(ColorProvider colorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        _buildSectionTitle('Comprovante de Pagamento', colorProvider),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final response = await gpsapis.getFinancialChargeReceipt(id: widget.charge.id);
              if (response != null && response['status'] == 1 && response['data'] != null) {
                final receiptData = response['data'];
                final receiptUrl = receiptData['receipt_url'];
                
                if (receiptUrl != null && receiptUrl.isNotEmpty) {
                  final uri = Uri.parse(receiptUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    Clipboard.setData(ClipboardData(text: receiptUrl));
                    Fluttertoast.showToast(
                      msg: 'Link do comprovante copiado!',
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    );
                  }
                } else {
                  Fluttertoast.showToast(
                    msg: 'Comprovante não disponível',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                }
              } else {
                Fluttertoast.showToast(
                  msg: 'Erro ao buscar comprovante',
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            } catch (e) {
              print('❌ Erro ao buscar comprovante: $e');
              Fluttertoast.showToast(
                msg: 'Erro ao buscar comprovante',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          },
          icon: Icon(Icons.receipt, color: Colors.white),
          label: Text('Abrir Comprovante (PDF)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorProvider.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'O comprovante será aberto em uma nova aba e pode ser salvo ou impresso.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
}

