import 'package:flutter/material.dart';
import '../../../home/presentation/widgets/home_app_bar.dart';
import '../../domain/entities/client_entity.dart';

/// Página: Estadísticas del Cliente
/// Esta página mostrará gráficos y estadísticas del cliente seleccionado
class ClientStatisticsPage extends StatefulWidget {
  final ClientEntity client;

  const ClientStatisticsPage({
    super.key,
    required this.client,
  });

  @override
  State<ClientStatisticsPage> createState() => _ClientStatisticsPageState();
}

class _ClientStatisticsPageState extends State<ClientStatisticsPage> {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente
            Card(
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
                    const SizedBox(height: 8),
                    Text('RUC: ${widget.client.ruc}'),
                    if (widget.client.address.isNotEmpty)
                      Text('Dirección: ${widget.client.address}'),
                    if (widget.client.phone.isNotEmpty)
                      Text('Teléfono: ${widget.client.phone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Placeholder para gráficos
            const Center(
              child: Text(
                'Gráficos y estadísticas se implementarán aquí',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder para gráfico de torta
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text('Gráfico de Torta\n(Extintores por tipo)'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder para histograma
            Card(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text('Histograma\n(Servicios por año/mes)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
