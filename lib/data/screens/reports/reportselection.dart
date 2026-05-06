import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/config/custom_image_assets.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/mapconfig/CommonMethod.dart';
import 'package:uconnect/ui/reusable/global_widget.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as IMG;
import 'package:uconnect/utils/Consts.dart';
import 'package:intl/intl.dart';
import '../../../config/Session.dart';
import 'report_event.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:uconnect/ui/reusable/custom_app_bar.dart';
import 'package:uconnect/ui/reusable/standard_header.dart';
import 'package:uconnect/ui/reusable/reusable_fluid_bottom_nav.dart';
import 'package:uconnect/ui/reusable/floating_menu_drawer.dart';

class reportselection extends StatefulWidget {
  @override
  _reportselection createState() => _reportselection();
}

class _reportselection extends State<reportselection> {
  // initialize global widget
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showFilters = false;

  bool _doneListing = false;
  //date time hepers
  int _selectedperiod = 0;

  List<String> _reportliststr = [
    "Daily Travel Report",
    "Travel Summary Bulk",
    "Task Report",
    "Vehicle History",
    "Traval Summary with Playback Image",
    "General information",
    "Drives and stops",
    "Geofence in/out",
    "Events",
    "Work hours daily"
  ];

  List<String> _devicesListstr = [];
  String _selectedReport = "";

  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate = DateTime.now();

  var selectedToTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoToTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedFromTime = TimeOfDay.fromDateTime(DateTime.now());
  var selectedTripInfoFromTime = TimeOfDay.fromDateTime(DateTime.now());
  var fromTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var fromTripInfoTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var toTime = DateFormat("HH:mm:ss").format(DateTime.now());
  var toTripInfoTime = DateFormat("HH:mm:ss").format(DateTime.now());

  String? _chosenValue = "30 min";
  String? _chosenValue1;

  var _stopFilter;

