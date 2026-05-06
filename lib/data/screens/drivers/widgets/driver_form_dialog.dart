import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/model/driver_form_data.dart';
import 'package:uconnect/data/screens/drivers/controllers/drivers_controller.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/config/static.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uconnect/storage/user_repository.dart';

class DriverFormDialog extends StatefulWidget {
  final DriverFormData? initialData; // null para criar, preenchido para editar
  final int? driverId; // ID do motorista para editar

  const DriverFormDialog({
    Key? key,
    this.initialData,
    this.driverId,
  }) : super(key: key);

  @override
  _DriverFormDialogState createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _rfidController;
  late TextEditingController _descriptionController;
  late TextEditingController _devicePortController;

  int? _selectedDeviceId;
  Map<String, String> _availableDevices = {};
  bool _isLoadingFormData = false;
  File? _selectedPhoto; // Foto selecionada do motorista
  String? _photoUrl; // URL da foto existente (para edição)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.name ?? '');
    _phoneController = TextEditingController(text: widget.initialData?.phone ?? '');
    _emailController = TextEditingController(text: widget.initialData?.email ?? '');
    _rfidController = TextEditingController(text: widget.initialData?.rfid ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?.description ?? '');
    _devicePortController = TextEditingController(text: widget.initialData?.devicePort ?? '');
    _selectedDeviceId = widget.initialData?.deviceId;

