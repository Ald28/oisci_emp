import 'package:flutter/material.dart';
import '../../../users/presentation/login_page.dart';
import '../../../../core/auth/auth_service.dart';

/// Menú lateral (Drawer) del Home
class MainDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final Function(String) onMenuItemSelected;

  const MainDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onMenuItemSelected,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Usar logout() en lugar de clearSession() para mantener credenciales para login offline
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header del Drawer
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE84343),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE84343),
                ),
              ),
            ),
          ),

          // Menú de navegación
          _buildMenuItem(
            context,
            icon: Icons.home,
            title: 'Inicio',
            onTap: () {
              Navigator.pop(context);
              onMenuItemSelected('Inicio');
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () {
              Navigator.pop(context);
              onMenuItemSelected('Configuración');
            },
          ),

          const Divider(),

          // Cerrar sesión
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            onTap: () => _handleLogout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }
}


