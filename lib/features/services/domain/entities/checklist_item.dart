/// Entidad: Ítem del checklist
class ChecklistItem {
  final String id;
  final String code; // CH1, CH2, etc.
  final String description;
  final bool isRequired;

  const ChecklistItem({
    required this.id,
    required this.code,
    required this.description,
    this.isRequired = true,
  });
}

