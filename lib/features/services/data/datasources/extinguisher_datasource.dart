import '../../domain/entities/extinguisher_entity.dart';

abstract class ExtinguisherDataSource {
  Future<Extinguisher?> searchExtinguisher(String searchTerm);
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data);
  Future<Extinguisher?> getExtinguisherById(int extintorId);
}
