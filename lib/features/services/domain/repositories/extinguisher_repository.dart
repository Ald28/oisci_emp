import '../entities/extinguisher_entity.dart';

/// Contrato del repositorio de extintores
abstract class ExtinguisherRepository {
  Future<Extinguisher?> searchExtinguisher(String searchTerm, {int? sedeId});
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data);
  Future<Extinguisher?> getExtinguisherById(int extintorId);
  Future<List<Extinguisher>> getExtinguishersBySedeId(int sedeId);
}
