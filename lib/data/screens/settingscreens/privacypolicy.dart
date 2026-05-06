import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class privacypolicy extends StatefulWidget {
  @override
  _privacypolicyState createState() => _privacypolicyState();
}

class _privacypolicyState extends State<privacypolicy> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: FloatingMenuDrawer(),
        backgroundColor: Colors.white,
        appBar: StandardHeader(
          title: TranslationHelper.translateSync(context, "Política de Privacidade", "Privacy Policy"),
          icon: Icons.privacy_tip,
        ),
        bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Card U-Connect
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.black,
                      size: 64,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'U-Connect',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      TranslationHelper.translateSync(context, 'Política de Privacidade', 'Privacy Policy'),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      TranslationHelper.translateSync(context, 'Última atualização: 20/7/2025', 'Last updated: 20/7/2025'),
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo da Política
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      TranslationHelper.translateSync(context, '1. Introdução', '1. Introduction'),
                      TranslationHelper.translateSync(context, 'A U-Connect está comprometida em proteger sua privacidade e garantir a segurança de seus dados pessoais. Esta Política de Privacidade descreve como coletamos, usamos, armazenamos e protegemos suas informações quando você utiliza nossos serviços de rastreamento GPS e monitoramento de veículos.', 'U-Connect is committed to protecting your privacy and ensuring the security of your personal data. This Privacy Policy describes how we collect, use, store and protect your information when you use our GPS tracking and vehicle monitoring services.'),
                      isFirst: true,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '2. Informações que Coletamos', '2. Information We Collect'),
                      '',
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Dados pessoais: nome completo, endereço, e-mail, telefone', 'Personal data: full name, address, email, phone'),
                        TranslationHelper.translateSync(context, 'Dados de conta: nome de usuário, senha, configurações de perfil', 'Account data: username, password, profile settings'),
                        TranslationHelper.translateSync(context, 'Dados de localização: coordenadas GPS, velocidade, altitude, direção', 'Location data: GPS coordinates, speed, altitude, direction'),
                        TranslationHelper.translateSync(context, 'Dados do veículo: placa, modelo, IMEI do dispositivo', 'Vehicle data: plate, model, device IMEI'),
                        TranslationHelper.translateSync(context, 'Dados de uso: logs de acesso, histórico de comandos, relatórios', 'Usage data: access logs, command history, reports'),
                        TranslationHelper.translateSync(context, 'Dados técnicos: IP, tipo de dispositivo, versão do aplicativo', 'Technical data: IP, device type, app version'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '3. Como Usamos Suas Informações', '3. How We Use Your Information'),
                      TranslationHelper.translateSync(context, 'Utilizamos suas informações exclusivamente para:', 'We use your information exclusively for:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Fornecer e manter nossos serviços de rastreamento', 'Provide and maintain our tracking services'),
                        TranslationHelper.translateSync(context, 'Processar pagamentos e faturas', 'Process payments and invoices'),
                        TranslationHelper.translateSync(context, 'Enviar notificações importantes sobre o serviço', 'Send important service notifications'),
                        TranslationHelper.translateSync(context, 'Melhorar a qualidade e funcionalidade do aplicativo', 'Improve app quality and functionality'),
                        TranslationHelper.translateSync(context, 'Cumprir obrigações legais e regulamentares', 'Comply with legal and regulatory obligations'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '4. Compartilhamento de Dados', '4. Data Sharing'),
                      TranslationHelper.translateSync(context, 'Nossa política de compartilhamento:', 'Our sharing policy:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Não vendemos, alugamos ou compartilhamos seus dados pessoais com terceiros', 'We do not sell, rent or share your personal data with third parties'),
                        TranslationHelper.translateSync(context, 'Compartilhamos dados apenas quando exigido por lei ou com seu consentimento explícito', 'We share data only when required by law or with your explicit consent'),
                        TranslationHelper.translateSync(context, 'Utilizamos provedores de serviços confiáveis que seguem rigorosos padrões de segurança', 'We use trusted service providers that follow strict security standards'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '5. Segurança dos Dados', '5. Data Security'),
                      TranslationHelper.translateSync(context, 'Implementamos medidas de segurança robustas:', 'We implement robust security measures:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Criptografia SSL/TLS para todas as transmissões de dados', 'SSL/TLS encryption for all data transmissions'),
                        TranslationHelper.translateSync(context, 'Armazenamento seguro em servidores com proteção avançada', 'Secure storage on servers with advanced protection'),
                        TranslationHelper.translateSync(context, 'Autenticação de dois fatores disponível', 'Two-factor authentication available'),
                        TranslationHelper.translateSync(context, 'Monitoramento contínuo de segurança', 'Continuous security monitoring'),
                        TranslationHelper.translateSync(context, 'Backups regulares e redundantes', 'Regular and redundant backups'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '6. Seus Direitos', '6. Your Rights'),
                      TranslationHelper.translateSync(context, 'Você tem os seguintes direitos:', 'You have the following rights:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Acessar seus dados pessoais a qualquer momento', 'Access your personal data at any time'),
                        TranslationHelper.translateSync(context, 'Corrigir informações imprecisas ou incompletas', 'Correct inaccurate or incomplete information'),
                        TranslationHelper.translateSync(context, 'Solicitar a exclusão de seus dados (direito ao esquecimento)', 'Request deletion of your data (right to be forgotten)'),
                        TranslationHelper.translateSync(context, 'Revogar consentimento para processamento de dados', 'Revoke consent for data processing'),
                        TranslationHelper.translateSync(context, 'Exportar seus dados em formato legível', 'Export your data in readable format'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '7. Retenção de Dados', '7. Data Retention'),
                      TranslationHelper.translateSync(context, 'Mantemos seus dados apenas pelo tempo necessário:', 'We keep your data only for as long as necessary:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Dados da conta: enquanto sua conta estiver ativa', 'Account data: while your account is active'),
                        TranslationHelper.translateSync(context, 'Dados de localização: conforme configurações do usuário', 'Location data: according to user settings'),
                        TranslationHelper.translateSync(context, 'Logs de sistema: por até 12 meses para fins de segurança', 'System logs: for up to 12 months for security purposes'),
                        TranslationHelper.translateSync(context, 'Dados de faturamento: conforme exigido por lei fiscal', 'Billing data: as required by tax law'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '8. Cookies e Tecnologias Similares', '8. Cookies and Similar Technologies'),
                      TranslationHelper.translateSync(context, 'Utilizamos cookies para:', 'We use cookies to:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Manter sua sessão ativa durante o uso do aplicativo', 'Keep your session active during app use'),
                        TranslationHelper.translateSync(context, 'Lembrar suas preferências e configurações', 'Remember your preferences and settings'),
                        TranslationHelper.translateSync(context, 'Analisar o uso do serviço para melhorias', 'Analyse service usage for improvements'),
                        TranslationHelper.translateSync(context, 'Garantir a segurança da sua conta', 'Ensure your account security'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '9. Alterações na Política', '9. Policy Changes'),
                      TranslationHelper.translateSync(context, 'Podemos atualizar esta política periodicamente. Notificaremos sobre mudanças significativas através do aplicativo ou e-mail.', 'We may update this policy periodically. We will notify you of significant changes through the app or email.'),
                      isFirst: false,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '10. Contato', '10. Contact'),
                      TranslationHelper.translateSync(context, 'Para dúvidas sobre esta política ou exercer seus direitos, entre em contato:', 'For questions about this policy or to exercise your rights, please contact:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        'E-mail: privacidade@u-connect.com.br',
                        'WhatsApp: (62) 8174-6605',
                        TranslationHelper.translateSync(context, 'Horário: Segunda a Sexta, 8h às 18h', 'Hours: Monday to Friday, 8am to 6pm'),
                      ],
                      isLast: true,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content, {
    required bool isFirst,
    required bool hasBulletPoints,
    required List<String> bulletPoints,
    required bool isLast,
    required bool hasSubBullets,
    required List<String> subBulletPoints,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 24,
        bottom: isLast ? 0 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F5C),
            ),
          ),
          SizedBox(height: 12),
          if (content.isNotEmpty)
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          if (hasBulletPoints) ...[
            if (content.isNotEmpty) SizedBox(height: 8),
            ...bulletPoints
                .map((point) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }
}
