import 'package:flutter/material.dart';

/// Modal: Selector de agente para RECARGA
class RechargeModal extends StatefulWidget {
  final String? initialAgent;

  const RechargeModal({super.key, this.initialAgent});

  @override
  State<RechargeModal> createState() => _RechargeModalState();
}

class _RechargeModalState extends State<RechargeModal> {
  String? _selectedAgent;

  final List<Map<String, dynamic>> _agents = [
    {'name': '40%', 'value': '40%'},
    {'name': '75%', 'value': '75%'},
    {'name': '90%', 'value': '90%'},
    {'name': 'PURPURA K 92%', 'value': 'PURPURA K 92%'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAgent = widget.initialAgent;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'AGENTE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            // Lista de agentes con barras de progreso
            ..._agents.map((agent) {
              final isSelected = _selectedAgent == agent['value'];
              final progressValue = _getProgressValue(agent['value'] as String);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAgent = agent['value'] as String;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE84343).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE84343)
                            : Colors.transparent,
                        width: isSelected ? 2 : 0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Barra de progreso
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agent['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFE84343)
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFFE84343),
                                  ),
                                  minHeight: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón OK (solo visible cuando está seleccionado)
                        if (isSelected)
                          SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(_selectedAgent);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE84343),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            // El botón OK está en cada item cuando está seleccionado
          ],
        ),
      ),
    );
  }

  double _getProgressValue(String agent) {
    switch (agent) {
      case '40%':
        return 0.4;
      case '75%':
        return 0.75;
      case '90%':
        return 0.9;
      case 'PURPURA K 92%':
        return 0.92;
      default:
        return 0.0;
    }
  }
}
