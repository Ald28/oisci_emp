/// Estado de búsqueda de extintor (NFC/código)
class ServicesScanState {
  final bool isScanning;
  final String? scannedCode;
  final String? error;

  const ServicesScanState({
    this.isScanning = false,
    this.scannedCode,
    this.error,
  });

  ServicesScanState copyWith({
    bool? isScanning,
    String? scannedCode,
    String? error,
  }) {
    return ServicesScanState(
      isScanning: isScanning ?? this.isScanning,
      scannedCode: scannedCode ?? this.scannedCode,
      error: error ?? this.error,
    );
  }
}

