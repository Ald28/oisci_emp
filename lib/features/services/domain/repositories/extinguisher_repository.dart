import '../entities/extinguisher.dart';

/// Contrato del repositorio de extintores
abstract class ExtinguisherRepository {
  Future<Extinguisher?> searchExtinguisher(String searchTerm);
}

