import '../entities/extinguisher_entity.dart';
import '../repositories/extinguisher_repository.dart';

class GetAllExtinguishersUseCase {
  final ExtinguisherRepository repository;

  GetAllExtinguishersUseCase(this.repository);

  Future<List<Extinguisher>> call() async {
    return await repository.getAllExtinguishers();
  }
}
