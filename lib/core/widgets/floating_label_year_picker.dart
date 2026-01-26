import 'package:flutter/material.dart';

/// Widget reutilizable: Selector de año con label flotante en el borde superior izquierdo
class FloatingLabelYearPicker extends StatefulWidget {
  final int? selectedYear;
  final String label;
  final String? hintText;
  final int? firstYear;
  final int? lastYear;
  final ValueChanged<int?>? onYearSelected;

  const FloatingLabelYearPicker({
    super.key,
    this.selectedYear,
    required this.label,
    this.hintText,
    this.firstYear,
    this.lastYear,
    this.onYearSelected,
  });

  @override
  State<FloatingLabelYearPicker> createState() => _FloatingLabelYearPickerState();
}

class _FloatingLabelYearPickerState extends State<FloatingLabelYearPicker> {
  int? _internalYear;

  @override
  void initState() {
    super.initState();
    _internalYear = widget.selectedYear;
  }

  @override
  void didUpdateWidget(FloatingLabelYearPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedYear != oldWidget.selectedYear) {
      _internalYear = widget.selectedYear;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = _internalYear != null;
    final currentYear = DateTime.now().year;
    final startYear = widget.firstYear ?? (currentYear - 50); // Por defecto, últimos 50 años
    final endYear = widget.lastYear ?? (currentYear + 10); // Por defecto, hasta 10 años en el futuro

    // Generar lista de años
    final years = List.generate(
      endYear - startYear + 1,
      (index) => startYear + index,
    ).reversed.toList(); // Años más recientes primero

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => _showYearPickerModal(context, years),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _internalYear != null
                          ? _internalYear.toString()
                          : (widget.hintText ?? widget.label),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _internalYear != null ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ),
        if (hasValue)
          Positioned(
            top: -8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showYearPickerModal(BuildContext context, List<int> years) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Calcular altura máxima (máximo 50% de la pantalla o altura suficiente para mostrar ~8 items)
        final screenHeight = MediaQuery.of(context).size.height;
        final itemHeight = 56.0; // Altura aproximada de cada ListTile
        final headerHeight = 80.0; // Altura del header (handle + título + divider)
        final maxItems = 8;
        final calculatedHeight = (itemHeight * maxItems) + headerHeight;
        final maxHeight = screenHeight * 0.5;
        final finalHeight = calculatedHeight < maxHeight ? calculatedHeight : maxHeight;

        return SizedBox(
          height: finalHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Lista de años con scroll
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: years.length,
                  itemBuilder: (context, index) {
                    final year = years[index];
                    final isSelected = _internalYear == year;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      dense: true,
                      title: Text(
                        year.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFFE84343) : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFE84343),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _internalYear = year;
                        });
                        if (widget.onYearSelected != null) {
                          widget.onYearSelected!(year);
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
