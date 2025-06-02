import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import './home_screen.dart';

class DetailScreen extends StatefulWidget {
  final Residence residence;

  const DetailScreen({super.key, required this.residence});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  LatLng? residenceLocation;
  LatLng? userLocation;
  String? walkingDistanceKm;
  final MapController _mapController = MapController();
  final double _defaultZoom = 15;
  List<LatLng> walkingRoutePoints = [];
  double _rotation = 0;

  final String openRouteServiceApiKey =
      '5b3ce3597851110001cf624880b29eb1232a423c855eebdc9e8daa64';

  @override
  void initState() {
    super.initState();

    residenceLocation = LatLng(
      widget.residence.latitude,
      widget.residence.length,
    );

    _mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {
          _rotation = event.camera.rotation * (3.1415926535 / 180);
        });
      }
    });

    _getUserLocationAndRoute(residenceLocation!);
  }

  Future<void> _getUserLocationAndRoute(LatLng destination) async {
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
    final userLatLng = LatLng(position.latitude, position.longitude);
    walkingDistanceKm = null;
    if (!mounted) return;
    setState(() {
      userLocation = userLatLng;
    });

    await _fetchWalkingRoute(from: userLatLng, to: destination);
  }

  Future<void> _fetchWalkingRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/foot-walking?start=${from.longitude},${from.latitude}&end=${to.longitude},${to.latitude}&geometry_format=geojson',
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
            walkingRoutePoints = points;
            walkingDistanceKm = (distanceMeters / 1000).toStringAsFixed(2);
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
    if (residenceLocation != null) {
      _mapController.rotate(0);
      _mapController.move(residenceLocation!, _defaultZoom);
    }
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, _mapController.camera.zoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 10),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: IntrinsicHeight(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(127, 255, 255, 255),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Comuna:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(residence.commune),
                              const SizedBox(height: 10),
                              const Text('Dirección:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(residence.address),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text('Distancia a pie:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 6),
                                  Text(walkingDistanceKm == null
                                      ? 'Calculando...'
                                      : '$walkingDistanceKm km'),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 250,
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: _mapController,
                                      options: MapOptions(
                                        initialCenter: residenceLocation!,
                                        initialZoom: _defaultZoom,
                                        interactionOptions:
                                            const InteractionOptions(
                                                flags: InteractiveFlag.all),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'com.cleanpro.app',
                                        ),
                                        if (walkingRoutePoints.isNotEmpty)
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
                                                color: const Color.fromARGB(
                                                    51, 33, 150, 243),
                                                borderStrokeWidth: 1,
                                                borderColor:
                                                    const Color.fromARGB(
                                                        128, 33, 150, 243),
                                              ),
                                            ],
                                          ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: residenceLocation!,
                                              width: 40,
                                              height: 40,
                                              child: Transform.rotate(
                                                angle: -_rotation,
                                                child: const Icon(Icons.home,
                                                    color: Colors.red,
                                                    size: 32),
                                              ),
                                            ),
                                            if (userLocation != null)
                                              Marker(
                                                point: userLocation!,
                                                width: 40,
                                                height: 40,
                                                child: Transform.rotate(
                                                  angle: -_rotation,
                                                  child: const Icon(
                                                      Icons.person_pin_circle,
                                                      color: Colors.blue,
                                                      size: 32),
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
                                            child:
                                                const Icon(Icons.my_location),
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
                              const SizedBox(height: 30),
                              Center(
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _showWarningDialog(
                                          context, 'ingreso'),
                                      child: const Text('Marcar Ingreso'),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _showWarningDialog(context, 'salida'),
                                      child: const Text('Marcar Salida'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
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