  @override
  void initState() {
    super.initState();
    getdeviesList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getdeviesList() async {
    _devicesListstr.clear();

    for (int i = 0; i < StaticVarMethod.devicelist.length; i++) {
      _devicesListstr.add(StaticVarMethod.devicelist.elementAt(i).name!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FloatingMenuDrawer(),
      backgroundColor: Colors.white,
      appBar: StandardHeader(
        title: StaticVarMethod.deviceName,
        icon: Icons.insert_chart,
      ),
      bottomNavigationBar: ReusableFluidBottomNav(scaffoldKey: _scaffoldKey),
      body: SingleChildScrollView(
        child: reportControls(),
      ),
    );
  }

  void showStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        Size size = MediaQuery.of(context).size;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(maxHeight: size.height * 0.75),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selecionar relatório',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003087),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),

                    // Lista de relatórios
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            RadioListTile(
                              title: Text(getTranslated(
                                  context, 'dayWiseInformation')!),
                              value: "Daily Travel Report",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title:
                                  Text(getTranslated(context, 'travel_sheet')!),
                              value: "Travel Summary Bulk",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(
                                  context, 'generalInformationMerged')!),
                              value: "Task Report",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(context, 'history')!),
                              value: "Vehicle History",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(
                                  context, 'travel_sheet_custom')!),
                              value: "Traval Summary with Playback Image",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(
                                  context, 'general_information')!),
                              value: "General information",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(
                                  context, 'drives_and_stops_drivers')!),
                              value: "Drives and stops",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title:
                                  Text(getTranslated(context, 'geofence_in')!),
                              value: "Geofence in/out",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(getTranslated(context, 'events')!),
                              value: "Events",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                            RadioListTile(
                              title: Text(
                                  getTranslated(context, 'work_hours_Daily')!),
                              value: "Work hours daily",
                              groupValue: _stopFilter,
                              activeColor: Color(0xFF003087),
                              onChanged: (value) {
                                setState(() => _stopFilter = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Botões
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cancelar
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Cancelar'),
                        ),

                        // OK com degradê
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF003087), Color(0xFF0077D7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _selectedReport = _stopFilter;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('OK',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget reportControls() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card "Veículo Selecionado"
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veículo Selecionado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.directions_car,
                        color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 8),
                    Text(
                      StaticVarMethod.deviceName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  StaticVarMethod.imei ?? 'IMEI não disponível',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          // Card "Tipo de Relatório"
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Relatório',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF001F5C), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    icon:
                        Icon(Icons.description, color: Colors.white, size: 20),
                    onPressed: () => showStopDialog(context),
                    label: Text(
                      'Selecionar relatório',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Card "Período Rápido"
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período Rápido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey[600]),
                      value: _selectedperiod,
                      items: const [
                        DropdownMenuItem(
                            value: 0, child: Text('Últimas horas')),
                        DropdownMenuItem(value: 1, child: Text('Hoje')),
                        DropdownMenuItem(value: 2, child: Text('Ontem')),
                        DropdownMenuItem(
                            value: 3, child: Text('Antes de ontem')),
                        DropdownMenuItem(
                            value: 4, child: Text('Últimos 7 dias')),
                        DropdownMenuItem(
                            value: 5, child: Text('Última semana')),
                      ],
                      onChanged: (int? value) {
                        if (value != null) {
                          setState(() {
                            _selectedperiod = value;
                            showReport();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Reorganizar o card "Filtros Avançados" para incluir os pickers dentro dele
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do card com botão "Refinar"
                Row(
                  children: [
                    Expanded(
                      child: Text('Filtros Avançados',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF001F5C), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.tune, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        label: Text('Refinar',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),

                // Conteúdo dos filtros (aparece quando _showFilters é true)
                if (_showFilters) ...[
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Text(
                      getTranslated(context, 'customDateTIme')!,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Campo "De"
                  const Text(
                    'De',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedFromDate,
                        firstDate: DateTime(2015, 8),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF1976D2),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedFromDate = pickedDate;
                        });
                      }

                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedFromTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF1976D2),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedFromTime = pickedTime;
                        });
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${DateFormat('dd MMM. yyyy', 'pt_BR').format(_selectedFromDate)} ${selectedFromTime.format(context)}",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                        ],
                      ),
                    ),
                  ),

                  // Campo "Até"
                  const SizedBox(height: 10),
                  const Text(
                    'Até',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedToDate,
                        firstDate: DateTime(2015, 8),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF1976D2),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedToDate = pickedDate;
                        });
                      }

                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedToTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF1976D2),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedToTime = pickedTime;
                        });
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${DateFormat('dd MMM. yyyy', 'pt_BR').format(_selectedToDate)} ${selectedToTime.format(context)}",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                          ),
                          Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 16),

          // Botão "Gerar Relatório"
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001F5C), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              icon: Icon(Icons.description, color: Colors.white, size: 20),
              onPressed: () {
                showReport();
              },
              label: Text(
                'Gerar Relatório',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16),
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

  //date time picker
  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedFromDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedFromDate)
      setState(() {
        _selectedFromDate = picked;
      });
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedToDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedToDate)
      setState(() {
        _selectedToDate = picked;
      });
  }

  Future<Null> _fromTime(BuildContext context) async {
    var picked = await showTimePicker(
      context: context,
      initialTime: selectedFromTime,
    );
    if (picked != null && picked != selectedFromTime)
      setState(() {
        selectedFromTime = picked;
        var hour = selectedFromTime.hour;
        var minute = selectedFromTime.minute;
        fromTime = "$hour:$minute:00";
        print(fromTime);
        //var formattedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
  }

  Future<Null> _toTime(BuildContext context) async {
    var picked = await showTimePicker(
      context: context,
      initialTime: selectedToTime,
    );
    if (picked != null && picked != selectedToTime)
      setState(() {
        selectedToTime = picked;
        var hour = selectedToTime.hour;
        var minute = selectedToTime.minute;
        toTime = "$hour:$minute:00";
      });
  }

  Widget _buildDateOrTimeButton(
      {required String label, required VoidCallback onPressed}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 6), // espaço lateral entre os botões
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void showReport() {
    String fromDate;
    String toDate;
    String fromTime;
    String toTime;

    DateTime current = DateTime.now();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    if (current.day < 10) {
      day = "0" + current.day.toString();
    } else {
      day = current.day.toString();
    }

    if (_selectedperiod == 1) {
      String today;

      int dayCon = current.day + 1;
      if (dayCon <= 10) {
        today = "0" + dayCon.toString();
      } else {
        today = dayCon.toString();
      }

      var date = DateTime.parse("${current.year}-"
          "$month-"
          "$today "
          "00:00:00");
      fromDate = formatDateReport(DateTime.now().toString());
      toDate = formatDateReport(date.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";

      StaticVarMethod.fromdate = formatDateReport(DateTime.now().toString());
      StaticVarMethod.todate = formatDateReport(date.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else if (_selectedperiod == 2) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day <= 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else if (_selectedperiod == 3) {
      String sevenDay, currentDayString;
      int dayCon = current.day - current.weekday;
      int currentDay = current.day;
      if (dayCon < 10) {
        sevenDay = "0" + dayCon.abs().toString();
      } else {
        sevenDay = dayCon.toString();
      }
      if (currentDay < 10) {
        currentDayString = "0" + currentDay.toString();
      } else {
        currentDayString = currentDay.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$sevenDay "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$currentDayString "
          "24:00:00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = "00:00:00";
      toTime = "00:00:00";
      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = "00:00";
      StaticVarMethod.totime = "00:00";
    } else {
      String startMonth, endMoth;
      if (_selectedFromDate.month < 10) {
        startMonth = "0" + _selectedFromDate.month.toString();
      } else {
        startMonth = _selectedFromDate.month.toString();
      }

      if (_selectedToDate.month < 10) {
        endMoth = "0" + _selectedToDate.month.toString();
      } else {
        endMoth = _selectedToDate.month.toString();
      }

      String startHour, endHour;
      if (selectedFromTime.hour < 10) {
        startHour = "0" + selectedFromTime.hour.toString();
      } else {
        startHour = selectedFromTime.hour.toString();
      }

      String startMin, endMin;
      if (selectedFromTime.minute < 10) {
        startMin = "0" + selectedFromTime.minute.toString();
      } else {
        startMin = selectedFromTime.minute.toString();
      }

      if (selectedToTime.minute < 10) {
        endMin = "0" + selectedToTime.minute.toString();
      } else {
        endMin = selectedToTime.minute.toString();
      }

      if (selectedToTime.hour < 10) {
        endHour = "0" + selectedToTime.hour.toString();
      } else {
        endHour = selectedToTime.hour.toString();
      }

      String startDay, endDay;
      if (_selectedFromDate.day <= 10) {
        if (_selectedFromDate.day == 10) {
          startDay = _selectedFromDate.day.toString();
        } else {
          startDay = "0" + _selectedFromDate.day.toString();
        }
      } else {
        startDay = _selectedFromDate.day.toString();
      }

      if (_selectedToDate.day <= 10) {
        if (_selectedToDate.day == 10) {
          endDay = _selectedToDate.day.toString();
        } else {
          endDay = "0" + _selectedToDate.day.toString();
        }
      } else {
        endDay = _selectedToDate.day.toString();
      }

      var start = DateTime.parse("${_selectedFromDate.year}-"
          "$startMonth-"
          "$startDay "
          "$startHour:"
          "$startMin:"
          "00");

      var end = DateTime.parse("${_selectedToDate.year}-"
          "$endMoth-"
          "$endDay "
          "$endHour:"
          "$endMin:"
          "00");

      fromDate = formatDateReport(start.toString());
      toDate = formatDateReport(end.toString());
      fromTime = formatTimeReport(start.toString());
      toTime = formatTimeReport(end.toString());

      StaticVarMethod.fromdate = formatDateReport(start.toString());
      StaticVarMethod.todate = formatDateReport(end.toString());
      StaticVarMethod.fromtime = formatTimeReport(start.toString());
      StaticVarMethod.totime = formatTimeReport(end.toString());
    }

    print(fromDate);
    print(toDate);

    //Navigator.pop(context);
    // Páginas de relatórios removidas
    Fluttertoast.showToast(msg: "Este relatório não está mais disponível");
    Widget _buildPeriodButton(String label, int periodId) {
      return OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedperiod = periodId;
            showReport();
          });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }
}
