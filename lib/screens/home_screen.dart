import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../routes/app_routes.dart';

class Residence {
  final int id;
  final String name;
  final String image;
  final String commune;
  final String address;
  String status;
  final double latitude;
  final double length;
  final String? date;

  Residence({
    required this.id,
    required this.name,
    required this.image,
    required this.commune,
    required this.address,
    required this.status,
    required this.latitude,
    required this.length,
    this.date,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: json['home_clean_register_id'] ?? 0,
      name: json['home_data_name'] ?? 'Sin nombre',
      image: json['home_data_image'] ?? '',
      commune: json['home_data_commune'] ?? 'Desconocida',
      address: json['home_data_address'] ?? 'Sin dirección',
      status: json['home_clean_register_state'] ?? 'Pendiente',
      latitude: json['home_data_latitude']?.toDouble() ?? 0.0,
      length: json['home_data_length']?.toDouble() ?? 0.0,
      date: json['home_clean_register_date'],
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Residence &&
        other.id == id &&
        other.name == name &&
        other.commune == commune;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ commune.hashCode;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Residence>> _residencesFuture;

  @override
  void initState() {
    super.initState();
    _residencesFuture = fetchResidences();
  }

  Future<List<Residence>> fetchResidences() async {
    final blacklist = [
      "Marino Lobera 1679",
      "Av. Alameda 5400",
      "Av. Vicuña Mackenna 9100",
      "Av. Apoquindo 3000",
      "Av. Macul 3600",
      "Av. Providencia 1234",
      "Bartolomé de las Casas 980",
      "Av. Recoleta 1600",
      "Gran Avenida 4900",
      "Avenida Irarrázaval 2400",
    ];

    final headers = {
      'Authorization': 'Basic ${base64Encode(utf8.encode('equipo3:equipo3'))}',
      'Accept': 'application/json',
    };

    final generationUrl =
        Uri.parse('http://143.198.118.203:8101/home/schedule_generation/');
    await http.get(generationUrl, headers: headers);

    final listUrl =
        Uri.parse('http://143.198.118.203:8101/home/schedule_list_current/');
    final response = await http.get(listUrl, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonList = data['list_current'] ?? [];

      final residences = jsonList
          .map((e) => Residence.fromJson(e))
          .where((r) => !blacklist.contains(r.address))
          .where((r) => r.status != 'Finalizado')
          .toSet()
          .toList();

      residences.sort((a, b) {
        if (a.status == 'Proceso' && b.status != 'Proceso') {
          return -1;
        } else if (a.status != 'Proceso' && b.status == 'Proceso') {
          return 1;
        }
        return 0;
      });

      return residences;
    } else {
      throw Exception('Error al cargar residencias: ${response.statusCode}');
    }
  }

  Widget _buildResidenceItem(BuildContext context, Residence res) {
    Color statusColor;
    Color chipTextColor = Colors.black; // Default: texto negro

    switch (res.status) {
      case 'Hecho':
        statusColor = Colors.green.shade100;
        break;
      case 'Proceso':
        statusColor = Colors.blue;
        chipTextColor = Colors.white; // Texto blanco para "Proceso"
        break;
      case 'Pendiente':
        statusColor = const Color.fromARGB(255, 212, 206, 206);
        chipTextColor = Colors.white; // Texto blanco para "Pendiente"
        break;
      default:
        statusColor = Colors.grey.shade100;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            res.image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.home),
          ),
        ),
        title: Text(
          res.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res.commune),
            Text(res.address),
          ],
        ),
        trailing: Chip(
          label: Text(
            res.status,
            style: TextStyle(color: chipTextColor), // Color condicional
          ),
          backgroundColor: statusColor,
        ),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: res,
          );
          if (result == true) {
            setState(() {
              _residencesFuture = fetchResidences();
            });
          }
        },
      ),
    );
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
                    'Bienvenido',
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
                    'Residencias asignadas hoy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Residence>>(
                      future: _residencesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No hay residencias disponibles.');
                        }

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final res = snapshot.data![index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: _buildResidenceItem(context, res),
                            );
                          },
                        );
                      },
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
