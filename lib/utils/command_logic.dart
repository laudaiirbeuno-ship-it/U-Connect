import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// === COMANDOS (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
List<String> _commands = <String>[];
List<String> _commandsValue = <String>[];

Future<void> getCommands() async {
  print('📡 Buscando comandos do deviceId: ${StaticVarMethod.deviceId}');
  try {
    final response = await gpsapis.getSavedCommands(StaticVarMethod.deviceId.toString());
    if (response != null && response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List && body.isNotEmpty) {
        print('🔁 COMANDOS ENCONTRADOS: ${body.length}');
        _commands.clear();
        _commandsValue.clear();
        for (var element in body) {
          if (element is Map) {
            print('🎯 COMANDO: ${element["title"]} | TYPE: ${element["type"]}');
            _commands.add(element["title"]);
            _commandsValue.add(element["type"]);
          }
        }
      } else {
        print('⚠️ Lista de comandos vazia da API, usando comandos padrão');
        _loadDefaultCommands();
      }
    } else {
      print('⚠️ Lista de comandos vazia da API, usando comandos padrão');
      _loadDefaultCommands();
    }
  } catch (e) {
    print('❌ Erro ao buscar comandos: $e');
    _loadDefaultCommands();
  }
}

// === COMANDOS PADRÃO (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
void _loadDefaultCommands() {
  print('🔄 Carregando comandos padrão...');
  _commands.clear();
  _commandsValue.clear();
  // Comandos padrão - apenas motor
  _commands.addAll([
    'Ligar Motor',
    'Desligar Motor',
    'Desbloquear Motor',
  ]);
  _commandsValue.addAll([
    'power_on',
    'lock',
    'unlock',
  ]);
  print('✅ ${_commands.length} comandos padrão carregados');
}

// === MODAL DE COMANDOS (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
void commandDialog(BuildContext context) {
  // Obter providers ANTES do showDialog para garantir acesso
  final colorProvider = context.read<ColorProvider>();
  final screenWidth = MediaQuery.of(context).size.width;
  final modalWidth = screenWidth * 0.75;

  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      // Garantir que o ColorProvider está disponível no contexto do dialog
      // IMPORTANTE: ColorProvider estende ChangeNotifier, então usar ChangeNotifierProvider
      return ChangeNotifierProvider<ColorProvider>.value(
        value: colorProvider,
        child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: modalWidth,
          constraints: BoxConstraints(maxWidth: 360, minWidth: 320),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER - Cabeçalho VERMELHO
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ações do Veículo',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // BODY - Botões em lista vertical com formato de card
              Padding(
                padding: EdgeInsets.all(24),
                child: _commands.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _cardButton(
                            context: ctx,
                            icon: Icons.lock,
                            label: 'Bloquear',
                            color: Colors.red,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              // Mostrar modal de confirmação com senha antes de bloquear
                              _showPasswordConfirmationDialog(ctx, 'lock');
                            },
                          ),
                          SizedBox(height: 12),
                          _cardButton(
                            context: ctx,
                            icon: Icons.lock_open,
                            label: 'Desbloquear',
                            color: Colors.red, // Vermelho no modal de bloqueio
                            onTap: () {
                              sendCommand('unlock');
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      )
                    : Builder(
                        builder: (context) {
                          // Filtrar comandos personalizados (custom) e criar lista
                          final filteredCommands = <MapEntry<int, String>>[];
                          _commands.asMap().forEach((index, command) {
                            final commandType = _commandsValue[index];
                            if (commandType.toLowerCase() != 'custom') {
                              filteredCommands.add(MapEntry(index, command));
                            }
                          });
                          
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filteredCommands.asMap().entries.map((entry) {
                              final listIndex = entry.key;
                              final originalIndex = entry.value.key;
                              final command = entry.value.value;
                              final commandType = _commandsValue[originalIndex];
                              final isLock = commandType.toLowerCase() == 'lock' || 
                                           command.toLowerCase().contains('bloquear') ||
                                           command.toLowerCase().contains('desligar');
                              final isUnlock = commandType.toLowerCase() == 'unlock' || 
                                             commandType.toLowerCase() == 'power_on' ||
                                             command.toLowerCase().contains('desbloquear') ||
                                             command.toLowerCase().contains('ligar');
                              
                              // Todos os botões devem ser vermelhos no modal de bloqueio
                              final buttonColor = Colors.red;
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: listIndex < filteredCommands.length - 1 ? 12 : 0),
                                child: _cardButton(
                                  context: ctx,
                                  icon: isLock 
                                      ? Icons.lock 
                                      : isUnlock 
                                          ? Icons.lock_open 
                                          : Icons.settings,
                                  label: command,
                                  color: buttonColor, // Sempre vermelho
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    // Verificar se é bloqueio - se for, mostrar confirmação com senha
                                    if (isLock) {
                                      _showPasswordConfirmationDialog(ctx, commandType);
                                    } else {
                                      // Para desbloqueio ou outros comandos, enviar diretamente
                                      sendCommand(commandType);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
              // FOOTER - Removido botão Cancelar conforme solicitado
            ],
          ),
        ),
        ), // Fecha Dialog
      ); // Fecha Provider.value
    },
  );
}

