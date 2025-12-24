import '../entities/extinguisher.dart';
import '../repositories/extinguisher_repository.dart';

/// Use case: Crear un nuevo extintor
class CreateExtinguisherUseCase {
  final ExtinguisherRepository repository;

  CreateExtinguisherUseCase(this.repository);

  Future<Extinguisher> call(Map<String, dynamic> data) async {
    return await repository.createExtinguisher(data);
  }
}

