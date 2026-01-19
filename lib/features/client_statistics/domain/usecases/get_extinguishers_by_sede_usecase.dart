import '../../../services/domain/entities/extinguisher_entity.dart';
import '../../../services/domain/repositories/extinguisher_repository.dart';

/// Use case: Obtener extintores por sedeId
class GetExtinguishersBySedeUseCase {
  final ExtinguisherRepository repository;

  GetExtinguishersBySedeUseCase(this.repository);

  Future<List<Extinguisher>> call(int sedeId) async {
    return await repository.getExtinguishersBySedeId(sedeId);
  }
}
