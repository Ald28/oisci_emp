import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../../../../core/widgets/action_button_expand.dart';
import '../../../services/presentation/pages/services_menu_page.dart';
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
      backgroundColor: const Color(0xFFEAEAEA),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Mensaje de bienvenida
            Text(
              'Bienvenido, ${widget.name} 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona la actividad a realizar:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 28),
            // Botón de Servicios (ancho completo)
            ActionButtonExpand(
              icon: Icons.handyman,
              title: 'Servicios',
              subtitle: 'Gestionar servicios',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServicesMenuPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


