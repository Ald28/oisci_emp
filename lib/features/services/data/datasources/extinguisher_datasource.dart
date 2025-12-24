import '../../domain/entities/extinguisher.dart';

abstract class ExtinguisherDataSource {
  Future<Extinguisher?> searchExtinguisher(String searchTerm);
  Future<Extinguisher> createExtinguisher(Map<String, dynamic> data);
}

