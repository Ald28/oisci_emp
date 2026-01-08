import '../entities/sede_entity.dart';
import '../repositories/sede_repository.dart';

/// Use case: Obtener lista de sedes
class GetSedesUseCase {
  final SedeRepository repository;

  GetSedesUseCase(this.repository);

  Future<List<Sede>> call() async {
    return await repository.getSedes();
  }
}

