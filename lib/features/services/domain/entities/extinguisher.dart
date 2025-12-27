/// Entidad: Extintor
/// Coincide con el modelo Extintor del backend (Prisma)
class Extinguisher {
  final int id;
  final String? codeNFC; // Código NFC único
  final String? serialNumber;
  final String? type; // Polvo Químico, CO2, Agua, etc.
  final String? capacity; // EJ: "5kg"
  final String? agent; // EJ: "ABC"
  final String? cylinderNumber;
  final String? location;
  final String? status; // OPERATIVO / INOPERATIVO
  final String? historic;
  final String? dateLow;
  final String? photo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sedeId;
  final int usuarioCreadorId;
  final String? sedeName; // Nombre de la sede (cuando viene en la respuesta)

  const Extinguisher({
    required this.id,
    this.codeNFC,
    this.serialNumber,
    this.type,
    this.capacity,
    this.agent,
    this.cylinderNumber,
    this.location,
    this.status,
    this.historic,
    this.dateLow,
    this.photo,
    this.createdAt,
    this.updatedAt,
    required this.sedeId,
    required this.usuarioCreadorId,
    this.sedeName,
  });
}

