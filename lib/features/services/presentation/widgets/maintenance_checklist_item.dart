import 'package:flutter/material.dart';

/// Widget: Item del checklist de mantenimiento
class MaintenanceChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool showEditIcon;
  final String? additionalInfo;

  const MaintenanceChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onTap,
    this.onEdit,
    this.showEditIcon = false,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: isChecked,
          onChanged: (_) => onTap(),
          activeColor: const Color(0xFFE84343),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
            color: Colors.black87,
            decoration: isChecked ? TextDecoration.none : null,
          ),
        ),
        subtitle: additionalInfo != null && additionalInfo!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  additionalInfo!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : null,
        trailing: showEditIcon
            ? IconButton(
                icon: Icon(
                  Icons.edit,
                  color: const Color(0xFFE84343),
                  size: 20,
                ),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
