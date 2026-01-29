import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../services/domain/entities/extinguisher_entity.dart';
import '../../../services/data/repositories/extinguisher_repository_impl.dart';

/// Página: Detalles del Equipo
class EquipmentDetailPage extends StatefulWidget {
  final Extinguisher extinguisher;

  const EquipmentDetailPage({super.key, required this.extinguisher});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  Extinguisher? _extinguisher;
  bool _isLoading = true;
  String? _errorMessage;

  late final ExtinguisherRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = ExtinguisherRepositoryImpl();
    // Usar datos iniciales mientras cargamos datos frescos
    _extinguisher = widget.extinguisher;
    _loadExtinguisherDetails();
  }

  Future<void> _loadExtinguisherDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener datos frescos del backend/SQLite
      final freshData = await _repository.getExtinguisherById(
        widget.extinguisher.id,
      );

      if (mounted) {
        setState(() {
          _extinguisher = freshData ?? widget.extinguisher;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar detalles: ${e.toString()}';
          _isLoading = false;
          // Mantener datos iniciales en caso de error
          _extinguisher = widget.extinguisher;
        });
      }
    }
  }

  String _getPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return '';

    // Si ya es una URL completa, retornarla
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    // Si es solo un nombre de archivo o path relativo, construir URL completa
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    // Remover barra inicial si existe
    final cleanPhoto = photo.startsWith('/') ? photo.substring(1) : photo;
    return '$baseUrl/$cleanPhoto';
  }

  /// Construir widget de foto con soporte para modo offline
  Widget _buildPhotoWidget(Extinguisher extinguisher) {
    // Verificar conexión a internet
    return FutureBuilder<bool>(
      future: InternetConnectionChecker().hasConnection,
      builder: (context, snapshot) {
        final hasInternet = snapshot.data ?? false;

        // Prioridad:
        // 1. Si hay internet y hay photo (URL) → usar Image.network
        // 2. Si no hay internet o falla la URL pero hay photoPath → usar Image.file
        // 3. Si no hay nada → mostrar placeholder

        if (hasInternet &&
            extinguisher.photo != null &&
            extinguisher.photo!.isNotEmpty) {
          // Modo online: usar URL
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _getPhotoUrl(extinguisher.photo),
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFFE84343),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Si falla la URL, intentar con path local
                if (extinguisher.photoPath != null &&
                    extinguisher.photoPath!.isNotEmpty &&
                    File(extinguisher.photoPath!).existsSync()) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(extinguisher.photoPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildNoPhotoPlaceholder();
                      },
                    ),
                  );
                }
                return _buildNoPhotoPlaceholder();
              },
            ),
          );
        } else if (extinguisher.photoPath != null &&
            extinguisher.photoPath!.isNotEmpty &&
            File(extinguisher.photoPath!).existsSync()) {
          // Modo offline: usar path local
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(extinguisher.photoPath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildNoPhotoPlaceholder();
              },
            ),
          );
        } else {
          // No hay foto disponible
          return _buildNoPhotoPlaceholder();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final extinguisher = _extinguisher ?? widget.extinguisher;

    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Equipo ${extinguisher.serialNumber ?? 'N/A'}',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mostrar error si existe
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Información del equipo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto del equipo - Dentro del Card blanco
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _buildPhotoWidget(extinguisher),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Información del Equipo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            '1',
                            'Nro. Serie',
                            extinguisher.serialNumber ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '2',
                            'Ubicación',
                            extinguisher.location ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '3',
                            'Nro. Cilindro',
                            extinguisher.cylinderNumber ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '4',
                            'Tipo',
                            extinguisher.type ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '5',
                            'Agente',
                            extinguisher.agent ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '6',
                            'Capacidad',
                            extinguisher.capacity ?? 'N/A',
                          ),
                          _buildDetailRow(
                            '7',
                            'Estado',
                            extinguisher.status ?? 'N/A',
                          ),
                          if (extinguisher.pressure != null)
                            _buildDetailRow(
                              '8',
                              'Presión',
                              extinguisher.pressure!,
                            ),
                          if (extinguisher.brand != null)
                            _buildDetailRow('9', 'Marca', extinguisher.brand!),
                          if (extinguisher.model != null)
                            _buildDetailRow(
                              '10',
                              'Modelo',
                              extinguisher.model!,
                            ),
                          if (extinguisher.rating != null)
                            _buildDetailRow(
                              '11',
                              'Clasificación',
                              extinguisher.rating!,
                            ),
                          if (extinguisher.yearManufacture != null)
                            _buildDetailRow(
                              '12',
                              'Año de Fabricación',
                              extinguisher.yearManufacture!,
                            ),
                          if (extinguisher.dateHydrostatic != null)
                            _buildDetailRow(
                              '13',
                              'Fecha Hidrostática',
                              _formatDate(extinguisher.dateHydrostatic),
                            ),
                          if (extinguisher.dateMaintenance != null)
                            _buildDetailRow(
                              '14',
                              'Fecha de Mantenimiento',
                              _formatDate(extinguisher.dateMaintenance),
                            ),
                          if (extinguisher.rechargeDate != null)
                            _buildDetailRow(
                              '15',
                              'Fecha de Recarga',
                              _formatDate(extinguisher.rechargeDate),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Formatear fecha desde String o DateTime
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return dateValue.toString();
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // Si no se puede parsear, retornar el string original
      return dateValue.toString();
    }
  }

  Widget _buildDetailRow(String number, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPhotoPlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 6),
          Text(
            'No hay foto del extintor',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
