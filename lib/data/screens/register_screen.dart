import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  IconData _iconVisible = Icons.visibility_off;
  IconData _iconConfirmVisible = Icons.visibility_off;
  TextEditingController _nameFieldController = TextEditingController();
  TextEditingController _emailFieldController = TextEditingController();
  TextEditingController _passwordFieldController = TextEditingController();
  TextEditingController _confirmPasswordFieldController = TextEditingController();
  late SharedPreferences prefs;

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool isBusy = false;
  bool _acceptTerms = false;
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFieldController.addListener(_nameListen);
    _emailFieldController.addListener(_emailListen);
    _passwordFieldController.addListener(_passwordListen);
    _confirmPasswordFieldController.addListener(_confirmPasswordListen);
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
    _initPrefs();
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _nameListen() {
    _name = _nameFieldController.text;
  }

  void _emailListen() {
    _email = _emailFieldController.text;
  }

  void _passwordListen() {
    _password = _passwordFieldController.text;
  }

  void _confirmPasswordListen() {
    _confirmPassword = _confirmPasswordFieldController.text;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
      _iconVisible = _obscureText ? Icons.visibility_off : Icons.visibility;
    });
  }

  void _toggleObscureConfirmText() {
    setState(() {
      _obscureConfirmText = !_obscureConfirmText;
      _iconConfirmVisible = _obscureConfirmText ? Icons.visibility_off : Icons.visibility;
    });
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        final primaryColor = colorProvider.primaryColor;
        return Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.9),
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Image.asset(
                        'assets/icon/anim/logo-principal.png',
                        width: 220,
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(height: 40),
                      _buildTextField(
                        controller: _nameFieldController,
                        label: TranslationHelper.translateSync(context, 'Nome completo', 'Full name'),
                        icon: Icons.person_outline,
                        obscure: false,
                        focusNode: _nameFocusNode,
                        colorProvider: colorProvider,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _emailFieldController,
                        label: TranslationHelper.translateSync(context, 'E-mail', 'Email'),
                        icon: Icons.email_outlined,
                        obscure: false,
                        focusNode: _emailFocusNode,
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
                          icon: Icon(_iconVisible, color: Colors.white),
                          onPressed: _toggleObscureText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _confirmPasswordFieldController,
                        label: TranslationHelper.translateSync(context, 'Confirmar senha', 'Confirm password'),
                        icon: Icons.lock_outline,
                        obscure: _obscureConfirmText,
                        focusNode: _confirmPasswordFocusNode,
                        colorProvider: colorProvider,
                        suffixIcon: IconButton(
                          icon: Icon(_iconConfirmVisible, color: Colors.white),
                          onPressed: _toggleObscureConfirmText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Checkbox de aceite de termos
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
                                checkColor: MaterialStateProperty.all(primaryColor),
                              ),
                            ),
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: Text(
                              TranslationHelper.translateSync(context, 'Aceito os termos e condições', 'I accept the terms and conditions'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Botão REGISTRAR branco e redondo
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_name.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Informe o nome completo', 'Enter full name'));
                            } else if (_email.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Informe o e-mail', 'Enter email'));
                            } else if (_password.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Informe a senha', 'Enter password'));
                            } else if (_confirmPassword.trim().isEmpty) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Confirme a senha', 'Confirm password'));
                            } else if (_password != _confirmPassword) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'As senhas não coincidem', 'Passwords do not match'));
                            } else if (!_acceptTerms) {
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Aceite os termos e condições', 'Accept the terms and conditions'));
                            } else {
                              _register();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add, color: primaryColor),
                              SizedBox(width: 10),
                              Text(
                                TranslationHelper.translateSync(context, 'REGISTRAR', 'REGISTER'),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: primaryColor,
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
                              // TODO: Implementar registro com Facebook
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Registro com Facebook em breve', 'Facebook registration coming soon'));
                            },
                          ),
                          SizedBox(width: 20),
                          _buildSocialButton(
                            icon: FontAwesomeIcons.google,
                            color: Color(0xFF4285F4),
                            backgroundColor: Colors.white,
                            iconColor: Color(0xFF4285F4),
                            onTap: () {
                              // TODO: Implementar registro com Google
                              Fluttertoast.showToast(msg: TranslationHelper.translateSync(context, 'Registro com Google em breve', 'Google registration coming soon'));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Link para login
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          TranslationHelper.translateSync(context, 'Já tem uma conta? Entrar', 'Already have an account? Sign in'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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

  Future<void> _register() async {
    // Mostrar aviso para falar com o administrador
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colorProvider = Provider.of<ColorProvider>(context, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: colorProvider.primaryColor),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Registro de Conta', 'Account Registration'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translateSync(context, 'Para ter acesso ao U-Connect, você precisa solicitar a criação da sua conta.', 'To access U-Connect, you need to request the creation of your account.'),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    TranslationHelper.translateSync(context, '💡 Entre em contato com o administrador da sua empresa para que ele possa criar um acesso personalizado para você.', '💡 Contact your company administrator so they can create a personalized access for you.'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorProvider.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                TranslationHelper.translateSync(context, 'Entendi', 'Got it'),
                style: TextStyle(
                  color: colorProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

