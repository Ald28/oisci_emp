import '../entities/sede.dart';

abstract class SedeRepository {
  Future<List<Sede>> getSedes();
}

