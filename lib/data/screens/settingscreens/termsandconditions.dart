import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/responsive_helper.dart';

class termsandconditions extends StatefulWidget {
  @override
  _termsandconditionsState createState() => _termsandconditionsState();
}

class _termsandconditionsState extends State<termsandconditions> {
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
          title: TranslationHelper.translateSync(context, "Termos de Uso", "Terms of Use"),
          icon: Icons.description,
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
                      Icons.description,
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
                      TranslationHelper.translateSync(context, 'Termos de Uso', 'Terms of Use'),
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

              // Conteúdo dos Termos
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      TranslationHelper.translateSync(context, '1. Aceitação dos Termos', '1. Acceptance of Terms'),
                      TranslationHelper.translateSync(context, 'Ao acessar e utilizar os serviços da U-Connect, você concorda em cumprir e estar vinculado a estes Termos de Uso. Se você não concordar com qualquer parte destes termos, não deve utilizar nossos serviços.', 'By accessing and using U-Connect services, you agree to comply with and be bound by these Terms of Use. If you do not agree with any part of these terms, you should not use our services.'),
                      isFirst: true,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '2. Descrição dos Serviços', '2. Service Description'),
                      TranslationHelper.translateSync(context, 'A U-Connect oferece serviços de rastreamento GPS e monitoramento de veículos, incluindo:', 'U-Connect offers GPS tracking and vehicle monitoring services, including:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Rastreamento em tempo real de veículos', 'Real-time vehicle tracking'),
                        TranslationHelper.translateSync(context, 'Histórico de rotas e relatórios detalhados', 'Route history and detailed reports'),
                        TranslationHelper.translateSync(context, 'Sistema de alertas e notificações', 'Alerts and notifications system'),
                        TranslationHelper.translateSync(context, 'Cercas virtuais (geofencing)', 'Virtual fences (geofencing)'),
                        TranslationHelper.translateSync(context, 'Monitoramento de velocidade e comportamento', 'Speed and behaviour monitoring'),
                        TranslationHelper.translateSync(context, 'Relatórios de quilometragem e consumo', 'Mileage and consumption reports'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '3. Uso Aceitável', '3. Acceptable Use'),
                      TranslationHelper.translateSync(context, 'Você concorda em utilizar nossos serviços apenas para fins legítimos e de acordo com estes termos:', 'You agree to use our services only for legitimate purposes and in accordance with these terms:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Rastreamento de veículos de sua propriedade ou sob sua responsabilidade', 'Tracking vehicles you own or are responsible for'),
                        TranslationHelper.translateSync(context, 'Monitoramento de frotas comerciais com autorização', 'Monitoring commercial fleets with authorisation'),
                        TranslationHelper.translateSync(context, 'Uso pessoal para segurança e controle de veículos próprios', 'Personal use for security and control of own vehicles'),
                        TranslationHelper.translateSync(context, 'Cumprimento de todas as leis e regulamentações aplicáveis', 'Compliance with all applicable laws and regulations'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '4. Uso Proibido', '4. Prohibited Use'),
                      TranslationHelper.translateSync(context, 'É estritamente proibido:', 'It is strictly prohibited:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Rastrear pessoas sem seu conhecimento e consentimento', 'Tracking people without their knowledge and consent'),
                        TranslationHelper.translateSync(context, 'Monitorar veículos sem autorização do proprietário', 'Monitoring vehicles without owner authorisation'),
                        TranslationHelper.translateSync(context, 'Utilizar os serviços para atividades ilegais', 'Using services for illegal activities'),
                        TranslationHelper.translateSync(context, 'Tentar acessar ou modificar sistemas sem autorização', 'Attempting to access or modify systems without authorisation'),
                        TranslationHelper.translateSync(context, 'Compartilhar credenciais de acesso com terceiros', 'Sharing access credentials with third parties'),
                        TranslationHelper.translateSync(context, 'Usar os serviços para assédio ou perseguição', 'Using services for harassment or stalking'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '5. Responsabilidades do Usuário', '5. User Responsibilities'),
                      TranslationHelper.translateSync(context, 'Como usuário dos nossos serviços, você é responsável por:', 'As a user of our services, you are responsible for:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Manter a confidencialidade de suas credenciais de acesso', 'Maintaining the confidentiality of your access credentials'),
                        TranslationHelper.translateSync(context, 'Notificar imediatamente sobre uso não autorizado', 'Immediately notifying of unauthorised use'),
                        TranslationHelper.translateSync(context, 'Respeitar a privacidade e direitos de terceiros', 'Respecting the privacy and rights of third parties'),
                        TranslationHelper.translateSync(context, 'Cumprir todas as leis de proteção de dados aplicáveis', 'Complying with all applicable data protection laws'),
                        TranslationHelper.translateSync(context, 'Usar os dispositivos GPS de forma segura e responsável', 'Using GPS devices safely and responsibly'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '6. Limitação de Responsabilidade', '6. Limitation of Liability'),
                      TranslationHelper.translateSync(context, 'A U-Connect não se responsabiliza por:', 'U-Connect is not responsible for:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        TranslationHelper.translateSync(context, 'Danos indiretos ou consequenciais decorrentes do uso dos serviços', 'Indirect or consequential damages arising from service use'),
                        TranslationHelper.translateSync(context, 'Perda de dados devido a falhas técnicas ou de conectividade', 'Data loss due to technical or connectivity failures'),
                        TranslationHelper.translateSync(context, 'Uso inadequado ou não autorizado dos dispositivos GPS', 'Inappropriate or unauthorised use of GPS devices'),
                        TranslationHelper.translateSync(context, 'Violações de leis locais por parte do usuário', 'User violations of local laws'),
                        TranslationHelper.translateSync(context, 'Interrupções temporárias do serviço por manutenção', 'Temporary service interruptions for maintenance'),
                      ],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '7. Propriedade Intelectual', '7. Intellectual Property'),
                      TranslationHelper.translateSync(context, 'Todos os direitos de propriedade intelectual relacionados aos nossos serviços, incluindo software, design, marcas e conteúdo, pertencem exclusivamente à U-Connect.', 'All intellectual property rights related to our services, including software, design, trademarks and content, belong exclusively to U-Connect.'),
                      isFirst: false,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '8. Modificações dos Termos', '8. Terms Modifications'),
                      TranslationHelper.translateSync(context, 'Reservamo-nos o direito de modificar estes termos a qualquer momento. Alterações significativas serão comunicadas através do aplicativo ou por e-mail.', 'We reserve the right to modify these terms at any time. Significant changes will be communicated through the app or by email.'),
                      isFirst: false,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '9. Rescisão', '9. Termination'),
                      TranslationHelper.translateSync(context, 'Podemos suspender ou encerrar sua conta imediatamente se você violar estes termos ou usar nossos serviços de forma inadequada.', 'We may suspend or terminate your account immediately if you violate these terms or use our services inappropriately.'),
                      isFirst: false,
                      hasBulletPoints: false,
                      bulletPoints: [],
                      isLast: false,
                      hasSubBullets: false,
                      subBulletPoints: [],
                    ),
                    _buildSection(
                      TranslationHelper.translateSync(context, '10. Contato', '10. Contact'),
                      TranslationHelper.translateSync(context, 'Para dúvidas sobre estes termos, entre em contato:', 'For questions about these terms, please contact:'),
                      isFirst: false,
                      hasBulletPoints: true,
                      bulletPoints: [
                        'E-mail: suporte@u-connect.com.br',
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
