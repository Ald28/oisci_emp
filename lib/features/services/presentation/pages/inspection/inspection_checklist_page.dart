import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/database/app_database.dart';
import '../../../domain/entities/extinguisher_entity.dart';
import '../../../domain/entities/service_type.dart';
import '../../../domain/entities/service_extinguisher_entity.dart';
import '../../../domain/usecases/create_inspection_detail_usecase.dart';
import '../../../domain/usecases/update_inspection_detail_usecase.dart';
import '../../../domain/usecases/get_inspection_detail_by_service_extinguisher_id_usecase.dart';
import '../../../domain/usecases/get_service_extinguishers_by_service_id_usecase.dart';
import '../../../data/repositories/service_repository_impl.dart';
import '../../widgets/inspection_checklist_item.dart';
import '../../widgets/service_extinguisher_cart_modal.dart';
import '../service_observations_page.dart';

/// Pantalla: Checklist de Inspección
class InspectionChecklistPage extends StatefulWidget {
  final Extinguisher extinguisher;
  final ServiceType serviceType;
  final int servicioId;
  final int servicioExtintorId;

  const InspectionChecklistPage({
    super.key,
    required this.extinguisher,
    required this.serviceType,
    required this.servicioId,
    required this.servicioExtintorId,
  });

  @override
  State<InspectionChecklistPage> createState() =>
      _InspectionChecklistPageState();
}

