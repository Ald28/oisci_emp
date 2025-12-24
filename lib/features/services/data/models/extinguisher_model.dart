import '../../domain/entities/extinguisher.dart';

/// Modelo: Extintor (Data Layer)
/// Coincide con la respuesta del backend
class ExtinguisherModel extends Extinguisher {
  const ExtinguisherModel({
    required super.id,
    super.codigoNFC,
    super.numeroSerie,
    super.tipo,
    super.capacidad,
    super.agente,
    super.numeroCilindro,
    super.ubicacion,
    super.estado,
    super.historico,
    super.fechaBaja,
    super.foto,
    super.createdAt,
    super.updatedAt,
    required super.sedeId,
    required super.usuarioCreadorId,
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

    return ExtinguisherModel(
      id: json['id'] as int,
      codigoNFC: json['codigoNFC'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      tipo: json['tipo'] as String?,
      capacidad: json['capacidad'] as String?,
      agente: json['agente'] as String?,
      numeroCilindro: json['numeroCilindro'] as String?,
      ubicacion: json['ubicacion'] as String?,
      estado: json['estado'] as String?,
      historico: json['historico'] as String?,
      fechaBaja: json['fechaBaja'] as String?,
      foto: json['foto'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      sedeId: sedeId,
      usuarioCreadorId: usuarioCreadorId,
    );
  }

  /// Convertir a JSON para crear/actualizar extintor
  Map<String, dynamic> toJson() {
    return {
      'codigoNFC': codigoNFC,
      'numeroSerie': numeroSerie,
      'tipo': tipo,
      'capacidad': capacidad,
      'agente': agente,
      'numeroCilindro': numeroCilindro,
      'ubicacion': ubicacion,
      'estado': estado,
      'historico': historico,
      'fechaBaja': fechaBaja,
      'foto': foto,
      'sedeId': sedeId,
    };
  }
}

