import '../../domain/entities/extinguisher.dart';

abstract class ExtinguisherDataSource {
  Future<Extinguisher?> searchExtinguisher(String query);
}

