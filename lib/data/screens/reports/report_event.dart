import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uconnect/storage/user_repository.dart';

class ReportEventsPage extends StatefulWidget {
  final String deviceId;
  final String userHash;
  final String fromDate;
  final String toDate;
  final String fromTime;
  final String toTime;

  const ReportEventsPage({
    super.key,
    required this.deviceId,
    required this.userHash,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
  });

  @override
  State<ReportEventsPage> createState() => _ReportEventsPageState();
}

class _ReportEventsPageState extends State<ReportEventsPage> {
  List<dynamic> _reportData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final url = Uri.parse(
      '${UserRepository.getServerURL()}/api/get_history'
      '?user_api_hash=${widget.userHash}'
      '&device_id=${widget.deviceId}'
      '&from=${widget.fromDate} ${widget.fromTime}'
      '&to=${widget.toDate} ${widget.toTime}'
      '&from_date=${widget.fromDate}'
      '&to_date=${widget.toDate}'
      '&from_time=${widget.fromTime}'
      '&to_time=${widget.toTime}'
      '&format=json'
      '&type=7'
    );

    print("🔍 URL requisitada: $url");

    final response = await http.get(url);
    print("🔽 Corpo bruto da resposta:");
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _reportData = data['items'] ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      print('❌ Erro ao carregar relatório: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       appBar: AppBar(
        backgroundColor: const Color(0xFF003399),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Eventos", style: TextStyle(color: Colors.white)),
      ),
      
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reportData.isEmpty
              ? const Center(child: Text("Nenhum dado encontrado."))
              : ListView.builder(
                  itemCount: _reportData.length,
                  itemBuilder: (context, index) {
                    final item = _reportData[index];
                    final subItems = item['items'] as List? ?? [];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "🕒 ${item['show'] ?? 'Sem horário'}",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (subItems.isNotEmpty) ...[
                              Text("Evento: ${subItems[0]['event'] ?? '-'}",
                                  style: const TextStyle(color: Colors.black87)),
                              Text("Latitude: ${subItems[0]['latitude'] ?? '-'}",
                                  style: const TextStyle(color: Colors.black87)),
                              Text("Longitude: ${subItems[0]['longitude'] ?? '-'}",
                                  style: const TextStyle(color: Colors.black87)),
                              Text("Velocidade: ${subItems[0]['speed'] ?? '-'} km/h",
                                  style: const TextStyle(color: Colors.black87)),
                            ] else
                              const Text("Sem dados do evento.",
                                  style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
