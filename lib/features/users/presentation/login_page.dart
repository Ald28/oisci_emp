import 'package:flutter/material.dart';
import 'widgets/auth_card.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/sync/sede_sync_service.dart';
import '../../../core/sync/extinguisher_sync_service.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../users/data/user_repository_impl.dart';
import '../../users/data/datasources/user_remote_datasource.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;

  final repo = UserRepositoryImpl(UserRemoteDataSource());

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validar campos vacíos
    if (email.isEmpty || password.isEmpty) {
      _msg("Por favor completa todos los campos");
      return;
    }

    final hasInternet = await InternetConnectionChecker().hasConnection;

    // =========================
    // LOGIN OFFLINE
    // =========================
    if (!hasInternet) {
      final session = await AuthService.loadSession();

      // Verificar si hay credenciales guardadas (email y password)
      final savedEmail = session["email"] as String?;
      final savedPassword = session["password"] as String?;

      if (savedEmail == null || savedPassword == null) {
        _msg(
          "No hay sesión guardada. Se requiere conexión a internet para iniciar sesión por primera vez.",
        );
        return;
      }

      // Verificar que las credenciales ingresadas coincidan con las guardadas
      if (savedEmail != email || savedPassword != password) {
        _msg("Credenciales incorrectas");
        return;
      }

      // Si hay token guardado, verificar que el rol sea técnico
      final savedToken = session["accessToken"] as String?;
      final savedRole = session["role"] as String?;
      final savedUserId = session["userId"] as String?;
      final savedName = session["name"] as String?;

      // Si hay token y datos completos, verificar rol
      if (savedToken != null && savedToken.isNotEmpty) {
        if (savedRole != "tecnico") {
          _msg("Acceso permitido solo para técnicos");
          return;
        }

        // Si hay userId y name, usar esos datos
        if (savedUserId != null && savedName != null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(userId: savedUserId, name: savedName),
            ),
          );
          return;
        }
      }

      // Si no hay token pero las credenciales coinciden,
      // permitir acceso pero mostrar advertencia de que algunas funciones pueden no estar disponibles
      if (savedRole == "tecnico" && savedUserId != null && savedName != null) {
        // Permitir acceso con datos guardados (aunque el token haya expirado)
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userId: savedUserId, name: savedName),
          ),
        );
        return;
      }

      // Si no hay datos suficientes
      _msg(
        "No hay sesión guardada. Se requiere conexión a internet para iniciar sesión por primera vez.",
      );
      return;
    }

    // =========================
    // LOGIN ONLINE
    // =========================
    try {
      final user = await repo.login(email, password);

      // 🚫 BLOQUEO POR ROL
      if (user.role != "tecnico") {
        _msg("Acceso permitido solo para técnicos");
        return;
      }

      // Guardar sesión para uso offline futuro
      await AuthService.saveSession(
        accessToken: user.accessToken,
        refreshToken: user.refreshToken,
        userId: user.userId.toString(),
        name: user.name,
        role: user.role,
        email: user.email,
        password: password,
      );

      // Sincronizar datos en background (descargar y guardar localmente)
      _syncSedesInBackground();
      _syncExtinguishersInBackground();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomePage(userId: user.userId.toString(), name: user.name),
        ),
      );
    } catch (e) {
      _msg("Credenciales incorrectas");
    }
  }

  void _msg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Sincronizar sedes en background después del login
  void _syncSedesInBackground() {
    // Ejecutar en background sin bloquear la UI
    SedeSyncService().syncSedes().then((success) {
      // Silenciar errores de sincronización en background
      // Las sedes se pueden cargar desde local si falla
    });
  }

  /// Descargar extintores en background después del login
  void _syncExtinguishersInBackground() {
    // Ejecutar en background sin bloquear la UI
    ExtinguisherSyncService().syncExtinguishers().then((success) {
      // Silenciar errores de sincronización en background
      // Los extintores se pueden cargar desde local si falla
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE84343),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset(
                  'assets/icon/OISCI.png',
                  height: 90,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                AuthCard(
                  title: "Iniciar Sesión",
                  buttonText: "INGRESAR",
                  onSubmit: login,
                  fields: [
                    _input("Usuario", "Ingresa tu usuario", emailController),
                    const SizedBox(height: 16),
                    _passwordInput(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _passwordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Contraseña"),
        const SizedBox(height: 6),
        TextField(
          controller: passwordController,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: "Ingresa tu contraseña",
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => showPassword = !showPassword);
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
