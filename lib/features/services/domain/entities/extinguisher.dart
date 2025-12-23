/// Entidad: Extintor
/// Coincide con el modelo Extintor del backend (Prisma)
class Extinguisher {
  final int id;
  final String? codigoNFC; // Código NFC único
  final String? numeroSerie;
  final String? tipo; // Polvo Químico, CO2, Agua, etc.
  final String? capacidad; // EJ: "5kg"
  final String? agente; // EJ: "ABC"
  final String? numeroCilindro;
  final String? ubicacion;
  final String? estado; // OPERATIVO / INOPERATIVO
  final String? historico;
  final String? fechaBaja;
  final String? foto;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sedeId;
  final int usuarioCreadorId;

  const Extinguisher({
    required this.id,
    this.codigoNFC,
    this.numeroSerie,
    this.tipo,
    this.capacidad,
    this.agente,
    this.numeroCilindro,
    this.ubicacion,
    this.estado,
    this.historico,
    this.fechaBaja,
    this.foto,
    this.createdAt,
    this.updatedAt,
    required this.sedeId,
    required this.usuarioCreadorId,
  });
}

