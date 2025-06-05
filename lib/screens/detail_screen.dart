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
  bool isFinalizado = false;
  bool _isDialogVisible = false;
  bool _isLoadingIngreso = false;
  bool _estadoCambiado = false;
  bool _cargandoEstadoYDistancia = true;

  final MapController _mapController = MapController();
  final double _defaultZoom = 17.8;
  List<LatLng> walkingRoutePoints = [];
  double _rotation = 0;
  bool showRoute = false;

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
    _cargarEstadoYDistancia();
    _distanceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateLocationAndDistances();
    });
  }

  Future<void> _fetchWalkingRoute() async {
    if (userLocation == null || residenceLocation == null) return;

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/foot-walking?start=${userLocation!.longitude},${userLocation!.latitude}&end=${residenceLocation!.longitude},${residenceLocation!.latitude}&geometry_format=geojson',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': openRouteServiceApiKey},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'] as List;
      final points =
          coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

      if (!mounted) return;
      setState(() {
        walkingRoutePoints = points;
      });
    }
  }

  Future<void> _cargarEstadoYDistancia() async {
    await Future.wait([
      _fetchAndSetEstado(),
      _updateLocationAndDistances(),
    ]);
    if (!mounted) return;
    setState(() {
      _cargandoEstadoYDistancia = false;
    });
  }

  Future<void> _fetchAndSetEstado() async {
    final response = await http.get(
      Uri.parse("http://143.198.118.203:8101/home/schedule_list_current/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Basic ${base64Encode(utf8.encode('equipo3:equipo3'))}",
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonList = data['list_current'] ?? [];
      for (final r in jsonList) {
        final id = r["home_schedule_id"] ?? r["home_clean_register_id"];
        final state =
            r["home_schedule_state"] ?? r["home_clean_register_state"];
        if (id == widget.residence.id) {
          if (!mounted) return;
          setState(() {
            hasEntered = (state == "Proceso");
            isFinalizado = (state == "Finalizado");
          });
          break;
        }
      }
    }
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

  Future<bool> _hasResidenceInProcess() async {
    final response = await http.get(
      Uri.parse("http://143.198.118.203:8101/home/schedule_list_current/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Basic ${base64Encode(utf8.encode('equipo3:equipo3'))}",
      },
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonList = data['list_current'] ?? [];
      for (final r in jsonList) {
        final id = r["home_schedule_id"] ?? r["home_clean_register_id"];
        final state =
            r["home_schedule_state"] ?? r["home_clean_register_state"];
        if (state == "Proceso" && id != widget.residence.id) {
          return true;
        }
      }
      return false;
    }
    return false;
  }

  Future<void> _handleMark(String action) async {
    if (directDistanceKm == null || directDistanceKm! > 0.05) {
      _showWarningDialog(action);
      return;
    }

    if (action == 'ingreso') {
      setState(() {
        _isLoadingIngreso = true;
      });
      final alreadyInProcess = await _hasResidenceInProcess();
      setState(() {
        _isLoadingIngreso = false;
      });
      if (alreadyInProcess) {
        _showAlreadyInProcessDialog();
        return;
      }
    }

    final estado = action == 'ingreso' ? 'Proceso' : 'Finalizado';

    final body = {
      "home_schedule_id": widget.residence.id,
      "home_schedule_state": estado,
    };

    const url = "http://143.198.118.203:8101/home/schedule_change_state/";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Basic ${base64Encode(utf8.encode('equipo3:equipo3'))}",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      if (action == 'salida') {
        setState(() {
          hasEntered = false;
          isFinalizado = true;
          _estadoCambiado = true;
        });
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Residencia finalizada con éxito!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        return;
      } else {
        setState(() {
          hasEntered = true;
          _estadoCambiado = true;
        });
      }
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

  void _showAlreadyInProcessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADVERTENCIA'),
        content: const Text(
          'Ya hay una residencia en proceso. Solo puede haber 1 a la vez.',
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(
                          onPressed: () {
                            Navigator.pop(context, _estadoCambiado);
                          },
                        ),
                      ),
                      const Text('Detalles residencia',
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
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    residence.image,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.home,
                                            size: 50, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Text(
                                    '\u2022 ',
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
                                    '\u2022 ',
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
                                        if (showRoute &&
                                            walkingRoutePoints.isNotEmpty)
                                          PolylineLayer(
                                            polylines: [
                                              Polyline(
                                                points: walkingRoutePoints,
                                                color: Colors.red,
                                                strokeWidth: 4,
                                              ),
                                            ],
                                          ),
                                        if (userLocation != null)
                                          CircleLayer(
                                            circles: [
                                              CircleMarker(
                                                point: userLocation!,
                                                radius: 50,
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
                                        child: _cargandoEstadoYDistancia
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : Text(
                                                (directDistanceKm ??
                                                            lastValidDirectDistanceKm) !=
                                                        null
                                                    ? ((directDistanceKm ??
                                                                lastValidDirectDistanceKm)! <
                                                            1
                                                        ? 'Distancia: ${((directDistanceKm ?? lastValidDirectDistanceKm)! * 1000).toStringAsFixed(0)} metros'
                                                        : 'Distancia: ${(directDistanceKm ?? lastValidDirectDistanceKm)!.toStringAsFixed(2)} km')
                                                    : '',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: SizedBox(
                                        height: 320,
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
                                            const SizedBox(height: 20),
                                            FloatingActionButton(
                                              heroTag: 'btnRoute',
                                              mini: true,
                                              onPressed: () {
                                                setState(() {
                                                  showRoute = !showRoute;
                                                  if (showRoute) {
                                                    _fetchWalkingRoute();
                                                  }
                                                });
                                              },
                                              tooltip: 'Mostrar ruta',
                                              child:
                                                  const Icon(Icons.directions),
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
                                child: isFinalizado
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 16),
                                        child: Text(
                                          'La residencia ya ha sido finalizada',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed:
                                                (_cargandoEstadoYDistancia ||
                                                        hasEntered ||
                                                        _isLoadingIngreso)
                                                    ? null
                                                    : () =>
                                                        _handleMark('ingreso'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (hasEntered ||
                                                      _cargandoEstadoYDistancia)
                                                  ? Colors.grey.shade400
                                                  : null,
                                            ),
                                            child: _isLoadingIngreso
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  )
                                                : const Text('Marcar Ingreso'),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed:
                                                (_cargandoEstadoYDistancia ||
                                                        !hasEntered)
                                                    ? null
                                                    : () =>
                                                        _handleMark('salida'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (!hasEntered ||
                                                      _cargandoEstadoYDistancia)
                                                  ? Colors.grey.shade400
                                                  : null,
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
