import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../../../core/widgets/floating_label_date_picker.dart';
import '../../../../core/widgets/floating_label_year_picker.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sede_entity.dart';
import '../../domain/usecases/create_extinguisher_usecase.dart';
import '../../domain/usecases/get_sedes_usecase.dart';
import '../../data/repositories/extinguisher_repository_impl.dart';
import '../../data/repositories/sede_repository_impl.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/repositories/extinguisher_repository.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../data/datasources/local_extinguisher_datasource.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/constants/extinguisher_types.dart';
import 'service_data_page.dart';

/// Pantalla: Registro de extintor nuevo
class ServiceRegisterPage extends StatefulWidget {
  final ServiceType serviceType;
  final String?
  initialSerial; // Número de serie autocompletado desde NFC o búsqueda
  final int servicioId;
  final int? initialSedeId; // Sede pre-seleccionada del servicio

  const ServiceRegisterPage({
    super.key,
    required this.serviceType,
    this.initialSerial,
    required this.servicioId,
    this.initialSedeId,
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
  final _pressureController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _ratingController = TextEditingController();
  
  // Para año y fechas
  int? _selectedYearManufacture;
  DateTime? _selectedDateHydrostatic;
  DateTime? _selectedDateMaintenance;

  String? _tipo;
  String? _agente;
  String? _estado;
  int? _sedeId;
  bool _isLoading = false;
  bool _isLoadingSedes = false;
  List<Sede> _sedes = [];
  
  // Para vincular con extintor existente sin número de serie
  Extinguisher? _selectedExtinguisher; // Extintor seleccionado para actualizar
  bool _isLoadingExtinguishers = false;

  late final CreateExtinguisherUseCase _createUseCase =
      CreateExtinguisherUseCase(ExtinguisherRepositoryImpl());
  late final ExtinguisherRepository _extinguisherRepository =
      ExtinguisherRepositoryImpl();
  late final GetSedesUseCase _getSedesUseCase = GetSedesUseCase(
    SedeRepositoryImpl(),
  );
  late final ServiceRepository _serviceRepository = ServiceRepositoryImpl();
  final LocalExtinguisherDataSource _localDataSource =
      LocalExtinguisherDataSource();

  @override
  void initState() {
    super.initState();
    // Autocompletar número de serie si viene desde NFC o búsqueda
    if (widget.initialSerial != null && widget.initialSerial!.isNotEmpty) {
      _numeroSerieController.text = widget.initialSerial!;
    }
    // Pre-seleccionar sede si viene como parámetro o obtenerla del servicio
    if (widget.initialSedeId != null) {
      _sedeId = widget.initialSedeId;
    } else {
      // Si no se proporciona initialSedeId, obtenerla del servicio
      _loadServiceSede();
    }
    // Listener para sincronizar _agente con _agenteController
    _agenteController.addListener(_onAgenteChanged);
    _loadSedes();
  }
  
  Future<void> _loadServiceSede() async {
    try {
      final service = await _serviceRepository.getServiceById(widget.servicioId);
      if (service != null && mounted) {
        setState(() {
          _sedeId = service.sedeId;
        });
      } else if (mounted) {
        // Si no se encuentra el servicio, intentar obtener desde local directamente
        debugPrint('Servicio no encontrado, intentando obtener desde local...');
        try {
          final db = await AppDatabase.database;
          final result = await db.query(
            'servicio',
            where: 'id = ?',
            whereArgs: [widget.servicioId],
            limit: 1,
          );
          if (result.isNotEmpty && mounted) {
            setState(() {
              _sedeId = result.first['sedeId'] as int?;
            });
          }
        } catch (e2) {
          debugPrint('Error al obtener sede desde local: $e2');
        }
      }
    } catch (e) {
      // Si hay error, continuar sin pre-seleccionar sede
      debugPrint('Error al obtener sede del servicio: $e');
      // Intentar obtener desde local como último recurso
      try {
        final db = await AppDatabase.database;
        final result = await db.query(
          'servicio',
          where: 'id = ?',
          whereArgs: [widget.servicioId],
          limit: 1,
        );
        if (result.isNotEmpty && mounted) {
          setState(() {
            _sedeId = result.first['sedeId'] as int?;
          });
        }
      } catch (e2) {
        debugPrint('Error al obtener sede desde local: $e2');
      }
    }
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
    _pressureController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _ratingController.dispose();
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
        'pressure': _pressureController.text.trim().isEmpty
            ? null
            : _pressureController.text.trim(),
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'model': _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        'rating': _ratingController.text.trim().isEmpty
            ? null
            : _ratingController.text.trim(),
        'yearManufacture': _selectedYearManufacture?.toString(),
        'dateHydrostatic': _selectedDateHydrostatic != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDateHydrostatic!)
            : null,
        'dateMaintenance': _selectedDateMaintenance != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDateMaintenance!)
            : null,
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

      final Extinguisher extinguisher;
      
      // Si hay un extintor seleccionado, hacer UPDATE en lugar de CREATE
      if (_selectedExtinguisher != null) {
        extinguisher = await _extinguisherRepository.updateExtinguisher(
          _selectedExtinguisher!.id,
          data,
        );
      } else {
        extinguisher = await _createUseCase.call(data);
      }

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
                      // 1. Nro. Serie con botón para vincular extintor existente
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FloatingLabelTextField(
                              controller: _numeroSerieController,
                              label: 'Nro. Serie',
                              hintText: 'Nro. Serie',
                            ),
                          ),
                          if (_sedeId != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _isLoadingExtinguishers
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE84343)),
                                      ),
                                    )
                                  : const Icon(Icons.link),
                              tooltip: 'Vincular con extintor existente sin número de serie',
                              onPressed: _isLoadingExtinguishers ? null : _showLinkExtinguisherModal,
                              color: const Color(0xFFE84343),
                            ),
                          ],
                        ],
                      ),
                      // Mostrar información si hay un extintor seleccionado
                      if (_selectedExtinguisher != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Actualizando extintor ID: ${_selectedExtinguisher!.id}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vinculando Nro Serie: ${_numeroSerieController.text.trim().isEmpty ? "N/A" : _numeroSerieController.text.trim()}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _clearFormData,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      // 8. Presión
                      FloatingLabelTextField(
                        controller: _pressureController,
                        label: 'Presión',
                        hintText: 'Presión',
                      ),
                      const SizedBox(height: 12),
                      // 9. Marca
                      FloatingLabelTextField(
                        controller: _brandController,
                        label: 'Marca',
                        hintText: 'Marca',
                      ),
                      const SizedBox(height: 12),
                      // 10. Modelo
                      FloatingLabelTextField(
                        controller: _modelController,
                        label: 'Modelo',
                        hintText: 'Modelo',
                      ),
                      const SizedBox(height: 12),
                      // 11. Clasificación
                      FloatingLabelTextField(
                        controller: _ratingController,
                        label: 'Clasificación',
                        hintText: 'Clasificación',
                      ),
                      const SizedBox(height: 12),
                      // 12. Año de Fabricación
                      FloatingLabelYearPicker(
                        selectedYear: _selectedYearManufacture,
                        label: 'Año de Fabricación',
                        hintText: 'Año de Fabricación',
                        firstYear: 1950,
                        lastYear: DateTime.now().year + 10,
                        onYearSelected: (year) {
                          setState(() {
                            _selectedYearManufacture = year;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // 13. Fecha Hidrostática
                      FloatingLabelDatePicker(
                        selectedDate: _selectedDateHydrostatic,
                        label: 'Fecha Hidrostática',
                        hintText: 'Fecha Hidrostática',
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDateHydrostatic = date;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // 14. Fecha de Mantenimiento
                      FloatingLabelDatePicker(
                        selectedDate: _selectedDateMaintenance,
                        label: 'Fecha de Mantenimiento',
                        hintText: 'Fecha de Mantenimiento',
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDateMaintenance = date;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Dropdown para Sede
                      _buildSedeDropdown(),
                      const SizedBox(height: 32),
                      // Botón Registrar
                      PrimaryButton(
                        text: _selectedExtinguisher != null ? 'Actualizar' : 'Registrar',
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

  Future<void> _showLinkExtinguisherModal() async {
    if (_sedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una sede primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingExtinguishers = true;
    });

    try {
      final extinguishers = await _extinguisherRepository.getExtinguishersWithoutSerialNumber(
        sedeId: _sedeId,
      );

      if (!mounted) return;

      setState(() {
        _isLoadingExtinguishers = false;
      });

      if (extinguishers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay extintores sin número de serie en esta sede'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar modal con lista de extintores
      final selected = await showDialog<Extinguisher>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE84343),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vincular con Extintor Existente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Lista de extintores
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: extinguishers.length,
                    itemBuilder: (context, index) {
                      final extinguisher = extinguishers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE84343),
                            child: Text(
                              '${extinguisher.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            'ID: ${extinguisher.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (extinguisher.type != null)
                                Text('Tipo: ${extinguisher.type}'),
                              if (extinguisher.location != null)
                                Text('Ubicación: ${extinguisher.location}'),
                              if (extinguisher.status != null)
                                Text('Estado: ${extinguisher.status}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context, extinguisher);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected != null && mounted) {
        _fillFormWithExtinguisher(selected);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingExtinguishers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar extintores: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _fillFormWithExtinguisher(Extinguisher extinguisher) {
    setState(() {
      _selectedExtinguisher = extinguisher;
      
      // Autocompletar campos del formulario
      // El número de serie ya está en el campo (viene del escaneo/búsqueda)
      // No lo sobrescribimos
      
      if (extinguisher.location != null) {
        _ubicacionController.text = extinguisher.location!;
      }
      if (extinguisher.cylinderNumber != null) {
        _numeroCilindroController.text = extinguisher.cylinderNumber!;
      }
      if (extinguisher.type != null) {
        _tipo = extinguisher.type;
      }
      if (extinguisher.agent != null) {
        _agente = extinguisher.agent;
        _agenteController.text = extinguisher.agent!;
      }
      if (extinguisher.capacity != null) {
        _capacidadController.text = extinguisher.capacity!;
      }
      if (extinguisher.status != null) {
        _estado = extinguisher.status;
      }
      if (extinguisher.pressure != null) {
        _pressureController.text = extinguisher.pressure!;
      }
      if (extinguisher.brand != null) {
        _brandController.text = extinguisher.brand!;
      }
      if (extinguisher.model != null) {
        _modelController.text = extinguisher.model!;
      }
      if (extinguisher.rating != null) {
        _ratingController.text = extinguisher.rating!;
      }
      if (extinguisher.yearManufacture != null) {
        _selectedYearManufacture = int.tryParse(extinguisher.yearManufacture!);
      }
      if (extinguisher.dateHydrostatic != null) {
        try {
          _selectedDateHydrostatic = DateTime.parse(extinguisher.dateHydrostatic!);
        } catch (e) {
          // Ignorar error de parsing
        }
      }
      if (extinguisher.dateMaintenance != null) {
        try {
          _selectedDateMaintenance = DateTime.parse(extinguisher.dateMaintenance!);
        } catch (e) {
          // Ignorar error de parsing
        }
      }
      // La sede ya está seleccionada, no la cambiamos
    });
  }

  void _clearFormData() {
    setState(() {
      // Limpiar el extintor seleccionado
      _selectedExtinguisher = null;
      
      // Limpiar todos los campos excepto el número de serie
      // El número de serie se mantiene porque viene del escaneo/búsqueda
      _ubicacionController.clear();
      _numeroCilindroController.clear();
      _tipo = null;
      _agente = null;
      _agenteController.clear();
      _capacidadController.clear();
      _estado = null;
      _pressureController.clear();
      _brandController.clear();
      _modelController.clear();
      _ratingController.clear();
      _selectedYearManufacture = null;
      _selectedDateHydrostatic = null;
      _selectedDateMaintenance = null;
      
      // La sede se mantiene porque es del servicio actual
    });
  }
}
