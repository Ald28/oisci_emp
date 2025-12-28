import 'package:flutter/material.dart';
import 'core/auth/auth_service.dart';
import 'features/users/presentation/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

/// GlobalKey para el Navigator, usado por el interceptor para redirecciones globales
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  Future<Map<String, dynamic>> _loadSession() async {
    return await AuthService.loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: FutureBuilder(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data!;
          final token = session["accessToken"];
          final userId = session["userId"];
          final name = session["name"];

          if (token != null && userId != null && name != null) {
            return HomePage(userId: userId, name: name);
          }

          return LoginPage();
        },
      ),
    );
  }
}
