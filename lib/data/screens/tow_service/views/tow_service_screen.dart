import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/animated_background.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';

class TowServiceScreen extends StatefulWidget {
  const TowServiceScreen({Key? key}) : super(key: key);

  @override
  State<TowServiceScreen> createState() => _TowServiceScreenState();
}

class _TowServiceScreenState extends State<TowServiceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _callEmergencyNumber() async {
    const phoneNumber = '0800';
    final uri = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                TranslationHelper.translateSync(
                  context,
                  'Não foi possível fazer a ligação. Verifique se seu dispositivo suporta chamadas.',
                  'Could not make the call. Check if your device supports calls.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationHelper.translateSync(
                context,
                'Erro ao fazer ligação: $e',
                'Error making call: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Chamar Reboque', 'Call Tow Service'),
        icon: Icons.local_taxi,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Stack(
        children: [
          AnimatedBackground(opacity: 0.03),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aviso importante
                    _buildWarningCard(colorProvider),
                    
                    SizedBox(height: 16),
                    
                    // Título principal
                    _buildTitleSection(colorProvider),
                    
                    SizedBox(height: 24),
                    
                    // Benefícios
                    _buildBenefitsSection(colorProvider),
                    
                    SizedBox(height: 24),
                    
                    // Botão de ligação
                    _buildCallButton(colorProvider),
                    
                    SizedBox(height: 24),
                    
                    // Informações de contratação
                    _buildContractInfo(colorProvider),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade700, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translateSync(
                    context,
                    'ATENÇÃO IMPORTANTE',
                    'IMPORTANT WARNING',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  TranslationHelper.translateSync(
                    context,
                    'Para ter direito a este serviço, você precisa contratá-lo. Se não tiver este serviço contratado, não adianta ligar no 0800, pois não será atendido.',
                    'To have access to this service, you need to contract it. If you do not have this service contracted, calling 0800 will not work, as you will not be served.',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorProvider.primaryColor,
            colorProvider.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorProvider.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_taxi,
            size: 64,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            TranslationHelper.translateSync(
              context,
              'Veja tudo o que você tem direito',
              'See everything you are entitled to',
            ),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            TranslationHelper.translateSync(
              context,
              'Mostre todos os benefícios',
              'Show all benefits',
            ),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(ColorProvider colorProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translateSync(
            context,
            'Benefícios Inclusos',
            'Included Benefits',
          ),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 16),
        _buildBenefitCard(
          Icons.local_taxi,
          TranslationHelper.translateSync(context, 'Reboque', 'Tow Service'),
          TranslationHelper.translateSync(
            context,
            '400 km de reboque sendo 200 km de raio. Serviço de socorro emergencial para remoção do veículo.',
            '400 km of towing with 200 km radius. Emergency assistance service for vehicle removal.',
          ),
          colorProvider,
        ),
        SizedBox(height: 12),
        _buildBenefitCard(
          Icons.build,
          TranslationHelper.translateSync(context, 'Mecânico', 'Mechanic'),
          TranslationHelper.translateSync(
            context,
            'Serviço de mecânico de emergência. Reparos básicos na estrada para que você possa seguir viagem.',
            'Emergency mechanic service. Basic roadside repairs so you can continue your journey.',
          ),
          colorProvider,
        ),
        SizedBox(height: 12),
        _buildBenefitCard(
          Icons.electrical_services,
          TranslationHelper.translateSync(context, 'Eletricista', 'Electrician'),
          TranslationHelper.translateSync(
            context,
            'Serviço de eletricista de emergência. Reparos elétricos básicos no veículo.',
            'Emergency electrician service. Basic electrical repairs on the vehicle.',
          ),
          colorProvider,
        ),
        SizedBox(height: 12),
        _buildBenefitCard(
          Icons.local_gas_station,
          TranslationHelper.translateSync(context, 'Combustível de Emergência', 'Emergency Fuel'),
          TranslationHelper.translateSync(
            context,
            'Fornecimento de combustível de emergência quando você ficar sem combustível na estrada.',
            'Emergency fuel supply when you run out of fuel on the road.',
          ),
          colorProvider,
        ),
        SizedBox(height: 12),
        _buildBenefitCard(
          Icons.car_repair,
          TranslationHelper.translateSync(context, 'Borracheiro', 'Tire Repair'),
          TranslationHelper.translateSync(
            context,
            'Serviço de borracheiro de emergência. Troca de pneus e reparos básicos.',
            'Emergency tire repair service. Tire changes and basic repairs.',
          ),
          colorProvider,
        ),
        SizedBox(height: 12),
        _buildBenefitCard(
          Icons.vpn_key,
          TranslationHelper.translateSync(context, 'Chaveiro', 'Locksmith'),
          TranslationHelper.translateSync(
            context,
            'Serviço de chaveiro de emergência. Abertura de portas e chaves travadas.',
            'Emergency locksmith service. Door opening and stuck keys.',
          ),
          colorProvider,
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorProvider.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorProvider.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(
                    context,
                    'Cada serviço tem direito a 3 acionamentos por mês (não acumulativo). Todos os serviços são de socorro emergencial.',
                    'Each service entitles you to 3 calls per month (non-cumulative). All services are emergency assistance.',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitCard(
    IconData icon,
    String title,
    String description,
    ColorProvider colorProvider,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorProvider.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorProvider.primaryColor,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    TranslationHelper.translateSync(
                      context,
                      '3 acionamentos/mês',
                      '3 calls/month',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton(ColorProvider colorProvider) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _callEmergencyNumber,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 28),
            SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '0800',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  TranslationHelper.translateSync(
                    context,
                    'Ligar Agora',
                    'Call Now',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractInfo(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.blue.shade700,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                TranslationHelper.translateSync(
                  context,
                  'Como Contratar',
                  'How to Contract',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            TranslationHelper.translateSync(
              context,
              'Para contratar este serviço, entre em contato com seu suporte através do aplicativo ou pelo telefone.',
              'To contract this service, contact your support through the app or by phone.',
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
