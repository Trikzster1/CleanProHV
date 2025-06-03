import 'dart:async';
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
  double? directDistanceKm;
  double? lastValidDirectDistanceKm;

  bool hasEntered = false;
  bool _isDialogVisible = false;

  final MapController _mapController = MapController();
  final double _defaultZoom = 17.8;
  List<LatLng> walkingRoutePoints = [];
  double _rotation = 0;

  Timer? _distanceTimer;

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

    _updateLocationAndDistances();
    _distanceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocationAndDistances();
    });
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    _isDialogVisible = false;

    super.dispose();
  }

  Future<void> _updateLocationAndDistances() async {
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
    const Distance distance = Distance();

    if (!mounted) return;
    setState(() {
      userLocation = userLatLng;
      final distanceInMeters =
          distance(userLatLng, residenceLocation!); // metros
      directDistanceKm = distanceInMeters / 1000;
      lastValidDirectDistanceKm = directDistanceKm;
    });
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

  Future<void> _handleMark(String action) async {
    if (directDistanceKm == null || directDistanceKm! > 0.03) {
      _showWarningDialog(action);
      return;
    }

    final estado = action == 'ingreso' ? 'Proceso' : 'Finalizado';

    final body = {
      "home_schedule_id": widget.residence.id,
      "home_schedule_state": estado,
    };

    final response = await http.post(
      Uri.parse("http://143.198.118.203:8101/home/schedule_change_state/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      setState(() {
        hasEntered = action == 'ingreso';
      });
    } else {
      _showErrorDialog("Error al marcar $action. Intente nuevamente.");
    }
  }

  void _showWarningDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADVERTENCIA'),
        content: Text(
          'No estás lo suficientemente cerca de la residencia.\n\n'
          'Debes estar dentro de un radio de 30 metros para marcar $action.',
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

  void _showErrorDialog(String msg) {
    if (!mounted || _isDialogVisible) return;

    _isDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              _isDialogVisible = false;
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;
    if (residenceLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
                          alignment: Alignment.centerLeft, child: BackButton()),
                      Text('Detalles residencia',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '\u2022 ', // Punto tipo lista
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Comuna:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(residence.commune),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text(
                                    '\u2022 ', // Punto tipo lista
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Dirección: ',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text(residence.address),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 320,
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
                                              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                          subdomains: const [
                                            'a',
                                            'b',
                                            'c',
                                            'd'
                                          ],
                                          retinaMode: MediaQuery.of(context)
                                                  .devicePixelRatio >
                                              1.0,
                                          userAgentPackageName:
                                              'com.cleanpro.app',
                                        ),
                                        if (userLocation != null)
                                          CircleLayer(
                                            circles: [
                                              CircleMarker(
                                                point: userLocation!,
                                                radius: 30,
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
                                      left: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              204, 255, 255, 255),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            )
                                          ],
                                        ),
                                        child: Text(
                                          (directDistanceKm ??
                                                      lastValidDirectDistanceKm) !=
                                                  null
                                              ? ((directDistanceKm ??
                                                          lastValidDirectDistanceKm)! <
                                                      1
                                                  ? 'Distancia: ${((directDistanceKm ?? lastValidDirectDistanceKm)! * 1000).toStringAsFixed(0)} m'
                                                  : 'Distancia: ${(directDistanceKm ?? lastValidDirectDistanceKm)!.toStringAsFixed(2)} km')
                                              : 'Distancia: ...',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: SizedBox(
                                        height: 320, // igual al alto del mapa
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FloatingActionButton(
                                              heroTag: 'btnUser',
                                              mini: true,
                                              onPressed: _centerOnUser,
                                              tooltip:
                                                  'Centrar en mi ubicación',
                                              child:
                                                  const Icon(Icons.my_location),
                                            ),
                                            const SizedBox(height: 20),
                                            FloatingActionButton(
                                              heroTag: 'btnHouse',
                                              mini: true,
                                              onPressed: _centerOnResidence,
                                              tooltip: 'Centrar en residencia',
                                              child: const Icon(Icons.home),
                                            ),
                                            const SizedBox(height: 20),
                                            FloatingActionButton(
                                              heroTag: 'btnZoomIn',
                                              mini: true,
                                              onPressed: _zoomIn,
                                              tooltip: 'Acercar',
                                              child: const Icon(Icons.zoom_in),
                                            ),
                                            const SizedBox(height: 20),
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
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              Center(
                                child: Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: hasEntered
                                          ? null
                                          : () => _handleMark('ingreso'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasEntered
                                            ? Colors.grey.shade400
                                            : null,
                                      ),
                                      child: const Text('Marcar Ingreso'),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: hasEntered
                                          ? () => _handleMark('salida')
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasEntered
                                            ? null
                                            : Colors.grey.shade400,
                                      ),
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
}
