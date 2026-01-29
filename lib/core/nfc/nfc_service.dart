import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Resultado del escaneo NFC
class NfcResult {
  final String uid;

  /// Valor de serie leído del NDEF (se usa como término de búsqueda → serialNumberNFC en extintor)
  final String? serialFromNdef;

  NfcResult({required this.uid, this.serialFromNdef});
}

/// Servicio para escanear tarjetas NFC
class NfcService {
  /// Escanear una tarjeta NFC
  /// Retorna null si no se pudo leer o el usuario canceló
  static Future<NfcResult?> scan() async {
    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
      );

      // UID viene como String
      final String uid = tag.id;

      String? serialFromNdef;

      // Intentar leer NDEF (si la tarjeta tiene datos con el número de serie)
      try {
        final records = await FlutterNfcKit.readNDEFRecords();

        if (records.isNotEmpty) {
          final record = records.first;
          final Uint8List? payload = record.payload;

          if (payload != null && payload.isNotEmpty) {
            final statusByte = payload[0];
            final languageCodeLength = statusByte & 0x3F;

            final textBytes = payload.sublist(1 + languageCodeLength);
            serialFromNdef = String.fromCharCodes(textBytes).trim();
          }
        }
      } catch (_) {
        // No NDEF → normal, solo tenemos UID
      }

      await FlutterNfcKit.finish();

      return NfcResult(uid: _formatUid(uid), serialFromNdef: serialFromNdef);
    } catch (e) {
      try {
        await FlutterNfcKit.finish();
      } catch (_) {}
      return null;
    }
  }

  /// Formatea el UID para mostrarlo con separadores
  /// Convierte "045ED59EC32A81" → "04:5E:D5:9E:C3:2A:81"
  static String _formatUid(String uid) {
    final buffer = StringBuffer();

    for (int i = 0; i < uid.length; i += 2) {
      buffer.write(uid.substring(i, i + 2).toUpperCase());
      if (i + 2 < uid.length) buffer.write(':');
    }

    return buffer.toString();
  }
}
