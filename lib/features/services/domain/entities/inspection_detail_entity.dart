/// Entidad: InspeccionDetalle
/// Coincide con el modelo InspeccionDetalle del backend (Prisma)
class InspectionDetailEntity {
  final int id;
  final int servicioExtintorId;
  final String? foto1Url;
  final String? foto2Url;
  final String? foto3Url;
  /// Paths locales para modo offline (no vienen del backend)
  final String? foto1Path;
  final String? foto2Path;
  final String? foto3Path;
  final String? visibilidad;
  final String? visualizacion;
  final String? accesibilidad;
  final String? altura;
  final String? situacion;
  final String? conservacion;
  final String? inscripciones;
  final String? recorrido;
  final String? peso;
  final String? observaciones;
  final int usuarioCreadorId;
  final int? usuarioActualizadorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InspectionDetailEntity({
    required this.id,
    required this.servicioExtintorId,
    this.foto1Url,
    this.foto2Url,
    this.foto3Url,
    this.foto1Path,
    this.foto2Path,
    this.foto3Path,
    this.visibilidad,
    this.visualizacion,
    this.accesibilidad,
    this.altura,
    this.situacion,
    this.conservacion,
    this.inscripciones,
    this.recorrido,
    this.peso,
    this.observaciones,
    required this.usuarioCreadorId,
    this.usuarioActualizadorId,
    this.createdAt,
    this.updatedAt,
  });
}
