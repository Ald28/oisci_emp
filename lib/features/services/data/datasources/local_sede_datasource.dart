import 'package:hive_flutter/hive_flutter.dart';
import '../models/sede_model.dart';
import '../models/sede_hive_model.dart';
import 'sede_datasource.dart';

/// DataSource local usando Hive para almacenar sedes
class LocalSedeDataSource implements SedeDataSource {
  static const String _boxName = 'sedes';

  /// Obtener la caja de Hive
  Future<Box<SedeHiveModel>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<SedeHiveModel>(_boxName);
    }
    return Hive.box<SedeHiveModel>(_boxName);
  }

  @override
  Future<List<SedeModel>> getSedes() async {
    final box = await _getBox();
    final sedesHive = box.values.toList();

    // Convertir de SedeHiveModel a SedeModel
    return sedesHive.map((sedeHive) {
      return SedeModel(
        id: sedeHive.id,
        nameSede: sedeHive.nameSede,
        address: sedeHive.address,
        city: sedeHive.city,
        active: sedeHive.active,
      );
    }).toList();
  }

  /// Guardar sedes localmente (desde el servidor)
  Future<void> saveSedes(List<SedeModel> sedes) async {
    final box = await _getBox();

    // Limpiar sedes existentes
    await box.clear();

    // Guardar nuevas sedes
    for (final sede in sedes) {
      final sedeHive = SedeHiveModel.fromSedeModel(sede);
      await box.add(sedeHive);
    }
  }

  /// Verificar si hay sedes guardadas localmente
  Future<bool> hasSedes() async {
    final box = await _getBox();
    return box.isNotEmpty;
  }

  /// Obtener cantidad de sedes guardadas
  Future<int> getSedesCount() async {
    final box = await _getBox();
    return box.length;
  }
}
