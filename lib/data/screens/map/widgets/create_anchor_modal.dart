import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';

class CreateAnchorModal extends StatefulWidget {
  final deviceItems device;
  final Function(String name, int radius, String color, int speedLimit, bool movementAllowed, {
    bool? autoBlock,
    bool? alertIgnition,
    bool? alertSpeed,
  })? onCreate;
  final bool hasActiveAnchor;
  final VoidCallback? onDeactivate;

  const CreateAnchorModal({
    Key? key,
    required this.device,
    this.onCreate,
    this.hasActiveAnchor = false,
    this.onDeactivate,
  }) : super(key: key);

  @override
  _CreateAnchorModalState createState() => _CreateAnchorModalState();
}

class _CreateAnchorModalState extends State<CreateAnchorModal> {
  late TextEditingController _nameController;
  int _selectedRadius = 50; // Raio padrão: 50 metros (conforme documentação)
  int _selectedSpeedLimit = 5; // Velocidade padrão: 5 km/h (conforme documentação)
  bool _movementAllowed = true; // Movimento ativado por padrão
  bool _autoBlock = true; // Bloquear automaticamente ao sair do raio
  bool _alertIgnition = true; // Alerta de ignição ligada dentro da cerca
  bool _alertSpeed = true; // Alerta de velocidade dentro da cerca
  String _selectedColor = '#FF0000'; // Vermelho padrão (conforme documentação)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: '${TranslationHelper.translateSync(context, 'Antifurto', 'Antitheft')} ${widget.device.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColorFromString(String colorHex) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.orange;
    }
  }

  Widget _buildColorOption(String colorHex, String label, String selectedColor, Function(String) onTap) {
    final isSelected = selectedColor == colorHex;
    final color = _parseColorFromString(colorHex);
    
    return GestureDetector(
      onTap: () => onTap(colorHex),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Cabeçalho (fixo) - usando cor do tema
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorProvider.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.hasActiveAnchor 
                        ? TranslationHelper.translateSync(context, 'Gerenciar Antifurto', 'Manage Antitheft')
                        : TranslationHelper.translateSync(context, 'Criar Antifurto', 'Create Antitheft'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Corpo (scrollável)
            Flexible(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do antifurto
                    Text(
                      TranslationHelper.translateSync(context, 'Nome do Antifurto', 'Antitheft Name'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: TranslationHelper.translateSync(context, 'Digite o nome do antifurto', 'Enter antitheft name'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.label, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Raio
                    Text(
                      TranslationHelper.translateSync(context, 'Raio (metros)', 'Radius (meters)'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _selectedRadius.toDouble(),
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '$_selectedRadius m',
                            onChanged: (value) {
                              setState(() {
                                _selectedRadius = value.toInt();
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_selectedRadius m',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ========== OPÇÕES DE ALERTA ==========
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 180, // Altura máxima reduzida
                      ),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorProvider.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorProvider.primaryColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                TranslationHelper.translateSync(context, 'Opções de Alerta', 'Alert Options'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorProvider.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Scroll para os alertas
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkboxes de alertas (sempre marcados, não editáveis)
                                  CheckboxListTile(
                                    title: Text(
                                      TranslationHelper.translateSync(context, 'Bloquear veículo automaticamente ao sair do raio', 'Automatically block vehicle when leaving radius'),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    value: _autoBlock,
                                    onChanged: null, // Não permite desmarcar
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      TranslationHelper.translateSync(context, 'Alerta de ignição ligada dentro da cerca', 'Alert when ignition is on inside geofence'),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    value: _alertIgnition,
                                    onChanged: null, // Não permite desmarcar
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      TranslationHelper.translateSync(context, 'Alerta de movimento dentro da cerca', 'Alert when movement detected inside geofence'),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    value: _movementAllowed,
                                    onChanged: null, // Não permite desmarcar
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                  CheckboxListTile(
                                    title: Text(
                                      TranslationHelper.translateSync(context, 'Alerta de velocidade dentro da cerca', 'Alert when speed limit exceeded inside geofence'),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    value: _alertSpeed,
                                    onChanged: null, // Não permite desmarcar
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                  // Limite de Velocidade (se alerta de velocidade marcado)
                                  if (_alertSpeed) ...[
                                    SizedBox(height: 8),
                          Text(
                                      TranslationHelper.translateSync(context, 'Limite de Velocidade (km/h):', 'Speed Limit (km/h):'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _selectedSpeedLimit.toDouble(),
                                            min: 1,
                                            max: 50,
                                            divisions: 49,
                                  label: '$_selectedSpeedLimit km/h',
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSpeedLimit = value.toInt();
                                    });
                                  },
                                  activeColor: colorProvider.primaryColor,
                                ),
                              ),
                              Container(
                                width: 70,
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorProvider.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_selectedSpeedLimit km/h',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorProvider.primaryColor,
                                              fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                                  ],
                                  ],
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    // Cor
                    Text(
                      TranslationHelper.translateSync(context, 'Cor', 'Color'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildColorOption('#FFA500', TranslationHelper.translateSync(context, 'Laranja', 'Orange'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                          SizedBox(width: 6),
                          _buildColorOption('#FF0000', TranslationHelper.translateSync(context, 'Vermelho', 'Red'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                          SizedBox(width: 6),
                          _buildColorOption('#00FF00', TranslationHelper.translateSync(context, 'Verde', 'Green'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                          SizedBox(width: 6),
                          _buildColorOption('#0000FF', TranslationHelper.translateSync(context, 'Azul', 'Blue'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                          SizedBox(width: 6),
                          _buildColorOption('#FF00FF', TranslationHelper.translateSync(context, 'Magenta', 'Magenta'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                          SizedBox(width: 6),
                          _buildColorOption('#FFFF00', TranslationHelper.translateSync(context, 'Amarelo', 'Yellow'), _selectedColor, (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    // Botões de ação
                    if (widget.hasActiveAnchor && widget.onDeactivate != null) ...[
                      // Informação sobre âncora ativa
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                TranslationHelper.translateSync(context, 'Este veículo possui um antifurto ativo com círculo no mapa.', 'This vehicle has an active antitheft with circle on the map.'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      // Botão Desativar (quando já existe âncora)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Future.microtask(() {
                              widget.onDeactivate?.call();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                TranslationHelper.translateSync(context, 'Desativar Antifurto', 'Deactivate Antitheft'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    // Botão criar (só aparece se não tem âncora ativa)
                    if (!widget.hasActiveAnchor) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final anchorName = _nameController.text.trim().isEmpty 
                              ? '${TranslationHelper.translateSync(context, 'Antifurto', 'Antitheft')} ${widget.device.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')}' 
                              : _nameController.text.trim();
                          
                          // Fechar o modal primeiro
                          Navigator.pop(context);
                          
                          // Criar a âncora após fechar o modal
                          // Usar Future.microtask para garantir que o modal foi fechado
                          if (widget.onCreate != null) {
                          Future.microtask(() {
                              widget.onCreate!(
                              anchorName,
                              _selectedRadius,
                              _selectedColor,
                              _selectedSpeedLimit,
                              _movementAllowed,
                                autoBlock: _autoBlock,
                                alertIgnition: _alertIgnition,
                                alertSpeed: _alertSpeed,
                            );
                          });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorProvider.primaryColor,
                          foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security, size: 20),
                              SizedBox(width: 8),
                              Text(
                                TranslationHelper.translateSync(context, 'Criar Antifurto', 'Create Antitheft'),
                          style: TextStyle(
                                  fontSize: 16,
                            fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

