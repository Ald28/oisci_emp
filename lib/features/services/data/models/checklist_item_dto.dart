/// DTO: Ítem del checklist (JSON)
class ChecklistItemDto {
  final String id;
  final String code;
  final String description;
  final bool isRequired;

  const ChecklistItemDto({
    required this.id,
    required this.code,
    required this.description,
    this.isRequired = true,
  });

  factory ChecklistItemDto.fromJson(Map<String, dynamic> json) {
    return ChecklistItemDto(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      isRequired: json['isRequired'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'isRequired': isRequired,
    };
  }
}

