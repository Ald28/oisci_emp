import '../../domain/entities/extinguisher_entity.dart';

/// Modelo: Extintor (Data Layer)
/// Coincide con la respuesta del backend
class ExtinguisherModel extends Extinguisher {
  const ExtinguisherModel({
    required super.id,
    super.codeExtintor,
    super.serialNumberNFC,
    super.type,
    super.capacity,
    super.agent,
    super.cylinderNumber,
    super.location,
    super.status,
    super.photo,
    super.photoPath,
    super.pressure,
    super.brand,
    super.model,
    super.rating,
    super.yearManufacture,
    super.dateHydrostatic,
    super.dateMaintenance,
    super.rechargeDate,
    super.createdAt,
    super.updatedAt,
    required super.sedeId,
    required super.usuarioCreadorId,
    super.sedeName,
  });

  /// Helper para parsear DateTime desde JSON
  /// Maneja tanto String ISO como objetos DateTime directamente
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Constructor desde JSON del backend
  /// El backend retorna: { ok: true, data: {...} }
  /// Cuando se crea, puede incluir usuarioCreador y sede como objetos
  factory ExtinguisherModel.fromJson(Map<String, dynamic> json) {
    // Manejar usuarioCreadorId (puede venir como campo directo o dentro de usuarioCreador)
    int usuarioCreadorId;
    if (json['usuarioCreadorId'] != null) {
      usuarioCreadorId = json['usuarioCreadorId'] as int;
    } else if (json['usuarioCreador'] != null &&
        json['usuarioCreador'] is Map) {
      usuarioCreadorId =
          (json['usuarioCreador'] as Map<String, dynamic>)['id'] as int;
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
      codeExtintor: json['codeExtintor'] as String?,
      serialNumberNFC: json['serialNumberNFC'] as String?,
      type: json['type'] as String?,
      capacity: json['capacity'] as String?,
      agent: json['agent'] as String?,
      cylinderNumber: json['cylinderNumber'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      photo: json['photo'] as String?,
      photoPath: null, // El backend no envía photoPath, solo photo (URL)
      pressure: json['pressure'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      rating: json['rating'] as String?,
      yearManufacture: json['yearManufacture'] as String?,
      dateHydrostatic: _parseDateTime(json['dateHydrostatic']),
      dateMaintenance: _parseDateTime(json['dateMaintenance']),
      rechargeDate: _parseDateTime(json['rechargeDate']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
      sedeName: sedeName,
    );
  }

  /// Convertir a JSON para crear/actualizar extintor
  Map<String, dynamic> toJson() {
    return {
      'codeExtintor': codeExtintor,
      'serialNumberNFC': serialNumberNFC,
      'type': type,
      'capacity': capacity,
      'agent': agent,
      'cylinderNumber': cylinderNumber,
      'location': location,
      'status': status,
      'photo': photo,
      'pressure': pressure,
      'brand': brand,
      'model': model,
      'rating': rating,
      'yearManufacture': yearManufacture,
      'dateHydrostatic': dateHydrostatic?.toIso8601String(),
      'dateMaintenance': dateMaintenance?.toIso8601String(),
      'rechargeDate': rechargeDate?.toIso8601String(),
      'sedeId': sedeId,
    };
  }

  /// Crear desde Map de SQLite
  factory ExtinguisherModel.fromMap(Map<String, dynamic> map) {
    return ExtinguisherModel(
      id: map['id'] as int,
      codeExtintor: map['codeExtintor'] as String?,
      serialNumberNFC: map['serialNumberNFC'] as String?,
      type: map['type'] as String?,
      capacity: map['capacity'] as String?,
      agent: map['agent'] as String?,
      cylinderNumber: map['cylinderNumber'] as String?,
      location: map['location'] as String?,
      status: map['status'] as String?,
      photo: map['photo'] as String?,
      photoPath: map['photoPath'] as String?,
      pressure: map['pressure'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      rating: map['rating'] as String?,
      yearManufacture: map['yearManufacture'] as String?,
      dateHydrostatic: map['dateHydrostatic'] != null
          ? DateTime.parse(map['dateHydrostatic'] as String)
          : null,
      dateMaintenance: map['dateMaintenance'] != null
          ? DateTime.parse(map['dateMaintenance'] as String)
          : null,
      rechargeDate: map['rechargeDate'] != null
          ? DateTime.parse(map['rechargeDate'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      sedeId: map['sedeId'] as int,
      usuarioCreadorId: map['usuarioCreadorId'] as int,
      sedeName:
          map['sede_name']
              as String?, // Incluir nombre de sede si viene del JOIN
    );
  }
}
