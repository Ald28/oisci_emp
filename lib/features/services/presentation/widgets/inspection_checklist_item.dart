import 'package:flutter/material.dart';
import '../../../../../core/widgets/custom_switch.dart';

/// Widget: Item del checklist de inspección con switch
class InspectionChecklistItem extends StatelessWidget {
  final String title;
  final bool value; // true o false
  final ValueChanged<bool> onChanged;

  const InspectionChecklistItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: CustomSwitch(value: value, onChanged: onChanged),
      ),
    );
  }
}