    // Carregar dados do formulário
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingFormData = true;
    });

    try {
      final controller = Provider.of<DriversController>(context, listen: false);
      
      if (widget.driverId != null) {
        // Editar: carregar dados do motorista
        final editData = await controller.getEditDriverData(widget.driverId!);
        if (editData != null) {
          _availableDevices = editData.devices;
          print('📱 [DriverFormDialog] Dispositivos carregados (editar): ${_availableDevices.length}');
          
          // Se não houver dispositivos, buscar usando fallback
          if (_availableDevices.isEmpty) {
            print('⚠️ [DriverFormDialog] Nenhum dispositivo retornado pela API, usando fallback...');
            await _loadDevicesFallback();
          }
          
          if (editData.item != null) {
            _nameController.text = editData.item!.name;
            _phoneController.text = editData.item!.phone;
            _emailController.text = editData.item!.email;
            _rfidController.text = editData.item!.rfid;
            _descriptionController.text = editData.item!.description;
            _selectedDeviceId = editData.item!.deviceId;
            _devicePortController.text = editData.item!.devicePort ?? '';
            // Carregar foto existente se houver
            if (widget.initialData?.photo != null && widget.initialData!.photo!.isNotEmpty) {
              _photoUrl = widget.initialData!.photo;
            }
          }
        } else {
          print('⚠️ [DriverFormDialog] editData é null, usando fallback...');
          await _loadDevicesFallback();
        }
      } else {
        // Criar: carregar lista de dispositivos
        final addData = await controller.getAddDriverData();
        if (addData != null) {
          _availableDevices = addData.devices;
          print('📱 [DriverFormDialog] Dispositivos carregados (criar): ${_availableDevices.length}');
          
          // Se não houver dispositivos, buscar usando fallback
          if (_availableDevices.isEmpty) {
            print('⚠️ [DriverFormDialog] Nenhum dispositivo retornado pela API, usando fallback...');
            await _loadDevicesFallback();
          }
        } else {
          print('⚠️ [DriverFormDialog] addData é null, usando fallback...');
          await _loadDevicesFallback();
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar dados do formulário: $e');
      // Em caso de erro, tentar usar fallback
      await _loadDevicesFallback();
    } finally {
      setState(() {
        _isLoadingFormData = false;
      });
    }
  }

  /// Fallback: Buscar dispositivos usando getDevicesList
  Future<void> _loadDevicesFallback() async {
    try {
      print('🔄 [DriverFormDialog] Carregando dispositivos via fallback...');
      final userApiHash = StaticVarMethod.user_api_hash;
      
      if (userApiHash == null || userApiHash.isEmpty) {
        print('❌ [DriverFormDialog] user_api_hash não disponível para fallback');
        return;
      }

      final devicesList = await gpsapis.getDevicesList(userApiHash);
      
      if (devicesList != null && devicesList.isNotEmpty) {
        // Converter lista de deviceItems para Map<String, String>
        _availableDevices = {};
        for (var device in devicesList) {
          if (device.id != null) {
            final deviceId = device.id.toString();
            final deviceName = device.name ?? 'Dispositivo ${device.id}';
            _availableDevices[deviceId] = deviceName;
          }
        }
        print('✅ [DriverFormDialog] ${_availableDevices.length} dispositivo(s) carregado(s) via fallback');
      } else {
        print('⚠️ [DriverFormDialog] Nenhum dispositivo encontrado via fallback');
      }
    } catch (e) {
      print('❌ [DriverFormDialog] Erro ao carregar dispositivos via fallback: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rfidController.dispose();
    _descriptionController.dispose();
    _devicePortController.dispose();
    super.dispose();
  }

  Future<void> _saveDriver() async {
    print('🔵 [DriverFormDialog] ========== _saveDriver INICIADO ==========');
    
    // Verificar se o FormState existe
    if (_formKey.currentState == null) {
      print('❌ [DriverFormDialog] FormState é null!');
      EasyLoading.showError('Erro: Formulário não inicializado');
      return;
    }
    
    print('✅ [DriverFormDialog] FormState existe');
    
    // Validar formulário
    print('🔵 [DriverFormDialog] Iniciando validação do formulário...');
    final isValid = _formKey.currentState!.validate();
    
    if (!isValid) {
      print('❌ [DriverFormDialog] Validação do formulário falhou');
      EasyLoading.showError('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    print('✅ [DriverFormDialog] Validação do formulário passou');
    
    // Verificar se o contexto ainda está montado
    if (!mounted) {
      print('❌ [DriverFormDialog] Widget não está montado');
      return;
    }
    
    print('🔵 [DriverFormDialog] Obtendo controller...');
    final controller = Provider.of<DriversController>(context, listen: false);
    print('✅ [DriverFormDialog] Controller obtido: ${controller.runtimeType}');
    
    // Validar duplicatas antes de criar/editar
    print('🔵 [DriverFormDialog] Validando duplicatas...');
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    
    // Helper para converter dynamic para String
    String? _toString(dynamic value) {
      if (value == null) return null;
      return value.toString().trim();
    }
    
    // Helper para comparar IDs
    bool _sameId(dynamic id1, dynamic id2) {
      if (id1 == null || id2 == null) return false;
      return id1.toString() == id2.toString();
    }
    
    // Verificar duplicatas de nome
    final duplicateName = controller.allDrivers.any((driver) {
      if (widget.driverId != null && _sameId(driver.id, widget.driverId)) {
        return false; // Ignorar o próprio motorista ao editar
      }
      final driverName = _toString(driver.name);
      return driverName != null && driverName.toLowerCase() == name.toLowerCase();
    });
    
    if (duplicateName) {
      EasyLoading.showError('Já existe ${widget.driverId != null ? "outro " : ""}motorista cadastrado com este nome');
      return;
    }
    
    // Verificar duplicatas de telefone
    if (phone.isNotEmpty) {
      final duplicatePhone = controller.allDrivers.any((driver) {
        if (widget.driverId != null && _sameId(driver.id, widget.driverId)) {
          return false; // Ignorar o próprio motorista ao editar
        }
        final driverPhone = _toString(driver.phone);
        return driverPhone != null && driverPhone.isNotEmpty && driverPhone == phone;
      });
      
      if (duplicatePhone) {
        EasyLoading.showError('Já existe ${widget.driverId != null ? "outro " : ""}motorista cadastrado com este número de telefone');
        return;
      }
    }
    
    // Verificar duplicatas de email
    if (email.isNotEmpty) {
      final duplicateEmail = controller.allDrivers.any((driver) {
        if (widget.driverId != null && _sameId(driver.id, widget.driverId)) {
          return false; // Ignorar o próprio motorista ao editar
        }
        final driverEmail = _toString(driver.email);
        return driverEmail != null && driverEmail.isNotEmpty && driverEmail.toLowerCase() == email.toLowerCase();
      });
      
      if (duplicateEmail) {
        EasyLoading.showError('Já existe ${widget.driverId != null ? "outro " : ""}motorista cadastrado com este email');
        return;
      }
    }
    
    print('✅ [DriverFormDialog] Nenhuma duplicata encontrada');
    
    print('🔵 [DriverFormDialog] Criando DriverFormData...');
    
    // Upload da foto se houver uma nova selecionada
    String? finalPhotoUrl = _photoUrl;
    if (_selectedPhoto != null) {
      // TODO: Implementar upload da foto para o servidor
      // Por enquanto, manter a URL existente ou null
      print('📸 [DriverFormDialog] Foto selecionada: ${_selectedPhoto!.path}');
      // Aqui você precisaria fazer upload da foto e obter a URL
      // Por enquanto, vamos manter como está
    }
    
    final driverData = DriverFormData(
      id: widget.driverId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      rfid: _rfidController.text.trim(),
      description: _descriptionController.text.trim(),
      deviceId: _selectedDeviceId,
      devicePort: _devicePortController.text.trim().isNotEmpty 
          ? _devicePortController.text.trim() 
          : null,
      photo: finalPhotoUrl,
    );
    
    print('✅ [DriverFormDialog] DriverFormData criado:');
    print('   - Nome: ${driverData.name}');
    print('   - Telefone: ${driverData.phone}');
    print('   - Email: ${driverData.email}');
    print('   - DeviceId: ${driverData.deviceId}');

    print('🔵 [DriverFormDialog] Mostrando loading...');
    EasyLoading.show(status: widget.driverId != null ? 'Atualizando...' : 'Criando...');

    try {
      print('🔵 [DriverFormDialog] Iniciando ${widget.driverId != null ? "atualização" : "criação"}...');
      bool success;
      if (widget.driverId != null) {
        print('🔵 [DriverFormDialog] Chamando updateDriver...');
        success = await controller.updateDriver(driverData);
      } else {
        print('🔵 [DriverFormDialog] Chamando createDriver...');
        success = await controller.createDriver(driverData);
      }

      print('✅ [DriverFormDialog] Operação concluída. Success: $success');

      if (success) {
        print('✅ [DriverFormDialog] Sucesso! Fechando modal...');
        EasyLoading.dismiss();
        
        // Fechar o modal primeiro
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        
        // Mostrar mensagem de sucesso após fechar o modal
        await Future.delayed(Duration(milliseconds: 300));
        EasyLoading.showSuccess(
          widget.driverId != null 
              ? 'Motorista atualizado com sucesso!' 
              : 'Motorista criado com sucesso!',
          duration: Duration(seconds: 2),
        );
      } else {
        print('❌ [DriverFormDialog] Falha na operação. Erro: ${controller.error}');
        EasyLoading.dismiss();
        EasyLoading.showError(
          controller.error ?? 'Erro ao salvar motorista',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [DriverFormDialog] EXCEÇÃO CAPTURADA:');
      print('   Erro: $e');
      print('   StackTrace: $stackTrace');
      EasyLoading.dismiss();
      EasyLoading.showError('Erro: $e');
    }
    
    print('🔵 [DriverFormDialog] ========== _saveDriver FINALIZADO ==========');
  }

  Future<void> _pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
          _photoUrl = null; // Limpar URL existente quando nova foto é selecionada
        });
      }
    } catch (e) {
      print('❌ Erro ao selecionar foto: $e');
      EasyLoading.showError('Erro ao selecionar foto');
    }
  }

  Widget _buildPhotoField(ColorProvider colorProvider) {
    final String baseUrl = UserRepository.getServerURL() + "/";
    String? displayPhotoUrl;
    
    if (_selectedPhoto != null) {
      // Mostrar foto selecionada
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto do Motorista',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedPhoto!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      // Mostrar foto existente
      displayPhotoUrl = _photoUrl!.startsWith('http') ? _photoUrl : "$baseUrl$_photoUrl";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto do Motorista',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      displayPhotoUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[200],
                          child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Mostrar botão para adicionar foto
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Foto do Motorista',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: colorProvider.primaryColor),
                  SizedBox(height: 8),
                  Text(
                    'Adicionar Foto',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorProvider.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final isEdit = widget.driverId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Cabeçalho padrão (igual ao modal de relatórios)
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
                            isEdit ? 'Editar Motorista' : 'Novo Motorista',
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
              child: _isLoadingFormData
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: colorProvider.primaryColor,
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Nome
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nome *',
                                      prefixIcon: Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Nome é obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // Foto do Motorista
                                  _buildPhotoField(colorProvider),
                                  SizedBox(height: 16),
                                  // Telefone
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Telefone',
                                      prefixIcon: Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  SizedBox(height: 16),
                                  // Email
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!value.contains('@')) {
                                          return 'Email inválido';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // RFID
                                  TextFormField(
                                    controller: _rfidController,
                                    decoration: InputDecoration(
                                      labelText: 'RFID (Opcional)',
                                      prefixIcon: Icon(Icons.credit_card),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      helperText: 'Código do cartão/tag RFID do motorista. Usado para identificação automática no veículo.',
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Descrição
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Descrição',
                                      prefixIcon: Icon(Icons.description),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 16),
                                  // Dispositivo
                                  DropdownButtonFormField<int>(
                                    value: _selectedDeviceId,
                                    decoration: InputDecoration(
                                      labelText: 'Associar a Veículo',
                                      prefixIcon: Icon(Icons.directions_car),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      helperText: 'Selecione um veículo para associar ao motorista',
                                    ),
                                    items: _availableDevices.entries.map((entry) {
                                      return DropdownMenuItem<int>(
                                        value: int.tryParse(entry.key),
                                        child: Text(entry.value),
                                      );
                                    }).toList()
                                      ..insert(0, DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('Nenhum veículo (sem associação)'),
                                      )),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDeviceId = value;
                                      });
                                    },
                                    validator: (value) {
                                      // Campo opcional, não precisa validação
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // Porta do dispositivo
                                  TextFormField(
                                    controller: _devicePortController,
                                    decoration: InputDecoration(
                                      labelText: 'Porta do Dispositivo',
                                      prefixIcon: Icon(Icons.usb),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      helperText: 'Opcional',
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          // Botões fixos na parte inferior
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
                                      child: Text('Cancelar'),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoadingFormData ? null : () async {
                                        print('🔵 [DriverFormDialog] ========== BOTÃO SALVAR CLICADO ==========');
                                        print('🔵 [DriverFormDialog] Nome: ${_nameController.text}');
                                        print('🔵 [DriverFormDialog] FormKey: ${_formKey.currentState}');
                                        
                                        try {
                                          await _saveDriver();
                                        } catch (e, stackTrace) {
                                          print('❌ [DriverFormDialog] Erro ao salvar: $e');
                                          print('❌ [DriverFormDialog] StackTrace: $stackTrace');
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
                                      child: Text(isEdit ? 'Atualizar' : 'Salvar'),
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
