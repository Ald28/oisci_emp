import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/client_entity.dart';
import '../../../services/domain/entities/sede_entity.dart';
import '../../../services/domain/entities/extinguisher_entity.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../domain/usecases/get_extinguishers_by_sede_usecase.dart';
import '../../domain/usecases/get_services_by_sede_usecase.dart';
import '../../../services/data/repositories/extinguisher_repository_impl.dart';
import '../../../services/data/repositories/service_repository_impl.dart';
import 'equipment_detail_page.dart';

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
  List<ServiceEntity> _services = [];
  bool _isLoading = true;

  late final GetExtinguishersBySedeUseCase _getExtinguishersUseCase;
  late final GetServicesBySedeUseCase _getServicesUseCase;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _getExtinguishersUseCase = GetExtinguishersBySedeUseCase(
      ExtinguisherRepositoryImpl(),
    );
    _getServicesUseCase = GetServicesBySedeUseCase(ServiceRepositoryImpl());

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
      // Si hay una sede seleccionada, obtener datos de esa sede
      // Si no, obtener datos de todas las sedes del cliente
      if (widget.sede != null) {
        final extinguishers = await _getExtinguishersUseCase.call(
          widget.sede!.id,
        );
        final services = await _getServicesUseCase.call(widget.sede!.id);
        setState(() {
          _extinguishers = extinguishers;
          _services = services;
          _isLoading = false;
        });
      } else if (widget.client.sedes != null &&
          widget.client.sedes!.isNotEmpty) {
        // Obtener datos de todas las sedes
        final allExtinguishers = <Extinguisher>[];
        final allServices = <ServiceEntity>[];

        for (final sede in widget.client.sedes!) {
          final extinguishers = await _getExtinguishersUseCase.call(sede.id);
          final services = await _getServicesUseCase.call(sede.id);
          allExtinguishers.addAll(extinguishers);
          allServices.addAll(services);
        }

        setState(() {
          _extinguishers = allExtinguishers;
          _services = allServices;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
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

  /// Calcular distribución de tipos de extintores
  Map<String, int> _calculateExtinguisherTypes() {
    final types = <String, int>{};
    for (final ext in _extinguishers) {
      final type = _getExtinguisherTypeLabel(ext);
      types[type] = (types[type] ?? 0) + 1;
    }
    return types;
  }

  /// Obtener etiqueta del tipo de extintor
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

  /// Calcular servicios anuales
  Map<String, int> _calculateAnnualServices() {
    final now = DateTime.now();
    final currentYear = now.year;
    final services = <String, int>{
      'MANTENIMIENTO': 0,
      'RECARGA': 0,
      'PRUEBA HIDROSTÁTICA': 0,
      'BAJA': 0,
    };

    for (final service in _services) {
      if (service.dateStart.year == currentYear) {
        if (service.type == 'MANTENIMIENTO') {
          services['MANTENIMIENTO'] = (services['MANTENIMIENTO'] ?? 0) + 1;
        } else if (service.type == 'INSPECCION') {
          // Las inspecciones pueden incluir recargas, pruebas hidrostáticas, etc.
          // Por ahora las contamos como inspecciones
          // TODO: Agregar lógica para diferenciar tipos de inspección
        }
      }
    }

    // Contar extintores dados de baja (status INOPERATIVO)
    final inoperativos = _extinguishers
        .where((e) => e.status == 'INOPERATIVO')
        .length;
    services['BAJA'] = inoperativos;

    return services;
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
    final extinguisherTypes = _calculateExtinguisherTypes();
    final annualServices = _calculateAnnualServices();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfico de torta - Tipos de extintores
              Flexible(
                flex: 3,
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
                                barGroups: _buildBarChartGroups(annualServices),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: _calculateYAxisReservedSize(
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
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sede!.nameSede,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.sede!.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (widget.sede!.city.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.sede!.city,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              extinguisher.serialNumber ?? 'Sin serie',
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
    return const Center(
      child: Text(
        'Certificados se implementarán aquí',
        style: TextStyle(color: Colors.grey),
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
