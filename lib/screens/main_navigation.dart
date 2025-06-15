import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 0 ? Colors.blue : Colors.transparent,
              ),
              child: Icon(
                Icons.home,
                color: _currentIndex == 0 ? Colors.white : Colors.grey,
              ),
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 1 ? Colors.blue : Colors.transparent,
              ),
              child: Icon(
                Icons.history,
                color: _currentIndex == 1 ? Colors.white : Colors.grey,
              ),
            ),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 2 ? Colors.blue : Colors.transparent,
              ),
              child: Icon(
                Icons.person,
                color: _currentIndex == 2 ? Colors.white : Colors.grey,
              ),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
