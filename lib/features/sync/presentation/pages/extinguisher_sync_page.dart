import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/sync/sync_service.dart';

/// Página de sincronización de extintores pendientes
class ExtinguisherSyncPage extends StatefulWidget {
  const ExtinguisherSyncPage({super.key});

  @override
  State<ExtinguisherSyncPage> createState() => _ExtinguisherSyncPageState();
}

class _ExtinguisherSyncPageState extends State<ExtinguisherSyncPage> {
  final SyncService _syncService = SyncService();

  List<Map<String, dynamic>> _pendingExtinguishers = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  int _syncedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingExtinguishers();
  }

  Future<void> _loadPendingExtinguishers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pending = await _syncService.getPendingExtinguishers();
      if (mounted) {
        setState(() {
          _pendingExtinguishers = pending;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Log del error completo para debugging
      if (kDebugMode) {
        print('Error al cargar pendientes: $e');
        print('Stack trace: $stackTrace');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _pendingExtinguishers = [];
        });

        // Solo mostrar error si realmente hay un problema
        final errorMessage = e.toString();
        if (!errorMessage.contains('No hay') &&
            !errorMessage.contains('empty')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar pendientes: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _syncAll() async {
    if (_pendingExtinguishers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay extintores pendientes para sincronizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncProgress = 0.0;
      _syncedCount = 0;
      _totalCount = _pendingExtinguishers.length;
    });

    try {
      final synced = await _syncService.syncPendingExtinguishers();

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });

        await _loadPendingExtinguishers();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced == _totalCount
                  ? 'Todos los extintores se sincronizaron exitosamente'
                  : '$synced de $_totalCount extintores sincronizados',
            ),
            backgroundColor: synced == _totalCount
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncSingle(int queueId) async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService.syncSingleExtinguisher(queueId);

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        await _loadPendingExtinguishers();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Extintor sincronizado exitosamente'
                  : 'Error al sincronizar extintor',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        await _loadPendingExtinguishers();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorDialog(Map<String, dynamic> item) {
    final payload =
        jsonDecode(item['payload'] as String) as Map<String, dynamic>;
    final lastSyncError = item['lastSyncError'] as String?;
    final syncAttempts = item['syncAttempts'] as int? ?? 0;
    final lastSyncAttempt = item['lastSyncAttempt'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Sincronización'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Extintor: ${payload['codeExtintor'] ?? payload['serialNumberNFC'] ?? "Sin código/serie"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Error: ${lastSyncError ?? "Error desconocido"}'),
              const SizedBox(height: 8),
              Text('Intentos: $syncAttempts'),
              if (lastSyncAttempt != null)
                Text(
                  'Último intento: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(lastSyncAttempt))}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _syncSingle(item['id'] as int);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: AppBar(
        title: const Text('Sincronización de Extintores'),
        backgroundColor: const Color(0xFFE84343),
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: _syncProgress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else if (_pendingExtinguishers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncAll,
              tooltip: 'Sincronizar todos',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingExtinguishers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay extintores pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Resumen de sincronización
                if (_isSyncing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: _syncProgress,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Sincronizando: $_syncedCount de $_totalCount',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '${(_syncProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Lista de pendientes
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingExtinguishers.length,
                    itemBuilder: (context, index) {
                      final item = _pendingExtinguishers[index];
                      return _buildExtinguisherCard(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExtinguisherCard(Map<String, dynamic> item) {
    final payload =
        jsonDecode(item['payload'] as String) as Map<String, dynamic>;
    final hasError =
        item['lastSyncError'] != null &&
        (item['lastSyncError'] as String).isNotEmpty;
    final codeExtintor = payload['codeExtintor'] as String?;
    final serialNumberNFC = payload['serialNumberNFC'] as String?;
    final displayLabel = codeExtintor ?? serialNumberNFC ?? 'Sin código/serie';
    final type = payload['type'] as String?;
    final location = payload['location'] as String?;
    final createdAt = item['createdAt'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasError ? Colors.red : Colors.orange,
          child: Icon(
            hasError ? Icons.error : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          displayLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type != null) Text('Tipo: $type'),
            if (location != null) Text('Ubicación: $location'),
            if (createdAt != null)
              Text(
                'Creado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(createdAt))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (hasError)
              Text(
                'Error: ${item['lastSyncError']}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError)
              IconButton(
                icon: const Icon(Icons.error_outline, color: Colors.red),
                onPressed: () => _showErrorDialog(item),
                tooltip: 'Ver error',
              ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _isSyncing
                  ? null
                  : () => _syncSingle(item['id'] as int),
              tooltip: 'Sincronizar',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
