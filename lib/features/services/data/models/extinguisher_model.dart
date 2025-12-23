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
  factory ExtinguisherModel.fromJson(Map<String, dynamic> json) {
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
      sedeId: json['sedeId'] as int,
      usuarioCreadorId: json['usuarioCreadorId'] as int,
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

