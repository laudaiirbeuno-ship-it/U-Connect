import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/user_api.dart';
import 'package:uconnect/data/screens/administration/controllers/administration_controller.dart';
import 'package:intl/intl.dart';

class CreateUserModal extends StatefulWidget {
  final UserItem? user; // Se fornecido, será modo edição

  CreateUserModal({this.user});

  @override
  _CreateUserModalState createState() => _CreateUserModalState();
}

class _CreateUserModalState extends State<CreateUserModal> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers básicos
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneNumberController;
  
  // Controllers do Cliente
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _personalCodeController;
  late TextEditingController _birthDateController;
  late TextEditingController _whatsappController;
  late TextEditingController _clientAddressController;
  late TextEditingController _commentController;
  
  // Controllers do Endereço
  late TextEditingController _zipCodeController;
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _complementController;
  
  // Controllers de Pagamento
  late TextEditingController _monthlyFeeController;
  late TextEditingController _paymentDayController;
  late TextEditingController _contractSignDateController;
  late TextEditingController _contractExpiryDateController;
  
  // Controllers de Configuração
  late TextEditingController _devicesLimitController;
  late TextEditingController _subscriptionExpirationController;
  late TextEditingController _billingPlanIdController;
  late TextEditingController _companyIdController;
  
  // Estados
  bool _active = true;
  int _groupId = 2; // Padrão: Usuário
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controllers
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneNumberController = TextEditingController();
    
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _personalCodeController = TextEditingController();
    _birthDateController = TextEditingController();
    _whatsappController = TextEditingController();
    _clientAddressController = TextEditingController();
    _commentController = TextEditingController();
    
    _zipCodeController = TextEditingController();
    _streetController = TextEditingController();
    _numberController = TextEditingController();
    _districtController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _complementController = TextEditingController();
    
    _monthlyFeeController = TextEditingController();
    _paymentDayController = TextEditingController();
    _contractSignDateController = TextEditingController();
    _contractExpiryDateController = TextEditingController();
    
    _devicesLimitController = TextEditingController();
    _subscriptionExpirationController = TextEditingController();
    _billingPlanIdController = TextEditingController();
    _companyIdController = TextEditingController();
    
    // Se for edição, preencher campos
    if (widget.user != null) {
      _loadUserData();
    }
  }
  
  void _loadUserData() {
    final user = widget.user!;
    _emailController.text = user.email;
    _active = user.active;
    _groupId = user.groupId;
    _phoneNumberController.text = user.phoneNumber ?? '';
    _devicesLimitController.text = user.devicesLimit?.toString() ?? '';
    _subscriptionExpirationController.text = user.subscriptionExpiration ?? '';
    _billingPlanIdController.text = user.billingPlanId?.toString() ?? '';
    _companyIdController.text = user.companyId?.toString() ?? '';
    
    if (user.client != null) {
      _firstNameController.text = user.client!.firstName;
      _lastNameController.text = user.client!.lastName;
      _personalCodeController.text = user.client!.personalCode ?? '';
      _birthDateController.text = user.client!.birthDate ?? '';
      _whatsappController.text = user.client!.whatsapp ?? '';
      _clientAddressController.text = user.client!.address ?? '';
      _commentController.text = user.client!.comment ?? '';
    }
    
    if (user.address != null) {
      _zipCodeController.text = user.address!.zipCode ?? '';
      _streetController.text = user.address!.street ?? '';
      _numberController.text = user.address!.number ?? '';
      _districtController.text = user.address!.district ?? '';
      _cityController.text = user.address!.city ?? '';
      _stateController.text = user.address!.state ?? '';
      _complementController.text = user.address!.complement ?? '';
    }
    
    if (user.paymentInfo != null) {
      _monthlyFeeController.text = user.paymentInfo!.monthlyFee?.toString() ?? '';
      _paymentDayController.text = user.paymentInfo!.paymentDay?.toString() ?? '';
      _contractSignDateController.text = user.paymentInfo!.contractSignDate ?? '';
      _contractExpiryDateController.text = user.paymentInfo!.contractExpiryDate ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _personalCodeController.dispose();
    _birthDateController.dispose();
    _whatsappController.dispose();
    _clientAddressController.dispose();
    _commentController.dispose();
    _zipCodeController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _complementController.dispose();
    _monthlyFeeController.dispose();
    _paymentDayController.dispose();
    _contractSignDateController.dispose();
    _contractExpiryDateController.dispose();
    _devicesLimitController.dispose();
    _subscriptionExpirationController.dispose();
    _billingPlanIdController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: Locale('pt', 'BR'),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectDateTime(TextEditingController controller, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: Locale('pt', 'BR'),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        controller.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
      }
    }
  }

  void _submitForm(AdministrationController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Criar request
    final request = CreateUserRequest(
      email: _emailController.text.trim(),
      password: widget.user == null 
          ? _passwordController.text 
          : _passwordController.text,
      groupId: _groupId,
      active: _active,
      phoneNumber: _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
      devicesLimit: _devicesLimitController.text.trim().isEmpty ? null : int.tryParse(_devicesLimitController.text.trim()),
      subscriptionExpiration: _subscriptionExpirationController.text.trim().isEmpty ? null : _subscriptionExpirationController.text.trim(),
      billingPlanId: _billingPlanIdController.text.trim().isEmpty ? null : int.tryParse(_billingPlanIdController.text.trim()),
      companyId: _companyIdController.text.trim().isEmpty ? null : int.tryParse(_companyIdController.text.trim()),
      client: UserClientRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        personalCode: _personalCodeController.text.trim().isEmpty ? null : _personalCodeController.text.trim(),
        birthDate: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        address: _clientAddressController.text.trim().isEmpty ? null : _clientAddressController.text.trim(),
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      ),
      address: (_zipCodeController.text.trim().isNotEmpty ||
              _streetController.text.trim().isNotEmpty ||
              _cityController.text.trim().isNotEmpty)
          ? UserAddressRequest(
              zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
              street: _streetController.text.trim().isEmpty ? null : _streetController.text.trim(),
              number: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
              district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
              city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
              state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
              complement: _complementController.text.trim().isEmpty ? null : _complementController.text.trim(),
            )
          : null,
      paymentInfo: (_monthlyFeeController.text.trim().isNotEmpty ||
              _paymentDayController.text.trim().isNotEmpty)
          ? PaymentInfoRequest(
              monthlyFee: _monthlyFeeController.text.trim().isEmpty ? null : double.tryParse(_monthlyFeeController.text.trim().replaceAll(',', '.')),
              paymentDay: _paymentDayController.text.trim().isEmpty ? null : int.tryParse(_paymentDayController.text.trim()),
              contractSignDate: _contractSignDateController.text.trim().isEmpty ? null : _contractSignDateController.text.trim(),
              contractExpiryDate: _contractExpiryDateController.text.trim().isEmpty ? null : _contractExpiryDateController.text.trim(),
            )
          : null,
    );

    // Se for edição, usar updateUser, senão createUser
    if (widget.user != null) {
      final success = await controller.updateUser(widget.user!.id, request);
      if (success) {
        Navigator.pop(context);
      }
    } else {
      final success = await controller.createUser(request);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.user == null ? 'Criar Novo Usuário' : 'Editar Usuário',
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
            // Form
            Flexible(
              child: Consumer<AdministrationController>(
                builder: (context, controller, child) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Informações Básicas do Usuário
                          _buildSection(
                            'Informações Básicas do Usuário',
                            Icons.person,
                            colorProvider,
                            [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email *',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              if (widget.user == null) ...[
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Senha *',
                                    prefixIcon: Icon(Icons.lock),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    helperText: 'Mínimo 6 caracteres',
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Senha é obrigatória';
                                    }
                                    if (value.length < 6) {
                                      return 'Senha deve ter no mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                              ] else ...[
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Nova Senha (deixe vazio para manter)',
                                    prefixIcon: Icon(Icons.lock),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    helperText: 'Deixe vazio para manter a senha atual',
                                  ),
                                  obscureText: true,
                                ),
                                SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _phoneNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Telefone',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _groupId,
                                decoration: InputDecoration(
                                  labelText: 'Grupo *',
                                  prefixIcon: Icon(Icons.group),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: [
                                  DropdownMenuItem(value: 1, child: Text('Admin')),
                                  DropdownMenuItem(value: 2, child: Text('Usuário')),
                                  DropdownMenuItem(value: 3, child: Text('Supervisor')),
                                  DropdownMenuItem(value: 4, child: Text('Gerente')),
                                  DropdownMenuItem(value: 5, child: Text('Operador')),
                                  DropdownMenuItem(value: 6, child: Text('Revendedor')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _groupId = value);
                                  }
                                },
                              ),
                              SizedBox(height: 16),
                              SwitchListTile(
                                title: Text('Usuário Ativo'),
                                value: _active,
                                onChanged: (value) => setState(() => _active = value),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _devicesLimitController,
                                decoration: InputDecoration(
                                  labelText: 'Limite de Dispositivos',
                                  prefixIcon: Icon(Icons.devices),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _subscriptionExpirationController,
                                decoration: InputDecoration(
                                  labelText: 'Data de Expiração da Assinatura',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Formato: YYYY-MM-DD HH:mm:ss ou YYYY-MM-DD',
                                ),
                                onTap: () => _selectDateTime(_subscriptionExpirationController, 'Data de Expiração'),
                                readOnly: true,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _billingPlanIdController,
                                decoration: InputDecoration(
                                  labelText: 'ID do Plano de Faturamento',
                                  prefixIcon: Icon(Icons.payment),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _companyIdController,
                                decoration: InputDecoration(
                                  labelText: 'ID da Empresa',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Dados do Cliente
                          _buildSection(
                            'Dados do Cliente',
                            Icons.person_outline,
                            colorProvider,
                            [
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nome *',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nome é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Sobrenome *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Sobrenome é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _personalCodeController,
                                decoration: InputDecoration(
                                  labelText: 'CPF/CNPJ',
                                  prefixIcon: Icon(Icons.badge),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _birthDateController,
                                decoration: InputDecoration(
                                  labelText: 'Data de Nascimento',
                                  prefixIcon: Icon(Icons.cake),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Formato: YYYY-MM-DD',
                                ),
                                onTap: () => _selectDate(_birthDateController, 'Data de Nascimento'),
                                readOnly: true,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _whatsappController,
                                decoration: InputDecoration(
                                  labelText: 'WhatsApp',
                                  prefixIcon: Icon(Icons.chat),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _clientAddressController,
                                decoration: InputDecoration(
                                  labelText: 'Endereço (texto livre)',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                maxLines: 2,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  labelText: 'Observações',
                                  prefixIcon: Icon(Icons.note),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Endereço Completo
                          _buildSection(
                            'Endereço Completo',
                            Icons.home,
                            colorProvider,
                            [
                              TextFormField(
                                controller: _zipCodeController,
                                decoration: InputDecoration(
                                  labelText: 'CEP',
                                  prefixIcon: Icon(Icons.pin),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _streetController,
                                decoration: InputDecoration(
                                  labelText: 'Rua',
                                  prefixIcon: Icon(Icons.streetview),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _numberController,
                                      decoration: InputDecoration(
                                        labelText: 'Número',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _districtController,
                                      decoration: InputDecoration(
                                        labelText: 'Bairro',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _cityController,
                                      decoration: InputDecoration(
                                        labelText: 'Cidade',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _stateController,
                                      decoration: InputDecoration(
                                        labelText: 'UF',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      maxLength: 2,
                                      textCapitalization: TextCapitalization.characters,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _complementController,
                                decoration: InputDecoration(
                                  labelText: 'Complemento',
                                  prefixIcon: Icon(Icons.add_location),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Informações de Pagamento
                          _buildSection(
                            'Informações de Pagamento',
                            Icons.payment,
                            colorProvider,
                            [
                              TextFormField(
                                controller: _monthlyFeeController,
                                decoration: InputDecoration(
                                  labelText: 'Mensalidade',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Valor da mensalidade',
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _paymentDayController,
                                decoration: InputDecoration(
                                  labelText: 'Dia de Pagamento',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Dia do mês (1-30)',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _contractSignDateController,
                                decoration: InputDecoration(
                                  labelText: 'Data de Assinatura do Contrato',
                                  prefixIcon: Icon(Icons.description),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Formato: YYYY-MM-DD',
                                ),
                                onTap: () => _selectDate(_contractSignDateController, 'Data de Assinatura'),
                                readOnly: true,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _contractExpiryDateController,
                                decoration: InputDecoration(
                                  labelText: 'Data de Expiração do Contrato',
                                  prefixIcon: Icon(Icons.event_busy),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  helperText: 'Formato: YYYY-MM-DD',
                                ),
                                onTap: () => _selectDate(_contractExpiryDateController, 'Data de Expiração'),
                                readOnly: true,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Botões
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: colorProvider.primaryColor),
                                  ),
                                  child: Text('Cancelar'),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading ? null : () => _submitForm(controller),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorProvider.primaryColor,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: controller.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(widget.user == null ? 'Criar Usuário' : 'Salvar Alterações'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, ColorProvider colorProvider, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorProvider.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorProvider.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

