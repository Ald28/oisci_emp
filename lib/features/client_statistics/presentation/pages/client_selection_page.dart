import 'dart:async';
import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/usecases/search_clients_usecase.dart';
import '../../data/repositories/client_repository_impl.dart';
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
          final clients = clientsList.cast<ClientEntity>().toList();

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

  void _handleClientTap(ClientEntity client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientStatisticsPage(client: client)),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFFE84343),
                                  child: Text(
                                    client.razonSocial.isNotEmpty
                                        ? client.razonSocial[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.razonSocial,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'RUC: ${client.ruc}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      if (client.address.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          client.address,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFFE84343),
                                ),
                              ],
                            ),
                          ),
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
