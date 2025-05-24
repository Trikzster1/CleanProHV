import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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

            _buildResidenceItem(
              context,
              'Recoleta',
              'Marino lobera 1679',
              'En Proceso',
            ),
            _buildResidenceItem(
              context,
              'Pudahuel',
              'Cerro campana 1001',
              'Pendiente',
            ),
            _buildResidenceItem(
              context,
              'Quilicura',
              'Valle grande 0102',
              'Pendiente',
            ),
            _buildResidenceItem(
              context,
              'San Miguel',
              'Lo rodriguez 104',
              'Pendiente',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidenceItem(
      BuildContext context, String comuna, String direccion, String status) {
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
            const SizedBox(height: 4),
            Text(comuna, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(direccion),
          ],
        ),
        trailing: Chip(
          label: Text(status),
          backgroundColor: statusColor,
        ),
        onTap: status == 'En Proceso'
            ? () {
                Navigator.pushNamed(context, AppRoutes.detail);
              }
            : null,
      ),
    );
  }
}
