import '../../domain/entities/extinguisher.dart';

/// Modelo: Extintor (Data Layer)
/// Coincide con la respuesta del backend
class ExtinguisherModel extends Extinguisher {
  const ExtinguisherModel({
    required super.id,
    super.codeNFC,
    super.serialNumber,
    super.type,
    super.capacity,
    super.agent,
    super.cylinderNumber,
    super.location,
    super.status,
    super.historic,
    super.dateLow,
    super.photo,
    super.createdAt,
    super.updatedAt,
    required super.sedeId,
    required super.usuarioCreadorId,
    super.sedeName,
  });

  /// Constructor desde JSON del backend
  /// El backend retorna: { ok: true, data: {...} }
  /// Cuando se crea, puede incluir usuarioCreador y sede como objetos
  factory ExtinguisherModel.fromJson(Map<String, dynamic> json) {
    // Manejar usuarioCreadorId (puede venir como campo directo o dentro de usuarioCreador)
    int usuarioCreadorId;
    if (json['usuarioCreadorId'] != null) {
      usuarioCreadorId = json['usuarioCreadorId'] as int;
    } else if (json['usuarioCreador'] != null && json['usuarioCreador'] is Map) {
      usuarioCreadorId = (json['usuarioCreador'] as Map<String, dynamic>)['id'] as int;
    } else {
      throw Exception('usuarioCreadorId no encontrado en la respuesta');
    }

    // Manejar sedeId (puede venir como campo directo o dentro de sede)
    int sedeId;
    if (json['sedeId'] != null) {
      sedeId = json['sedeId'] as int;
    } else if (json['sede'] != null && json['sede'] is Map) {
      sedeId = (json['sede'] as Map<String, dynamic>)['id'] as int;
    } else {
      throw Exception('sedeId no encontrado en la respuesta');
    }

    // Extraer nombre de la sede si viene en la respuesta
    String? sedeName;
    if (json['sede'] != null && json['sede'] is Map) {
      sedeName = (json['sede'] as Map<String, dynamic>)['name_sede'] as String?;
    }

    return ExtinguisherModel(
      id: json['id'] as int,
      codeNFC: json['codeNFC'] as String?,
      serialNumber: json['serialNumber'] as String?,
      type: json['type'] as String?,
      capacity: json['capacity'] as String?,
      agent: json['agent'] as String?,
      cylinderNumber: json['cylinderNumber'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      historic: json['historic'] as String?,
      dateLow: json['dateLow'] as String?,
      photo: json['photo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
      sedeName: sedeName,
    );
  }

  /// Convertir a JSON para crear/actualizar extintor
  Map<String, dynamic> toJson() {
    return {
      'codeNFC': codeNFC,
      'serialNumber': serialNumber,
      'type': type,
      'capacity': capacity,
      'agent': agent,
      'cylinderNumber': cylinderNumber,
      'location': location,
      'status': status,
      'historic': historic,
      'dateLow': dateLow,
      'photo': photo,
      'sedeId': sedeId,
    };
  }
}

