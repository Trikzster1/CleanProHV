import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum RutaVisible { pie, auto, ambos }

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final LatLng residenceLocation =
      const LatLng(-33.40814553453603, -70.67376433196056);

  LatLng? userLocation;
  String? walkingDistanceKm;
  String? drivingDistanceKm;
  List<LatLng> walkingRoutePoints = [];
  List<LatLng> drivingRoutePoints = [];

  final MapController _mapController = MapController();
  double _rotation = 0;
  final double _defaultZoom = 15;

  RutaVisible rutaVisible = RutaVisible.ambos;

  final String openRouteServiceApiKey =
      '5b3ce3597851110001cf624880b29eb1232a423c855eebdc9e8daa64';

  @override
  void initState() {
    super.initState();
    _getUserLocation();

    _mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {
          _rotation = event.camera.rotation * (3.1415926535 / 180);
        });
      }
    });
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    final userLatLng = LatLng(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() {
      userLocation = userLatLng;
    });

    await _fetchRoute(
        from: userLatLng, to: residenceLocation, profile: 'foot-walking');
    await _fetchRoute(
        from: userLatLng, to: residenceLocation, profile: 'driving-car');
  }

  Future<void> _fetchRoute({
    required LatLng from,
    required LatLng to,
    required String profile,
  }) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/$profile?start=${from.longitude},${from.latitude}&end=${to.longitude},${to.latitude}&geometry_format=geojson',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': openRouteServiceApiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'];

      if (features != null && features.isNotEmpty) {
        final geometry = features[0]['geometry'];
        final segment = features[0]['properties']['segments'][0];

        if (geometry != null && segment != null) {
          final coords = geometry['coordinates'] as List;
          final distanceMeters = segment['distance'];
          final points = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();

          if (!mounted) return;
          setState(() {
            if (profile == 'foot-walking') {
              walkingRoutePoints = points;
              walkingDistanceKm = (distanceMeters / 1000).toStringAsFixed(2);
            } else {
              drivingRoutePoints = points;
              drivingDistanceKm = (distanceMeters / 1000).toStringAsFixed(2);
            }
          });
        }
      }
    }
  }

  void _centerOnUser() {
    if (userLocation != null) {
      _mapController.rotate(0);
      _mapController.move(userLocation!, _defaultZoom);
    }
  }

  void _centerOnResidence() {
    _mapController.rotate(0);
    _mapController.move(residenceLocation, _defaultZoom);
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  Widget _buildDistanceRow(String label, String? distance, Color lineColor) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        if (distance != null) Text('$distance km'),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => rutaVisible = RutaVisible.pie),
          child: const Text('Solo pie'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => rutaVisible = RutaVisible.ambos),
          child: const Text('Ambas rutas'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => rutaVisible = RutaVisible.auto),
          child: const Text('Solo auto'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(),
                  ),
                  Text(
                    'Detalles residencia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Divider(thickness: 1.2),
              const SizedBox(height: 20),
              const Text('Comuna:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Independencia'),
              const SizedBox(height: 10),
              const Text('Dirección:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Marino de Lobera 1679'),
              const SizedBox(height: 10),
              _buildDistanceRow(
                  'Distancia en vehículo', drivingDistanceKm, Colors.black),
              const SizedBox(height: 6),
              _buildDistanceRow(
                  'Distancia a pie', walkingDistanceKm, Colors.green),
              const SizedBox(height: 30),
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: residenceLocation,
                        initialZoom: _defaultZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cleanpro.app',
                        ),
                        if (rutaVisible == RutaVisible.auto ||
                            rutaVisible == RutaVisible.ambos)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: drivingRoutePoints,
                                color: Colors.black,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        if (rutaVisible == RutaVisible.pie ||
                            rutaVisible == RutaVisible.ambos)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: walkingRoutePoints,
                                color: Colors.green,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        if (userLocation != null)
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: userLocation!,
                                radius: 20,
                                useRadiusInMeter: true,
                                color: Colors.blue.withAlpha(51),
                                borderStrokeWidth: 1,
                                borderColor: Colors.blueAccent.withAlpha(128),
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: residenceLocation,
                              width: 40,
                              height: 40,
                              child: Transform.rotate(
                                angle: -_rotation,
                                child: const Icon(Icons.home,
                                    color: Colors.red, size: 32),
                              ),
                            ),
                            if (userLocation != null)
                              Marker(
                                point: userLocation!,
                                width: 40,
                                height: 40,
                                child: Transform.rotate(
                                  angle: -_rotation,
                                  child: const Icon(Icons.person_pin_circle,
                                      color: Colors.blue, size: 32),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            heroTag: 'btnUser',
                            mini: true,
                            onPressed: _centerOnUser,
                            tooltip: 'Centrar en mi ubicación',
                            child: const Icon(Icons.my_location),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            heroTag: 'btnHouse',
                            mini: true,
                            onPressed: _centerOnResidence,
                            tooltip: 'Centrar en residencia',
                            child: const Icon(Icons.home),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            heroTag: 'btnZoomIn',
                            mini: true,
                            onPressed: _zoomIn,
                            tooltip: 'Acercar',
                            child: const Icon(Icons.zoom_in),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            heroTag: 'btnZoomOut',
                            mini: true,
                            onPressed: _zoomOut,
                            tooltip: 'Alejar',
                            child: const Icon(Icons.zoom_out),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Rutas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildRouteFilterButtons(),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showWarningDialog(context, 'ingreso'),
                      child: const Text('Marcar Ingreso'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showWarningDialog(context, 'salida'),
                      child: const Text('Marcar Salida'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showWarningDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADVERTENCIA'),
        content: Text(
          'No estás lo suficientemente cerca de la residencia\n\n'
          'Debe estar cerca de la ubicación de la residencia para marcar $action',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