// === BOTÃO EM FORMATO DE CARD (LISTA VERTICAL) ===
Widget _cardButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: color.withOpacity(0.5),
            size: 24,
          ),
        ],
      ),
    ),
  );
}

void showSavedCommandDialog(BuildContext context) {
  Dialog simpleDialog = Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Container(
      height: 180,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Remover todas as referências a _customCommand e blocos relacionados a comando personalizado
              ],
            ),
          ),
        ],
      ),
    ),
  );

  showDialog(context: context, builder: (_) => simpleDialog);
}

// === MODAL DE CONFIRMAÇÃO COM SENHA (APENAS PARA BLOQUEIO) ===
Future<void> _showPasswordConfirmationDialog(BuildContext context, String commandType) async {
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  String? errorMessage;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER - Cabeçalho VERMELHO
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Confirmar Bloqueio',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: () => Navigator.of(ctx).pop(),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // BODY - Campo de senha e aviso
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aviso
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, 
                                color: Colors.orange, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Esta ação bloqueará o veículo. Digite sua senha para confirmar.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // Campo de senha
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            hintText: 'Digite sua senha',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible 
                                  ? Icons.visibility 
                                  : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: errorMessage,
                            errorMaxLines: 2,
                          ),
                          onChanged: (value) {
                            if (errorMessage != null) {
                              setState(() {
                                errorMessage = null;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 24),
                        // Botão Confirmar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final enteredPassword = passwordController.text.trim();
                              
                              if (enteredPassword.isEmpty) {
                                setState(() {
                                  errorMessage = 'Por favor, digite sua senha';
                                });
                                return;
                              }

                              // Validar senha
                              final prefs = await SharedPreferences.getInstance();
                              final savedPassword = prefs.getString('password');
                              
                              if (savedPassword == null || savedPassword.isEmpty) {
                                setState(() {
                                  errorMessage = 'Senha não encontrada. Faça login novamente.';
                                });
                                return;
                              }

                              if (enteredPassword != savedPassword) {
                                setState(() {
                                  errorMessage = 'Senha incorreta. Tente novamente.';
                                });
                                return;
                              }

                              // Senha correta - fechar modal e enviar comando
                              Navigator.of(ctx).pop();
                              sendCommand(commandType);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Confirmar',
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
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// === ENVIO DE COMANDOS (ATUALIZADO PARA USAR API REAL) ===
void sendCommand(String type, {String? data, String? deviceId}) async {
  final targetDeviceId = deviceId ?? StaticVarMethod.deviceId;
  
  print('📤 ENVIANDO COMANDO: $type');
  print('📤 DEVICE_ID: $targetDeviceId');
  
  if (targetDeviceId.isEmpty) {
    print('❌ Device ID não está definido!');
    Fluttertoast.showToast(
      msg: '❌ Device ID não está definido!',
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
    );
    return;
  }

  // Usar o novo método sendGprsCommand
  final result = await gpsapis.sendGprsCommand(
    deviceId: targetDeviceId,
    type: type,
    message: data,
  );
  
  final res = http.Response(
    json.encode(result),
    result['success'] == true ? 200 : 400,
  );

  if (res.statusCode == 200) {
    print('✅ Comando enviado com sucesso!');
    
    // Criar notificação local baseada no tipo de comando (MESMA LÓGICA DO CÓDIGO FORNECIDO)
    await _createCommandNotification(type);

    // Fluxo quando for desbloqueio: notificar servidor (MESMA LÓGICA DO CÓDIGO FORNECIDO)
    if (type.toLowerCase() == 'unlock') {
      await _notifyServerUnlock();
    }

    // Notificações para dashboard: registrar bloqueio/desbloqueio (MESMA LÓGICA DO CÓDIGO FORNECIDO)
    final lower = type.toLowerCase();
    
    if (lower == 'lock' || lower.contains('desligar_motor')) {
      print('📱 Notificação de bloqueio criada');
      Fluttertoast.showToast(
        msg: '🔒 Veículo ${StaticVarMethod.deviceName} foi bloqueado',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );
    }

    if (lower == 'unlock' || lower.contains('ligar_motor')) {
      print('📱 Notificação de desbloqueio criada');
      Fluttertoast.showToast(
        msg: '🔓 Veículo ${StaticVarMethod.deviceName} foi desbloqueado',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.green,
      );
    }
  } else {
    print('❌ Falha ao enviar comando!');
    Fluttertoast.showToast(
      msg: '❌ Falha ao enviar comando!',
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.red,
    );
  }
}

// === NOTIFICA O SERVIDOR CRIANDO UM REGISTRO (TASK) PARA DESBLOQUEIO (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
Future<void> _notifyServerUnlock() async {
  try {
    final String deviceId = StaticVarMethod.deviceId;
    final String deviceName = StaticVarMethod.deviceName;
    
    // Tentar obter informações do dispositivo (pode não estar disponível no contexto)
    String pickupAddress = 'Endereço não disponível';
    String pickupLat = '0';
    String pickupLng = '0';

    StaticVarMethod.deviceId = deviceId;
    final res = await gpsapis.AddTask(
      'DESBLOQUEIO - $deviceName',
      'Desbloqueio solicitado em ${DateTime.now().toIso8601String()}',
      pickupAddress,
      pickupLat,
      pickupLng,
    );

    if (res.statusCode == 200) {
      print('✅ Servidor notificado (Task DESBLOQUEIO criada)');
    } else {
      print('⚠️ Falha ao notificar servidor (DESBLOQUEIO): ${res.statusCode}');
    }
  } catch (e) {
    print('❌ Erro ao notificar servidor (DESBLOQUEIO): $e');
  }
}

// === CRIAR NOTIFICAÇÃO PARA COMANDO (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
Future<void> _createCommandNotification(String commandType) async {
  try {
    String deviceName = StaticVarMethod.deviceName;
    String notificationTitle = '';
    String notificationMessage = '';

    // Determinar tipo de notificação baseado no comando (MESMA LÓGICA DO CÓDIGO FORNECIDO)
    switch (commandType.toLowerCase()) {
      case 'unlock':
      case 'desbloquear':
        notificationTitle = '🔓 Veículo Desbloqueado';
        notificationMessage = 'Veículo $deviceName foi desbloqueado com sucesso';
        break;
      case 'power_on':
      case 'ligar_motor':
        notificationTitle = '🚗 Motor Ligado';
        notificationMessage = 'Motor do veículo $deviceName foi ligado';
        break;
      case 'lock':
      case 'desligar_motor':
        notificationTitle = '🔒 Motor Bloqueado';
        notificationMessage = 'Motor do veículo $deviceName foi bloqueado';
        break;
      default:
        notificationTitle = '📱 Comando Executado';
        notificationMessage = 'Comando executado no veículo $deviceName';
    }

    // Mostrar toast (MESMA LÓGICA DO CÓDIGO FORNECIDO)
    Fluttertoast.showToast(
      msg: notificationMessage,
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.green,
    );

    print('📱 Notificação de comando criada: $notificationTitle - $notificationMessage');
  } catch (e) {
    print('❌ Erro ao criar notificação de comando: $e');
  }
}

void showCountdownAndSuccess(BuildContext context, String message, String iconLottiePath) async {
  // Primeira tela: Countdown elegante
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001F5C), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone de loading elegante
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Lottie.asset(
                    'assets/icon/anim/countdown321.json',
                    width: 80,
                    height: 80,
                    repeat: false,
                    onLoaded: (composition) {
                      Future.delayed(composition.duration, () async {
                        Navigator.of(context).pop();
                        
                        // Navegar para a tela de sucesso como uma nova página
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return _SuccessScreen(message: message, iconLottiePath: iconLottiePath);
                            },
                            transitionDuration: Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Enviando comando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Aguarde um momento',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Nova tela de sucesso como widget separado
class _SuccessScreen extends StatefulWidget {
  final String message;
  final String iconLottiePath;

  const _SuccessScreen({
    required this.message,
    required this.iconLottiePath,
  });

  @override
  _SuccessScreenState createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Auto-close após 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 320,
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF001F5C),
                        Color(0xFF1976D2),
                        Color(0xFF42A5F5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Círculo de fundo com efeito de brilho
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Lottie.asset(
                                widget.iconLottiePath,
                                width: 60,
                                height: 60,
                                repeat: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Mensagem de sucesso
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            Text(
                              '✅ Sucesso!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Indicador de progresso elegante
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(seconds: 3),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
