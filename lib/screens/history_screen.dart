import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
      body: Padding(
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
                  'Historial',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),
            const Text(
              'Residencias finalizadas este mes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FutureBuilder<List<Residence>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay residencias finalizadas este mes.'),
                    );
                  }

                  final residences = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero, // ✅ elimina espacio adicional
                    itemCount: residences.length,
                    itemBuilder: (context, index) {
                      final res = residences[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.home),
                              ),
                            ),
                            title: Text(
                              res.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(res.commune),
                                Text(res.address),
                                Text('Fecha: ${res.date ?? ''}'),
                              ],
                            ),
                            trailing: const Chip(
                              label: Text('Finalizado'),
                              backgroundColor: Color(0xFFD0F5E8),
                            ),
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
                final count = snapshot.hasData ? snapshot.data!.length : 0;
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
    );
  }
}
