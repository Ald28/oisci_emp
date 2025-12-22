/// DTO: Resultado de checklist (JSON)
class ChecklistResultDto {
  final String itemId;
  final bool isCompleted;
  final String? value;
  final String? notes;

  const ChecklistResultDto({
    required this.itemId,
    required this.isCompleted,
    this.value,
    this.notes,
  });

  factory ChecklistResultDto.fromJson(Map<String, dynamic> json) {
    return ChecklistResultDto(
      itemId: json['itemId'] as String,
      isCompleted: json['isCompleted'] as bool,
      value: json['value'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'isCompleted': isCompleted,
      'value': value,
      'notes': notes,
    };
  }
}

