/// DTO: Evidencia/Adjunto (JSON)
class AttachmentDto {
  final String id;
  final String serviceId;
  final String type;
  final String url;
  final String createdAt;

  const AttachmentDto({
    required this.id,
    required this.serviceId,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  factory AttachmentDto.fromJson(Map<String, dynamic> json) {
    return AttachmentDto(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'type': type,
      'url': url,
      'createdAt': createdAt,
    };
  }
}

