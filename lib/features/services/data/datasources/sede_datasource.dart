import '../../domain/entities/sede_entity.dart';

abstract class SedeDataSource {
  Future<List<Sede>> getSedes();
}

