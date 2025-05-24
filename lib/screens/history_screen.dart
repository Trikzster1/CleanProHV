import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🧾 Contenido scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // 🧹 Logo + título centrado
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 20),

                  // 📅 Sección por mes
                  const Text(
                    'Abril',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  _buildHistoryItem('Abril, 25', 'Residencia Pedro de Valdivia',
                      '09:00AM - 10:15AM', 'Hecho'),
                  _buildHistoryItem('Abril, 25', 'Residencia Valle Grande',
                      '11:00AM - 12:15PM', 'Hecho'),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 📊 Resumen mensual fijo
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Divider(thickness: 1.2),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'Residencias este mes: 2',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
      String date, String name, String time, String status) {
    Color statusColor;
    switch (status) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(time),
          ],
        ),
        trailing: Chip(
          label: Text(status),
          backgroundColor: statusColor,
        ),
      ),
    );
  }
}
