import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../routes/app_routes.dart';

class Residence {
  final String name;
  final String image;
  final String commune;
  final String address;
  final String status;
  final double latitude;
  final double length;

  Residence({
    required this.name,
    required this.image,
    required this.commune,
    required this.address,
    required this.status,
    required this.latitude,
    required this.length,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      name: json['home_data_name'] ?? 'Sin nombre',
      image: json['home_data_image'] ?? '',
      commune: json['home_data_commune'] ?? 'Desconocida',
      address: json['home_data_address'] ?? 'Sin dirección',
      status: json['home_clean_register_state'] ?? 'Pendiente',
      latitude: json['home_data_latitude']?.toDouble() ?? 0.0,
      length: json['home_data_length']?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Residence && other.name == name && other.commune == commune;
  }

  @override
  int get hashCode => name.hashCode ^ commune.hashCode;
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
          .toSet()
          .toList();

      print(
          '✔️ Se encontraron ${residences.length} residencias válidas para hoy');
      return residences;
    } else {
      throw Exception('Error al cargar residencias: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/LogoOnlyPro.png',
                    height: 30,
                  ),
                ),
                const Text(
                  'Bienvenido, "Tú Nombre"',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),
            const Text(
              'Residencias asignadas hoy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<Residence>>(
              future: _residencesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No hay residencias disponibles.');
                }

                return Column(
                  children: snapshot.data!
                      .map((res) => _buildResidenceItem(context, res))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidenceItem(BuildContext context, Residence res) {
    Color statusColor;
    switch (res.status) {
      case 'Hecho':
        statusColor = Colors.green.shade100;
        break;
      case 'En Proceso':
        statusColor = Colors.orange.shade100;
        break;
      case 'Pendiente':
        statusColor = Colors.red.shade100;
        break;
      default:
        statusColor = Colors.grey.shade100;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        title:
            Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(res.commune),
            Text(res.address),
          ],
        ),
        trailing: Chip(
          label: Text(res.status),
          backgroundColor: statusColor,
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.detail,
            arguments: res,
          );
        },
      ),
    );
  }
}
