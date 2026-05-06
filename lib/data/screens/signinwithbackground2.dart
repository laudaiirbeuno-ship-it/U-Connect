import 'dart:convert';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/loginModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/logo_provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/data/screens/register_screen.dart';
import 'package:uconnect/data/screens/login_welcome_screen.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class signinwithbackground2 extends StatefulWidget {
  @override
  _signinState createState() => _signinState();
}

class _signinState extends State<signinwithbackground2> {
  bool _obscureText = true;
  IconData _iconVisible = Icons.visibility_off;
  TextEditingController _usernameFieldController = TextEditingController();
  TextEditingController _passwordFieldController = TextEditingController();
  late SharedPreferences prefs;

  String _username = '';
  String _password = '';
  bool isBusy = false;
  bool _rememberPassword = true; // Sempre marcado por padrão
  FocusNode _usernameFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameFieldController.addListener(_emailListen);
    _passwordFieldController.addListener(_passwordListen);
    _usernameFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    checkPreference();
  }

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _emailListen() {
    _username = _usernameFieldController.text;
  }

  void _passwordListen() {
    _password = _passwordFieldController.text;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
      _iconVisible = _obscureText ? Icons.visibility_off : Icons.visibility;
    });
  }

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    
    // Verificar se há credenciais salvas (se "Lembrar senha" estava ativo)
    if (prefs.get('email') != null && prefs.get('password') != null) {
      _usernameFieldController.text = prefs.getString('email')!;
      _passwordFieldController.text = prefs.getString('password')!;
      _username = _usernameFieldController.text.trim();
      _password = _passwordFieldController.text.trim();
      // Não fazer login automático - usuário precisa aceitar políticas novamente
      setState(() {});
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        // Cor azul padrão para tela de login
        const Color defaultBlueColor = Color(0xFF3b82f6);
        // Usar cor personalizada apenas se o usuário tiver configurado
        const Color defaultSecondaryColor = Color(0xFF6b7280); // Cinza padrão do ColorProvider
        final secondaryColor = (colorProvider.secondaryColor.value != defaultSecondaryColor.value)
            ? colorProvider.secondaryColor 
            : defaultBlueColor;
        return Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondaryColor,
                    secondaryColor.withOpacity(0.8),
                    secondaryColor.withOpacity(0.9),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo personalizada (local ou servidor)
                        Consumer2<AppSettingsProvider, LogoProvider>(
                          builder: (context, settingsProvider, logoProvider, child) {
                            // 1ª Prioridade: Logo personalizada local
                            if (settingsProvider.customLogo != null && 
                                settingsProvider.customLogo!.existsSync()) {
                              return Image.file(
                                settingsProvider.customLogo!,
                                width: 220,
                                fit: BoxFit.contain,
                              );
                            }
                            // 2ª Prioridade: Logo do servidor (LogoProvider)
                            else if (logoProvider.hasLoginLogo) {
                              return logoProvider.getLoginLogoWidget(
                                width: 220,
                                fit: BoxFit.contain,
                                placeholder: Image.asset(
                                  'assets/appsicon/logo-main.png',
                                  width: 220,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
                                      width: 220,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/icon/anim/logo-principal.png',
                                          width: 220,
                                        );
                                      },
                                    );
                                  },
                                ),
                                errorWidget: Image.asset(
                                  'assets/appsicon/logo-main.png',
                                  width: 220,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
                                      width: 220,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/icon/anim/logo-principal.png',
                                          width: 220,
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                            // 3ª Prioridade: Logo-main padrão
                            else {
                              return Image.asset(
                                'assets/appsicon/logo-main.png',
                                width: 220,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback para IMG se logo-main não existir
                                  return Image.asset(
                                    'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
                                    width: 220,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback para logo antiga se nenhuma existir
                                      return Image.asset(
                                        'assets/icon/anim/logo-principal.png',
                                        width: 220,
                                      );
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _usernameFieldController,
                          label: TranslationHelper.translateSync(context, 'E-mail', 'Email'),
                          icon: Icons.email_outlined,
                          obscure: false,
                          focusNode: _usernameFocusNode,
                          colorProvider: colorProvider,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordFieldController,
                          label: TranslationHelper.translateSync(context, 'Senha', 'Password'),
                          icon: Icons.lock_outline,
                          obscure: _obscureText,
                          focusNode: _passwordFocusNode,
                          colorProvider: colorProvider,
                          suffixIcon: IconButton(
                            icon: Icon(_iconVisible, color: colorProvider.primaryColor),
                            onPressed: _toggleObscureText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Checkbox "Lembrar senha" e "Esqueci minha senha" na mesma linha
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Theme(
                                data: ThemeData(
                                  unselectedWidgetColor: Colors.white,
                                  checkboxTheme: CheckboxThemeData(
                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return Colors.white;
                                        }
                                        return Colors.transparent;
                                      },
                                    ),
                                    checkColor: MaterialStateProperty.all(colorProvider.primaryColor),
                                  ),
                                ),
                                child: Checkbox(
                                  value: _rememberPassword,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberPassword = value ?? true;
                                    });
                                  },
                                ),
                              ),
                              Text(
                                TranslationHelper.translateSync(context, 'Lembrar senha', 'Remember password'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              const url =
                                  'https://web.unnicatelemetria.com.br/password_reminder';
                              final Uri _url = Uri.parse(url);
                              if (await canLaunchUrl(_url)) {
                                await launchUrl(_url);
                              } else {
                                Fluttertoast.showToast(
                                    msg: TranslationHelper.translateSync(context, 'Sem permissão para abrir navegador', 'No permission to open browser'));
                              }
                            },
                            child: Text(
                              TranslationHelper.translateSync(context, 'Esqueci minha senha', 'Forgot password'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        ),
                        const SizedBox(height: 20),
                        // Botão ENTRAR branco e redondo
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                          onPressed: () {
                            if (_username.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Informe o e-mail', 'Enter email'));
                            } else if (_password.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Informe a senha', 'Enter password'));
                            } else {
                              // Mostrar modal de políticas de privacidade antes de fazer login
                              _showPrivacyPolicyModal(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorProvider.primaryColor,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: colorProvider.primaryColor),
                              SizedBox(width: 10),
                              Text(
                                TranslationHelper.translateSync(context, 'ENTRAR', 'LOGIN'),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorProvider.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        const SizedBox(height: 24),
                        // Ícones Facebook e Google
                        Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: Icons.facebook,
                            color: Color(0xFF1877F2),
                            backgroundColor: Colors.white,
                            iconColor: Color(0xFF1877F2),
                            onTap: () {
                              // TODO: Implementar login com Facebook
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Login com Facebook em breve', 'Facebook login coming soon'));
                            },
                          ),
                          SizedBox(width: 20),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.google,
                            color: Color(0xFF4285F4),
                            backgroundColor: Colors.white,
                            iconColor: Color(0xFF4285F4),
                            onTap: () {
                              // TODO: Implementar login com Google
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Login com Google em breve', 'Google login coming soon'));
                            },
                          ),
                        ],
                        ),
                        const SizedBox(height: 20),
                        // Link para registro
                        TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          TranslationHelper.translateSync(context, 'Não tem uma conta? Registre-se', 'Don\'t have an account? Sign up'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
    required ColorProvider colorProvider,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused ? colorProvider.primaryColor : Colors.black54,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: colorProvider.primaryColor,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
          ),
          prefixIcon: Icon(
            icon,
            color: colorProvider.primaryColor,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? color,
          shape: BoxShape.circle,
          border: backgroundColor != null
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? (backgroundColor != null ? Colors.grey.shade700 : Colors.white),
          size: 28,
        ),
      ),
    );
  }

  // === MODAL DE POLÍTICAS DE PRIVACIDADE ===
  void _showPrivacyPolicyModal(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    bool privacyAccepted = false;
    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void scrollToBottom() {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorProvider.primaryColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  TranslationHelper.translateSync(context, 'Políticas de Privacidade', 'Privacy Policy'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // BODY - Conteúdo das políticas
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: EdgeInsets.all(24),
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationHelper.translateSync(context, 'Ao usar este aplicativo, você concorda com as seguintes políticas de privacidade:', 'By using this app, you agree to the following privacy policies:'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildPolicySection(
                              '1. Introdução e Escopo',
                              'Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos suas informações pessoais quando você utiliza nosso aplicativo de rastreamento de veículos. Ao utilizar nossos serviços, você concorda com as práticas descritas nesta política.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '2. Informações que Coletamos',
                              'Coletamos diversos tipos de informações, incluindo dados de identificação pessoal, informações de localização em tempo real, dados do veículo, histórico de viagens, informações de conta, dados de dispositivo e logs de uso do aplicativo.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '3. Dados de Identificação Pessoal',
                              'Coletamos seu nome completo, endereço de e-mail, número de telefone, CPF/CNPJ, endereço residencial e comercial, data de nascimento e outras informações de identificação fornecidas durante o cadastro.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '4. Dados de Localização',
                              'Coletamos dados de localização GPS em tempo real, histórico de rotas, pontos de parada, velocidade do veículo, direção, altitude e coordenadas geográficas precisas para fornecer serviços de rastreamento.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '5. Dados do Veículo',
                              'Coletamos informações sobre o veículo rastreado, incluindo placa, modelo, marca, ano, cor, número de série, tipo de combustível, odômetro e outras características técnicas relevantes.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '6. Histórico de Viagens',
                              'Armazenamos informações sobre todas as viagens realizadas, incluindo data, hora, duração, distância percorrida, pontos de origem e destino, e eventos ocorridos durante o trajeto.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '7. Dados de Conta e Autenticação',
                              'Armazenamos informações de login, senhas criptografadas, tokens de autenticação, histórico de acessos, endereços IP e informações de sessão para garantir a segurança da sua conta.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '8. Dados do Dispositivo',
                              'Coletamos informações sobre o dispositivo móvel utilizado, incluindo modelo, sistema operacional, versão do aplicativo, identificadores únicos do dispositivo, informações de rede e configurações de privacidade.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '9. Logs e Metadados',
                              'Registramos automaticamente informações sobre o uso do aplicativo, incluindo ações realizadas, horários de acesso, funcionalidades utilizadas, erros ocorridos e padrões de uso para melhorar nossos serviços.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '10. Informações de Pagamento',
                              'Quando aplicável, coletamos informações de pagamento processadas por terceiros seguros, incluindo dados de cartão de crédito (armazenados de forma criptografada), histórico de transações e informações de faturamento.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '11. Como Utilizamos suas Informações',
                              'Utilizamos suas informações para fornecer, manter e melhorar nossos serviços de rastreamento, processar transações, enviar notificações, personalizar sua experiência e desenvolver novos recursos.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '12. Prestação de Serviços',
                              'Utilizamos seus dados para fornecer serviços de rastreamento em tempo real, gerar relatórios, criar alertas personalizados, monitorar veículos e fornecer suporte técnico quando necessário.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '13. Comunicação com Usuários',
                              'Utilizamos suas informações de contato para enviar notificações importantes sobre o serviço, alertas de segurança, atualizações do aplicativo, informações de conta e comunicações de marketing (com sua permissão).',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '14. Melhoria de Serviços',
                              'Analisamos dados agregados e anonimizados para entender padrões de uso, identificar problemas, desenvolver novos recursos, melhorar a interface do usuário e otimizar o desempenho do aplicativo.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '15. Segurança e Prevenção de Fraudes',
                              'Utilizamos suas informações para detectar, prevenir e investigar atividades fraudulentas, violações de segurança, uso não autorizado e outras atividades suspeitas que possam comprometer a segurança do serviço.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '16. Conformidade Legal',
                              'Utilizamos e divulgamos informações quando necessário para cumprir obrigações legais, responder a processos judiciais, executar nossos termos de serviço e proteger nossos direitos legais.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '17. Compartilhamento de Informações',
                              'Não vendemos suas informações pessoais. Podemos compartilhar dados com prestadores de serviços confiáveis, parceiros comerciais autorizados, autoridades legais quando exigido por lei, e em caso de fusão ou aquisição empresarial.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '18. Prestadores de Serviços',
                              'Compartilhamos informações com prestadores de serviços terceirizados que nos auxiliam na operação do aplicativo, incluindo hospedagem de dados, processamento de pagamentos, análise de dados e serviços de comunicação, todos sob acordos de confidencialidade.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '19. Parceiros Comerciais',
                              'Podemos compartilhar dados agregados e anonimizados com parceiros comerciais para fins de análise, pesquisa e desenvolvimento de produtos, sempre respeitando sua privacidade e sem identificar indivíduos específicos.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '20. Requisições Legais',
                              'Divulgamos informações pessoais quando exigido por lei, ordem judicial, processo legal, ou quando acreditamos de boa fé que a divulgação é necessária para proteger direitos, propriedade ou segurança.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '21. Transferências de Negócios',
                              'Em caso de fusão, aquisição, reestruturação ou venda de ativos, suas informações pessoais podem ser transferidas como parte da transação, com notificação prévia quando aplicável.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '22. Segurança dos Dados',
                              'Implementamos medidas de segurança técnicas, administrativas e físicas robustas para proteger suas informações contra acesso não autorizado, alteração, divulgação ou destruição, incluindo criptografia, firewalls e controles de acesso.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '23. Criptografia',
                              'Utilizamos criptografia de ponta a ponta para proteger dados em trânsito e em repouso, garantindo que suas informações sejam transmitidas e armazenadas de forma segura, utilizando protocolos SSL/TLS e algoritmos de criptografia avançados.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '24. Controles de Acesso',
                              'Implementamos controles rigorosos de acesso, incluindo autenticação de dois fatores, senhas fortes, tokens de segurança e permissões baseadas em funções para garantir que apenas pessoal autorizado tenha acesso aos dados.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '25. Monitoramento de Segurança',
                              'Monitoramos continuamente nossos sistemas para detectar e responder a ameaças de segurança, realizamos auditorias regulares, testes de penetração e mantemos planos de resposta a incidentes para proteger seus dados.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '26. Retenção de Dados',
                              'Mantemos suas informações pessoais pelo tempo necessário para fornecer nossos serviços, cumprir obrigações legais, resolver disputas e fazer cumprir nossos acordos, após o qual os dados são excluídos de forma segura.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '27. Período de Retenção',
                              'Dados de localização são retidos por períodos específicos conforme necessário para o serviço, dados de conta são mantidos enquanto a conta estiver ativa, e dados legais podem ser retidos conforme exigido por lei.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '28. Exclusão de Dados',
                              'Você pode solicitar a exclusão de suas informações pessoais a qualquer momento. Processaremos tais solicitações conforme aplicável, exceto quando a retenção for necessária para fins legais ou operacionais legítimos.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '29. Seus Direitos',
                              'Você tem direitos sobre suas informações pessoais, incluindo direito de acesso, correção, exclusão, portabilidade, objeção ao processamento, retirada de consentimento e apresentação de reclamações às autoridades de proteção de dados.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '30. Acesso aos Dados',
                              'Você tem o direito de acessar suas informações pessoais que mantemos, incluindo dados de localização, histórico de viagens, informações de conta e outros dados coletados, através das configurações do aplicativo ou contatando nosso suporte.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '31. Correção de Dados',
                              'Você pode solicitar a correção de informações imprecisas ou incompletas. Processaremos tais solicitações prontamente e atualizaremos seus dados em nossos sistemas após verificação adequada.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '32. Exclusão de Conta',
                              'Você pode solicitar a exclusão de sua conta e dados associados a qualquer momento. Após a exclusão, não poderemos restaurar suas informações e você perderá acesso permanente aos dados históricos.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '33. Portabilidade de Dados',
                              'Você tem o direito de receber seus dados pessoais em formato estruturado e de uso comum, permitindo a transferência para outro serviço quando tecnicamente viável e conforme regulamentações aplicáveis.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '34. Cookies e Tecnologias Similares',
                              'Utilizamos cookies, tags, pixels e tecnologias similares para melhorar sua experiência, analisar o uso do aplicativo, personalizar conteúdo e fornecer funcionalidades de segurança. Você pode gerenciar preferências de cookies nas configurações.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '35. Privacidade de Menores',
                              'Nossos serviços não são destinados a menores de 18 anos. Não coletamos intencionalmente informações pessoais de menores. Se tomarmos conhecimento de coleta inadvertida, tomaremos medidas para excluir tais informações prontamente.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '36. Transferências Internacionais',
                              'Seus dados podem ser processados e armazenados em servidores localizados fora do seu país de residência. Garantimos que tais transferências sejam realizadas com salvaguardas adequadas e em conformidade com leis de proteção de dados aplicáveis.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '37. Alterações nesta Política',
                              'Podemos atualizar esta Política de Privacidade periodicamente para refletir mudanças em nossas práticas, serviços ou requisitos legais. Notificaremos você sobre mudanças significativas através do aplicativo ou por e-mail.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '38. Consentimento e Aceitação',
                              'Ao utilizar nosso aplicativo, você consente com a coleta, uso e compartilhamento de suas informações conforme descrito nesta política. Seu uso continuado após alterações constitui aceitação da política revisada.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '39. Contato e Suporte',
                              'Para questões sobre privacidade, exercer seus direitos ou apresentar reclamações, entre em contato conosco através dos canais de suporte disponíveis no aplicativo ou através do e-mail de privacidade fornecido em nossos termos de serviço.',
                            ),
                            SizedBox(height: 12),
                            _buildPolicySection(
                              '40. Lei Aplicável',
                              'Esta política é regida pelas leis de proteção de dados aplicáveis, incluindo a Lei Geral de Proteção de Dados (LGPD) do Brasil. Qualquer disputa será resolvida de acordo com as leis e jurisdições competentes.',
                            ),
                            SizedBox(height: 20),
                            // Checkbox de aceite
                            Row(
                              children: [
                                Checkbox(
                                  value: privacyAccepted,
                                  onChanged: (value) {
                                    setModalState(() {
                                      privacyAccepted = value ?? false;
                                    });
                                  },
                                  activeColor: colorProvider.primaryColor,
                                ),
                                Expanded(
                                  child: Text(
                                    TranslationHelper.translateSync(context, 'Li e aceito as políticas de privacidade', 'I have read and accept the privacy policy'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // FOOTER - Botões
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: colorProvider.primaryColor,
                                ),
                              ),
                              child: Text(
                                TranslationHelper.translateSync(context, 'Cancelar', 'Cancel'),
                                style: TextStyle(
                                  color: colorProvider.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: privacyAccepted
                                  ? () {
                                      Navigator.of(ctx).pop();
                                      // Agora fazer o login e mostrar splash de boas-vindas
                                      login();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorProvider.primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                TranslationHelper.translateSync(context, 'ENTRAR', 'LOGIN'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                    // Botão flutuante para scroll até o final
                    Positioned(
                      bottom: 100,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: scrollToBottom,
                        backgroundColor: colorProvider.primaryColor,
                        mini: true,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      scrollController.dispose();
    });
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translateSync(context, title, _getEnglishTitle(title)),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          TranslationHelper.translateSync(context, content, _getEnglishContent(content)),
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _getEnglishTitle(String ptTitle) {
    final translations = {
      '1. Introdução e Escopo': '1. Introduction and Scope',
      '2. Informações que Coletamos': '2. Information We Collect',
      '3. Dados de Identificação Pessoal': '3. Personal Identification Data',
      '4. Dados de Localização': '4. Location Data',
      '5. Dados do Veículo': '5. Vehicle Data',
      '6. Histórico de Viagens': '6. Travel History',
      '7. Dados de Conta e Autenticação': '7. Account and Authentication Data',
      '8. Dados do Dispositivo': '8. Device Data',
      '9. Logs e Metadados': '9. Logs and Metadata',
      '10. Informações de Pagamento': '10. Payment Information',
      '11. Como Utilizamos suas Informações': '11. How We Use Your Information',
      '12. Prestação de Serviços': '12. Service Provision',
      '13. Comunicação com Usuários': '13. User Communication',
      '14. Melhoria de Serviços': '14. Service Improvement',
      '15. Segurança e Prevenção de Fraudes': '15. Security and Fraud Prevention',
      '16. Conformidade Legal': '16. Legal Compliance',
      '17. Compartilhamento de Informações': '17. Information Sharing',
      '18. Prestadores de Serviços': '18. Service Providers',
      '19. Parceiros Comerciais': '19. Business Partners',
      '20. Requisições Legais': '20. Legal Requests',
      '21. Transferências de Negócios': '21. Business Transfers',
      '22. Segurança dos Dados': '22. Data Security',
      '23. Criptografia': '23. Encryption',
      '24. Controles de Acesso': '24. Access Controls',
      '25. Monitoramento de Segurança': '25. Security Monitoring',
      '26. Retenção de Dados': '26. Data Retention',
      '27. Período de Retenção': '27. Retention Period',
      '28. Exclusão de Dados': '28. Data Deletion',
      '29. Seus Direitos': '29. Your Rights',
      '30. Acesso aos Dados': '30. Data Access',
      '31. Correção de Dados': '31. Data Correction',
      '32. Exclusão de Conta': '32. Account Deletion',
      '33. Portabilidade de Dados': '33. Data Portability',
      '34. Cookies e Tecnologias Similares': '34. Cookies and Similar Technologies',
      '35. Privacidade de Menores': '35. Children\'s Privacy',
      '36. Transferências Internacionais': '36. International Transfers',
      '37. Alterações nesta Política': '37. Changes to this Policy',
      '38. Consentimento e Aceitação': '38. Consent and Acceptance',
      '39. Contato e Suporte': '39. Contact and Support',
      '40. Lei Aplicável': '40. Applicable Law',
    };
    return translations[ptTitle] ?? ptTitle;
  }

  String _getEnglishContent(String ptContent) {
    // Traduções simplificadas das principais seções
    if (ptContent.contains('Esta Política de Privacidade descreve')) {
      return 'This Privacy Policy describes how we collect, use, store and protect your personal information when you use our vehicle tracking app. By using our services, you agree to the practices described in this policy.';
    } else if (ptContent.contains('Coletamos diversos tipos')) {
      return 'We collect various types of information, including personal identification data, real-time location information, vehicle data, travel history, account information, device data and app usage logs.';
    } else if (ptContent.contains('Coletamos seu nome completo')) {
      return 'We collect your full name, email address, phone number, CPF/CNPJ, residential and business address, date of birth and other identification information provided during registration.';
    } else if (ptContent.contains('Coletamos dados de localização GPS')) {
      return 'We collect real-time GPS location data, route history, stop points, vehicle speed, direction, altitude and precise geographic coordinates to provide tracking services.';
    } else if (ptContent.contains('Coletamos informações sobre o veículo')) {
      return 'We collect information about the tracked vehicle, including license plate, model, brand, year, color, serial number, fuel type, odometer and other relevant technical characteristics.';
    } else if (ptContent.contains('Armazenamos informações sobre todas as viagens')) {
      return 'We store information about all trips taken, including date, time, duration, distance traveled, origin and destination points, and events that occurred during the journey.';
    } else if (ptContent.contains('Armazenamos informações de login')) {
      return 'We store login information, encrypted passwords, authentication tokens, access history, IP addresses and session information to ensure the security of your account.';
    } else if (ptContent.contains('Coletamos informações sobre o dispositivo móvel')) {
      return 'We collect information about the mobile device used, including model, operating system, app version, unique device identifiers, network information and privacy settings.';
    } else if (ptContent.contains('Registramos automaticamente')) {
      return 'We automatically record information about app usage, including actions taken, access times, features used, errors occurred and usage patterns to improve our services.';
    } else if (ptContent.contains('Quando aplicável, coletamos informações de pagamento')) {
      return 'When applicable, we collect payment information processed by secure third parties, including credit card data (stored encrypted), transaction history and billing information.';
    } else if (ptContent.contains('Utilizamos suas informações para fornecer')) {
      return 'We use your information to provide, maintain and improve our tracking services, process transactions, send notifications, personalize your experience and develop new features.';
    } else if (ptContent.contains('Utilizamos seus dados para fornecer serviços')) {
      return 'We use your data to provide real-time tracking services, generate reports, create custom alerts, monitor vehicles and provide technical support when necessary.';
    } else if (ptContent.contains('Utilizamos suas informações de contato')) {
      return 'We use your contact information to send important service notifications, security alerts, app updates, account information and marketing communications (with your permission).';
    } else if (ptContent.contains('Analisamos dados agregados')) {
      return 'We analyze aggregated and anonymized data to understand usage patterns, identify issues, develop new features, improve user interface and optimize app performance.';
    } else if (ptContent.contains('Utilizamos suas informações para detectar')) {
      return 'We use your information to detect, prevent and investigate fraudulent activities, security breaches, unauthorized use and other suspicious activities that may compromise service security.';
    } else if (ptContent.contains('Utilizamos e divulgamos informações quando necessário')) {
      return 'We use and disclose information when necessary to comply with legal obligations, respond to legal proceedings, enforce our terms of service and protect our legal rights.';
    } else if (ptContent.contains('Não vendemos suas informações pessoais')) {
      return 'We do not sell your personal information. We may share data with trusted service providers, authorized business partners, legal authorities when required by law, and in case of merger or business acquisition.';
    } else if (ptContent.contains('Compartilhamos informações com prestadores')) {
      return 'We share information with third-party service providers who assist us in operating the app, including data hosting, payment processing, data analysis and communication services, all under confidentiality agreements.';
    } else if (ptContent.contains('Podemos compartilhar dados agregados')) {
      return 'We may share aggregated and anonymized data with business partners for analysis, research and product development purposes, always respecting your privacy and without identifying specific individuals.';
    } else if (ptContent.contains('Divulgamos informações pessoais quando exigido')) {
      return 'We disclose personal information when required by law, court order, legal process, or when we believe in good faith that disclosure is necessary to protect rights, property or safety.';
    } else if (ptContent.contains('Em caso de fusão')) {
      return 'In case of merger, acquisition, restructuring or asset sale, your personal information may be transferred as part of the transaction, with prior notification when applicable.';
    } else if (ptContent.contains('Implementamos medidas de segurança técnicas')) {
      return 'We implement robust technical, administrative and physical security measures to protect your information against unauthorized access, alteration, disclosure or destruction, including encryption, firewalls and access controls.';
    } else if (ptContent.contains('Utilizamos criptografia de ponta a ponta')) {
      return 'We use end-to-end encryption to protect data in transit and at rest, ensuring your information is transmitted and stored securely, using SSL/TLS protocols and advanced encryption algorithms.';
    } else if (ptContent.contains('Implementamos controles rigorosos')) {
      return 'We implement strict access controls, including two-factor authentication, strong passwords, security tokens and role-based permissions to ensure only authorized personnel have access to data.';
    } else if (ptContent.contains('Monitoramos continuamente nossos sistemas')) {
      return 'We continuously monitor our systems to detect and respond to security threats, conduct regular audits, penetration tests and maintain incident response plans to protect your data.';
    } else if (ptContent.contains('Mantemos suas informações pessoais pelo tempo')) {
      return 'We retain your personal information for as long as necessary to provide our services, comply with legal obligations, resolve disputes and enforce our agreements, after which data is securely deleted.';
    } else if (ptContent.contains('Dados de localização são retidos')) {
      return 'Location data is retained for specific periods as necessary for the service, account data is kept while the account is active, and legal data may be retained as required by law.';
    } else if (ptContent.contains('Você pode solicitar a exclusão')) {
      return 'You may request deletion of your personal information at any time. We will process such requests as applicable, except when retention is necessary for legal or legitimate operational purposes.';
    } else if (ptContent.contains('Você tem direitos sobre suas informações')) {
      return 'You have rights over your personal information, including right of access, correction, deletion, portability, objection to processing, withdrawal of consent and filing complaints with data protection authorities.';
    } else if (ptContent.contains('Você tem o direito de acessar')) {
      return 'You have the right to access your personal information we maintain, including location data, travel history, account information and other collected data, through app settings or by contacting our support.';
    } else if (ptContent.contains('Você pode solicitar a correção')) {
      return 'You may request correction of inaccurate or incomplete information. We will process such requests promptly and update your data in our systems after proper verification.';
    } else if (ptContent.contains('Você pode solicitar a exclusão de sua conta')) {
      return 'You may request deletion of your account and associated data at any time. After deletion, we will not be able to restore your information and you will permanently lose access to historical data.';
    } else if (ptContent.contains('Você tem o direito de receber')) {
      return 'You have the right to receive your personal data in a structured and commonly used format, allowing transfer to another service when technically feasible and in accordance with applicable regulations.';
    } else if (ptContent.contains('Utilizamos cookies, tags')) {
      return 'We use cookies, tags, pixels and similar technologies to improve your experience, analyze app usage, personalize content and provide security features. You can manage cookie preferences in settings.';
    } else if (ptContent.contains('Nossos serviços não são destinados')) {
      return 'Our services are not intended for minors under 18 years of age. We do not intentionally collect personal information from minors. If we become aware of inadvertent collection, we will take steps to delete such information promptly.';
    } else if (ptContent.contains('Seus dados podem ser processados')) {
      return 'Your data may be processed and stored on servers located outside your country of residence. We ensure such transfers are made with adequate safeguards and in compliance with applicable data protection laws.';
    } else if (ptContent.contains('Podemos atualizar esta Política')) {
      return 'We may update this Privacy Policy periodically to reflect changes in our practices, services or legal requirements. We will notify you of significant changes through the app or by email.';
    } else if (ptContent.contains('Ao utilizar nosso aplicativo')) {
      return 'By using our app, you consent to the collection, use and sharing of your information as described in this policy. Your continued use after changes constitutes acceptance of the revised policy.';
    } else if (ptContent.contains('Para questões sobre privacidade')) {
      return 'For privacy questions, to exercise your rights or file complaints, contact us through the support channels available in the app or through the privacy email provided in our terms of service.';
    } else if (ptContent.contains('Esta política é regida')) {
      return 'This policy is governed by applicable data protection laws, including Brazil\'s General Data Protection Law (LGPD). Any dispute will be resolved in accordance with applicable laws and competent jurisdictions.';
    }
    return ptContent;
  }

  Future<void> login() async {
    gpsapis api = gpsapis();

    api.getlogin(_username.trim(), _password.trim()).then((response) async {
      if (response.statusCode == 200) {
        prefs.setBool("popup_notify", true);
        prefs.setString("user", response.body);
        final res = LoginModel.fromJson(json.decode(response.body));
        StaticVarMethod.user_api_hash = res.userApiHash;
        prefs.setString('user_api_hash', res.userApiHash!);
        
        // Buscar e salvar dados completos do usuário após login
        try {
          final userData = await gpsapis.getUserData();
          if (userData != null) {
            final userJson = json.encode(userData.toJson());
            await prefs.setString('user_data', userJson);
            print('Dados do usuário salvos: group_id=${userData.group_id}, plan=${userData.plan}');
          }
        } catch (e) {
          print('Erro ao buscar dados do usuário após login: $e');
        }
        
        // Enviar token FCM ao servidor após login
        if (StaticVarMethod.notificationToken.isNotEmpty) {
          try {
            final fcmResponse = await gpsapis.activateFCM(StaticVarMethod.notificationToken);
            if (fcmResponse.statusCode == 200 || fcmResponse.statusCode == 201) {
              print("✅ Token FCM enviado ao servidor após login");
            } else {
              print("⚠️ Erro ao enviar token FCM após login: ${fcmResponse.statusCode}");
            }
          } catch (e) {
            print("❌ Erro ao enviar token FCM após login: $e");
          }
        }
        
        // Salvar credenciais se "Lembrar senha" estiver marcado
        if (_rememberPassword) {
          prefs.setString('email', _username.trim());
          prefs.setString('password', _password.trim());
        } else {
          prefs.remove('email');
          prefs.remove('password');
        }
        
        EasyLoading.dismiss();

        // Navegar para splash screen de boas-vindas que carrega veículos em segundo plano
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginWelcomeScreen()),
        );
      } else {
        EasyLoading.dismiss();
        Fluttertoast.showToast(
          msg: TranslationHelper.translateSync(context, "Login falhou", "Login failed"),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    });
  }
}
