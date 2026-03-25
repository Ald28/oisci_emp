import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:oisci_emp/features/services/domain/usecases/update_inspection_detail_usecase.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../domain/entities/service_extinguisher_entity.dart';
import '../../domain/entities/service_type.dart';
import '../../data/repositories/service_repository_impl.dart';
import 'services_scan_page.dart';
import 'services_menu_page.dart';
import 'service_extinguisher_list_page.dart';

/// Pantalla: Observaciones de servicio (inspección y mantenimiento)
class ServiceObservationsPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;
  final int servicioId;
  final int servicioExtintorId;
  final Map<String, bool> checklistItems;
  final String? rechargeAgent;
  final String? decommissionReason;
  final String? partsChangeDetails;

  const ServiceObservationsPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
    required this.servicioId,
    required this.servicioExtintorId,
    required this.checklistItems,
    this.rechargeAgent,
    this.decommissionReason,
    this.partsChangeDetails,
  });

  @override
  State<ServiceObservationsPage> createState() =>
      _ServiceObservationsPageState();
}

class _ServiceObservationsPageState extends State<ServiceObservationsPage> {
  final _observationsController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  File? _photo4File;
  String? _photo4Path;
  String? _photo4Url;

  late final UpdateInspectionDetailUseCase _updateObservationsUseCase =
      UpdateInspectionDetailUseCase(ServiceRepositoryImpl());
  late final ServiceRepositoryImpl _repository = ServiceRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadExistingObservations();
  }

  Future<void> _loadExistingObservations() async {
    try {
      // Obtener todos los servicio_extintor del servicio
      final serviceExtinguishers = await _repository
          .getServiceExtinguishersByServiceId(widget.servicioId);

      if (serviceExtinguishers.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Buscar el que coincide con nuestro servicioExtintorId
      // Si no se encuentra por ID (puede haber cambiado si se sincronizó),
      // buscar por extintorId como fallback
      ServiceExtinguisherEntity? serviceExtinguisher;
      try {
        serviceExtinguisher = serviceExtinguishers.firstWhere(
          (se) => se.id == widget.servicioExtintorId,
        );
      } catch (e) {
        // Si no se encuentra por ID, buscar por extintorId
        serviceExtinguisher = serviceExtinguishers.firstWhere(
          (se) => se.extintorId == widget.extinguisher.id,
          orElse: () =>
              serviceExtinguishers.first, // Fallback si no se encuentra
        );
      }

      // Cargar las observaciones existentes
      if (serviceExtinguisher.observaciones != null &&
          serviceExtinguisher.observaciones!.isNotEmpty) {
        _observationsController.text = serviceExtinguisher.observaciones!;
      }

      // Cargar foto4 si existe en el detalle de inspección
      final existingDetail = await _repository
          .getInspectionDetailByServiceExtinguisherId(
            serviceExtinguisher.id,
          );

      if (existingDetail != null) {
        _photo4Path = existingDetail.foto4Path;
        _photo4Url = existingDetail.foto4Url;
        
        if (_photo4Path != null && _photo4Path!.isNotEmpty) {
           _photo4File = File(_photo4Path!);
           if (!_photo4File!.existsSync()) {
              _photo4File = null;
           }
        }
      }

    } catch (e) {
      // Si hay error, continuar sin cargar observaciones
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectPhoto4() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    final hasInternet = await InternetConnectionChecker().hasConnection;

    if (hasInternet) {
      setState(() {
        _photo4File = File(image.path);
        _photo4Path = null;
      });
      
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final inspectionDir = Directory(path.join(appDir.path, 'inspecciones'));
      if (!await inspectionDir.exists()) {
        await inspectionDir.create(recursive: true);
      }

      final fileName =
          '${widget.servicioExtintorId}_foto4_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File(path.join(inspectionDir.path, fileName));
      await File(image.path).copy(savedFile.path);

      setState(() {
        _photo4Path = savedFile.path;
        _photo4File = null;
      });

    }
  }

  Future<void> _saveObservations() async {
    print('⛔ _isSaving actual: $_isSaving');
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final hasInternet = await InternetConnectionChecker().hasConnection;

      final existingDetail = await _repository
          .getInspectionDetailByServiceExtinguisherId(
            widget.servicioExtintorId,
          );

      final inspectionData = <String, dynamic>{
        'accesibilidad': existingDetail?.accesibilidad ?? 'NO',
        'ubicacion': existingDetail?.ubicacion ?? 'NO',
        'instalacion': existingDetail?.instalacion ?? 'NO',
        'instrucciones': existingDetail?.instrucciones ?? 'NO',
        'clasificacion': existingDetail?.clasificacion ?? 'NO',
        'recarga': existingDetail?.recarga ?? 'NO',
        'certificacion': existingDetail?.certificacion ?? 'NO',
        'presion': existingDetail?.presion ?? 'NO',
        'seguridad': existingDetail?.seguridad ?? 'NO',
        'estado': existingDetail?.estado ?? 'NO',
        'carga': existingDetail?.carga ?? 'NO',
        'soporte': existingDetail?.soporte ?? 'NO',
        'activacion': existingDetail?.activacion ?? 'NO',
        'manguera': existingDetail?.manguera ?? 'NO',
        'boquilla': existingDetail?.boquilla ?? 'NO',
        'abrazadera': existingDetail?.abrazadera ?? 'NO',

        // Mantener fotos anteriores si existen
        'foto1Path': existingDetail?.foto1Path,
        'foto2Path': existingDetail?.foto2Path,
        'foto3Path': existingDetail?.foto3Path,
        'foto1Url': existingDetail?.foto1Url,
        'foto2Url': existingDetail?.foto2Url,
        'foto3Url': existingDetail?.foto3Url,
      };

      // -----------------------------
      // FOTO 4 (CONSTRUCCIÓN SEGURA)
      // -----------------------------

      if (_photo4File != null) {
        inspectionData['foto4'] = _photo4File;
      }

      if (_photo4Path != null) {
        inspectionData['foto4Path'] = _photo4Path;
      }

      if (_photo4Url != null) {
        inspectionData['foto4Url'] = _photo4Url;
      }

      // -----------------------------
      // OBSERVACIONES (NO ENVIAR NULL)
      // -----------------------------

      final obsText = _observationsController.text.trim();
      
      // SIEMPRE actualizamos las observaciones genéricas en el servicio_extintor
      if (obsText.isNotEmpty) {
        await _repository.updateServiceExtinguisherObservations(
          servicioExtintorId: widget.servicioExtintorId,
          observaciones: obsText,
        );
      }

      // Solo si es inspección actualizamos la tabla inspeccion_detalle
      if (widget.serviceType == ServiceType.inspection) {
        if (obsText.isNotEmpty) {
          inspectionData['observaciones'] = obsText;
        }

        // 🔥 ELIMINAR TODOS LOS NULL
        inspectionData.removeWhere((key, value) => value == null);

        inspectionData.forEach((key, value) {
          print('$key -> $value');
        });

        await _updateObservationsUseCase.call(
          servicioExtintorId: widget.servicioExtintorId,
          inspectionData: inspectionData,
        );
      }

      // Al terminar las observaciones, marcar el extintor como completado
      await _repository.markServiceExtinguisherCompleted(
        widget.servicioExtintorId,
      );

    } catch (e) {
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar observaciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleReturnToScanner() async {
    // Guardar observaciones antes de navegar
    await _saveObservations();

    if (!mounted) return;

    // Navegar al scanner NFC para agregar otro extintor
    // Limpiar el stack hasta la primera ruta (HomePage) y luego construir el stack correcto:
    // HomePage -> ServicesMenuPage -> ServicesScanPage
    // Esto asegura que al dar atrás desde ServicesScanPage, se vaya a ServicesMenuPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ServicesMenuPage()),
      (route) => route.isFirst, // Mantener solo la primera ruta (HomePage)
    );

    // Esperar al siguiente frame para asegurar que la navegación se complete
    // antes de hacer push de ServicesScanPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServicesScanPage(
              serviceType: widget.serviceType,
              servicioId: widget.servicioId,
            ),
          ),
        );
      }
    });
  }

  Future<void> _handleListAllExtinguishers() async {
    // Guardar observaciones antes de navegar
    await _saveObservations();

    if (!mounted) return;

    // Navegar a la página de listado de extintores
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceExtinguisherListPage(
          servicioId: widget.servicioId,
          serviceType: widget.serviceType,
        ),
      ),
    );
  }

  Widget _buildPhotoOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Cambiar fotografía',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title:
            'Servicios/${widget.serviceType == ServiceType.maintenance ? 'Mantenimiento' : 'Inspección'}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE84343)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Observaciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Campo de observaciones
                  FloatingLabelTextField(
                    controller: _observationsController,
                    label: 'Observaciones',
                    hintText: 'Ingrese sus observaciones aquí...',
                    maxLines: 10,
                  ),
                  const SizedBox(height: 24),

                  // Sección de Foto 4 (Observaciones)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE84343).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFFE84343),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Evidencia Fotográfica',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Adjunte una fotografía de las observaciones encontradas en el equipo.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _isSaving ? null : _selectPhoto4,
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _photo4File != null || _photo4Path != null
                                    ? Colors.transparent
                                    : Colors.grey[300]!,
                                width: 2,
                                style: _photo4File != null || _photo4Path != null
                                    ? BorderStyle.none
                                    : BorderStyle.solid,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _photo4File != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _photo4File!,
                                        fit: BoxFit.cover,
                                      ),
                                      _buildPhotoOverlay(),
                                    ],
                                  )
                                : _photo4Path != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(
                                            File(_photo4Path!),
                                            fit: BoxFit.cover,
                                          ),
                                          _buildPhotoOverlay(),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Tomar fotografía',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botón: Agregar otro extintor
                  SecondaryButton(
                    text: 'Agregar otro extintor',
                    onPressed: _isSaving ? null : _handleReturnToScanner,
                  ),
                  const SizedBox(height: 16),
                  // Botón: Listar todos los extintores
                  PrimaryButton(
                    text: 'Listar todos los extintores',
                    onPressed: _isSaving ? null : _handleListAllExtinguishers,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
    );
  }
}
