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

  Extinguisher copyWith({
    String? codeExtintor,
    String? serialNumberNFC,
    String? type,
    String? capacity,
    String? agent,
    String? cylinderNumber,
    String? location,
    String? status,
    String? photo,
    String? photoPath,
    String? pressure,
    String? brand,
    String? model,
    String? rating,
    String? yearManufacture,
    DateTime? dateHydrostatic,
    DateTime? dateMaintenance,
    DateTime? rechargeDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sedeName,
  }) {
    return Extinguisher(
      id: id, // obligatorio
      sedeId: sedeId, // obligatorio
      usuarioCreadorId: usuarioCreadorId, // obligatorio

      codeExtintor: codeExtintor ?? this.codeExtintor,
      serialNumberNFC: serialNumberNFC ?? this.serialNumberNFC,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      agent: agent ?? this.agent,
      cylinderNumber: cylinderNumber ?? this.cylinderNumber,
      location: location ?? this.location,
      status: status ?? this.status,
      photo: photo ?? this.photo,
      photoPath: photoPath ?? this.photoPath,
      pressure: pressure ?? this.pressure,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      rating: rating ?? this.rating,
      yearManufacture: yearManufacture ?? this.yearManufacture,
      dateHydrostatic: dateHydrostatic ?? this.dateHydrostatic,
      dateMaintenance: dateMaintenance ?? this.dateMaintenance,
      rechargeDate: rechargeDate ?? this.rechargeDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sedeName: sedeName ?? this.sedeName,
    );
  }
}
