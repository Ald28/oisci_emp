enum DocType { inspeccionMensual, fotografico }

extension DocTypeX on DocType {
  String get key =>
      this == DocType.inspeccionMensual ? 'INSPECCION_MENSUAL' : 'FOTOGRAFICO';

  String get title => this == DocType.inspeccionMensual
      ? 'Inspección mensual'
      : 'Reporte fotográfico';
}
