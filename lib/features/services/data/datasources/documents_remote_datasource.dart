import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class DocumentsRemoteDataSource {
  final DioClient dioClient;
  DocumentsRemoteDataSource(this.dioClient);

  Future<Uint8List> downloadInspeccionMensualPdf(int servicioId) async {
    final res = await dioClient.dio.get<List<int>>(
      '/reporte/inspeccion-mensual/$servicioId/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }

  Future<Uint8List> downloadFotograficoPdf(int servicioId) async {
    final res = await dioClient.dio.get<List<int>>(
      '/reporte/fotografico/$servicioId/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }
}
