/// Entidad: Sede (Domain Layer)
class Sede {
  final int id;
  final String nameSede;
  final String address;
  final String city;
  final bool active;
  final String? managerName;
  final String? managerPhone;
  final String? managerEmail;

  const Sede({
    required this.id,
    required this.nameSede,
    required this.address,
    required this.city,
    required this.active,
    this.managerName,
    this.managerPhone,
    this.managerEmail,
  });
}
