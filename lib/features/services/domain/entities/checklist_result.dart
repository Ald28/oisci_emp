/// Entidad: Resultado de un ítem del checklist
class ChecklistResult {
  final String itemId;
  final bool isCompleted;
  final String? value; // Para valores como "cartucho", etc.
  final String? notes;

  const ChecklistResult({
    required this.itemId,
    required this.isCompleted,
    this.value,
    this.notes,
  });
}

