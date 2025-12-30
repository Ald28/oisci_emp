import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sede.dart';
import '../../domain/usecases/create_extinguisher_usecase.dart';
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import '../../data/repositories/sede_repository_impl.dart';
import 'service_data_page.dart';

/// Pantalla: Registro de extintor nuevo
class ServiceRegisterPage extends StatefulWidget {
  final ServiceType serviceType;

  const ServiceRegisterPage({super.key, required this.serviceType});

  @override
  State<ServiceRegisterPage> createState() => _ServiceRegisterPageState();
}

class _ServiceRegisterPageState extends State<ServiceRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoNFCController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _tipoController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _agenteController = TextEditingController();
  final _numeroCilindroController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _historicoController = TextEditingController();
  final _fechaBajaController = TextEditingController();
  final _fotoController = TextEditingController();

  String? _estado;
  int? _sedeId;
  bool _isLoading = false;
  bool _isLoadingSedes = false;
  List<Sede> _sedes = [];

  late final CreateExtinguisherUseCase _createUseCase =
      CreateExtinguisherUseCase(ExtinguisherRepositoryImpl());
  late final GetSedesUseCase _getSedesUseCase = GetSedesUseCase(
    SedeRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  @override
  void dispose() {
    _codigoNFCController.dispose();
    _numeroSerieController.dispose();
    _tipoController.dispose();
    _capacidadController.dispose();
    _agenteController.dispose();
    _numeroCilindroController.dispose();
    _ubicacionController.dispose();
    _historicoController.dispose();
    _fechaBajaController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  Future<void> _loadSedes() async {
    setState(() {
      _isLoadingSedes = true;
    });

    try {
      final sedes = await _getSedesUseCase();

      if (mounted) {
        setState(() {
          _sedes = sedes;
          _isLoadingSedes = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSedes = false;
        });
        // Usar el helper reutilizable para manejar errores
        ErrorHandler.handleDioError(
          context,
          e,
          customMessage:
              'Error al cargar sedes: ${ErrorHandler.getErrorMessage(e)}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSedes = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sedes: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'codeNFC': _codigoNFCController.text.trim().isEmpty
            ? null
            : _codigoNFCController.text.trim(),
        'serialNumber': _numeroSerieController.text.trim().isEmpty
            ? null
            : _numeroSerieController.text.trim(),
        'type': _tipoController.text.trim().isEmpty
            ? null
            : _tipoController.text.trim(),
        'capacity': _capacidadController.text.trim().isEmpty
            ? null
            : _capacidadController.text.trim(),
        'agent': _agenteController.text.trim().isEmpty
            ? null
            : _agenteController.text.trim(),
        'cylinderNumber': _numeroCilindroController.text.trim().isEmpty
            ? null
            : _numeroCilindroController.text.trim(),
        'location': _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        'status': _estado,
        'historic': _historicoController.text.trim().isEmpty
            ? null
            : _historicoController.text.trim(),
        'dateLow': _fechaBajaController.text.trim().isEmpty
            ? null
            : _fechaBajaController.text.trim(),
        'photo': _fotoController.text.trim().isEmpty
            ? null
            : _fotoController.text.trim(),
        'sedeId': _sedeId,
      };

      if (_sedeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una sede'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verificar conectividad antes de registrar
      final hasInternet = await InternetConnectionChecker().hasConnection;

      final extinguisher = await _createUseCase.call(data);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje según si se guardó localmente o en el servidor
      if (!hasInternet || extinguisher.id == 0) {
        // Se guardó localmente (sin internet o ID temporal)
        final syncService = SyncService();
        final pendingCount = await syncService.getPendingCount();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Extintor guardado localmente. Se sincronizará automáticamente cuando haya conexión.\n'
              'Pendientes: $pendingCount',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Se guardó en el servidor
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extintor registrado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Si se guardó localmente (ID = 0), intentar sincronizar en background
      if (extinguisher.id == 0) {
        final syncService = SyncService();
        syncService.syncPendingExtinguishers().then((syncedCount) {
          if (syncedCount > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$syncedCount extintor(es) sincronizado(s)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDataPage(
            extinguisher: extinguisher,
            serviceType: widget.serviceType,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Usar el helper reutilizable para manejar errores
      ErrorHandler.handleDioError(
        context,
        e,
        customMessage:
            'Error al registrar extintor: ${ErrorHandler.getErrorMessage(e)}',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje de error más amigable
      String errorMessage = 'Error al registrar extintor';
      final errorStr = e.toString();

      if (errorStr.contains('sedeId')) {
        errorMessage = 'Por favor selecciona una sede antes de registrar';
      } else if (errorStr.contains('usuario') || errorStr.contains('sesión')) {
        errorMessage = 'Error de sesión. Por favor, inicia sesión nuevamente';
      } else if (errorStr.contains('Null') && errorStr.contains('int')) {
        errorMessage =
            'Error: Faltan datos requeridos. Por favor, completa todos los campos obligatorios';
      } else {
        errorMessage = 'Error al registrar extintor: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Servicios',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Título Registro de Extintor
                      const Text(
                        'Registro de Extintor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Campos del formulario
                      FloatingLabelTextField(
                        controller: _codigoNFCController,
                        label: 'Código NFC',
                        hintText: 'Código NFC',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _numeroSerieController,
                        label: 'Nro. Serie',
                        hintText: 'Nro. Serie',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _tipoController,
                        label: 'Tipo',
                        hintText: 'Tipo',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _capacidadController,
                        label: 'Capacidad',
                        hintText: 'Capacidad',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _agenteController,
                        label: 'Agente',
                        hintText: 'Agente',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _numeroCilindroController,
                        label: 'Nro. Cilindro',
                        hintText: 'Nro. Cilindro',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _ubicacionController,
                        label: 'Ubicación',
                        hintText: 'Ubicación',
                      ),
                      const SizedBox(height: 12),
                      // Dropdown para Sede
                      _buildSedeDropdown(),
                      const SizedBox(height: 12),
                      // Dropdown para Estado
                      _buildEstadoDropdown(),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _historicoController,
                        label: 'Histórico',
                        hintText: 'Histórico',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _fechaBajaController,
                        label: 'Fecha de Baja',
                        hintText: 'Fecha de Baja',
                      ),
                      const SizedBox(height: 12),
                      FloatingLabelTextField(
                        controller: _fotoController,
                        label: 'Foto (URL)',
                        hintText: 'Foto (URL)',
                      ),
                      const SizedBox(height: 32),
                      // Botón Registrar
                      PrimaryButton(
                        text: 'Registrar',
                        onPressed: _isLoading ? null : _handleRegister,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    final hasValue = _estado != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _estado,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            hint: Text(
              'Estado',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'OPERATIVO',
                child: Text(
                  'OPERATIVO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'INOPERATIVO',
                child: Text(
                  'INOPERATIVO',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _estado = value;
              });
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        if (hasValue)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Estado',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSedeDropdown() {
    final hasValue = _sedeId != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isLoadingSedes
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<int>(
                  initialValue: _sedeId,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  hint: Text(
                    'Sede',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                  items: _sedes.map((sede) {
                    return DropdownMenuItem<int>(
                      value: sede.id,
                      child: Text(
                        sede.nameSede,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sedeId = value;
                    });
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
        ),
        if (hasValue)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sede',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
