import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/data/screens/notifications/widgets/notification_filter_widget.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/data/screens/street_view/views/street_view_screen.dart';
import 'package:uconnect/data/screens/map/utils/coordinate_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/utils/responsive_helper.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uconnect/utils/translation_helper.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  var _isLoading = true;
  int _expandedCardIndex = -1;

  bool? read; // Adicione na classe EventsData

  List<EventsData> eventList = [];
  
  // Filtros
  String? _selectedVehicleId;
  String? _selectedEventType;
  DateTime? _fromDate;
  DateTime? _toDate;
  
  List<EventsData> get _filteredEvents {
    List<EventsData> events = StaticVarMethod.eventList;
    
    // Filtro por veículo
    if (_selectedVehicleId != null && _selectedVehicleId!.isNotEmpty) {
      events = events.where((e) => 
        e.deviceId?.toString() == _selectedVehicleId
      ).toList();
    }
    
    // Filtro por tipo de evento
    if (_selectedEventType != null && _selectedEventType!.isNotEmpty) {
      events = events.where((e) {
        final type = e.type?.toLowerCase() ?? '';
        final name = e.name?.toLowerCase() ?? '';
        
        switch (_selectedEventType) {
          case 'Velocidade':
          case 'Speed':
            return type.contains('speed') || type.contains('overspeed');
          case 'Custom':
            return type.contains('custom');
          case 'Ignição Desligada':
          case 'Ignition Off':
            return type.contains('ignition') && (name.contains('off') || name.contains('deslig'));
          case 'Ignição Ligada':
          case 'Ignition On':
            return type.contains('ignition') && (name.contains('on') || name.contains('lig'));
          case 'Âncora Ativa':
          case 'Anchor Active':
            return type.contains('anchor') && (name.contains('active') || name.contains('ativ'));
          case 'Âncora Desativada':
          case 'Anchor Deactivated':
            return type.contains('anchor') && (name.contains('deactive') || name.contains('desativ'));
          case 'Bloqueio':
          case 'Lock':
            return type.contains('lock') || name.contains('block') || name.contains('bloqueio');
          case 'Desbloqueio':
          case 'Unlock':
            return type.contains('unlock') || name.contains('unblock') || name.contains('desbloqueio');
          case 'Offline':
            return type.contains('offline') || name.contains('offline');
          default:
            return true;
        }
      }).toList();
    }
    
    // Filtro por data
    if (_fromDate != null) {
      events = events.where((e) {
        try {
          final eventDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(e.time ?? '');
          return eventDate.isAfter(_fromDate!.subtract(Duration(days: 1))) ||
                 eventDate.isAtSameMomentAs(_fromDate!);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    
    if (_toDate != null) {
      events = events.where((e) {
        try {
          final eventDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(e.time ?? '');
          return eventDate.isBefore(_toDate!.add(Duration(days: 1))) ||
                 eventDate.isAtSameMomentAs(_toDate!);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    
    return events;
  }

  
  @override
  Widget build(BuildContext context) {
    //return noNotificationScreen();
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.white,
      appBar: StandardHeader(
        title: TranslationHelper.translateSync(context, 'Central de Notificações', 'Notifications Centre'),
        icon: Icons.notifications,
        actions: [
          Builder(
            builder: (context) {
              final colorProvider = Provider.of<ColorProvider>(context);
              return IconButton(
                onPressed: () {
                  getnotiList(); // Recarregar notificações
                },
                icon: Icon(Icons.refresh, color: colorProvider.primaryColor),
                tooltip: TranslationHelper.translateSync(context, 'Atualizar notificações', 'Refresh notifications'),
              );
            },
          ),
          Builder(
            builder: (context) {
              final colorProvider = Provider.of<ColorProvider>(context);
              return IconButton(
                onPressed: () {
                  setState(() {
                    for (var e in StaticVarMethod.eventList) {
                      e.read = true;
                    }
                    StaticVarMethod.notificationCount = 0;
                  });
                  saveReadNotifications();
                },
                icon: Icon(Icons.done_all, color: colorProvider.primaryColor),
                tooltip: TranslationHelper.translateSync(context, 'Marcar todas como lidas', 'Mark all as read'),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: Column(
        children: [
          // Filtro
          NotificationFilterWidget(
            selectedVehicleId: _selectedVehicleId,
            selectedEventType: _selectedEventType,
            fromDate: _fromDate,
            toDate: _toDate,
            onVehicleChanged: (value) {
              setState(() {
                _selectedVehicleId = value;
              });
            },
            onEventTypeChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
            },
            onFromDateChanged: (value) {
              setState(() {
                _fromDate = value;
              });
            },
            onToDateChanged: (value) {
              setState(() {
                _toDate = value;
              });
            },
          ),
          // Lista de notificações
          Expanded(
            child: _filteredEvents.isNotEmpty
                ? listView()
                : (_isLoading)
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Center(
                        child: Text(TranslationHelper.translateSync(context, 'Você ainda não tem nenhuma notificação', 'You do not have any notifications yet')),
                      ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(TranslationHelper.translateSync(context, "Notificações", "Notifications"),
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget prefixIconinfo() {
    return Container(
      height: 55,
      width: 55,
      margin: EdgeInsets.only(top: 15, left: 10),
      padding: EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child:
          Image.asset("assets/settingicon/aboutus.png", height: 55, width: 55),
      /* child: Icon(Icons.notifications,
          size: 25,
          color:Colors.grey.shade700),*/
    );
  }

 Widget listView() {
  final colorProvider = Provider.of<ColorProvider>(context);
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: GestureDetector(
          onTap: () {
  setState(() {
    for (var e in _filteredEvents) {
      e.read = true;
    }
    StaticVarMethod.notificationCount = 0;
  });
  saveReadNotifications();
},

          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.done_all, color: colorProvider.primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                TranslationHelper.translateSync(context, 'Marcar todas como lidas', 'Mark all as read'),
                style: TextStyle(
                  color: colorProvider.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _filteredEvents.length,
          // Otimizações para dispositivos fracos
          cacheExtent: 200, // Cache menor para economizar memória
          addAutomaticKeepAlives: false, // Não manter widgets vivos quando fora da tela
          addRepaintBoundaries: true, // Adicionar limites de repintura para melhor performance
          itemBuilder: (BuildContext context, int index) {
            return _listViewItems(index);
          },
        ),
      ),
    ],
  );
}

  Widget _listViewItems(int index) {
    final colorProvider = Provider.of<ColorProvider>(context);
    final item = _filteredEvents[index];
    final isRead = item.read == true;

    // Parse da data
    DateTime dateTime;
    try {
      dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(item.time.toString());
    } catch (e) {
      dateTime = DateTime.now();
    }
    
    final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    final String formattedTime = DateFormat('HH:mm:ss').format(dateTime);
    final String formattedDateTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

    final bool isExpanded = _expandedCardIndex == index;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.grey.shade300 : colorProvider.primaryColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho clicável - PARTE NÃO EXPANDIDA
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedCardIndex = isExpanded ? -1 : index;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: colorProvider.primaryColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome do Veículo
                          Text(
                            item.deviceName ?? TranslationHelper.translateSync(context, 'Veículo Desconhecido', 'Unknown Vehicle'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          // Tipo de Evento
                          Text(
                            item.name ?? TranslationHelper.translateSync(context, 'Evento', 'Event'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorProvider.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: colorProvider.primaryColor,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Divider(height: 1),
                SizedBox(height: 8),
                // Informações principais (sempre visíveis)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: colorProvider.primaryColor),
                    SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 14, color: colorProvider.primaryColor),
                    SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                // Endereço (se disponível) ou coordenadas
                FutureBuilder<String>(
                  future: item.address != null && item.address.toString().isNotEmpty && item.address.toString() != 'null'
                      ? Future.value(item.address.toString())
                      : (item.latitude != null && item.longitude != null
                          ? gpsapis.geocode(item.latitude.toString(), item.longitude.toString())
                          : Future.value(TranslationHelper.translateSync(context, 'Endereço não disponível', 'Address not available'))),
                  builder: (context, snapshot) {
                    final address = snapshot.data ?? TranslationHelper.translateSync(context, 'Carregando endereço...', 'Loading address...');
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 14, color: colorProvider.primaryColor),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.length > 50 ? '${address.substring(0, 50)}...' : address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Conteúdo expandido
          if (isExpanded) ...[
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 10),
            // Mensagem do evento
            _infoRow(Icons.article_outlined, item.message ?? TranslationHelper.translateSync(context, 'Sem mensagem', 'No message')),
            // Velocidade
            if (item.speed != null)
              _infoRow(Icons.speed, '${TranslationHelper.translateSync(context, 'Velocidade', 'Speed')}: ${item.speed?.toStringAsFixed(0)} km/h'),
            // Coordenadas
            _infoRow(Icons.location_on_outlined,
                'Lat: ${item.latitude?.toStringAsFixed(6)}, Lng: ${item.longitude?.toStringAsFixed(6)}'),
            // Data e hora completa
            _infoRow(Icons.access_time, '${TranslationHelper.translateSync(context, 'Data/Hora', 'Date/Time')}: $formattedDateTime'),
            SizedBox(height: 12),
            // Endereço completo na parte expandida
            FutureBuilder<String>(
              future: item.address != null && item.address.toString().isNotEmpty && item.address.toString() != 'null'
                  ? Future.value(item.address.toString())
                  : (item.latitude != null && item.longitude != null
                      ? gpsapis.geocode(item.latitude.toString(), item.longitude.toString())
                      : Future.value(TranslationHelper.translateSync(context, 'Endereço não disponível', 'Address not available'))),
              builder: (context, snapshot) {
                final fullAddress = snapshot.data ?? TranslationHelper.translateSync(context, 'Carregando endereço...', 'Loading address...');
                return _infoRow(Icons.home, '${TranslationHelper.translateSync(context, 'Endereço', 'Address')}: $fullAddress');
              },
            ),
            SizedBox(height: 16),
            // Botão Compartilhar Localização
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareEventLocation(item),
                icon: Icon(Icons.share, color: Colors.white),
                label: Text(
                  TranslationHelper.translateSync(context, 'Compartilhar Localização', 'Share Location'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorProvider.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            // STREET VIEW
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, size: 20, color: colorProvider.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        TranslationHelper.translateSync(context, "Visualização da rua", "Street View"),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorProvider.primaryColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        if (item.latitude != null && item.longitude != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StreetViewScreen(
                                initialPosition: LatLng(
                                  CoordinateUtils.toDouble(item.latitude) ?? 0.0,
                                  CoordinateUtils.toDouble(item.longitude) ?? 0.0,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          Image.network(
                            'https://maps.googleapis.com/maps/api/streetview?size=400x200&location=${item.latitude},${item.longitude}&key=AIzaSyAD3aCRNglXgQNU1vnQAbC14YQyrcLH4V0&heading=345&pitch=0',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on, color: colorProvider.primaryColor, size: 32),
                                    SizedBox(height: 8),
                                    Text(
                                      TranslationHelper.translateSync(context, 'Street View não disponível', 'Street View not available'),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Função para compartilhar localização do evento
  Future<void> _shareEventLocation(EventsData item) async {
    try {
      // Buscar endereço completo
      String address = TranslationHelper.translateSync(context, 'Endereço não disponível', 'Address not available');
      if (item.address != null && item.address.toString().isNotEmpty && item.address.toString() != 'null') {
        address = item.address.toString();
      } else if (item.latitude != null && item.longitude != null) {
        try {
          address = await gpsapis.geocode(item.latitude.toString(), item.longitude.toString());
          address = address.replaceAll('"', '');
        } catch (e) {
          address = 'Lat: ${item.latitude?.toStringAsFixed(6)}, Lng: ${item.longitude?.toStringAsFixed(6)}';
        }
      }

      // Formatar data
      DateTime dateTime;
      try {
        dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(item.time.toString());
      } catch (e) {
        dateTime = DateTime.now();
      }
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

      // Criar link do Google Maps
      final googleMapsLink = item.latitude != null && item.longitude != null
          ? 'https://www.google.com/maps?q=${item.latitude},${item.longitude}'
          : '';

      // Montar mensagem completa
      final isEnglish = Localizations.localeOf(context).languageCode == 'en';
      final message = isEnglish
          ? '''📍 *TRACKING EVENT*

🚗 *Vehicle:* ${item.deviceName ?? 'Not informed'}
📋 *Event Type:* ${item.name ?? 'Not informed'}
📝 *Message:* ${item.message ?? 'No message'}
${item.speed != null ? '⚡ *Speed:* ${item.speed?.toStringAsFixed(0)} km/h' : ''}

📍 *Location:*
$address
${item.latitude != null && item.longitude != null ? 'Coordinates: ${item.latitude?.toStringAsFixed(6)}, ${item.longitude?.toStringAsFixed(6)}' : ''}

🕐 *Date/Time:* $formattedDate

${googleMapsLink.isNotEmpty ? '🗺️ View on map:\n$googleMapsLink' : ''}

---
*Sent via U-Connect - GPS Tracking System*'''
          : '''📍 *EVENTO DE RASTREAMENTO*

🚗 *Veículo:* ${item.deviceName ?? 'Não informado'}
📋 *Tipo de Evento:* ${item.name ?? 'Não informado'}
📝 *Mensagem:* ${item.message ?? 'Sem mensagem'}
${item.speed != null ? '⚡ *Velocidade:* ${item.speed?.toStringAsFixed(0)} km/h' : ''}

📍 *Localização:*
$address
${item.latitude != null && item.longitude != null ? 'Coordenadas: ${item.latitude?.toStringAsFixed(6)}, ${item.longitude?.toStringAsFixed(6)}' : ''}

🕐 *Data/Hora:* $formattedDate

${googleMapsLink.isNotEmpty ? '🗺️ Visualizar no mapa:\n$googleMapsLink' : ''}

---
*Enviado via U-Connect - Sistema de Rastreamento GPS*''';

      await Share.share(
        message,
        subject: isEnglish 
            ? 'Tracking Event - ${item.deviceName}'
            : 'Evento de Rastreamento - ${item.deviceName}',
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao compartilhar localização: $e', 'Error sharing location: $e'),
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

Widget _infoRow(IconData icon, String text) {
  final colorProvider = Provider.of<ColorProvider>(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: colorProvider.primaryColor),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
          ),
        ),
      ],
    ),
  );
}


  Widget prefixIcon(int index) {
    return Container(
      height: 45,
      width: 45,
      margin: const EdgeInsets.only(top: 15, left: 10),
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Image.asset("assets/images/alarmnotification96by96.png",
          height: 55, width: 55),
      
    );
  }

  Widget DeleteIcon(int index) {
    return Container(
     
        );
  }

  Widget message(int index) {
    double textsize = 12;

    return Container(
      padding: const EdgeInsets.only(right: 1, top: 10, bottom: 5),
      child: RichText(
        maxLines: 5,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
            text:
                TranslationHelper.translateSync(context, 
                  'Seu dispositivo ${StaticVarMethod.eventList[index].deviceName} gerou eventos de (${StaticVarMethod.eventList[index].name})',
                  'Your device ${StaticVarMethod.eventList[index].deviceName} generated events of (${StaticVarMethod.eventList[index].name})'),
            style: TextStyle(
              fontSize: textsize,
              color: Colors.grey.shade700,
              //fontWeight: FontWeight.bold
            ),
            children: [
             
            ]),
      ),
    );
  }

  Widget timeAndDate(int index) {
    // Parse the original date string using DateFormat
    DateFormat inputFormat = DateFormat('yyyy-mm-dd hh:mm:ss');
    DateTime dateTime =
        inputFormat.parse(StaticVarMethod.eventList[index].time.toString());

    // Format the date to the Brazilian standard
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);

    return Container(
      padding: const EdgeInsets.only(right: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> getnotiList() async {
    print("📋 Buscando lista de notificações...");
    _isLoading = true;
    
    // Verificar se user_api_hash está disponível
    if (StaticVarMethod.user_api_hash == null || StaticVarMethod.user_api_hash!.isEmpty) {
      print("❌ user_api_hash não disponível");
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro: Usuário não autenticado', 'Error: User not authenticated'),
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      gpsapis api = gpsapis();
      print("📡 Chamando API getEventsList...");
      
      final result = await api.getEventsList(StaticVarMethod.user_api_hash);
      
      // Verificar se o resultado é null ou vazio
      if (result == null) {
        print("⚠️ API retornou null");
        eventList = [];
      } else {
        eventList = result;
        print("✅ ${eventList.length} notificações recebidas");
      }
      
      if (eventList.isNotEmpty) {
        StaticVarMethod.eventList = eventList;
        StaticVarMethod.notificationCount = eventList.length;
        print("✅ Notificações atualizadas: ${eventList.length}");
      } else {
        StaticVarMethod.eventList.clear();
        StaticVarMethod.notificationCount = 0;
        print("ℹ️ Nenhuma notificação encontrada");
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Carregar notificações lidas após atualizar a lista
      loadReadNotifications();
      
    } catch (e, stackTrace) {
      print("❌ Erro ao buscar notificações: $e");
      print("Stack trace: $stackTrace");
      
      Fluttertoast.showToast(
        msg: TranslationHelper.translateSync(context, 'Erro ao buscar notificações: ${e.toString()}', 'Error loading notifications: ${e.toString()}'),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
      
      setState(() {
        _isLoading = false;
        eventList = [];
        StaticVarMethod.eventList = [];
        StaticVarMethod.notificationCount = 0;
      });
    }
  }

@override
void initState() {
  super.initState();
  _isLoading = true;

  // Sempre tentar carregar notificações ao abrir a tela
  WidgetsBinding.instance.addPostFrameCallback((_) {
    getnotiList();
  });
}


  Widget noNotificationScreen() {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    final pageTitle = Padding(
      padding: EdgeInsets.only(top: 1.0, bottom: 30.0),
      child: Text(
        TranslationHelper.translateSync(context, "Notificações", "Notifications"),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 40.0,
        ),
      ),
    );

    final image = Image.asset("assets/images/empty.png");

    final notificationHeader = Container(
      padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
      child: Text(
        TranslationHelper.translateSync(context, "Nenhuma Notificação Nova", "No New Notification"),
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0),
      ),
    );
    final notificationText = Text(
      TranslationHelper.translateSync(context, "Você atualmente não tem nenhuma notificação não lida.", "You currently do not have any unread notifications."),
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
        color: Colors.grey.withOpacity(0.6),
      ),
      textAlign: TextAlign.center,
    );

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(
          top: 70.0,
          left: 30.0,
          right: 30.0,
          bottom: 30.0,
        ),
        height: deviceHeight,
        width: deviceWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            pageTitle,
            SizedBox(
              height: deviceHeight * 0.1,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[image, notificationHeader, notificationText],
            ),
          ],
        ),
      ),
    );
  }


Future<void> saveReadNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  // Isolar por userHash
  final userHash = prefs.getString('user_api_hash') ?? 'default';
  final key = 'read_notifications_$userHash';
  
  List<String> readIds = StaticVarMethod.eventList
      .where((e) => e.read == true)
      .map((e) => e.id.toString())
      .toList();
  await prefs.setStringList(key, readIds);
  print('✅ Notificações lidas salvas para userHash: ${userHash.substring(0, 10)}...');
}

Future<void> loadReadNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  // Isolar por userHash
  final userHash = prefs.getString('user_api_hash') ?? 'default';
  final key = 'read_notifications_$userHash';
  
  List<String>? readIds = prefs.getStringList(key);

  if (readIds != null) {
    for (var e in StaticVarMethod.eventList) {
      if (readIds.contains(e.id.toString())) {
        e.read = true;
      }
    }
  }
}


}
