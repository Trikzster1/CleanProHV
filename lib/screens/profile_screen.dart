import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                  'Perfil',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 1.2),
            const SizedBox(height: 20),

            // 👤 Imagen de perfil centrada
            Center(
              child: Image.asset(
                'assets/images/PngProfile_transparente.png',
                height: 160,
              ),
            ),
            const SizedBox(height: 20),

            // 👤 Información centrada
            const Center(
              child: Text(
                'Tu información',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Nombre: Vicente Mena'),
            const Text('Rut: 21.129.054-4'),
            const Text('Correo electrónico: CorreoExample@gmail.com'),
            const Text('Residencias totales completadas: 2'),
            const Spacer(),

            // 🔒 Botón cerrar sesión
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('Cerrar Sesión'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
