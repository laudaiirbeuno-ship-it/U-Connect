import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/utils/translation_helper.dart';

class AppSettingsScreen extends StatefulWidget {
  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.grey.shade50,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Configurações do Aplicativo', 'App Settings'),
        icon: Icons.settings_outlined,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Consumer2<ColorProvider, AppSettingsProvider>(
        builder: (context, colorProvider, settingsProvider, child) {
          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            child: Column(
              children: [
                // Seletor de Cores Principal
                _buildColorSliderSelector(context, colorProvider, TranslationHelper.translateSync(context, 'Cor Principal do Tema', 'Primary Theme Color'), Icons.palette_outlined, (color) {
                  colorProvider.setPrimaryColor(color);
                }),
                SizedBox(height: 20),
                
                // Seletor de Cor Secundária
                _buildColorSliderSelector(context, colorProvider, TranslationHelper.translateSync(context, 'Cor Secundária do Tema', 'Secondary Theme Color'), Icons.color_lens_outlined, (color) {
                  colorProvider.setSecondaryColor(color);
                }, isSecondary: true),
                SizedBox(height: 20),
                
                // Seção: Ícones de Status da Frota (separada)
                _buildFleetIconSelectorStandalone(context, colorProvider),
                SizedBox(height: 20),
                
                // Seção 1: Trocar Logo
                _buildLogoSection(context, settingsProvider),
                SizedBox(height: 20),
                
                // Seção 2: Trocar Logo do Splash Screen
                _buildSplashLogoSection(context, settingsProvider),
                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // Seletor de Cores com Grade
  Widget _buildColorSliderSelector(BuildContext context, ColorProvider colorProvider, String title, IconData icon, Function(Color) onColorSelected, {bool isSecondary = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorProvider.primaryColor,
                      colorProvider.primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorProvider.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Top Section: Paleta de Cores com Scroll
          _buildTopColorCircles(context, colorProvider, isSecondary),
          
          SizedBox(height: 20),
          
          // Botão para seleção customizada de cor (RGB)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _showCustomColorPicker(context, colorProvider, isSecondary, onColorSelected);
              },
              icon: Icon(Icons.colorize),
              label: Text(TranslationHelper.translateSync(context, 'Personalizar Cor (RGB)', 'Customise Colour (RGB)')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSecondary ? colorProvider.secondaryColor : colorProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCustomColorPicker(BuildContext context, ColorProvider colorProvider, bool isSecondary, Function(Color) onColorSelected) {
    final currentColor = isSecondary ? colorProvider.secondaryColor : colorProvider.primaryColor;
    final title = isSecondary 
        ? TranslationHelper.translateSync(context, 'Personalizar Cor Secundária', 'Customise Secondary Colour')
        : TranslationHelper.translateSync(context, 'Personalizar Cor Principal', 'Customise Primary Colour');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: double.maxFinite,
          child: ColorPicker(
            currentColor: currentColor,
            onColorSelected: (color) {
              onColorSelected(color);
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopColorCircles(BuildContext context, ColorProvider colorProvider, bool isSecondary) {
    final topColors = [
      Colors.black,                    // 1. Preto
      // Colors.white removido - não permitir cor branca
      Colors.red.shade700,             // 2. Vermelho
      Colors.lime.shade600,            // 4. Verde Lima
      Colors.blue.shade700,            // 5. Azul
      Colors.yellow.shade600,          // 6. Amarelo
      Colors.cyan.shade600,            // 7. Ciano
      Color(0xFFFF00FF),               // 8. Magenta
      Colors.grey.shade400,            // 9. Cinza claro
      Colors.grey.shade600,            // 10. Cinza médio
      Colors.red.shade900,             // 11. Vermelho escuro
      Color(0xFF6B8E23),               // 12. Verde oliva
      Colors.green.shade900,           // 13. Verde escuro
      Colors.purple.shade900,          // 14. Roxo escuro
      Colors.teal.shade900,            // 15. Teal escuro
      Colors.blue.shade900,            // 16. Azul marinho escuro
      Colors.orange.shade700,          // 17. Laranja
      Colors.pink.shade600,            // 18. Rosa
      Colors.indigo.shade700,          // 19. Índigo
      Colors.amber.shade700,           // 20. Âmbar
      Colors.brown.shade700,           // 21. Marrom
      Colors.deepOrange.shade700,      // 22. Laranja escuro
      Colors.lightBlue.shade600,       // 23. Azul claro
      Colors.lightGreen.shade600,      // 24. Verde claro
      Color(0xFF4A148C),               // 25. Roxo muito escuro
      Color(0xFF006064),               // 26. Ciano escuro
      Color(0xFF1A10CD),               // 27. Azul roxo personalizado
      Color(0xFF05055C),               // 28. Azul escuro personalizado
    ];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: topColors.map((color) {
            final currentColor = isSecondary ? colorProvider.secondaryColor : colorProvider.primaryColor;
            final isSelected = _areColorsSimilar(color, currentColor);
            return GestureDetector(
              onTap: () {
                if (isSecondary) {
                  colorProvider.setSecondaryColor(color);
                } else {
                  colorProvider.setPrimaryColor(color);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected ? currentColor : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: currentColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  bool _areColorsSimilar(Color c1, Color c2) {
    final threshold = 30;
    return (c1.red - c2.red).abs() < threshold &&
           (c1.green - c2.green).abs() < threshold &&
           (c1.blue - c2.blue).abs() < threshold;
  }

  // Seção: Seletor de Ícone do Status da Frota (Standalone)
  Widget _buildFleetIconSelectorStandalone(BuildContext context, ColorProvider colorProvider) {
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorProvider.primaryColor,
                      colorProvider.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  TranslationHelper.translateSync(context, 'Ícone do Status da Frota', 'Fleet Status Icon'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children: settingsProvider.availableFleetIcons.map((iconData) {
                final iconCode = iconData['code'] as String;
                final icon = iconData['icon'] as IconData;
                final name = iconData['name'] as String;
                final isSelected = settingsProvider.fleetStatusIcon == iconCode;
                
                return GestureDetector(
                  onTap: () {
                    settingsProvider.setFleetStatusIcon(iconCode);
                  },
                  child: Container(
                    width: 80,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? colorProvider.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? colorProvider.primaryColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected 
                              ? colorProvider.primaryColor
                              : Colors.grey.shade700,
                          size: 32,
                        ),
                        SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected 
                                ? colorProvider.primaryColor
                                : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Seção: Trocar Logo
  Widget _buildLogoSection(BuildContext context, AppSettingsProvider settingsProvider) {
    return _buildSectionCard(
      context: context,
      icon: Icons.image_outlined,
      title: TranslationHelper.translateSync(context, 'Trocar Logo da Página de Login', 'Change Login Page Logo'),
      child: Column(
        children: [
          SizedBox(height: 8),
          // Informação sobre formato e tamanho
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Esta logo será aplicada na página de login:', 'This logo will be applied to the login page:'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, '• Tamanho de exibição: 280x140px', '• Display size: 280x140px'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        TranslationHelper.translateSync(context, '• Proporção: 2:1 (horizontal)', '• Ratio: 2:1 (horizontal)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        TranslationHelper.translateSync(context, 'Tamanho ideal: 560x280px ou maior (PNG)', 'Ideal size: 560x280px or larger (PNG)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Preview da logo atual
          _buildLogoPreview(context, settingsProvider),
          SizedBox(height: 16),
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickLogo(context, settingsProvider),
                  icon: Icon(Icons.upload_file, size: 18),
                  label: Text(TranslationHelper.translateSync(context, 'Escolher Logo', 'Choose Logo')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Provider.of<ColorProvider>(context).primaryColor,
                    side: BorderSide(
                      color: Provider.of<ColorProvider>(context).primaryColor,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              if (settingsProvider.customLogo != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeLogo(context, settingsProvider),
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text(TranslationHelper.translateSync(context, 'Remover', 'Remove')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.aspect_ratio,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    SizedBox(width: 6),
                    Text(
                      TranslationHelper.translateSync(context, 'Tamanho de exibição: 280x140px', 'Display size: 280x140px'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  TranslationHelper.translateSync(context, 'Recomendado: 560x280px ou maior (PNG)', 'Recommended: 560x280px or larger (PNG)'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(BuildContext context, AppSettingsProvider settingsProvider) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: settingsProvider.customLogo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                settingsProvider.customLogo!,
                fit: BoxFit.contain,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Logo atual do app', 'Current app logo'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _pickLogo(BuildContext context, AppSettingsProvider settingsProvider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Validar se é PNG
        if (!image.path.toLowerCase().endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Por favor, selecione um arquivo PNG', 'Please select a PNG file')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validar resolução (simplificado - em produção usar package de imagem)
        await settingsProvider.setCustomLogo(file);
        
        // Atualizar StaticVarMethod
        StaticVarMethod.loginimageurl = file.path;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Logo atualizada com sucesso!', 'Logo updated successfully!')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao selecionar logo: $e', 'Error selecting logo: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeLogo(BuildContext context, AppSettingsProvider settingsProvider) async {
    await settingsProvider.removeCustomLogo();
    StaticVarMethod.loginimageurl = 'assets/appsicon/logo.png';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translateSync(context, 'Logo removida', 'Logo removed')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Seção: Trocar Logo do Splash Screen
  Widget _buildSplashLogoSection(BuildContext context, AppSettingsProvider settingsProvider) {
    return _buildSectionCard(
      context: context,
      icon: Icons.mobile_screen_share_outlined,
      title: TranslationHelper.translateSync(context, 'Trocar Ícone do Splash Screen', 'Change Splash Screen Icon'),
      child: Column(
        children: [
          SizedBox(height: 8),
          // Informação sobre formato e tamanho
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        TranslationHelper.translateSync(context, 'Esta logo será aplicada em 2 telas:', 'This logo will be applied to 2 screens:'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.translateSync(context, '• Splash Screen: 280x140px (proporção 2:1)', '• Splash Screen: 280x140px (2:1 ratio)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        TranslationHelper.translateSync(context, '• Tela de Boas-Vindas: 180x180px (circular)', '• Welcome Screen: 180x180px (circular)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        TranslationHelper.translateSync(context, 'Tamanho ideal: 560x560px ou maior (PNG)', 'Ideal size: 560x560px or larger (PNG)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Preview da logo atual do splash
          _buildSplashLogoPreview(context, settingsProvider),
          SizedBox(height: 16),
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickSplashLogo(context, settingsProvider),
                  icon: Icon(Icons.upload_file, size: 18),
                  label: Text(TranslationHelper.translateSync(context, 'Escolher Ícone', 'Choose Icon')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Provider.of<ColorProvider>(context).primaryColor,
                    side: BorderSide(
                      color: Provider.of<ColorProvider>(context).primaryColor,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              if (settingsProvider.customSplashLogo != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _removeSplashLogo(context, settingsProvider),
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text(TranslationHelper.translateSync(context, 'Remover', 'Remove')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.aspect_ratio,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    SizedBox(width: 6),
                    Text(
                      TranslationHelper.translateSync(context, 'Tamanhos de exibição:', 'Display sizes:'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  TranslationHelper.translateSync(context, 'Splash: 280x140px | Boas-Vindas: 180x180px', 'Splash: 280x140px | Welcome: 180x180px'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  TranslationHelper.translateSync(context, 'Recomendado: 560x560px ou maior (PNG)', 'Recommended: 560x560px or larger (PNG)'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashLogoPreview(BuildContext context, AppSettingsProvider settingsProvider) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: settingsProvider.customSplashLogo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                settingsProvider.customSplashLogo!,
                fit: BoxFit.contain,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mobile_screen_share_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 8),
                Text(
                  TranslationHelper.translateSync(context, 'Ícone padrão do splash screen', 'Default splash screen icon'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _pickSplashLogo(BuildContext context, AppSettingsProvider settingsProvider) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Validar se é PNG
        if (!image.path.toLowerCase().endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Por favor, selecione um arquivo PNG', 'Please select a PNG file')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await settingsProvider.setCustomSplashLogo(file);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(context, 'Ícone do splash screen atualizado com sucesso!', 'Splash screen icon updated successfully!')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(context, 'Erro ao selecionar ícone: $e', 'Error selecting icon: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeSplashLogo(BuildContext context, AppSettingsProvider settingsProvider) async {
    await settingsProvider.removeCustomSplashLogo();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.translateSync(context, 'Ícone do splash screen removido', 'Splash screen icon removed')),
        backgroundColor: Colors.orange,
      ),
    );
  }



  // Widget auxiliar para criar cards de seção
  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colorProvider = Provider.of<ColorProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da seção com gradiente sutil
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorProvider.primaryColor.withOpacity(0.05),
                  colorProvider.primaryColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorProvider.primaryColor,
                        colorProvider.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorProvider.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da seção
          Padding(
            padding: EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// Widget simples de ColorPicker
class ColorPicker extends StatefulWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorPicker({
    Key? key,
    required this.currentColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: _selectedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _selectedColor,
            thumbColor: _selectedColor,
            overlayColor: _selectedColor.withOpacity(0.2),
          ),
          child: Column(
            children: [
              Text(TranslationHelper.translateSync(context, 'Vermelho: ${_selectedColor.red}', 'Red: ${_selectedColor.red}')),
              Slider(
                value: _selectedColor.red.toDouble(),
                min: 0,
                max: 255,
                onChanged: (value) {
                  setState(() {
                    _selectedColor = Color.fromRGBO(
                      value.toInt(),
                      _selectedColor.green,
                      _selectedColor.blue,
                      1,
                    );
                  });
                },
              ),
              Text(TranslationHelper.translateSync(context, 'Verde: ${_selectedColor.green}', 'Green: ${_selectedColor.green}')),
              Slider(
                value: _selectedColor.green.toDouble(),
                min: 0,
                max: 255,
                onChanged: (value) {
                  setState(() {
                    _selectedColor = Color.fromRGBO(
                      _selectedColor.red,
                      value.toInt(),
                      _selectedColor.blue,
                      1,
                    );
                  });
                },
              ),
              Text(TranslationHelper.translateSync(context, 'Azul: ${_selectedColor.blue}', 'Blue: ${_selectedColor.blue}')),
              Slider(
                value: _selectedColor.blue.toDouble(),
                min: 0,
                max: 255,
                onChanged: (value) {
                  setState(() {
                    _selectedColor = Color.fromRGBO(
                      _selectedColor.red,
                      _selectedColor.green,
                      value.toInt(),
                      1,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => widget.onColorSelected(_selectedColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(TranslationHelper.translateSync(context, 'Aplicar Cor', 'Apply Colour')),
        ),
      ],
    );
  }
}
