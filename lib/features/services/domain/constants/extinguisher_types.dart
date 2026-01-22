/// Constantes para tipos y agentes de extintores
/// Datos estáticos que no cambiarán en el futuro
class ExtinguisherTypes {
  /// Lista de tipos de extintores disponibles
  static const List<String> types = [
    'PQS ABC',
    'PQS BC',
    'CO2 BC',
    'Acetato K',
    'H2O A',
    'H2O AC',
    'Agente limpio',
    'Espuma',
    'PQS D',
  ];

  /// Obtener agentes disponibles para un tipo específico
  /// Retorna una lista de agentes predefinidos y si tiene opción "Otros"
  static Map<String, dynamic> getAgentsByType(String? type) {
    if (type == null) {
      return {'predefined': <String>[], 'hasOther': false};
    }

    switch (type) {
      case 'PQS ABC':
        return {
          'predefined': [
            'Chino 40%',
            'Chino 75%',
            'Chino 90%',
            'Pyro-Chem 90%',
            'Ansul Foray',
          ],
          'hasOther': true,
        };

      case 'PQS BC':
        return {
          'predefined': [
            'Ansul Purple K',
            'Bicarbonato de potasio',
            'Bicarbonato de sodio',
          ],
          'hasOther': true,
        };

      case 'Espuma':
        return {
          'predefined': ['AFFF 3%', 'AFFF 6%', 'AR-AFFF', 'FFFP', 'Ecológica'],
          'hasOther': true,
        };

      case 'Agente limpio':
        return {
          'predefined': ['Halotron', 'Halon', 'FM-200', 'Novec 1230'],
          'hasOther': true,
        };

      // Para otros tipos (CO2 BC, Acetato K, H2O A, H2O AC, PQS D)
      // No tienen opciones predefinidas, se ingresa texto libre
      default:
        return {'predefined': <String>[], 'hasOther': false};
    }
  }

  /// Verificar si un tipo requiere selección de agente predefinido
  static bool requiresAgentSelection(String? type) {
    if (type == null) return false;
    return ['PQS ABC', 'PQS BC', 'Espuma', 'Agente limpio'].contains(type);
  }
}
