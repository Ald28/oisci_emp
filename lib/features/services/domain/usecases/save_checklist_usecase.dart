import '../entities/checklist_result.dart';
import '../repositories/services_repository.dart';

/// UseCase: Guardar checklist parcial
class SaveChecklistUseCase {
  final ServicesRepository repository;

  SaveChecklistUseCase(this.repository);

  Future<void> call({
    required String serviceId,
    required List<ChecklistResult> results,
  }) async {
    return await repository.saveChecklist(
      serviceId: serviceId,
      results: results,
    );
  }
}

