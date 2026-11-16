import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/weather_repository.dart';

class MapPickerScreen extends StatefulWidget{
  const MapPickerScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MapPickerState();
  }  
}

class _MapPickerState extends State<MapPickerScreen> {

  LatLng? _picked;

  void _confirm() {
    final p = _picked!;
    print("---------------------------{$p}");
    Navigator.pop(
      context,
      City('Selected location', p.latitude, p.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick a Location'),),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(22.5, 79.0),         // middle of India
                initialZoom: 4.5,                                // whole country visible
                cameraConstraint: CameraConstraint.containCenter(      // can't pan outside these bounds
                  bounds: LatLngBounds(
                    const LatLng(6.5, 68.0),                     // south-west corner
                    const LatLng(35.7, 97.5),                    // north-east corner
                  ),
                ),
                minZoom: 4,
                onTap: (tapPosition, point) => setState(() => _picked = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.weather_app',
                ),
                if (_picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _picked!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,              // the pin's TIP sits on the point
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                ),
              ],
            )
          ),
          SafeArea(                                            // keeps it above the phone's gesture bar
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,                // only as tall as its content
                children: [
                  Text(_picked == null
                      ? 'Tap the map to choose a location'
                      : 'Selected: ${_picked!.latitude.toStringAsFixed(2)}, '
                        '${_picked!.longitude.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _picked == null ? null : _confirm,   // null = disabled (Phase 5)
                    icon: const Icon(Icons.check),
                    label: const Text('Show weather here'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
}

