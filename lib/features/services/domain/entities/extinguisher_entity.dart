/// Entidad: Extintor
/// Coincide con el modelo Extintor del backend (Prisma)
class Extinguisher {
  final int id;
  final String? serialNumber;
  final String? type; // Polvo Químico, CO2, Agua, etc.
  final String? capacity; // EJ: "5kg"
  final String? agent; // EJ: "ABC"
  final String? cylinderNumber;
  final String? location;
  final String? status; // OPERATIVO / INOPERATIVO
  final String? photo; // URL de la foto
  final String? photoPath; // Path local de la foto (para modo offline)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sedeId;
  final int usuarioCreadorId;
  final String? sedeName; // Nombre de la sede (cuando viene en la respuesta)

  const Extinguisher({
    required this.id,
    this.serialNumber,
    this.type,
    this.capacity,
    this.agent,
    this.cylinderNumber,
    this.location,
    this.status,
    this.photo,
    this.photoPath,
    this.createdAt,
    this.updatedAt,
    required this.sedeId,
    required this.usuarioCreadorId,
    this.sedeName,
  });
}
