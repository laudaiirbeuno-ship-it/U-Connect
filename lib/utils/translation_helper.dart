import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/Session.dart';

class TranslationHelper {
  // Detectar idioma atual
  static Future<String> getCurrentLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LAGUAGE_CODE) ?? 'pt';
  }

  // Verificar se é inglês
  static Future<bool> isEnglish() async {
    final code = await getCurrentLanguageCode();
    return code == 'en';
  }

  // Traduzir texto baseado no idioma atual
  static Future<String> translate(String portuguese, String english) async {
    final isEn = await isEnglish();
    return isEn ? english : portuguese;
  }

  // Traduzir texto síncrono (usando context) - suporta múltiplos idiomas
  static String translateSync(BuildContext context, String portuguese, String english, {String? spanish, String? french, String? italian}) {
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    
    switch (langCode) {
      case 'en':
        return english;
      case 'es':
        return spanish ?? english; // Fallback para inglês se não fornecido
      case 'fr':
        return french ?? english; // Fallback para inglês se não fornecido
      case 'it':
        return italian ?? english; // Fallback para inglês se não fornecido
      default:
        return portuguese; // Português como padrão
    }
  }

  // Traduções das categorias do menu
  static Future<String> getMenuCategory(String category) async {
    final isEn = await isEnglish();
    switch (category) {
      case 'GESTÃO DE FROTAS':
        return isEn ? 'FLEET MANAGEMENT' : 'GESTÃO DE FROTAS';
      case 'EVENTOS':
        return isEn ? 'EVENTS' : 'EVENTOS';
      case 'FINANCEIRO':
        return isEn ? 'FINANCIAL' : 'FINANCEIRO';
      case 'PROMOÇOES':
        return isEn ? 'PROMOTIONS' : 'PROMOÇOES';
      case 'CONTATOS':
        return isEn ? 'CONTACTS' : 'CONTATOS';
      case 'SUPORTE':
        return isEn ? 'SUPPORT' : 'SUPORTE';
      case 'CONFIGURAÇÕES':
        return isEn ? 'SETTINGS' : 'CONFIGURAÇÕES';
      case 'LEGAIS':
        return isEn ? 'LEGAL' : 'LEGAIS';
      case 'LOGOUT':
        return isEn ? 'LOGOUT' : 'LOGOUT';
      default:
        return category;
    }
  }

  // Traduções dos itens do menu
  static Future<String> getMenuItem(String item) async {
    final isEn = await isEnglish();
    switch (item) {
      case 'Mapa Principal':
        return isEn ? 'Main Map' : 'Mapa Principal';
      case 'Lista de Veículos':
        return isEn ? 'Vehicle List' : 'Lista de Veículos';
      case 'Informações detalhadas do meu Veículo':
        return isEn ? 'Detailed Vehicle Information' : 'Informações detalhadas do meu Veículo';
      case 'Meus Motoristas':
        return isEn ? 'My Drivers' : 'Meus Motoristas';
      case 'Manutenção':
        return isEn ? 'Maintenance' : 'Manutenção';
      case 'Km Percorrida':
        return isEn ? 'Distance Travelled' : 'Km Percorrida';
      case 'Consumo de Combustível':
        return isEn ? 'Fuel Consumption' : 'Consumo de Combustível';
      case 'Sensores':
        return isEn ? 'Sensors' : 'Sensores';
      case 'Video Telemetria':
        return isEn ? 'Video Telemetry' : 'Video Telemetria';
      case 'Relatórios':
        return isEn ? 'Reports' : 'Relatórios';
      case 'Histórico de Rotas':
        return isEn ? 'Route History' : 'Histórico de Rotas';
      case 'Central de Notificações':
        return isEn ? 'Notifications Centre' : 'Central de Notificações';
      case 'Alertas':
        return isEn ? 'Alerts' : 'Alertas';
      case 'Mapa de Calor':
        return isEn ? 'Heat Map' : 'Mapa de Calor';
      case 'Minhas Cobranças':
        return isEn ? 'My Charges' : 'Minhas Cobranças';
      case 'Meus Contratos':
        return isEn ? 'My Contracts' : 'Meus Contratos';
      case 'Comprovantes':
        return isEn ? 'Receipts' : 'Comprovantes';
      case 'Indique um Amigo':
        return isEn ? 'Refer a Friend' : 'Indique um Amigo';
      case 'Avisos':
        return isEn ? 'Announcements' : 'Avisos';
      case 'Parceiros':
        return isEn ? 'Partners' : 'Parceiros';
      case 'Contatos de Emergência':
        return isEn ? 'Emergency Contacts' : 'Contatos de Emergência';
      case 'Suporte':
        return isEn ? 'Support' : 'Suporte';
      case 'Configuração':
        return isEn ? 'Settings' : 'Configuração';
      case 'Configuração da Personalização':
        return isEn ? 'Customisation Settings' : 'Configuração da Personalização';
      case 'Políticas e Privacidade':
        return isEn ? 'Privacy Policy' : 'Políticas e Privacidade';
      case 'Termos de Uso':
        return isEn ? 'Terms of Use' : 'Termos de Uso';
      case 'Sair':
        return isEn ? 'Logout' : 'Sair';
      case 'Menu':
        return isEn ? 'Menu' : 'Menu';
      default:
        return item;
    }
  }
}
