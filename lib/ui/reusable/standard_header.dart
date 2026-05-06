import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/logo_provider.dart';
import 'dart:convert';

class StandardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData? icon;
  final List<Widget>? actions;

  const StandardHeader({
    Key? key,
    this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.icon,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(70); // Diminuído de 85 para 70 (mais compacto)

  Widget _getPeriodIcon() {
    final hour = DateTime.now().hour;
    IconData icon;
    Color color;

    if (hour >= 5 && hour < 12) {
      // Bom dia (5h - 11h59)
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (hour >= 12 && hour < 18) {
      // Boa tarde (12h - 17h59)
      icon = Icons.wb_twilight;
      color = Colors.deepOrange;
    } else {
      // Boa noite (18h - 4h59)
      icon = Icons.nightlight_round;
      color = Colors.indigo;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Future<String?> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final client = userData['user']['client'];
        final firstname = client['first_name'] ?? '';
        return firstname;
      }
    } catch (e) {
      print('Erro ao obter nome do usuário: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: true);
    
    return FutureBuilder<String?>(
      future: _getUserName(),
      builder: (context, snapshot) {
        final firstname = snapshot.data ?? 'Usuário';
        
        return AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: colorProvider.primaryColor,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Ícone de período do dia (só mostra se não tiver título customizado)
                  if (title == null) ...[
                    _getPeriodIcon(),
                    const SizedBox(width: 10),
                  ],
                  // Ícone da página (se fornecido)
                  if (icon != null) ...[
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white, // Ícone branco
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Se não tiver título customizado, verificar se deve mostrar logo
                        if (title == null)
                          Consumer<LogoProvider>(
                            builder: (context, logoProvider, child) {
                              if (logoProvider.hasMainLogo) {
                                // Mostrar logo principal se disponível
                                return Row(
                                  children: [
                                    logoProvider.getMainLogoWidget(
                                      height: 32,
                                      fit: BoxFit.contain,
                                      placeholder: Text(
                                        'Olá, ${firstname ?? 'Usuário'}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      errorWidget: Text(
                                        'Olá, ${firstname ?? 'Usuário'}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Fallback para texto se não houver logo
                                return Text(
                                  'Olá, ${firstname ?? 'Usuário'}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              }
                            },
                          )
                        else
                          // Título customizado sempre mostra texto
                          Text(
                            title ?? '',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        if (title == null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Gerencie sua frota',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions (botões adicionais)
                  if (actions != null && actions!.isNotEmpty) ...actions!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

