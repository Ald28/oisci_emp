/// Entidad: Extintor
/// Coincide con el modelo Extintor del backend (Prisma)
class Extinguisher {
  final int id;
  final String? codeExtintor;
  final String? serialNumberNFC;
  final String? type; // Polvo Químico, CO2, Agua, etc.
  final String? capacity; // EJ: "5kg"
  final String? agent; // EJ: "ABC"
  final String? cylinderNumber;
  final String? location;
  final String? status; // OPERATIVO / INOPERATIVO
  final String? photo; // URL de la foto
  final String? photoPath; // Path local de la foto (para modo offline)
  final String? pressure;
  final String? brand;
  final String? model;
  final String? rating;
  final String? yearManufacture;
  final DateTime? dateHydrostatic;
  final DateTime? dateMaintenance;
  final DateTime? rechargeDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sedeId;
  final int usuarioCreadorId;
  final String? sedeName; // Nombre de la sede (cuando viene en la respuesta)

  const Extinguisher({
    required this.id,
    this.codeExtintor,
    this.serialNumberNFC,
    this.type,
    this.capacity,
    this.agent,
    this.cylinderNumber,
    this.location,
    this.status,
    this.photo,
    this.photoPath,
    this.pressure,
    this.brand,
    this.model,
    this.rating,
    this.yearManufacture,
    this.dateHydrostatic,
    this.dateMaintenance,
    this.rechargeDate,
    this.createdAt,
    this.updatedAt,
    required this.sedeId,
    required this.usuarioCreadorId,
    this.sedeName,
  });
}
