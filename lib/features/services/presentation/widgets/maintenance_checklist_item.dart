import 'package:flutter/material.dart';

/// Widget: Item del checklist de mantenimiento
class MaintenanceChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool showEditIcon;
  final String? additionalInfo;
  final bool isDisabled;

  const MaintenanceChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onTap,
    this.onEdit,
    this.showEditIcon = false,
    this.additionalInfo,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Checkbox(
            value: isChecked,
            onChanged: isDisabled ? null : (_) => onTap(),
            activeColor: const Color(0xFFE84343),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
              color: isDisabled ? Colors.grey[400] : Colors.black87,
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
                    color: isDisabled
                        ? Colors.grey[400]
                        : const Color(0xFFE84343),
                    size: 20,
                  ),
                  onPressed: isDisabled ? null : onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          onTap: isDisabled ? null : onTap,
        ),
      ),
    );
  }
}
