import 'package:flutter/material.dart';

/// Widget: Item row del checklist
class ChecklistItemRow extends StatelessWidget {
  final String code;
  final String description;
  final bool isCompleted;
  final VoidCallback? onTap;

  const ChecklistItemRow({
    super.key,
    required this.code,
    required this.description,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: isCompleted,
        onChanged: (_) => onTap?.call(),
      ),
      title: Text(description),
      subtitle: Text(code),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

