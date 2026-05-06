import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/gpsserver/datasources.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uconnect/utils/translation_helper.dart';

class CreateChargeModal extends StatefulWidget {
  final VoidCallback onChargeCreated;

  const CreateChargeModal({
    Key? key,
    required this.onChargeCreated,
  }) : super(key: key);

  @override
  _CreateChargeModalState createState() => _CreateChargeModalState();
}

class _CreateChargeModalState extends State<CreateChargeModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Tipo de cobrança: 'oneoff' = avulsa, 'plan' = vinculada a plano
  String _chargeType = 'oneoff';
  
  // Controllers para cobrança avulsa
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerDocumentController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  
  // Controllers para cobrança vinculada a plano
  final _planIdController = TextEditingController();
  final _planCustomerIdController = TextEditingController();

  String _selectedGateway = 'asaas';
  String _selectedBillingType = 'PIX';
  DateTime _selectedDueDate = DateTime.now().add(Duration(days: 7));
  bool _blockAfterDue = false;
  bool _isLoading = false;

  final List<String> _gatewayOptions = ['asaas', 'suitpay'];
  final Map<String, List<String>> _billingTypes = {
    'asaas': ['PIX', 'BOLETO', 'CREDIT_CARD'],
    'suitpay': ['PIX'],
  };

  @override
  void dispose() {
    _valueController.dispose();
    _descriptionController.dispose();
    _customerIdController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerDocumentController.dispose();
    _customerPhoneController.dispose();
    _planIdController.dispose();
    _planCustomerIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _createCharge() async {
    print('🔵 [CreateChargeModal] ========== _createCharge INICIADO ==========');
    
    // Verificar se o FormState existe
    if (_formKey.currentState == null) {
      print('❌ [CreateChargeModal] FormState é null!');
      EasyLoading.showError('Erro: Formulário não inicializado');
      return;
    }
    
    print('✅ [CreateChargeModal] FormState existe');
    
    // Validar formulário
    print('🔵 [CreateChargeModal] Iniciando validação do formulário...');
    final isValid = _formKey.currentState!.validate();
    
    if (!isValid) {
      print('❌ [CreateChargeModal] Validação do formulário falhou');
      EasyLoading.showError(TranslationHelper.translateSync(
        context,
        'Por favor, preencha todos os campos obrigatórios',
        'Please fill in all required fields',
      ));
      return;
    }

    print('✅ [CreateChargeModal] Validação do formulário passou');

    // Verificar se o contexto ainda está montado
    if (!mounted) {
      print('❌ [CreateChargeModal] Widget não está montado');
      return;
    }

    try {
      print('🔵 [CreateChargeModal] Iniciando criação da cobrança...');
      EasyLoading.show(status: TranslationHelper.translateSync(
        context,
        'Criando cobrança...',
        'Creating charge...',
      ));

      final dueDate = DateFormat('yyyy-MM-dd').format(_selectedDueDate);
      Map<String, dynamic> response;

      if (_chargeType == 'plan') {
        // Cobrança vinculada a plano
        final planId = int.tryParse(_planIdController.text.trim());
        final customerId = _planCustomerIdController.text.trim().isEmpty
            ? null
            : int.tryParse(_planCustomerIdController.text.trim());

        if (planId == null || planId <= 0) {
          EasyLoading.dismiss();
          EasyLoading.showError(TranslationHelper.translateSync(
            context,
            'ID do plano inválido',
            'Invalid plan ID',
          ));
          return;
        }

        if (customerId == null) {
          EasyLoading.dismiss();
          EasyLoading.showError(TranslationHelper.translateSync(
            context,
            'ID do cliente é obrigatório para cobrança vinculada a plano',
            'Customer ID is required for plan-linked charge',
          ));
          return;
        }

        response = await gpsapis.createFinancialCharge(
          planId: planId,
          customerId: customerId,
          dueDate: dueDate,
          billingType: _selectedBillingType,
          gateway: _selectedGateway,
          blockAfterDue: _blockAfterDue ? 1 : 0, // Converter boolean para int (0 ou 1)
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
        );
      } else {
        // Cobrança avulsa
        final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
        if (value == null || value <= 0) {
          EasyLoading.dismiss();
          EasyLoading.showError(TranslationHelper.translateSync(
            context,
            'Valor inválido',
            'Invalid value',
          ));
          return;
        }

        final customerId = _customerIdController.text.trim().isEmpty
            ? null
            : int.tryParse(_customerIdController.text.trim());

        response = await gpsapis.createFinancialCharge(
          gateway: _selectedGateway,
          value: value,
          dueDate: dueDate,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          billingType: _selectedBillingType,
          customerId: customerId,
          customerName: _customerNameController.text.trim(),
          customerEmail: _customerEmailController.text.trim().isEmpty 
              ? null 
              : _customerEmailController.text.trim(),
          customerDocument: _customerDocumentController.text.trim().isEmpty 
              ? null 
              : _customerDocumentController.text.trim(),
          customerPhone: _customerPhoneController.text.trim().isEmpty 
              ? null 
              : _customerPhoneController.text.trim(),
        );
      }

      print('✅ [CreateChargeModal] Operação concluída. Status: ${response['status']}');

      if (response['status'] == 1) {
        print('✅ [CreateChargeModal] Sucesso! Fechando modal...');
        EasyLoading.dismiss();
        
        // Fechar o modal primeiro
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        
        // Mostrar mensagem de sucesso após fechar o modal
        await Future.delayed(Duration(milliseconds: 300));
        EasyLoading.showSuccess(
          TranslationHelper.translateSync(
            context,
            'Cobrança criada com sucesso!',
            'Charge created successfully!',
          ),
          duration: Duration(seconds: 2),
        );
      } else {
        print('❌ [CreateChargeModal] Falha na operação. Erro: ${response['message']}');
        EasyLoading.dismiss();
        
        // Verificar se é erro de API não configurada
        final errorMessage = response['message'] ?? '';
        final isApiNotConfigured = errorMessage.toLowerCase().contains('api key') ||
            errorMessage.toLowerCase().contains('não configurada') ||
            errorMessage.toLowerCase().contains('not configured') ||
            errorMessage.toLowerCase().contains('api key do') ||
            errorMessage.toLowerCase().contains('gateway não configurado');
        
        if (isApiNotConfigured) {
          // Mostrar aviso específico sobre API não configurada
          if (mounted) {
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
                          'A API do gateway ${_selectedGateway.toUpperCase()} não está configurada para este usuário.',
                          'The ${_selectedGateway.toUpperCase()} gateway API is not configured for this user.',
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        TranslationHelper.translateSync(
                          context,
                          'Por favor, configure a API Key do gateway nas configurações antes de criar cobranças.',
                          'Please configure the gateway API Key in settings before creating charges.',
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
        } else {
          // Mostrar erro genérico
          EasyLoading.showError(
            errorMessage.isNotEmpty
                ? errorMessage
                : TranslationHelper.translateSync(
                    context,
                    'Erro ao criar cobrança',
                    'Error creating charge',
                  ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [CreateChargeModal] EXCEÇÃO CAPTURADA:');
      print('   Erro: $e');
      print('   StackTrace: $stackTrace');
      EasyLoading.dismiss();
      EasyLoading.showError('Erro: $e');
    }
    
    print('🔵 [CreateChargeModal] ========== _createCharge FINALIZADO ==========');
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho padrão (igual ao modal de motorista)
          Container(
            color: colorProvider.primaryColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TranslationHelper.translateSync(
                              context,
                              'Nova Cobrança',
                              'New Charge',
                            ),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Conteúdo com scroll
          Expanded(
            child: Container(
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tipo de Cobrança
                            Text(
                              TranslationHelper.translateSync(
                                context,
                                'Tipo de Cobrança',
                                'Charge Type',
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorProvider.primaryColor,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(TranslationHelper.translateSync(
                                      context,
                                      'Avulsa',
                                      'One-off',
                                    )),
                                    value: 'oneoff',
                                    groupValue: _chargeType,
                                    onChanged: (value) {
                                      setState(() {
                                        _chargeType = value!;
                                      });
                                    },
                                    activeColor: colorProvider.primaryColor,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(TranslationHelper.translateSync(
                                      context,
                                      'Vinculada a Plano',
                                      'Plan Linked',
                                    )),
                                    value: 'plan',
                                    groupValue: _chargeType,
                                    onChanged: (value) {
                                      setState(() {
                                        _chargeType = value!;
                                      });
                                    },
                                    activeColor: colorProvider.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            
                            // Gateway
                            DropdownButtonFormField<String>(
                              value: _selectedGateway,
                              decoration: InputDecoration(
                                labelText: TranslationHelper.translateSync(
                                  context,
                                  'Gateway',
                                  'Gateway',
                                ),
                                prefixIcon: Icon(Icons.payment),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _gatewayOptions.map((String gateway) {
                                return DropdownMenuItem<String>(
                                  value: gateway,
                                  child: Text(gateway.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGateway = value!;
                                  // Resetar billing type se não for compatível
                                  final availableTypes = _billingTypes[_selectedGateway] ?? [];
                                  if (!availableTypes.contains(_selectedBillingType)) {
                                    _selectedBillingType = availableTypes.first;
                                  }
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            // Tipo de Pagamento
                            DropdownButtonFormField<String>(
                              value: _selectedBillingType,
                              decoration: InputDecoration(
                                labelText: TranslationHelper.translateSync(
                                  context,
                                  'Tipo de Pagamento',
                                  'Payment Type',
                                ),
                                prefixIcon: Icon(Icons.credit_card),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: (_billingTypes[_selectedGateway] ?? []).map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBillingType = value!;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            // Data de Vencimento
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: colorProvider.primaryColor),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            TranslationHelper.translateSync(
                                              context,
                                              'Data de Vencimento',
                                              'Due Date',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            dateFormat.format(_selectedDueDate),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Descrição
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: TranslationHelper.translateSync(
                                  context,
                                  'Descrição',
                                  'Description',
                                ),
                                prefixIcon: Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 2,
                            ),
                            SizedBox(height: 24),
                            
                            // Campos específicos por tipo de cobrança
                            if (_chargeType == 'plan') ...[
                              // Campos para cobrança vinculada a plano
                              Text(
                                TranslationHelper.translateSync(
                                  context,
                                  'Dados do Plano',
                                  'Plan Data',
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorProvider.primaryColor,
                                ),
                              ),
                              SizedBox(height: 16),
                              // ID do Plano
                              TextFormField(
                                controller: _planIdController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'ID do Plano *',
                                    'Plan ID *',
                                  ),
                                  prefixIcon: Icon(Icons.assignment),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'ID do plano é obrigatório',
                                      'Plan ID is required',
                                    );
                                  }
                                  final id = int.tryParse(value);
                                  if (id == null || id <= 0) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'ID do plano inválido',
                                      'Invalid plan ID',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // ID do Cliente (obrigatório para plano)
                              TextFormField(
                                controller: _planCustomerIdController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'ID do Cliente *',
                                    'Customer ID *',
                                  ),
                                  hintText: TranslationHelper.translateSync(
                                    context,
                                    'Informe o ID do cliente',
                                    'Enter customer ID',
                                  ),
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'ID do cliente é obrigatório',
                                      'Customer ID is required',
                                    );
                                  }
                                  final id = int.tryParse(value);
                                  if (id == null || id <= 0) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'ID inválido',
                                      'Invalid ID',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // Bloquear após vencimento
                              CheckboxListTile(
                                title: Text(TranslationHelper.translateSync(
                                  context,
                                  'Bloquear após vencimento',
                                  'Block after due date',
                                )),
                                value: _blockAfterDue,
                                onChanged: (value) {
                                  setState(() {
                                    _blockAfterDue = value ?? false;
                                  });
                                },
                                activeColor: colorProvider.primaryColor,
                              ),
                            ] else ...[
                              // Campos para cobrança avulsa
                              // Valor
                              TextFormField(
                                controller: _valueController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'Valor (R\$) *',
                                    'Amount (R\$) *',
                                  ),
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'Valor é obrigatório',
                                      'Amount is required',
                                    );
                                  }
                                  final numValue = double.tryParse(value.replaceAll(',', '.'));
                                  if (numValue == null || numValue <= 0) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'Valor inválido',
                                      'Invalid amount',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 24),
                              // Dados do Cliente
                              Text(
                                TranslationHelper.translateSync(
                                  context,
                                  'Dados do Cliente',
                                  'Customer Data',
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorProvider.primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                TranslationHelper.translateSync(
                                  context,
                                  'Deixe o ID do Cliente em branco para criar cobrança para você mesmo',
                                  'Leave Customer ID blank to create charge for yourself',
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 16),
                              // ID do Cliente (opcional)
                              TextFormField(
                                controller: _customerIdController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'ID do Cliente (Opcional)',
                                    'Customer ID (Optional)',
                                  ),
                                  hintText: TranslationHelper.translateSync(
                                    context,
                                    'Deixe em branco para você mesmo',
                                    'Leave blank for yourself',
                                  ),
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final id = int.tryParse(value);
                                    if (id == null || id <= 0) {
                                      return TranslationHelper.translateSync(
                                        context,
                                        'ID inválido',
                                        'Invalid ID',
                                      );
                                    }
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // Nome do Cliente
                              TextFormField(
                                controller: _customerNameController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'Nome *',
                                    'Name *',
                                  ),
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return TranslationHelper.translateSync(
                                      context,
                                      'Nome é obrigatório',
                                      'Name is required',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // Email
                              TextFormField(
                                controller: _customerEmailController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'Email',
                                    'Email',
                                  ),
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (!value.contains('@')) {
                                      return TranslationHelper.translateSync(
                                        context,
                                        'Email inválido',
                                        'Invalid email',
                                      );
                                    }
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              // Documento
                              TextFormField(
                                controller: _customerDocumentController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'CPF/CNPJ (Opcional)',
                                    'CPF/CNPJ (Optional)',
                                  ),
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              // Telefone
                              TextFormField(
                                controller: _customerPhoneController,
                                decoration: InputDecoration(
                                  labelText: TranslationHelper.translateSync(
                                    context,
                                    'Telefone',
                                    'Phone',
                                  ),
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Botões fixos na parte inferior (igual ao modal de motorista)
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  TranslationHelper.translateSync(
                                    context,
                                    'Cancelar',
                                    'Cancel',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () async {
                                  try {
                                    await _createCharge();
                                  } catch (e, stackTrace) {
                                    print('❌ [CreateChargeModal] Erro ao criar: $e');
                                    print('❌ [CreateChargeModal] StackTrace: $stackTrace');
                                    EasyLoading.showError('Erro: $e');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorProvider.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        TranslationHelper.translateSync(
                                          context,
                                          'Criar Cobrança',
                                          'Create Charge',
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}
