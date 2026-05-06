import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uconnect/ui/reusable/custom_app_bar.dart'; // Importe o CustomAppBar

class ReportLocationDetail extends StatelessWidget {
  final String time;
  final double speed;
  final double lat;
  final double lng;

  const ReportLocationDetail({
    super.key,
    required this.time,
    required this.speed,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Detalhes do Ponto"), // Usando o CustomAppBar
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF0077D7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hora: $time',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Velocidade: $speed km/h',
                    style: const TextStyle(fontSize: 14)),
                Text('Latitude: $lat', style: const TextStyle(fontSize: 14)),
                Text('Longitude: $lng', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('local'),
                  position: LatLng(lat, lng),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
