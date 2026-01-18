/// Entidad: Cliente (Domain Layer)
class ClientEntity {
  final int id;
  final String clientCode;
  final String razonSocial;
  final String ruc;
  final String phone;
  final String address;
  final int userId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientEntity({
    required this.id,
    required this.clientCode,
    required this.razonSocial,
    required this.ruc,
    required this.phone,
    required this.address,
    required this.userId,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });
}