class _InspectionChecklistPageState extends State<InspectionChecklistPage>
    with SingleTickerProviderStateMixin {
  // Estado de los items del checklist (true/false)
  Map<String, bool> _checklistItems = {
    'ACCESIBILIDAD': true,
    'UBICACION': true,
    'INSTALACION': true,
    'INSTRUCCIONES': true,
    'CLASIFICACION': true,
    'RECARGA': true,
    'CERTIFICACION': true,
    'PRESION': true,
    'SEGURIDAD': true,
    'ESTADO': true,
    'CARGA': true,
    'SOPORTE': true,
    'ACTIVACION': true,
    'MANGUERA': true,
    'BOQUILLA': true,
    'ABRAZADERA': true,
  };

  final List<Map<String, String>> _checklistConfig = [
    {'id': 'ACCESIBILIDAD', 'label': 'Acceso libre'},
    {'id': 'UBICACION', 'label': 'Ubicación y numeración'},
    {'id': 'INSTALACION', 'label': 'Instalación según NTP'},
    {'id': 'INSTRUCCIONES', 'label': 'Pictograma de uso'},
    {'id': 'CLASIFICACION', 'label': 'Pictograma clase fuego'},
    {'id': 'RECARGA', 'label': 'Etiqueta recarga vigente'},
    {'id': 'CERTIFICACION', 'label': 'Prueba hidrostática vigente'},
    {'id': 'PRESION', 'label': 'Presión conforme'},
    {'id': 'SEGURIDAD', 'label': 'Precinto de seguridad'},
    {'id': 'ESTADO', 'label': 'Cilindro en buen estado'},
    {'id': 'CARGA', 'label': 'Tipo de carga'},
    {'id': 'SOPORTE', 'label': 'Colgador en buen estado'},
    {'id': 'ACTIVACION', 'label': 'Manija en buen estado'},
    {'id': 'MANGUERA', 'label': 'Manguera en buen estado'},
    {'id': 'BOQUILLA', 'label': 'Tobera en buen estado'},
    {'id': 'ABRAZADERA', 'label': 'Abrazadera en buen estado'},
  ];

  // Estado de las fotos
  int _selectedPhotoTab = 0;
  final List<File?> _photos = [
    null,
    null,
    null,
  ]; // Para modo online (File)
  final List<String?> _photoPaths = [
    null,
    null,
    null,
  ]; // Para modo offline (path local)
  final List<String?> _photoUrls = [
    null,
    null,
    null,
  ]; // URLs de fotos ya subidas

  bool _isLoading = false;
  bool _isLoadingData = false;
  bool _hasExistingInspection = false;
  List<ServiceExtinguisherEntity> _serviceExtinguishers = [];

  late final CreateInspectionDetailUseCase _createInspectionDetailUseCase =
      CreateInspectionDetailUseCase(ServiceRepositoryImpl());
  late final UpdateInspectionDetailUseCase _updateInspectionDetailUseCase =
      UpdateInspectionDetailUseCase(ServiceRepositoryImpl());
  late final GetInspectionDetailByServiceExtinguisherIdUseCase
  _getInspectionDetailUseCase =
      GetInspectionDetailByServiceExtinguisherIdUseCase(
        ServiceRepositoryImpl(),
      );
  late final GetServiceExtinguishersByServiceIdUseCase
  _getServiceExtinguishersUseCase = GetServiceExtinguishersByServiceIdUseCase(
    ServiceRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _loadExistingInspectionDetail();
    _loadServiceExtinguishers();
  }

  Future<void> _loadServiceExtinguishers() async {
    try {
      final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
        widget.servicioId,
      );

      if (mounted) {
        setState(() {
          _serviceExtinguishers = serviceExtinguishers;
        });
      }
    } catch (e) {
      // Si hay error, no hacer nada (la lista queda vacía)
    }
  }

  Future<void> _loadExistingInspectionDetail() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final existingDetail = await _getInspectionDetailUseCase.call(
        widget.servicioExtintorId,
      );

      if (existingDetail != null && mounted) {
        // Leer paths locales desde la base de datos directamente
        final db = await AppDatabase.database;
        final result = await db.query(
          'inspeccion_detalle',
          where: 'servicioExtintorId = ?',
          whereArgs: [widget.servicioExtintorId],
          limit: 1,
        );

        String? foto1Path;
        String? foto2Path;
        String? foto3Path;
        String? foto4Path;

        if (result.isNotEmpty) {
          foto1Path = result.first['foto1Path'] as String?;
          foto2Path = result.first['foto2Path'] as String?;
          foto3Path = result.first['foto3Path'] as String?;
          foto4Path = result.first['foto4Path'] as String?;
        }

        // Verificar conexión a internet para decidir qué mostrar
        final hasInternet = await InternetConnectionChecker().hasConnection;

        setState(() {
          _hasExistingInspection = true;
          // Cargar los datos existentes en el estado
          // Convertir 'SI'/'NO'/null a booleanos: 'SI' -> true, 'NO' o null -> false
          _checklistItems = {
            'ACCESIBILIDAD': existingDetail.accesibilidad == 'SI',
            'UBICACION': existingDetail.ubicacion == 'SI',
            'INSTALACION': existingDetail.instalacion == 'SI',
            'INSTRUCCIONES': existingDetail.instrucciones == 'SI',
            'CLASIFICACION': existingDetail.clasificacion == 'SI',
            'RECARGA': existingDetail.recarga == 'SI',
            'CERTIFICACION': existingDetail.certificacion == 'SI',
            'PRESION': existingDetail.presion == 'SI',
            'SEGURIDAD': existingDetail.seguridad == 'SI',
            'ESTADO': existingDetail.estado == 'SI',
            'CARGA': existingDetail.carga == 'SI',
            'SOPORTE': existingDetail.soporte == 'SI',
            'ACTIVACION': existingDetail.activacion == 'SI',
            'MANGUERA': existingDetail.manguera == 'SI',
            'BOQUILLA': existingDetail.boquilla == 'SI',
            'ABRAZADERA': existingDetail.abrazadera == 'SI',
          };

          // Lógica: Si hay internet Y hay URL → usar URL (Cloudinary)
          // Si no hay internet O no hay URL pero hay path local → usar path local
          if (hasInternet &&
              existingDetail.foto1Url != null &&
              existingDetail.foto1Url!.isNotEmpty) {
            // Modo online: usar URL de Cloudinary
            _photoUrls[0] = existingDetail.foto1Url;
            _photoPaths[0] = null;
            _photos[0] = null;
          } else if (foto1Path != null && File(foto1Path).existsSync()) {
            // Modo offline o sin URL: usar path local
            _photoPaths[0] = foto1Path;
            _photos[0] = File(foto1Path);
            _photoUrls[0] = null;
          } else {
            // Fallback: intentar con URL si existe (por si acaso)
            _photoUrls[0] = existingDetail.foto1Url;
            _photoPaths[0] = null;
            _photos[0] = null;
          }

          if (hasInternet &&
              existingDetail.foto2Url != null &&
              existingDetail.foto2Url!.isNotEmpty) {
            _photoUrls[1] = existingDetail.foto2Url;
            _photoPaths[1] = null;
            _photos[1] = null;
          } else if (foto2Path != null && File(foto2Path).existsSync()) {
            _photoPaths[1] = foto2Path;
            _photos[1] = File(foto2Path);
            _photoUrls[1] = null;
          } else {
            _photoUrls[1] = existingDetail.foto2Url;
            _photoPaths[1] = null;
            _photos[1] = null;
          }

          if (hasInternet &&
              existingDetail.foto3Url != null &&
              existingDetail.foto3Url!.isNotEmpty) {
            _photoUrls[2] = existingDetail.foto3Url;
            _photoPaths[2] = null;
            _photos[2] = null;
          } else if (foto3Path != null && File(foto3Path).existsSync()) {
            _photoPaths[2] = foto3Path;
            _photos[2] = File(foto3Path);
            _photoUrls[2] = null;
          } else {
            _photoUrls[2] = existingDetail.foto3Url;
            _photoPaths[2] = null;
            _photos[2] = null;
          }

          if (hasInternet &&
              existingDetail.foto4Url != null &&
              existingDetail.foto4Url!.isNotEmpty) {
            _photoUrls[3] = existingDetail.foto4Url;
            _photoPaths[3] = null;
            _photos[3] = null;
          } else if (foto4Path != null && File(foto4Path).existsSync()) {
            _photoPaths[3] = foto4Path;
            _photos[3] = File(foto4Path);
            _photoUrls[3] = null;
          } else {
            _photoUrls[3] = existingDetail.foto4Url;
            _photoPaths[3] = null;
            _photos[3] = null;
          }
        });
        
        for (int i = 0; i < 4; i++) {
          print(
            'Foto $i -> File: ${_photos[i]?.path}, Path: ${_photoPaths[i]}, URL: ${_photoUrls[i]}',
          );
        }
      }
    } catch (e) {
      // Si hay error, continuar sin cargar datos (modo creación)
      if (mounted) {
        setState(() {
          _hasExistingInspection = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _toggleItem(String itemId, bool value) {
    setState(() {
      _checklistItems[itemId] = value;
    });
  }

  Future<void> _selectPhoto(int index) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      final hasInternet = await InternetConnectionChecker().hasConnection;

      if (hasInternet) {
        setState(() {
          _photos[index] = File(image.path);
          _photoPaths[index] = null;
        });

      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final inspectionDir = Directory(path.join(appDir.path, 'inspecciones'));
        if (!await inspectionDir.exists())
          await inspectionDir.create(recursive: true);

        final fileName =
            '${widget.servicioExtintorId}_foto${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = File(path.join(inspectionDir.path, fileName));
        await File(image.path).copy(savedFile.path);

        setState(() {
          _photoPaths[index] = savedFile.path;
          _photos[index] = null;
        });
        
      }
    } catch (e) {
      print('❌ Error al seleccionar foto $index: $e');
    }
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final inspectionData = <String, dynamic>{
        'accesibilidad': _checklistItems['ACCESIBILIDAD'] == true ? 'SI' : 'NO',
        'ubicacion': _checklistItems['UBICACION'] == true ? 'SI' : 'NO',
        'instalacion': _checklistItems['INSTALACION'] == true ? 'SI' : 'NO',
        'instrucciones': _checklistItems['INSTRUCCIONES'] == true ? 'SI' : 'NO',
        'clasificacion': _checklistItems['CLASIFICACION'] == true ? 'SI' : 'NO',
        'recarga': _checklistItems['RECARGA'] == true ? 'SI' : 'NO',
        'certificacion': _checklistItems['CERTIFICACION'] == true ? 'SI' : 'NO',
        'presion': _checklistItems['PRESION'] == true ? 'SI' : 'NO',
        'seguridad': _checklistItems['SEGURIDAD'] == true ? 'SI' : 'NO',
        'estado': _checklistItems['ESTADO'] == true ? 'SI' : 'NO',
        'carga': _checklistItems['CARGA'] == true ? 'SI' : 'NO',
        'soporte': _checklistItems['SOPORTE'] == true ? 'SI' : 'NO',
        'activacion': _checklistItems['ACTIVACION'] == true ? 'SI' : 'NO',
        'manguera': _checklistItems['MANGUERA'] == true ? 'SI' : 'NO',
        'boquilla': _checklistItems['BOQUILLA'] == true ? 'SI' : 'NO',
        'abrazadera': _checklistItems['ABRAZADERA'] == true ? 'SI' : 'NO',
        'observaciones':
            null, // Se agregará después en la página de observaciones
      };

      // Agregar fotos según el modo (online/offline)
      final hasInternet = await InternetConnectionChecker().hasConnection;
      if (hasInternet) {
        inspectionData['foto1'] = _photos[0];
        inspectionData['foto2'] = _photos[1];
        inspectionData['foto3'] = _photos[2];
        
      } else {
        inspectionData['foto1Path'] = _photoPaths[0];
        inspectionData['foto2Path'] = _photoPaths[1];
        inspectionData['foto3Path'] = _photoPaths[2];
        inspectionData['foto1Url'] = _photoUrls[0];
        inspectionData['foto2Url'] = _photoUrls[1];
        inspectionData['foto3Url'] = _photoUrls[2];
        print(
          '📴 Modo offline, fotos enviadas: '
          '${inspectionData['foto1Path']}, '
          '${inspectionData['foto2Path']}, '
          '${inspectionData['foto3Path']} '
          'y URLs: '
          '${inspectionData['foto1Url']}, '
          '${inspectionData['foto2Url']}, '
          '${inspectionData['foto3Url']}',
        );
      }

      // Llamada al usecase
      if (_hasExistingInspection) {
        await _updateInspectionDetailUseCase.call(
          servicioExtintorId: widget.servicioExtintorId,
          inspectionData: inspectionData,
        );
        
      } else {
        await _createInspectionDetailUseCase.call(
          servicioExtintorId: widget.servicioExtintorId,
          inspectionData: inspectionData,
        );
        
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navegar a la página de observaciones
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceObservationsPage(
            extinguisher: widget.extinguisher,
            serviceType: widget.serviceType,
            servicioId: widget.servicioId,
            servicioExtintorId: widget.servicioExtintorId,
            checklistItems: _checklistItems,
            rechargeAgent: null,
            decommissionReason: null,
            partsChangeDetails: null,
          ),
        ),
      );
    } catch (e) {
      print('❌ Error al enviar inspección: $e');
    }
  }

  Widget _buildCartIconWithBadge() {
    final count = _serviceExtinguishers.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
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

  Future<void> _showCartModal() async {
    try {
      final serviceExtinguishers = await _getServiceExtinguishersUseCase.call(
        widget.servicioId,
      );

      if (!mounted) return;

      // Actualizar el estado local
      setState(() {
        _serviceExtinguishers = serviceExtinguishers;
      });

      showDialog(
        context: context,
        builder: (context) => ServiceExtinguisherCartModal(
          serviceExtinguishers: serviceExtinguishers,
          servicioId: widget.servicioId,
          serviceType: widget.serviceType,
          currentServicioExtintorId: widget.servicioExtintorId,
        ),
      ).then((_) {
        // Recargar cuando se cierra el modal
        _loadServiceExtinguishers();
        _loadExistingInspectionDetail(); // También recargar el checklist
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar extintores: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Servicios/Inspección',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _buildCartIconWithBadge(),
            onPressed: _showCartModal,
            tooltip: 'Ver extintores agregados',
          ),
        ],
      ),
      body: _isLoadingData
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
                    'Inspección',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tabs de fotos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildPhotoTab(0, 'Foto 1')),
                            Expanded(child: _buildPhotoTab(1, 'Foto 2')),
                            Expanded(child: _buildPhotoTab(2, 'Foto 3')),
                          ],
                        ),
                        // Preview de foto seleccionada
                        if (_selectedPhotoTab >= 0 && _selectedPhotoTab < 4)
                          _buildPhotoPreview(_selectedPhotoTab),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Lista de items del checklist
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Column(
                      children: _checklistConfig.map((item) {
                        final id = item['id']!;
                        final label = item['label']!;

                        return InspectionChecklistItem(
                          title: label, // 👈 texto bonito
                          value: _checklistItems[id] ?? false,
                          onChanged: (value) => _toggleItem(id, value),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botón Guardar checklist y continuar
                  PrimaryButton(
                    text: 'Guardar checklist y continuar',
                    onPressed: _isLoading ? null : _handleContinue,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoTab(int index, String label) {
    final isSelected = _selectedPhotoTab == index;
    final hasPhoto =
        _photos[index] != null ||
        _photoPaths[index] != null ||
        _photoUrls[index] != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE84343).withValues(alpha: 0.1)
              : null,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFE84343) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFFE84343) : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            if (hasPhoto)
              const Icon(Icons.check_circle, size: 16, color: Colors.green)
            else
              Icon(
                Icons.edit,
                size: 16,
                color: isSelected ? const Color(0xFFE84343) : Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(int index) {
    File? photoFile;
    String? photoUrl;

    // Prioridad según conexión:
    // Si hay URL y estamos online → mostrar URL (Cloudinary)
    // Si no hay URL o estamos offline pero hay path local → mostrar path local
    // Si hay File en memoria → mostrar File (recién tomada)
    if (_photos[index] != null) {
      // Foto recién tomada en memoria (tiene prioridad)
      photoFile = _photos[index];
    } else if (_photoUrls[index] != null && _photoUrls[index]!.isNotEmpty) {
      // URL de Cloudinary (modo online)
      photoUrl = _photoUrls[index];
    } else if (_photoPaths[index] != null &&
        File(_photoPaths[index]!).existsSync()) {
      // Path local (modo offline)
      photoFile = File(_photoPaths[index]!);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (photoFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                photoFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else if (photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.camera_alt, size: 48, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectPhoto(index),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Tomar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE84343),
                  foregroundColor: Colors.white,
                ),
              ),
              if (photoFile != null || photoUrl != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _photos[index] = null;
                      _photoPaths[index] = null;
                      _photoUrls[index] = null;
                    });
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
