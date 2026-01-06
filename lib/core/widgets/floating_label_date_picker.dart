import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget reutilizable: Selector de fecha con label flotante en el borde superior izquierdo
class FloatingLabelDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final String label;
  final String? hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final Color? primaryColor;

  const FloatingLabelDatePicker({
    super.key,
    this.selectedDate,
    required this.label,
    this.hintText,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.onDateSelected,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedDate != null;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final primary = primaryColor ?? const Color(0xFFE84343);

    return GestureDetector(
      onTap: () => _showDatePicker(context, primary),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? dateFormat.format(selectedDate!)
                          : (hintText ?? label),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: hasValue ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                ],
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
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, Color primary) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && onDateSelected != null) {
      onDateSelected!(picked);
    }
  }
}
