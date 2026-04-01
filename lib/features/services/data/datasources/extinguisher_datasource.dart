import '../../domain/entities/extinguisher_entity.dart';

abstract class ExtinguisherDataSource {
  Future<Extinguisher?> searchExtinguisher(String searchTerm, {int? sedeId});
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data);
  Future<Extinguisher> updateExtinguisher(int extintorId, Map<String, dynamic> data);
  Future<Extinguisher?> getExtinguisherById(int extintorId);
  Future<List<Extinguisher>> getExtinguishersBySedeId(int sedeId);
  Future<List<Extinguisher>> getExtinguishersWithoutSerialNumber({int? sedeId});
  Future<List<Extinguisher>> getAllExtinguishers();
}
