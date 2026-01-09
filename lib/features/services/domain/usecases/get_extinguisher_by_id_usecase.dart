import '../entities/extinguisher_entity.dart';
import '../repositories/extinguisher_repository.dart';

/// Use case: Obtener extintor por ID
class GetExtinguisherByIdUseCase {
  final ExtinguisherRepository repository;

  GetExtinguisherByIdUseCase(this.repository);

  Future<Extinguisher?> call(int extintorId) async {
    return await repository.getExtinguisherById(extintorId);
  }
}
