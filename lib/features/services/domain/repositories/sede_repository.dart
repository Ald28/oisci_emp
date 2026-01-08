import '../entities/sede_entity.dart';

abstract class SedeRepository {
  Future<List<Sede>> getSedes();
}

