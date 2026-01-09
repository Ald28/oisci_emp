import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/service_notifications_modal.dart';
import '../../../../core/widgets/action_button_expand.dart';
import '../../../../core/widgets/sync_progress_banner.dart';
import '../../../../core/sync/initial_sync_service.dart';
import '../../../../core/sync/sync_progress_controller.dart';
import '../../../services/presentation/pages/services_menu_page.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../services/domain/usecases/get_services_in_progress_usecase.dart';
import '../../../services/data/repositories/service_repository_impl.dart';
import '../../../../core/auth/auth_service.dart';

/// Página principal del Home con AppBar y Drawer
class HomePage extends StatefulWidget {
  final String userId;
  final String name;

  const HomePage({super.key, required this.userId, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentTitle = 'Inicio';
  String? _userEmail;
  bool _isSyncing = false;
  String _syncStep = '';
  double _syncProgress = 0.0;
  String? _syncError;
  StreamSubscription<Map<String, dynamic>>? _syncProgressSubscription;
  List<ServiceEntity> _servicesInProgress = [];

  late final GetServicesInProgressUseCase _getServicesInProgressUseCase =
      GetServicesInProgressUseCase(ServiceRepositoryImpl());

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    _checkAndSyncInitialData();
    _listenToAutoSyncProgress();
    _checkServiceInProgress();
  }

  Future<void> _checkServiceInProgress() async {
    if (!mounted) return;

    try {
      final services = await _getServicesInProgressUseCase.call();

      if (mounted) {
        setState(() {
          _servicesInProgress = services;
        });
      }
    } catch (e) {
      // Si hay error, no mostrar notificaciones
      if (mounted) {
        setState(() {
          _servicesInProgress = [];
        });
      }
    }
  }

  void _handleShowNotifications() {
    showDialog(
      context: context,
      builder: (context) =>
          ServiceNotificationsModal(servicesInProgress: _servicesInProgress),
    );
  }

  Widget _buildNotificationIcon() {
    final count = _servicesInProgress.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _handleShowNotifications,
          tooltip: 'Notificaciones',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _syncProgressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final session = await AuthService.loadSession();
    setState(() {
      _userEmail = session['email'] ?? 'usuario@example.com';
    });
  }

  /// Escuchar el progreso de sincronización automática
  void _listenToAutoSyncProgress() {
    _syncProgressSubscription = SyncProgressController().progressStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _isSyncing = true;
            _syncStep = data['step'] as String? ?? 'Sincronizando...';
            _syncProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
            _syncError = data['error'] as String?;

            // Si está completado o hay error, ocultar después de un momento
            if (_syncProgress >= 1.0 || _syncError != null) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _isSyncing = false;
                  });
                }
              });
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _syncError = 'Error: ${error.toString()}';
            _isSyncing = false;
          });
        }
      },
    );
  }

  /// Verificar si necesita sincronización inicial y ejecutarla
  Future<void> _checkAndSyncInitialData() async {
    final initialSyncService = InitialSyncService();
    final needsSync = await initialSyncService.needsInitialSync();

    if (needsSync) {
      setState(() {
        _isSyncing = true;
        _syncStep = 'Iniciando...';
        _syncProgress = 0.0;
        _syncError = null;
      });

      // Escuchar el stream de progreso
      initialSyncService.syncInitialData().listen(
        (data) {
          if (mounted) {
            setState(() {
              _syncStep = data['step'] as String? ?? 'Procesando...';
              _syncProgress = (data['progress'] as num?)?.toDouble() ?? 0.0;
              _syncError = data['error'] as String?;

              // Si está completado o hay error, ocultar después de un momento
              if (_syncProgress >= 1.0 || _syncError != null) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _isSyncing = false;
                    });
                  }
                });
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _syncError = 'Error: ${error.toString()}';
              _isSyncing = false;
            });
          }
        },
      );
    }
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
        actions: [_buildNotificationIcon()],
      ),
      drawer: MainDrawer(
        userName: widget.name,
        userEmail: _userEmail ?? 'usuario@example.com',
        onMenuItemSelected: _handleMenuItemSelected,
      ),
      body: Column(
        children: [
          // Banner de progreso de sincronización (si está sincronizando)
          if (_isSyncing || _syncError != null)
            SyncProgressBanner(
              step: _syncStep,
              progress: _syncProgress,
              error: _syncError,
            ),
          // Contenido principal
          Expanded(
            child: RefreshIndicator(
              onRefresh: _checkServiceInProgress,
              color: const Color(0xFFE84343),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
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
                          MaterialPageRoute(builder: (_) => ServicesMenuPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
