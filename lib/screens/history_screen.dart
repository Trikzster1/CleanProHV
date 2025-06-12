import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Residence>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = fetchHistoryResidences();
  }

  Future<List<Residence>> fetchHistoryResidences() async {
    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode('equipo3:equipo3'))}',
      'Accept': 'application/json',
    };
    final listUrl =
        Uri.parse('http://143.198.118.203:8101/home/schedule_list_current/');
    final response = await http.get(listUrl, headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonList = data['list_current'] ?? [];
      final now = DateTime.now();
      final String currentMonth = DateFormat('yyyy-MM').format(now);
      final residences = jsonList
          .where((e) => (e['home_clean_register_state'] == 'Finalizado'))
          .where((e) => (e['home_clean_register_date'] ?? '')
              .toString()
              .startsWith(currentMonth))
          .map((e) => Residence.fromJson(e))
          .toList();
      return residences;
    } else {
      throw Exception('Error al cargar historial: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/LogoOnlyPro.png',
                    height: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Residencias finalizadas este mes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Residence>>(
                      future: _historyFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                                'No hay residencias finalizadas este mes.'),
                          );
                        }

                        final residences = snapshot.data!;
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: residences.length,
                          itemBuilder: (context, index) {
                            final res = residences[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      res.image,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.home),
                                    ),
                                  ),
                                  title: Text(
                                    res.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(res.commune),
                                      Text(res.address),
                                      Text('Fecha: ${res.date ?? ''}'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CompletedResidenceDetail(
                                                residence: res),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  FutureBuilder<List<Residence>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      final count =
                          snapshot.hasData ? snapshot.data!.length : 0;
                      return Column(
                        children: [
                          const Divider(thickness: 1.2),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Residencias este mes: $count',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
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

class CompletedResidenceDetail extends StatefulWidget {
  final Residence residence;

  const CompletedResidenceDetail({super.key, required this.residence});

  @override
  State<CompletedResidenceDetail> createState() =>
      _CompletedResidenceDetailState();
}

class _CompletedResidenceDetailState extends State<CompletedResidenceDetail> {
  LatLng? residenceLocation;
  LatLng? userLocation;
  double? directDistanceKm;
  double? lastValidDirectDistanceKm;
  final MapController _mapController = MapController();
  final double _defaultZoom = 17.8;
  double _rotation = 0;
  List<LatLng> walkingRoutePoints = [];
  bool showRoute = false;

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
      final distanceInMeters = distance(userLatLng, residenceLocation!);
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

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;
    if (residenceLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // RECUADRO AZUL COMPLETO (sin bordes)
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Stack(
              children: [
                // Botón de retroceso alineado a la izquierda
                Positioned(
                  left: 16,
                  top: 50, // Ajustado para alinear con el texto
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Título centrado
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60, // Ajustado para alinear con el botón
                  child: const Center(
                    child: Text(
                      'Detalles residencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Card única con comuna, dirección e imagen
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Comuna y Dirección
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    '\u2022 ',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Dirección: ',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Flexible(
                                    child: Text(
                                      residence.address,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Imagen de referencia
                          const Text(
                            'Imagen de referencia de la residencia',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              residence.image,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card con mapa
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
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
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                      retinaMode: MediaQuery.of(context)
                                              .devicePixelRatio >
                                          1.0,
                                      userAgentPackageName: 'com.cleanpro.app',
                                    ),
                                    if (showRoute &&
                                        walkingRoutePoints.isNotEmpty)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: walkingRoutePoints,
                                            color: Colors.blue,
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
                                            borderColor: const Color.fromARGB(
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
                                      borderRadius: BorderRadius.circular(12),
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
                                              ? 'Distancia: ${((directDistanceKm ?? lastValidDirectDistanceKm)! * 1000).toStringAsFixed(0)} metros'
                                              : 'Distancia: ${(directDistanceKm ?? lastValidDirectDistanceKm)!.toStringAsFixed(2)} km')
                                          : '',
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
                                    height: 320,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        FloatingActionButton(
                                          heroTag: 'btnUser',
                                          mini: true,
                                          onPressed: _centerOnUser,
                                          tooltip: 'Centrar en mi ubicación',
                                          child: const Icon(Icons.my_location),
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
                                          child: const Icon(Icons.directions),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Residencia Finalizada',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (residence.date != null)
                                  Text(
                                    'Fecha: ${residence.date!}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Volver al Historial'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
