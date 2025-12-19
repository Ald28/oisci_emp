import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../../../../core/auth/auth_service.dart';

/// Página principal del Home con AppBar y Drawer
class HomePage extends StatefulWidget {
  final String userId;
  final String name;

  const HomePage({
    super.key,
    required this.userId,
    required this.name,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentTitle = 'Inicio';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final session = await AuthService.loadSession();
    setState(() {
      _userEmail = session['email'] ?? 'usuario@example.com';
    });
  }

  void _handleMenuItemSelected(String menuItem) {
    setState(() {
      _currentTitle = menuItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        title: _currentTitle,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: MainDrawer(
        userName: widget.name,
        userEmail: _userEmail ?? 'usuario@example.com',
        onMenuItemSelected: _handleMenuItemSelected,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, ${widget.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona una opción del menú para comenzar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


