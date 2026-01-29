/// Entidad: ServicioExtintor
/// Coincide con el modelo ServicioExtintor del backend (Prisma)
class ServiceExtinguisherEntity {
  final int id;
  final int servicioId;
  final int extintorId;
  final String? estadoInicial; // OPERATIVO o INOPERATIVO
  final String? estadoFinal; // OPERATIVO o INOPERATIVO
  final bool completado;
  final String? observaciones;
  final int usuarioCreadorId;
  final int? usuarioActualizadorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? codeExtintor;
  final String? serialNumberNFC;

  const ServiceExtinguisherEntity({
    required this.id,
    required this.servicioId,
    required this.extintorId,
    this.estadoInicial,
    this.estadoFinal,
    this.completado = false,
    this.observaciones,
    required this.usuarioCreadorId,
    this.usuarioActualizadorId,
    this.createdAt,
    this.updatedAt,
    this.codeExtintor,
    this.serialNumberNFC,
  });
}
