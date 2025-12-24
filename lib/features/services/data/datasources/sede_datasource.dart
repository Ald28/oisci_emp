import '../../domain/entities/sede.dart';

abstract class SedeDataSource {
  Future<List<Sede>> getSedes();
}

