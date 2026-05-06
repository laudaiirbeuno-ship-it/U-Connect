import 'dart:core';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/utils/command_logic.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:uconnect/data/screens/street_view/views/street_view_screen.dart';
import 'package:uconnect/data/screens/map/widgets/create_anchor_modal.dart';
import 'package:uconnect/utils/translation_helper.dart';

class VehicleCard extends StatefulWidget {
  final deviceItems vehicle;
  final bool isModal; // Indica se está sendo usado como modal

  const VehicleCard({Key? key, required this.vehicle, this.isModal = false}) : super(key: key);

  @override
  _VehicleCardState createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  double _dragPosition = 0.0;
  bool _hasActiveAnchor = false;
  bool _isCheckingAnchor = false;

  // Obter a placa do carro - mesma lógica da lista de veículos
  String _getPlateNumber(deviceItems vehicle) {
    if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty) {
      return vehicle.plateNumber!;
    } else if (vehicle.deviceData?.plateNumber != null &&
        vehicle.deviceData!.plateNumber!.isNotEmpty) {
      return vehicle.deviceData!.plateNumber!;
    } else if (vehicle.deviceData?.registrationNumber != null &&
        vehicle.deviceData!.registrationNumber!.isNotEmpty) {
      return vehicle.deviceData!.registrationNumber!;
    } else if (vehicle.name != null && vehicle.name!.contains(' ')) {
      final nameParts = vehicle.name!.split(' ');
      if (nameParts.length >= 2) {
        final possiblePlate = nameParts[1];
        if (RegExp(r'[A-Za-z].*\d|\d.*[A-Za-z]').hasMatch(possiblePlate)) {
          return possiblePlate;
        }
      }
    }
    return vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle');
  }

  /// Formata o nome do motorista: Primeiro Nome + Primeira Inicial do Sobrenome
  /// Exemplo: "João Silva" -> "João S."
  String _formatDriverName(String fullName) {
    if (fullName.isEmpty || fullName.toLowerCase() == 'null' || fullName.toLowerCase() == 'sem motorista') {
      return TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    }

    // Remove espaços extras e divide o nome
    final parts = fullName.trim().split(' ').where((part) => part.isNotEmpty).toList();
    
    if (parts.isEmpty) {
      return TranslationHelper.translateSync(context, 'Sem motorista', 'No driver');
    }

    // Se tiver apenas um nome, retorna ele
    if (parts.length == 1) {
      return parts[0];
    }

    // Primeiro nome + primeira inicial do sobrenome
    final firstName = parts[0];
    final lastNameInitial = parts[1][0].toUpperCase();
    
    return '$firstName $lastNameInitial.';
  }

  // Verificar status de ignição - mesma lógica da lista de veículos
  bool _isIgnitionOn(deviceItems vehicle) {
    final String xmlData = vehicle.deviceData?.traccar?.other ?? '';
    return xmlData.contains("<ignition>true</ignition>");
  }

  // Verificar se está offline
  bool _isOffline(deviceItems vehicle) {
    return vehicle.online?.toLowerCase().contains("offline") ?? false;
  }

  void _closeCard(BuildContext context) {
    if (widget.isModal) {
      Navigator.pop(context);
    } else {
      final mapController = context.read<MapController>();
      mapController.closeVehicleCard();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAnchorStatus();
  }

  Future<void> _checkAnchorStatus() async {
    if (_isCheckingAnchor) return;
    
    _isCheckingAnchor = true;
    
    try {
      // Verificar no MapController primeiro (rápido)
      final mapController = context.read<MapController>();
      bool hasAnchor = mapController.hasActiveAnchor(widget.vehicle.id.toString());
      
      // Se não encontrou no MapController, verificar na API (assíncrono)
      if (!hasAnchor) {
        hasAnchor = await _checkAnchorInAPI();
      }
      
      if (mounted) {
        setState(() {
          _hasActiveAnchor = hasAnchor;
          _isCheckingAnchor = false;
        });
      }
    } catch (e) {
      print('Erro ao verificar âncora: $e');
      if (mounted) {
        setState(() {
          _isCheckingAnchor = false;
        });
      }
    }
  }

  Future<bool> _checkAnchorInAPI() async {
    try {
      // Verificar via geofences (método atual)
      final geofences = await gpsapis.getGeoFences(lang: 'br');
      if (geofences != null && geofences.isNotEmpty) {
        final deviceId = widget.vehicle.id;
        final deviceName = widget.vehicle.name?.toLowerCase() ?? '';
        
        return geofences.any((geofence) {
          final isAnchor = geofence.isAnchor;
          final isActive = geofence.isActive;
          final isCircle = geofence.type == 'circle';
          
          if (!isAnchor || !isActive || !isCircle) return false;
          
          // Verificar por device_id
          if (geofence.device_id == deviceId) {
            return true;
          }
          
          // Se device_id é null, verificar por nome ou palavras-chave
          if (geofence.device_id == null) {
            final geofenceName = geofence.name?.toLowerCase() ?? '';
            
            if (deviceName.isNotEmpty && geofenceName.contains(deviceName)) {
              return true;
            }
            
            if (geofenceName.contains('antifurto') || geofenceName.contains('ancora')) {
              return true;
            }
          }
          
          return false;
        });
      }
    } catch (e) {
      print('Erro ao verificar âncora na API: $e');
    }
    
    return false;
  }


  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    MapController? mapController;
    try {
      mapController = context.read<MapController>();
    } catch (e) {
      // MapController não disponível quando usado como modal
      mapController = null;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.75; // 75% da largura da tela (igual para modal e mapa)

    Widget cardContent = Container(
      width: widget.isModal ? double.infinity : cardWidth, // No modal, ocupa toda largura do Container pai
      constraints: widget.isModal ? null : BoxConstraints(maxWidth: 360, minWidth: 320),
      margin: widget.isModal 
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: 5), // Margem adequada para posicionamento otimizado
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER - Fundo cor principal com imagem e nome
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Menor padding vertical
                  decoration: BoxDecoration(
                    color: colorProvider.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Alinhar no centro vertical
                    children: [
                      // IMAGEM DO VEÍCULO EM CÍRCULO (lado esquerdo)
                      Builder(
                        builder: (context) {
                          final String baseUrl = "https://web.unnicatelemetria.com.br/";
                          final String? imagePath = widget.vehicle.image;
                          final String imageUrl = imagePath != null && imagePath.trim().isNotEmpty
                              ? "$baseUrl$imagePath"
                              : "$baseUrl/images/device_icons/rotating/1.png";
                          
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Container(
                                color: Colors.white,
                                child: Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: colorProvider.primaryColor,
                                      child: Icon(Icons.directions_car, color: Colors.white, size: 28),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      // INFORMAÇÕES À DIREITA (alinhadas verticalmente no meio)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Centralizar verticalmente
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nome do Veículo
                            Text(
                              widget.vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle'),
                              style: TextStyle(
                                fontSize: 16, // Diminuído de 18
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            // Placa
                            Text(
                              '${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: ${_getPlateNumber(widget.vehicle)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            // Status de ignição e velocidade (badges iguais à lista)
                            Row(
                              children: [
                                // Status de ignição
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _isOffline(widget.vehicle) 
                                        ? Colors.red 
                                        : (_isIgnitionOn(widget.vehicle) 
                                            ? Colors.green.withOpacity(0.3) 
                                            : Colors.white.withOpacity(0.3)),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _isOffline(widget.vehicle) 
                                          ? Colors.red 
                                          : (_isIgnitionOn(widget.vehicle) ? Colors.green : Colors.white70),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isOffline(widget.vehicle) 
                                            ? Icons.power_off 
                                            : Icons.power,
                                        size: 12,
                                        color: _isOffline(widget.vehicle) 
                                            ? Colors.white 
                                            : (_isIgnitionOn(widget.vehicle) ? Colors.green : Colors.white70),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        _isOffline(widget.vehicle) 
                                            ? TranslationHelper.translateSync(context, 'Desligada', 'Off') 
                                            : (_isIgnitionOn(widget.vehicle) ? TranslationHelper.translateSync(context, 'Ligada', 'On') : TranslationHelper.translateSync(context, 'Desligada', 'Off')),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isOffline(widget.vehicle) 
                                              ? Colors.white 
                                              : (_isIgnitionOn(widget.vehicle) ? Colors.green : Colors.white70),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Velocidade
                                if (widget.vehicle.speed != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white70,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          '${(widget.vehicle.speed as num).toStringAsFixed(1)} km/h',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Botão fechar
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => _closeCard(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // STREET VIEW - Abaixo do cabeçalho
                if (widget.vehicle.lat != null && widget.vehicle.lng != null)
                  Container(
                    color: Colors.white,
                    child: Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                          top: 16,     // margem abaixo do cabeçalho
                          left: 16,    // margem lateral esquerda
                          right: 16,   // margem lateral direita
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,   // sombra leve
                              blurRadius: 8,           // suavidade da sombra
                              offset: Offset(0, 3),    // posição da sombra
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StreetViewScreen(
                                    initialPosition: LatLng(
                                      CoordinateUtils.toDouble(widget.vehicle.lat) ?? 0.0,
                                      CoordinateUtils.toDouble(widget.vehicle.lng) ?? 0.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 135,
                                  child: Image.network(
                                    'https://maps.googleapis.com/maps/api/streetview?size=400x200&location=${widget.vehicle.lat},${widget.vehicle.lng}&key=AIzaSyAD3aCRNglXgQNU1vnQAbC14YQyrcLH4V0&heading=345&pitch=0',
                                    height: 135,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 135,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.streetview, size: 40, color: Colors.grey.shade400),
                                            SizedBox(height: 6),
                                            Text(
                                              TranslationHelper.translateSync(context, 'Street View não disponível', 'Street View not available'),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 135,
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: colorProvider.primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Overlay indicando que é clicável
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.streetview, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          TranslationHelper.translateSync(context, 'Toque para ver', 'Tap to view'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Botão de compartilhar no canto superior direito
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _shareLocation(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),

                // BODY - Informações do veículo
                Container(
                  color: Colors.white,
                  child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do Motorista
                      _buildInfoRow(
                        icon: Icons.person,
                        label: TranslationHelper.translateSync(context, 'Motorista', 'Driver'),
                        value: (widget.vehicle.driver != null && 
                                widget.vehicle.driver!.isNotEmpty && 
                                widget.vehicle.driver!.toLowerCase() != 'null')
                            ? _formatDriverName(widget.vehicle.driver!)
                            : TranslationHelper.translateSync(context, 'Sem motorista', 'No driver'),
                        colorProvider: colorProvider,
                      ),
                      SizedBox(height: 10),
                      // KM Percorrido
                      if (widget.vehicle.totalDistance != null)
                        _buildInfoRow(
                          icon: Icons.route,
                          label: TranslationHelper.translateSync(context, 'KM percorrido', 'Distance traveled'),
                          value: '${widget.vehicle.totalDistance?.toStringAsFixed(1) ?? '0.0'} km',
                          colorProvider: colorProvider,
                        ),
                      if (widget.vehicle.totalDistance != null) SizedBox(height: 10),
                      // Consumo de Combustível
                      if (widget.vehicle.deviceData?.fuelPerKm != null && 
                          widget.vehicle.deviceData!.fuelPerKm!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.local_gas_station,
                          label: TranslationHelper.translateSync(context, 'Consumo', 'Consumption'),
                          value: '${widget.vehicle.deviceData!.fuelPerKm} L/km',
                          colorProvider: colorProvider,
                        ),
                      if (widget.vehicle.deviceData?.fuelPerKm != null && 
                          widget.vehicle.deviceData!.fuelPerKm!.isNotEmpty) SizedBox(height: 10),
                      // Movimento
                      _buildInfoRow(
                        icon: Icons.directions_run,
                        label: TranslationHelper.translateSync(context, 'Movimento', 'Movement'),
                        value: (widget.vehicle.speed != null && widget.vehicle.speed! > 0) 
                            ? TranslationHelper.translateSync(context, 'Em movimento', 'Moving') 
                            : TranslationHelper.translateSync(context, 'Parado', 'Stopped'),
                        colorProvider: colorProvider,
                      ),
                      SizedBox(height: 10),
                      // Última posição
                      if (widget.vehicle.time != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: colorProvider.primaryColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.vehicle.time ?? TranslationHelper.translateSync(context, '--', '--'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (widget.vehicle.time != null) SizedBox(height: 10),
                      // Endereço
                      if (widget.vehicle.address != null &&
                          widget.vehicle.address != '-' &&
                          widget.vehicle.address!.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, size: 18, color: colorProvider.primaryColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.vehicle.address!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                    ),
                  ),
                ),

                // Linha separadora
                Container(
                  color: Colors.white,
                  child: Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                ),

                // FOOTER - Botões de ação
                Container(
                  margin: EdgeInsets.only(bottom: 8), // Margem reduzida abaixo dos botões
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Padding reduzido
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botão Criar/Desativar Antifurto (apenas no mapa principal, não no modal)
                      if (!widget.isModal && mapController != null)
                        Expanded(
                          child: _buildActionButton(
                            context: context,
                            icon: _hasActiveAnchor 
                                ? Icons.security 
                                : Icons.security_outlined,
                            label: _hasActiveAnchor 
                                ? TranslationHelper.translateSync(context, 'Desativar Antifurto', 'Deactivate Antitheft') 
                                : TranslationHelper.translateSync(context, 'Antifurto', 'Antitheft'),
                            onTap: () {
                              // Sempre abrir o modal, que mostrará o botão correto baseado em hasActiveAnchor
                              _handleToggleAnchor(context, mapController!);
                            },
                            colorProvider: colorProvider,
                            isPrimary: true,
                          ),
                        ),
                      if (!widget.isModal && mapController != null) SizedBox(width: 12),
                      // Botão Bloquear Veículo (sempre visível) - MESMA LÓGICA DO CÓDIGO FORNECIDO
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.lock,
                          label: TranslationHelper.translateSync(context, 'Bloquear', 'Lock'),
                          onTap: () {
                            if (mapController != null) {
                              _handleBlockVehicle(context, mapController);
                            }
                          },
                          colorProvider: colorProvider,
                          isPrimary: false,
                          customColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );

    // Se for modal, retornar apenas o cardContent
    if (widget.isModal) {
      return SingleChildScrollView(child: cardContent);
    }

    // Se não for modal, retornar envolvido na estrutura original
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragPosition += details.delta.dy;
          if (_dragPosition > 100 && mapController != null) {
            mapController.closeVehicleCard();
          }
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragPosition > 50 && mapController != null) {
          mapController.closeVehicleCard();
        } else {
          setState(() {
            _dragPosition = 0.0;
          });
        }
      },
      child: Center(
        child: Transform.translate(
          offset: Offset(0, _dragPosition.clamp(0.0, 100.0)),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorProvider colorProvider,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorProvider.primaryColor),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorProvider colorProvider,
    required bool isPrimary,
    Color? customColor,
  }) {
    final buttonColor = customColor ?? (isPrimary
        ? colorProvider.primaryColor
        : colorProvider.secondaryColor);
    
    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLocation(BuildContext context) async {
    // Verificar se tem coordenadas
    if (widget.vehicle.lat == null || widget.vehicle.lng == null) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Coordenadas não disponíveis para compartilhar', 'Coordinates not available to share'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    final vehicleName = widget.vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle');
    final plateNumber = _getPlateNumber(widget.vehicle);
    final position = CoordinateUtils.toLatLng(widget.vehicle.lat, widget.vehicle.lng);
    if (position == null) return;
    final lat = position.latitude;
    final lng = position.longitude;
    
    // Criar link do Google Maps
    final googleMapsLink = 'https://www.google.com/maps?q=$lat,$lng';
    
    // Formatar coordenadas
    final coordinates = 'Lat: ${lat.toStringAsFixed(6)}, Long: ${lng.toStringAsFixed(6)}';
    
    // Montar mensagem profissional e completa
    final message = '''📍 ${TranslationHelper.translateSync(context, 'Olá, essa é minha localização atual:', 'Hello, this is my current location:')}

🚗 ${TranslationHelper.translateSync(context, 'Veículo', 'Vehicle')}: $vehicleName
🔢 ${TranslationHelper.translateSync(context, 'Placa', 'Plate')}: $plateNumber
📍 ${TranslationHelper.translateSync(context, 'Coordenadas', 'Coordinates')}: $coordinates

🗺️ ${TranslationHelper.translateSync(context, 'Visualizar no mapa:', 'View on map:')}
$googleMapsLink

---
${TranslationHelper.translateSync(context, 'Enviado via U-Connect - Sistema de Rastreamento GPS', 'Sent via U-Connect - GPS Tracking System')}''';

    try {
      await Share.share(
        message,
        subject: '${TranslationHelper.translateSync(context, 'Localização do veículo', 'Vehicle location')} $vehicleName',
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao compartilhar localização', 'Error sharing location'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // === REMOVIDO: _showBlockModal - Agora usa commandDialog diretamente (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===

  // === MÉTODO DE BLOQUEIO (MESMA LÓGICA DO CÓDIGO FORNECIDO) ===
  Future<void> _handleBlockVehicle(
      BuildContext context, MapController mapController) async {
    try {
      // Definir o deviceId para o sistema de comandos (MESMA LÓGICA DO CÓDIGO FORNECIDO)
      StaticVarMethod.deviceId = widget.vehicle.id.toString();
      StaticVarMethod.deviceName = widget.vehicle.name ?? TranslationHelper.translateSync(context, 'Veículo', 'Vehicle');

      // Buscar comandos salvos para o dispositivo (MESMA LÓGICA DO CÓDIGO FORNECIDO)
      await getCommands();

      // Mostrar dialog com comandos disponíveis usando o modal (MESMA LÓGICA DO CÓDIGO FORNECIDO)
      commandDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${TranslationHelper.translateSync(context, 'Erro ao executar bloqueio', 'Error executing lock')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleToggleAnchor(
      BuildContext context, MapController mapController) async {
    // Verificar se tem coordenadas
    if (widget.vehicle.lat == null || widget.vehicle.lng == null) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Coordenadas não disponíveis', 'Coordinates not available'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // Atualizar status da âncora antes de abrir o modal
    await _checkAnchorStatus();

    // Usar o modal separado CreateAnchorModal
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CreateAnchorModal(
          device: widget.vehicle,
          hasActiveAnchor: _hasActiveAnchor,
          onCreate: (name, radius, color, speedLimit, movementAllowed, {autoBlock, alertIgnition, alertSpeed}) async {
            // Verificar novamente se já tem âncora ativa antes de criar
            await _checkAnchorStatus();
            
            if (_hasActiveAnchor) {
              Fluttertoast.showToast(
                msg: TranslationHelper.translateSync(context, 'Este veículo já possui uma âncora ativa. Desative a âncora existente antes de criar uma nova.', 'This vehicle already has an active anchor. Deactivate the existing anchor before creating a new one.'),
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
              return;
            }
            
            // Aguardar um pouco para garantir que o modal foi fechado completamente
            await Future.delayed(Duration(milliseconds: 300));
            
            // Criar antifurto usando a mesma lógica do main_map_screen
            try {
              // Converter coordenadas
              final position = CoordinateUtils.toLatLng(widget.vehicle.lat, widget.vehicle.lng);
              if (position == null) {
                Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, 'Erro ao processar coordenadas', 'Error processing coordinates'),
                  backgroundColor: Colors.orange,
                );
                return;
              }

              final lat = position.latitude;
              final lng = position.longitude;

              if (lat == 0.0 && lng == 0.0) {
                Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, 'Coordenadas inválidas', 'Invalid coordinates'),
                  backgroundColor: Colors.orange,
                );
                return;
              }

              // Criar geofence via API
              final result = await gpsapis.addGeofence(
                name: name,
                active: true,
                device_id: widget.vehicle.id,
                type: 'circle',
                lat: lat,
                lng: lng,
                radius: radius.toDouble(),
                speed_limit: speedLimit,
                movement_allowed: movementAllowed,
                polygon_color: color,
                lang: 'br',
              );

              if (result != null && result['status'] == 1) {
                // Adicionar círculo no mapa via MapController
                final geofenceId = result['geofence_id'] ?? result['id'];
                if (geofenceId != null) {
                  mapController.addAnchorCircle(
                    widget.vehicle.id.toString(),
                    position,
                    radius.toDouble(),
                    geofenceId.toString(),
                    vehicleName: widget.vehicle.name,
                    vehicleAddress: widget.vehicle.address,
                    circleColor: _parseColorFromHex(color),
                  );
                }

                // Criar alerta se movement_allowed for true
                if (geofenceId != null && movementAllowed) {
                  String deviceParams = "devices[]=${widget.vehicle.id.toString()}";
                  String geofencesParams = "geofences[]=$geofenceId";
                  String commandParam = "command[active]=1&command[type]=engineStop";
                  var request = "&name=$name" +
                      "&type=geofence_out&" +
                      deviceParams +
                      "&" +
                      geofencesParams +
                      "&" +
                      commandParam;
                  await gpsapis.addAlertAncor(request);
                }

                // Chamar API get_events para gerar notificação
                try {
                  final gpsapisInstance = gpsapis();
                  await gpsapisInstance.getEvents(StaticVarMethod.user_api_hash);
                  await gpsapisInstance.getEventsList(StaticVarMethod.user_api_hash);
                } catch (e) {
                  print('⚠️ Erro ao chamar get_events: $e');
                }

                Fluttertoast.showToast(
                  msg: TranslationHelper.translateSync(context, 'Antifurto criado com sucesso!', 'Antitheft created successfully!'),
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );

                // Atualizar status da âncora após criar
                await _checkAnchorStatus();

                // Fechar o vehicle card após um pequeno delay
                await Future.delayed(Duration(milliseconds: 300));
                mapController.closeVehicleCard();
              } else {
                final errorMsg = result?['message'] ?? TranslationHelper.translateSync(context, 'Erro ao criar antifurto', 'Error creating antitheft');
                Fluttertoast.showToast(
                  msg: errorMsg.toString(),
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            } catch (e) {
              print('❌ Erro ao criar antifurto: $e');
              Fluttertoast.showToast(
                msg: 'Erro ao criar antifurto: $e',
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
            }
          },
          onDeactivate: () {
            _handleDeactivateAnchor(context, mapController);
          },
        );
      },
    );
  }

  // Função auxiliar para converter hex string para Color
  Color _parseColorFromHex(String colorHex) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.orange;
    }
  }

  Future<void> _handleDeactivateAnchor(
      BuildContext context, MapController mapController) async {
    // Verificar âncoras na API também
    try {
      final geofences = await gpsapis.getGeoFences(lang: 'br');
      if (geofences != null && geofences.isNotEmpty) {
        final deviceId = widget.vehicle.id;
        
        // Encontrar geofence de âncora ativa para este veículo
        for (var geofence in geofences) {
          final isAnchor = geofence.isAnchor;
          final isActive = geofence.isActive;
          final isCircle = geofence.type == 'circle';
          
          if (!isAnchor || !isActive || !isCircle) continue;
          
          bool matches = false;
          
          if (geofence.device_id == deviceId) {
            matches = true;
          } else if (geofence.device_id == null) {
            final geofenceName = geofence.name?.toLowerCase() ?? '';
            final deviceName = widget.vehicle.name?.toLowerCase() ?? '';
            
            if (deviceName.isNotEmpty && geofenceName.contains(deviceName)) {
              matches = true;
            } else if (geofenceName.contains('antifurto') || geofenceName.contains('ancora')) {
              matches = true;
            }
          }
          
          if (matches && geofence.id != null) {
            // Desativar geofence via API
            await gpsapis.destroyGeofence(id: geofence.id!);
            print('✅ Geofence ${geofence.id} desativada via API');
          }
        }
      }
    } catch (e) {
      print('Erro ao desativar geofence na API: $e');
    }
    
    final anchorInfo = mapController.getAnchorInfo(widget.vehicle.id.toString());

    // Mostrar confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desativar Antifurto'),
        content: Text('Deseja realmente desativar o antifurto deste veículo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Desativar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remover geofence via API
        if (anchorInfo != null) {
        await gpsapis.destroyGeofenceAncor(anchorInfo.geofenceId);
        }
        
        // Remover círculo do mapa
        mapController.removeAnchorCircle(widget.vehicle.id.toString());
        
        Fluttertoast.showToast(
          msg: 'Antifurto desativado com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: '${TranslationHelper.translateSync(context, 'Erro ao desativar antifurto', 'Error deactivating antitheft')}: $e',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

}
