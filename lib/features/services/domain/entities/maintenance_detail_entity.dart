/// Entidad: MantenimientoDetalle
/// Coincide con el modelo MantenimientoDetalle del backend (Prisma)
class MaintenanceDetailEntity {
  final int id;
  final int servicioExtintorId;
  final bool mantenimiento;
  final bool recarga;
  final String? agenteCarga;
  final bool pruebaHidrostatica;
  final bool bajaExtintor;
  final String? motivoBaja;
  final bool pintura;
  final bool recargaCartucho;
  final bool cambioPartes;
  final int usuarioCreadorId;
  final int? usuarioActualizadorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaintenanceDetailEntity({
    required this.id,
    required this.servicioExtintorId,
    this.mantenimiento = false,
    this.recarga = false,
    this.agenteCarga,
    this.pruebaHidrostatica = false,
    this.bajaExtintor = false,
    this.motivoBaja,
    this.pintura = false,
    this.recargaCartucho = false,
    this.cambioPartes = false,
    required this.usuarioCreadorId,
    this.usuarioActualizadorId,
    this.createdAt,
    this.updatedAt,
  });
}
