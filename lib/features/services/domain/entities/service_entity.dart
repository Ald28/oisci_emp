/// Entidad: Servicio
/// Coincide con el modelo Servicio del backend (Prisma)
class ServiceEntity {
  final int id;
  final String type; // MANTENIMIENTO o INSPECCION
  final DateTime dateStart;
  final DateTime? dateEnd;
  final bool sincronizado;
  final String status; // EN_PROCESO o FINALIZADO
  final String statusValid; // APROBADO o RECHAZADO
  final String? historic;
  final int sedeId;
  final int userId;
  final int usuarioCreadorId;
  final int? usuarioActualizadorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceEntity({
    required this.id,
    required this.type,
    required this.dateStart,
    this.dateEnd,
    this.sincronizado = false,
    required this.status,
    this.statusValid = 'APROBADO',
    this.historic,
    required this.sedeId,
    required this.userId,
    required this.usuarioCreadorId,
    this.usuarioActualizadorId,
    this.createdAt,
    this.updatedAt,
  });
}
