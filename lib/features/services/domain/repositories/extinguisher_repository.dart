import '../entities/extinguisher.dart';

/// Contrato del repositorio de extintores
abstract class ExtinguisherRepository {
  /// Buscar extintor por código, número de serie o NFC UID
  /// Retorna null si no se encuentra
  Future<Extinguisher?> searchExtinguisher(String query);
}

