import 'package:flutter/material.dart';

/// Widget: Tabla resumen CH1..CHn
class ServiceSummaryTable extends StatelessWidget {
  final Map<String, bool> items; // CH1 -> true/false

  const ServiceSummaryTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('ITEM')),
        DataColumn(label: Text('COD')),
        DataColumn(label: Text('ESTADO')),
      ],
      rows: items.entries.map((entry) {
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(entry.key)),
            DataCell(Checkbox(value: entry.value, onChanged: null)),
          ],
        );
      }).toList(),
    );
  }
}

