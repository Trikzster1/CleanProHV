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

            // Card con la imagen y los datos
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/PngProfile_transparente.png',
                          height: 160,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Tu información',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text('Nombre:',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text('Franco Molina',
                                    style: TextStyle(fontSize: 17)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text('Rut:',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text('21.223.344-6',
                                    style: TextStyle(fontSize: 17)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text('Correo:',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text('CorreoExample@gmail.com',
                                    style: TextStyle(fontSize: 17)),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text('Teléfono:',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Text('+56 9 7654 3210',
                                    style: TextStyle(fontSize: 17)),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón de cerrar sesión con confirmación
            Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirmar'),
                        content: const Text(
                            '¿Estás seguro que quieres cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(); // Volver
                            },
                            child: const Text('Volver'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext)
                                  .pop(); // Cerrar diálogo
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.login);
                            },
                            child: const Text('Aceptar'),
                          ),
                        ],
                      );
                    },
                  );
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
