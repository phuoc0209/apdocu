import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const double _lat = 21.0278;
  static const double _lon = 105.8342;

  @override
  Widget build(BuildContext context) {
    final osmUrl = Uri.parse('https://www.openstreetmap.org/?mlat=$_lat&mlon=$_lon#map=13/$_lat/$_lon');

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ địa điểm')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Color(0xFF6C63FF)),
              const SizedBox(height: 12),
              const Text('Địa điểm: Hà Nội (ví dụ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Vĩ độ: $_lat, Kinh độ: $_lon', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở trên OpenStreetMap'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (!await launchUrl(osmUrl, mode: LaunchMode.externalApplication)) {
                    messenger.showSnackBar(const SnackBar(content: Text('Không thể mở bản đồ')));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
