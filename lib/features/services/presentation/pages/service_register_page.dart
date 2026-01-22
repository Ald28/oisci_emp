import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sede_entity.dart';
import '../../domain/usecases/create_extinguisher_usecase.dart';
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import '../../data/repositories/sede_repository_impl.dart';
import '../../data/datasources/local_extinguisher_datasource.dart';
import '../../domain/constants/extinguisher_types.dart';
import 'service_data_page.dart';

/// Pantalla: Registro de extintor nuevo
class ServiceRegisterPage extends StatefulWidget {
  final ServiceType serviceType;
  final String?
  initialSerial; // Número de serie autocompletado desde NFC o búsqueda
  final int servicioId;

  const ServiceRegisterPage({
    super.key,
    required this.serviceType,
    this.initialSerial,
    required this.servicioId,
  });

  @override
  State<ServiceRegisterPage> createState() => _ServiceRegisterPageState();
}

class _ServiceRegisterPageState extends State<ServiceRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroSerieController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _numeroCilindroController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _agenteController = TextEditingController();

  String? _tipo;
  String? _agente;
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
  final LocalExtinguisherDataSource _localDataSource =
      LocalExtinguisherDataSource();

  @override
  void initState() {
    super.initState();
    // Autocompletar número de serie si viene desde NFC o búsqueda
    if (widget.initialSerial != null) {
      _numeroSerieController.text = widget.initialSerial!;
    }
    // Listener para sincronizar _agente con _agenteController
    _agenteController.addListener(_onAgenteChanged);
    _loadSedes();
  }

  void _onAgenteChanged() {
    if (_agenteController.text.trim() != (_agente ?? '')) {
      setState(() {
        _agente = _agenteController.text.trim().isEmpty
            ? null
            : _agenteController.text.trim();
      });
    }
  }

  @override
  void dispose() {
    _numeroSerieController.dispose();
    _capacidadController.dispose();
    _numeroCilindroController.dispose();
    _ubicacionController.dispose();
    _agenteController.removeListener(_onAgenteChanged);
    _agenteController.dispose();
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
        'serialNumber': _numeroSerieController.text.trim().isEmpty
            ? null
            : _numeroSerieController.text.trim(),
        'type': _tipo,
        'capacity': _capacidadController.text.trim().isEmpty
            ? null
            : _capacidadController.text.trim(),
        'agent': _agente,
        'cylinderNumber': _numeroCilindroController.text.trim().isEmpty
            ? null
            : _numeroCilindroController.text.trim(),
        'location': _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        'status': _estado,
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

      // Validar unicidad de serialNumber antes de registrar
      final serialNumber = _numeroSerieController.text.trim().isEmpty
          ? null
          : _numeroSerieController.text.trim();

      // Verificar si ya existe en SQLite (tanto sincronizados como pendientes)
      final duplicates = await _localDataSource.checkDuplicates(
        serialNumber: serialNumber,
      );

      if (duplicates['serialNumber'] == true) {
        setState(() {
          _isLoading = false;
        });

        const errorMessage =
            'Ya existe un extintor con el mismo número de serie.\n\n'
            'Nota: El número de serie debe ser único. Si continúa, tendrá problemas al sincronizar.';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
            servicioId: widget.servicioId,
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Verificar si es un error de duplicado desde el backend
      final errorMessage = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message'] as String?
          : null;

      if (errorMessage != null &&
          (errorMessage.toLowerCase().contains('unique') ||
              errorMessage.toLowerCase().contains('duplicate') ||
              errorMessage.toLowerCase().contains('ya existe') ||
              errorMessage.toLowerCase().contains('serialnumber'))) {
        // Error de duplicado desde el backend
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ya existe un extintor con el mismo número de serie.\n\n'
              'Nota: El número de serie debe ser único.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

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
      } else if (errorStr.toLowerCase().contains('unique') ||
          errorStr.toLowerCase().contains('duplicate')) {
        errorMessage =
            'Ya existe un extintor con el mismo número de serie.\n\n'
            'Nota: El número de serie debe ser único.';
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
                      // Campos del formulario (orden según imagen)
                      // 1. Nro. Serie
                      FloatingLabelTextField(
                        controller: _numeroSerieController,
                        label: 'Nro. Serie',
                        hintText: 'Nro. Serie',
                      ),
                      const SizedBox(height: 12),
                      // 2. Ubicación
                      FloatingLabelTextField(
                        controller: _ubicacionController,
                        label: 'Ubicación',
                        hintText: 'Ubicación',
                      ),
                      const SizedBox(height: 12),
                      // 3. Nro. Cilindro
                      FloatingLabelTextField(
                        controller: _numeroCilindroController,
                        label: 'Nro. Cilindro',
                        hintText: 'Nro. Cilindro',
                      ),
                      const SizedBox(height: 12),
                      // 4. Tipo (Dropdown)
                      _buildTipoDropdown(),
                      const SizedBox(height: 12),
                      // 5. Agente (Dropdown dependiente del tipo)
                      _buildAgenteDropdown(),
                      const SizedBox(height: 12),
                      // 6. Capacidad
                      FloatingLabelTextField(
                        controller: _capacidadController,
                        label: 'Capacidad',
                        hintText: 'Capacidad',
                      ),
                      const SizedBox(height: 12),
                      // 7. Estado (Dropdown)
                      _buildEstadoDropdown(),
                      const SizedBox(height: 12),
                      // Dropdown para Sede
                      _buildSedeDropdown(),
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

  Widget _buildTipoDropdown() {
    final hasValue = _tipo != null;

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
            initialValue: _tipo,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            hint: Text(
              'Tipo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
            items: ExtinguisherTypes.types.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(
                  type,
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
                _tipo = value;
                // Limpiar agente cuando cambia el tipo
                _agente = null;
                _agenteController.clear();
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
                'Tipo',
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

  Widget _buildAgenteDropdown() {
    final hasValue = _agente != null;
    final agentsData = ExtinguisherTypes.getAgentsByType(_tipo);
    final predefinedAgents = agentsData['predefined'] as List<String>;
    final hasOther = agentsData['hasOther'] as bool;
    final requiresSelection = ExtinguisherTypes.requiresAgentSelection(_tipo);

    // Si el tipo no requiere selección de agente, mostrar campo de texto libre
    if (!requiresSelection) {
      // Sincronizar el controller con el estado si es necesario
      if (_agente != null && _agenteController.text != _agente) {
        _agenteController.text = _agente!;
      }
      return FloatingLabelTextField(
        controller: _agenteController,
        label: 'Agente',
        hintText: 'Agente',
      );
    }

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
            initialValue: _agente,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            hint: Text(
              'Agente',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
            items: [
              ...predefinedAgents.map((agent) {
                return DropdownMenuItem<String>(
                  value: agent,
                  child: Text(
                    agent,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }),
              // Si hay un agente personalizado que no está en la lista predefinida, mostrarlo
              if (_agente != null &&
                  !predefinedAgents.contains(_agente) &&
                  _agente != '__OTROS__')
                DropdownMenuItem<String>(
                  value: _agente,
                  child: Text(
                    _agente!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              if (hasOther)
                DropdownMenuItem<String>(
                  value: '__OTROS__',
                  child: Text(
                    'Otros: ____',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            onChanged: (value) async {
              if (value == '__OTROS__') {
                // Guardar el valor anterior temporalmente
                final previousAgent = _agente;
                // Establecer temporalmente para que el dropdown muestre la selección
                setState(() {
                  _agente = '__OTROS__';
                });
                // Mostrar modal para ingresar texto libre
                final customAgent = await _showOtherAgentModal();
                if (customAgent != null && customAgent.isNotEmpty) {
                  setState(() {
                    _agente = customAgent;
                  });
                } else {
                  // Si se cancela el modal, restaurar el valor anterior
                  setState(() {
                    _agente = previousAgent;
                  });
                }
              } else {
                setState(() {
                  _agente = value;
                });
              }
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
                'Agente',
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

  /// Mostrar modal para ingresar agente personalizado
  Future<String?> _showOtherAgentModal() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar Agente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Agente',
            hintText: 'Ingrese el nombre del agente',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84343),
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
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
