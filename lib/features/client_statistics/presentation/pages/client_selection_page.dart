import 'dart:async';
import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/search_clients_usecase.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../data/models/client_model.dart';
import '../../../services/domain/entities/sede_entity.dart';
import 'client_statistics_page.dart';

/// Página: Selección de Cliente para ver estadísticas
class ClientSelectionPage extends StatefulWidget {
  const ClientSelectionPage({super.key});

  @override
  State<ClientSelectionPage> createState() => _ClientSelectionPageState();
}

class _ClientSelectionPageState extends State<ClientSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ClientEntity> _clients = [];
  List<ClientEntity> _filteredClients = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  final Map<int, bool> _expandedClients =
      {}; // Para rastrear qué clientes están expandidos

  late final SearchClientsUseCase _searchClientsUseCase = SearchClientsUseCase(
    ClientRepositoryImpl(),
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadClients();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Timer? _debounceTimer;

  void _onSearchChanged() {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Crear un nuevo timer para el debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _lastSearchTerm) {
        _lastSearchTerm = _searchController.text;
        _currentPage = 1;
        _hasMore = true;
        _loadClients();
      }
    });
  }

  String _lastSearchTerm = '';

  Future<void> _loadClients({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final result = await _searchClientsUseCase.call(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        page: page,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          final clientsList = result['data'] as List<dynamic>;
          // Los clientes pueden venir como ClientModel o ClientEntity
          final clients = clientsList
              .map((item) {
                if (item is ClientEntity) {
                  return item;
                } else if (item is Map<String, dynamic>) {
                  // Si viene como Map, convertir a ClientModel
                  return ClientModel.fromJson(item);
                }
                return null;
              })
              .whereType<ClientEntity>()
              .toList();

          if (loadMore) {
            _clients.addAll(clients);
            _currentPage = page;
          } else {
            _clients = clients;
            _currentPage = 1;
          }

          final pagination = result['pagination'] as Map<String, dynamic>;
          _totalPages = pagination['totalPages'] as int? ?? 1;
          _hasMore = page < _totalPages;

          _filteredClients = _clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleClientTap(ClientEntity client, {Sede? sede}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientStatisticsPage(client: client, sede: sede),
      ),
    );
  }

  /// Construir el contenido de la tarjeta del cliente
  Widget _buildClientCardContent(ClientEntity client) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del cliente
          Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  client.razonSocial,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construir tarjeta de sede (hijo del cliente)
  Widget _buildSedeCard(Sede sede, ClientEntity client) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleClientTap(client, sede: sede),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.business, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sede.nameSede,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (sede.city.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${sede.city})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sede.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFE84343),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FloatingLabelTextField(
              controller: _searchController,
              label: 'Buscar por RUC o Razón Social',
              hintText: 'Buscar por RUC o Razón Social',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE84343)),
            ),
          ),
          // Lista de clientes
          Expanded(
            child: _isLoading && _clients.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE84343)),
                  )
                : _filteredClients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay clientes disponibles'
                              : 'No se encontraron clientes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: _filteredClients.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredClients.length) {
                        // Botón para cargar más
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Color(0xFFE84343),
                                  )
                                : TextButton(
                                    onPressed: () =>
                                        _loadClients(loadMore: true),
                                    child: const Text('Cargar más'),
                                  ),
                          ),
                        );
                      }

                      final client = _filteredClients[index];
                      final clientModel = client is ClientModel ? client : null;
                      final hasSedes =
                          clientModel?.sedes != null &&
                          clientModel!.sedes!.isNotEmpty;

                      // Si el cliente tiene sedes, mostrar como expandible
                      if (hasSedes) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            dense: true,
                            trailing: Icon(
                              _expandedClients[client.id] == true
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: const Color(0xFFE84343),
                              size: 20,
                            ),
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedClients[client.id] = expanded;
                              });
                            },
                            title: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    client.razonSocial,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            children: clientModel.sedes!
                                .map((sede) => _buildSedeCard(sede, client))
                                .toList(),
                          ),
                        );
                      }

                      // Si no tiene sedes, mostrar como tarjeta normal
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        child: InkWell(
                          onTap: () => _handleClientTap(client),
                          borderRadius: BorderRadius.circular(12),
                          child: _buildClientCardContent(client),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
