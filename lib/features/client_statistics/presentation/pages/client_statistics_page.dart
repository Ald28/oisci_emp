import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/client_entity.dart';
import '../../../services/domain/entities/sede_entity.dart';
import '../../../services/domain/entities/extinguisher_entity.dart';
import '../../domain/usecases/get_extinguishers_by_sede_usecase.dart';
import '../../domain/usecases/get_extinguisher_stats_usecase.dart';
import '../../domain/usecases/get_service_stats_usecase.dart';
import '../../../services/data/repositories/extinguisher_repository_impl.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/extinguisher_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import 'equipment_detail_page.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_checker.dart';

import '../../../services/domain/entities/doc_type.dart';
import '../../../services/domain/entities/cached_document_entity.dart';
import '../../../services/domain/usecases/get_documents_by_services_usecase.dart';
import '../../../services/domain/usecases/download_document_usecase.dart';
import '../../../services/data/datasources/documents_local_datasource.dart';
import '../../../services/data/datasources/documents_remote_datasource.dart';
import '../../../services/data/repositories/documents_repository_impl.dart';

/// Página: Estadísticas del Cliente
class ClientStatisticsPage extends StatefulWidget {
  final ClientEntity client;
  final Sede? sede;

  const ClientStatisticsPage({super.key, required this.client, this.sede});

  @override
  State<ClientStatisticsPage> createState() => _ClientStatisticsPageState();
}

