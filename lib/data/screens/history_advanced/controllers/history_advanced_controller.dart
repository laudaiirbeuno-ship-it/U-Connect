import 'package:flutter/material.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/model/history.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/provider/color_provider.dart';

class HistoryAdvancedController with ChangeNotifier {
  List<AllItems> _allHistoryItems = [];
  List<EventsData> _allEvents = [];
  bool _isLoading = false;
  String? _selectedDeviceId;
  String? _selectedGroupId;
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _toDate = DateTime.now();
  TimeOfDay _fromTime = TimeOfDay.now();
  TimeOfDay _toTime = TimeOfDay.now();
  Map<String, List<HistoryEventItem>> _groupedEvents = {};
  Map<String, String> _addressCache = {};

  List<AllItems> get allHistoryItems => _allHistoryItems;
  List<EventsData> get allEvents => _allEvents;
  bool get isLoading => _isLoading;
  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedGroupId => _selectedGroupId;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  TimeOfDay get fromTime => _fromTime;
  TimeOfDay get toTime => _toTime;
  Map<String, List<HistoryEventItem>> get groupedEvents => _groupedEvents;

  // Resumo do período
  int get totalEvents => _allHistoryItems.length + _allEvents.length;
  int get totalMovements => _allHistoryItems.where((item) => item.speed != null && item.speed! > 0).length;
  int get totalStops => _allHistoryItems.where((item) => item.speed == null || item.speed == 0).length;
  int get criticalAlerts => _allEvents.where((e) => _isCriticalEvent(e.type)).length;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userApiHash = prefs.getString('user_api_hash') ?? StaticVarMethod.user_api_hash;

      if (_selectedDeviceId != null) {
        // Carregar histórico
        String fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate);
        String toDateStr = DateFormat('yyyy-MM-dd').format(_toDate);
        String fromTimeStr = '${_fromTime.hour.toString().padLeft(2, '0')}:${_fromTime.minute.toString().padLeft(2, '0')}:00';
        String toTimeStr = '${_toTime.hour.toString().padLeft(2, '0')}:${_toTime.minute.toString().padLeft(2, '0')}:00';

        final history = await gpsapis.getHistorynew(
          _selectedDeviceId!,
          fromDateStr,
          fromTimeStr,
          toDateStr,
          toTimeStr,
        );

        if (history != null && history.items != null) {
          _allHistoryItems = [];
          for (var trip in history.items!) {
            if (trip.items != null) {
              _allHistoryItems.addAll(trip.items!);
            }
          }
        }

        // Carregar eventos
        final events = await gpsapis().getEvents(userApiHash);
        if (events.items?.data != null) {
          _allEvents = events.items!.data!
              .where((e) => e.deviceId?.toString() == _selectedDeviceId)
              .where((e) {
                if (e.time == null) return false;
                try {
                  DateTime eventDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(e.time!);
                  return eventDate.isAfter(_fromDate.subtract(Duration(days: 1))) &&
                      eventDate.isBefore(_toDate.add(Duration(days: 1)));
                } catch (e) {
                  return false;
                }
              })
              .toList();
        }
      }

      _groupEvents();
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _groupEvents() {
    _groupedEvents.clear();
    List<HistoryEventItem> allItems = [];

    // Adicionar itens de histórico
    for (var item in _allHistoryItems) {
      if (item.time != null) {
        allItems.add(HistoryEventItem(
          type: 'position',
          item: item,
          event: null,
          time: item.time!,
        ));
      }
    }

    // Adicionar eventos
    for (var event in _allEvents) {
      if (event.time != null) {
        allItems.add(HistoryEventItem(
          type: 'event',
          item: null,
          event: event,
          time: event.time!,
        ));
      }
    }

    // Ordenar por data
    allItems.sort((a, b) {
      try {
        DateTime dateA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a.time);
        DateTime dateB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b.time);
        return dateB.compareTo(dateA); // Mais recente primeiro
      } catch (e) {
        return 0;
      }
    });

    // Agrupar por dia
    for (var item in allItems) {
      try {
        DateTime date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(item.time);
        String displayKey = _formatDayKey(date);

        if (!_groupedEvents.containsKey(displayKey)) {
          _groupedEvents[displayKey] = [];
        }
        _groupedEvents[displayKey]!.add(item);
      } catch (e) {
        // Ignorar itens com data inválida
      }
    }
  }

  String _formatDayKey(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));
    DateTime itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Hoje - ${DateFormat('dd/MM/yyyy').format(date)}';
    } else if (itemDate == yesterday) {
      return 'Ontem - ${DateFormat('dd/MM/yyyy').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void setDeviceId(String? deviceId) {
    _selectedDeviceId = deviceId;
    notifyListeners();
  }

  void setGroupId(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  void setFromDate(DateTime date) {
    _fromDate = date;
    notifyListeners();
  }

  void setToDate(DateTime date) {
    _toDate = date;
    notifyListeners();
  }

  void setFromTime(TimeOfDay time) {
    _fromTime = time;
    notifyListeners();
  }

  void setToTime(TimeOfDay time) {
    _toTime = time;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDeviceId = null;
    _selectedGroupId = null;
    _fromDate = DateTime.now().subtract(Duration(days: 7));
    _toDate = DateTime.now();
    _fromTime = TimeOfDay.now();
    _toTime = TimeOfDay.now();
    notifyListeners();
  }

  Future<String> getAddress(double lat, double lng) async {
    String key = '${lat}_${lng}';
    if (_addressCache.containsKey(key)) {
      return _addressCache[key]!;
    }

    try {
      final address = await gpsapis.geocode(lat, lng);
      _addressCache[key] = address;
      return address;
    } catch (e) {
      return "Endereço não disponível";
    }
  }

  /// Limpar cache de endereços
  void clearAddressCache() {
    _addressCache.clear();
    print('✅ Cache de endereços limpo');
  }

  bool _isCriticalEvent(String? type) {
    if (type == null) return false;
    final criticalTypes = ['overspeed', 'panic', 'geofence', 'disconnection'];
    return criticalTypes.any((t) => type.toLowerCase().contains(t));
  }

  String getEventType(HistoryEventItem item) {
    if (item.type == 'event' && item.event != null) {
      return item.event!.type ?? 'event';
    }
    if (item.item != null) {
      if (item.item!.speed != null && item.item!.speed! > 0) {
        return 'movement';
      }
      return 'stop';
    }
    return 'unknown';
  }

  IconData getEventIcon(HistoryEventItem item) {
    String eventType = getEventType(item);
    switch (eventType) {
      case 'overspeed':
        return Icons.speed;
      case 'panic':
        return Icons.warning;
      case 'geofence':
        return Icons.fence;
      case 'movement':
        return Icons.directions_car;
      case 'stop':
        return Icons.stop_circle;
      case 'ignition':
        return Icons.power;
      default:
        return Icons.location_on;
    }
  }

  Color getEventColor(HistoryEventItem item, ColorProvider colorProvider) {
    String eventType = getEventType(item);
    if (eventType == 'overspeed' || eventType == 'panic') {
      return Colors.red;
    }
    if (eventType == 'geofence' || eventType == 'disconnection') {
      return Colors.orange;
    }
    return colorProvider.secondaryColor;
  }
}

class HistoryEventItem {
  final String type; // 'position' or 'event'
  final AllItems? item;
  final EventsData? event;
  final String time;

  HistoryEventItem({
    required this.type,
    this.item,
    this.event,
    required this.time,
  });
}

