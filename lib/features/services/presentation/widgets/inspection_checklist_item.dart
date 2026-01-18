import 'package:flutter/material.dart';

/// Widget: Item del checklist de inspección
class InspectionChecklistItem extends StatelessWidget {
  final String title;
  final String? value; // "SI" o "NO" o null
  final VoidCallback onTap;

  const InspectionChecklistItem({
    super.key,
    required this.title,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSi = value == 'SI';
    final isNo = value == 'NO';

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón SI
            GestureDetector(
              onTap: () {
                if (!isSi) {
                  onTap();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSi ? const Color(0xFFE84343) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSi ? const Color(0xFFE84343) : Colors.grey[400]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  'SI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSi ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón NO
            GestureDetector(
              onTap: () {
                if (!isNo) {
                  onTap();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isNo ? Colors.green : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isNo ? Colors.green : Colors.grey[400]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  'NO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isNo ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