class _ClientStatisticsPageState extends State<ClientStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Extinguisher> _extinguishers = [];
  ExtinguisherStatsEntity? _extinguisherStats;
  ServiceStatsEntity? _serviceStats;
  bool _isLoading = true;

  late final GetExtinguishersBySedeUseCase _getExtinguishersUseCase;
  late final GetExtinguisherStatsUseCase _getExtinguisherStatsUseCase;
  late final GetServiceStatsUseCase _getServiceStatsUseCase;

  late final GetDocumentsByServicesUseCase _getDocumentsByServicesUseCase;
  late final DownloadDocumentUseCase _downloadDocumentUseCase;

  List<Map<String, dynamic>> _serviciosLocal =
      []; // lista de servicios desde SQLite
  List<CachedDocumentEntity> _documents = [];
  bool _loadingDocs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _getExtinguishersUseCase = GetExtinguishersBySedeUseCase(
      ExtinguisherRepositoryImpl(),
    );
    _getExtinguisherStatsUseCase = GetExtinguisherStatsUseCase(
      StatisticsRepositoryImpl(),
    );
    _getServiceStatsUseCase = GetServiceStatsUseCase(
      StatisticsRepositoryImpl(),
    );
    final docsRepo = DocumentsRepositoryImpl(
      networkChecker: NetworkChecker(),
      remote: DocumentsRemoteDataSource(DioClient()),
      local: DocumentsLocalDataSource(),
    );

    _getDocumentsByServicesUseCase = GetDocumentsByServicesUseCase(docsRepo);
    _downloadDocumentUseCase = DownloadDocumentUseCase(docsRepo);

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentYear = DateTime.now().year;

      // Si hay una sede seleccionada, obtener datos de esa sede
      if (widget.sede != null) {
        final sedeId = widget.sede!.id;

        // Obtener estadísticas desde los endpoints
        final extinguisherStats = await _getExtinguisherStatsUseCase.call(
          sedeId,
        );
        final serviceStats = await _getServiceStatsUseCase.call(
          sedeId,
          currentYear,
        );

        // También obtener lista completa de extintores para otras funcionalidades
        final extinguishers = await _getExtinguishersUseCase.call(sedeId);

        setState(() {
          _extinguisherStats = extinguisherStats;
          _serviceStats = serviceStats;
          _extinguishers = extinguishers;
          _isLoading = false;
        });
      } else if (widget.client.sedes != null &&
          widget.client.sedes!.isNotEmpty) {
        // Si no hay sede específica, agregar estadísticas de todas las sedes
        final allExtinguisherTypes = <String, int>{};
        final allServiceTypes = <String, int>{
          'MANTENIMIENTO': 0,
          'RECARGA': 0,
          'PRUEBA HIDROSTÁTICA': 0,
          'BAJA': 0,
        };
        int totalOperativos = 0;
        int totalInoperativos = 0;
        int totalExtinguishers = 0;

        for (final sede in widget.client.sedes!) {
          try {
            final extinguisherStats = await _getExtinguisherStatsUseCase.call(
              sede.id,
            );
            final serviceStats = await _getServiceStatsUseCase.call(
              sede.id,
              currentYear,
            );

            // Agregar tipos de extintores
            extinguisherStats.byType.forEach((key, value) {
              allExtinguisherTypes[key] =
                  (allExtinguisherTypes[key] ?? 0) + value;
            });

            // Agregar tipos de servicios
            serviceStats.byType.forEach((key, value) {
              allServiceTypes[key] = (allServiceTypes[key] ?? 0) + value;
            });

            totalOperativos += extinguisherStats.operativos;
            totalInoperativos += extinguisherStats.inoperativos;
            totalExtinguishers += extinguisherStats.total;
          } catch (e) {
            // Si falla obtener estadísticas de una sede, continuar con las demás
            continue;
          }
        }

        // Crear estadísticas agregadas
        final aggregatedExtinguisherStats = ExtinguisherStatsEntity(
          sedeId: widget
              .client
              .sedes!
              .first
              .id, // Usar el ID de la primera sede como referencia
          byType: allExtinguisherTypes,
          total: totalExtinguishers,
          operativos: totalOperativos,
          inoperativos: totalInoperativos,
        );

        final aggregatedServiceStats = ServiceStatsEntity(
          sedeId: widget.client.sedes!.first.id,
          year: currentYear,
          byType: allServiceTypes,
        );

        // También obtener lista completa de extintores
        final allExtinguishers = <Extinguisher>[];

        for (final sede in widget.client.sedes!) {
          final extinguishers = await _getExtinguishersUseCase.call(sede.id);
          allExtinguishers.addAll(extinguishers);
        }

        setState(() {
          _extinguisherStats = aggregatedExtinguisherStats;
          _serviceStats = aggregatedServiceStats;
          _extinguishers = allExtinguishers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      // Cargar servicios + documentos (certificados/reportes) desde SQLite/cache
      await _loadDocumentsForServicios();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadServiciosFromSQLite() async {
    // si hay sede seleccionada => filtra por sedeId
    final db = await AppDatabase.database;

    if (widget.sede != null) {
      _serviciosLocal = await db.query(
        'servicio',
        where: 'sedeId = ?',
        whereArgs: [widget.sede!.id],
        orderBy: 'dateStart DESC',
        limit: 30,
      );
    } else {
      // si no hay sede, muestra igual los últimos 30 servicios de todas las sedes cacheadas
      _serviciosLocal = await db.query(
        'servicio',
        orderBy: 'dateStart DESC',
        limit: 30,
      );
    }
  }

  DateTime _parseDateSafe(String? iso) {
    if (iso == null || iso.isEmpty)
      return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _loadDocumentsForServicios() async {
    if (mounted) setState(() => _loadingDocs = true);

    try {
      await _loadServiciosFromSQLite();

      final servicioIds = _serviciosLocal.map((s) => s['id'] as int).toList();
      final docs = await _getDocumentsByServicesUseCase.call(servicioIds);

      setState(() {
        _documents = docs;
        _loadingDocs = false;
      });
    } catch (e) {
      setState(() => _loadingDocs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando documentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  CachedDocumentEntity _getDoc(int servicioId, DocType type) {
    return _documents.firstWhere(
      (d) => d.servicioId == servicioId && d.docType == type,
      orElse: () => CachedDocumentEntity(servicioId: servicioId, docType: type),
    );
  }

  Future<void> _downloadDoc(
    int servicioId,
    DocType type,
    DateTime servicioUpdatedAt,
  ) async {
    try {
      await _downloadDocumentUseCase.call(
        servicioId: servicioId,
        type: type,
        servicioUpdatedAt: servicioUpdatedAt,
      );

      // recarga lista para reflejar “Disponible offline”
      await _loadDocumentsForServicios();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${type.title} descargado ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openPdf(String path) {
    OpenFilex.open(path);
  }

  /// Obtener distribución de tipos de extintores desde estadísticas
  Map<String, int> _getExtinguisherTypes() {
    if (_extinguisherStats != null) {
      return _extinguisherStats!.byType;
    }
    return {};
  }

  /// Obtener servicios anuales desde estadísticas
  Map<String, int> _getAnnualServices() {
    if (_serviceStats != null) {
      return _serviceStats!.byType;
    }
    return {
      'MANTENIMIENTO': 0,
      'RECARGA': 0,
      'PRUEBA HIDROSTÁTICA': 0,
      'BAJA': 0,
    };
  }

  /// Obtener etiqueta del tipo de extintor (para mostrar en lista de equipos)
  String _getExtinguisherTypeLabel(Extinguisher ext) {
    if (ext.type != null && ext.agent != null) {
      return '${ext.type} ${ext.agent}';
    } else if (ext.type != null) {
      return ext.type!;
    } else if (ext.agent != null) {
      return ext.agent!;
    }
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: HomeAppBar(
        title: 'Estadísticas por cliente',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE84343)),
            )
          : Column(
              children: [
                // Gráficos
                _buildChartsSection(),
                // Tabs
                _buildTabsSection(),
                // Contenido de tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInformationTab(),
                      _buildEquipmentTab(),
                      _buildCertificatesTab(),
                      _buildReportsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  double _calculateYAxisReservedSize(int maxValue) {
    // Calcular el espacio necesario basado en el número de dígitos
    final digitCount = maxValue.toString().length;
    // Para 1 dígito: mínimo espacio para estar cerca del gráfico
    // Para más dígitos: espacio adicional a la izquierda, manteniendo el gráfico cerca
    switch (digitCount) {
      case 1:
        return 14.0; // Muy cerca para 1 dígito
      case 2:
        return 22.0; // Cerca para 2 dígitos
      case 3:
        return 30.0; // Espacio adicional a la izquierda para 3 dígitos
      default:
        // Para 4+ dígitos: 8 píxeles por dígito + padding base
        return (digitCount * 8.0) + 8.0;
    }
  }

  Widget _buildChartsSection() {
    final extinguisherTypes = _getExtinguisherTypes();
    final annualServices = _getAnnualServices();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfico de torta - Tipos de extintores
              Flexible(
                flex: 2,
                fit: FlexFit.loose,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        child: const Text(
                          'EXTINTORES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: extinguisherTypes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay datos',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 9,
                                  ),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: _buildPieChartSections(
                                    extinguisherTypes,
                                  ),
                                  centerSpaceRadius: 13,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      _buildPieChartLegend(extinguisherTypes),
                    ],
                  ),
                ),
              ),
              // Línea vertical de separación
              Container(
                width: 1,
                height: 95,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              // Gráfico de barras - Servicios anuales (más espacio)
              Flexible(
                flex: 4,
                fit: FlexFit.loose,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        child: const Text(
                          'SERVICIO ANUAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 70,
                        child: annualServices.values.every((v) => v == 0)
                            ? const Center(
                                child: Text(
                                  'No hay datos',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY:
                                      annualServices.values
                                          .reduce((a, b) => a > b ? a : b)
                                          .toDouble() +
                                      2,
                                  minY: 0,
                                  barGroups: _buildBarChartGroups(
                                    annualServices,
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize:
                                            _calculateYAxisReservedSize(
                                              annualServices.values.reduce(
                                                (a, b) => a > b ? a : b,
                                              ),
                                            ),
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() == value) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey,
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    drawHorizontalLine: true,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey[300]!,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.grey[400]!,
                                        width: 1,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.grey[400]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      _buildBarChartLegend(annualServices),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> types) {
    final total = types.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return [];

    final colors = [
      const Color(0xFF4A90E2), // Azul
      const Color(0xFFE84343), // Rojo
      const Color(0xFF50C878), // Verde
      const Color(0xFFFFA500), // Naranja
      const Color(0xFF9B59B6), // Morado
    ];

    int colorIndex = 0;
    return types.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        color: color,
        radius: 24,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPieChartLegend(Map<String, int> types) {
    final colors = [
      const Color(0xFF4A90E2),
      const Color(0xFFE84343),
      const Color(0xFF50C878),
      const Color(0xFFFFA500),
      const Color(0xFF9B59B6),
    ];

    int colorIndex = 0;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: types.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<BarChartGroupData> _buildBarChartGroups(Map<String, int> services) {
    final colors = {
      'MANTENIMIENTO': const Color(0xFF4A90E2),
      'RECARGA': const Color(0xFFFFA500),
      'PRUEBA HIDROSTÁTICA': const Color(0xFF50C878),
      'BAJA': const Color(0xFF9B59B6),
    };

    int x = 0;
    return services.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.grey;
      return BarChartGroupData(
        x: x++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: color,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBarChartLegend(Map<String, int> services) {
    final colors = {
      'MANTENIMIENTO': const Color(0xFF4A90E2),
      'RECARGA': const Color(0xFFFFA500),
      'PRUEBA HIDROSTÁTICA': const Color(0xFF50C878),
      'BAJA': const Color(0xFF9B59B6),
    };

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: services.entries.map((entry) {
        final color = colors[entry.key] ?? Colors.grey;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.rectangle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFE84343),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFE84343),
        tabs: const [
          Tab(text: 'INFORMACIÓN'),
          Tab(text: 'EQUIPOS'),
          Tab(text: 'CERTIFICADOS'),
          Tab(text: 'REPORTES'),
        ],
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.client.razonSocial,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('RUC', widget.client.ruc),
              if (widget.client.address.isNotEmpty)
                _buildInfoRow('Dirección', widget.client.address),
              if (widget.client.phone.isNotEmpty)
                _buildInfoRow('Teléfono', widget.client.phone),
              if (widget.sede != null) ...[
                const Divider(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sede!.nameSede,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Dirección con icono
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.sede!.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.sede!.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.sede!.city,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Información del gestor
                    if (widget.sede!.managerName != null &&
                        widget.sede!.managerName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Gestor: ${widget.sede!.managerName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.sede!.managerPhone != null &&
                        widget.sede!.managerPhone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Teléfono: ${widget.sede!.managerPhone}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
              const Divider(height: 24),
              _buildInfoRow(
                'Cantidad de equipos',
                '${_extinguishers.length} und',
              ),
              _buildInfoRow(
                'Equipos operativos',
                '${_extinguishers.where((e) => e.status == 'OPERATIVO').length} und',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEquipmentTab() {
    if (_extinguishers.isEmpty) {
      return const Center(
        child: Text(
          'No hay equipos disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _extinguishers.length,
      itemBuilder: (context, index) {
        final extinguisher = _extinguishers[index];
        final numero = index + 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE84343),
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '$numero. ${extinguisher.codeExtintor ?? extinguisher.serialNumberNFC ?? 'Sin serie'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Tipo: ${_getExtinguisherTypeLabel(extinguisher)}'),
                if (extinguisher.capacity != null)
                  Text('Cap.: ${extinguisher.capacity}'),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: extinguisher.status == 'OPERATIVO'
                    ? Colors.green
                    : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                extinguisher.status ?? 'DESCONOCIDO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EquipmentDetailPage(extinguisher: extinguisher),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCertificatesTab() {
    if (_loadingDocs) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE84343)),
      );
    }

    if (_serviciosLocal.isEmpty) {
      return const Center(
        child: Text(
          'No hay servicios guardados para mostrar certificados',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocumentsForServicios,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _serviciosLocal.length,
        itemBuilder: (context, index) {
          final s = _serviciosLocal[index];
          final servicioId = s['id'] as int;
          final typeService = (s['type'] ?? '').toString();
          final dateStart = (s['dateStart'] ?? '').toString();
          final updatedAt = _parseDateSafe((s['updatedAt'] ?? '').toString());

          final inspeccionDoc = _getDoc(servicioId, DocType.inspeccionMensual);
          final fotoDoc = _getDoc(servicioId, DocType.fotografico);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      'Servicio #$servicioId - $typeService',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Inicio: $dateStart'),
                  ),
                  const Divider(height: 1),

                  _docTile(
                    title: 'Certificado: Inspección mensual',
                    available: inspeccionDoc.isAvailableOffline,
                    onDownload: () => _downloadDoc(
                      servicioId,
                      DocType.inspeccionMensual,
                      updatedAt,
                    ),
                    onOpen: inspeccionDoc.isAvailableOffline
                        ? () => _openPdf(inspeccionDoc.filePath!)
                        : null,
                  ),

                  const Divider(height: 1),

                  _docTile(
                    title: 'Certificado: Reporte fotográfico',
                    available: fotoDoc.isAvailableOffline,
                    onDownload: () => _downloadDoc(
                      servicioId,
                      DocType.fotografico,
                      updatedAt,
                    ),
                    onOpen: fotoDoc.isAvailableOffline
                        ? () => _openPdf(fotoDoc.filePath!)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _docTile({
    required String title,
    required bool available,
    required VoidCallback onDownload,
    required VoidCallback? onOpen,
  }) {
    return ListTile(
      leading: Icon(
        Icons.picture_as_pdf,
        color: available ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(available ? 'Disponible offline' : 'No descargado'),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(icon: const Icon(Icons.download), onPressed: onDownload),
          IconButton(icon: const Icon(Icons.open_in_new), onPressed: onOpen),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Reportes se implementarán aquí',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
