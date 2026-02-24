import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/extinguisher_entity.dart';
import '../../../../core/network/dio_client.dart';

class EditExtinguisherPage extends StatefulWidget {
  final Extinguisher extinguisher;

  const EditExtinguisherPage({super.key, required this.extinguisher});

  @override
  State<EditExtinguisherPage> createState() => _EditExtinguisherPageState();
}

class _EditExtinguisherPageState extends State<EditExtinguisherPage> {
  final _formKey = GlobalKey<FormState>();
  final Dio _dio = DioClient().dio;

  late TextEditingController codeController;
  late TextEditingController serialController;
  late TextEditingController locationController;
  late TextEditingController cylinderController;
  late TextEditingController typeController;
  late TextEditingController agentController;
  late TextEditingController capacityController;
  late TextEditingController statusController;
  late TextEditingController pressureController;
  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController ratingController;
  late TextEditingController yearController;
  late TextEditingController rechargeDateController;
  late TextEditingController hydrostaticDateController;
  late TextEditingController maintenanceDateController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.extinguisher;

    codeController = TextEditingController(text: e.codeExtintor);
    serialController = TextEditingController(text: e.serialNumberNFC);
    locationController = TextEditingController(text: e.location);
    cylinderController = TextEditingController(text: e.cylinderNumber);
    typeController = TextEditingController(text: e.type);
    agentController = TextEditingController(text: e.agent);
    capacityController = TextEditingController(text: e.capacity);
    statusController = TextEditingController(text: e.status);
    pressureController = TextEditingController(text: e.pressure);
    brandController = TextEditingController(text: e.brand);
    modelController = TextEditingController(text: e.model);
    ratingController = TextEditingController(text: e.rating);
    yearController = TextEditingController(text: e.yearManufacture);

    rechargeDateController = TextEditingController(
      text: e.rechargeDate?.toIso8601String().split('T').first ?? '',
    );

    hydrostaticDateController = TextEditingController(
      text: e.dateHydrostatic?.toIso8601String().split('T').first ?? '',
    );

    maintenanceDateController = TextEditingController(
      text: e.dateMaintenance?.toIso8601String().split('T').first ?? '',
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    serialController.dispose();
    locationController.dispose();
    cylinderController.dispose();
    typeController.dispose();
    agentController.dispose();
    capacityController.dispose();
    statusController.dispose();
    pressureController.dispose();
    brandController.dispose();
    modelController.dispose();
    ratingController.dispose();
    yearController.dispose();
    rechargeDateController.dispose();
    hydrostaticDateController.dispose();
    maintenanceDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initialDate = controller.text.isNotEmpty
        ? DateTime.parse(controller.text)
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
              child: GestureDetector(
                onTap: isDate ? () => _selectDate(controller) : null,
                child: AbsorbPointer(
                  absorbing: isDate,
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (isDate)
              const Positioned(
                right: 12,
                top: 18,
                child: Icon(Icons.calendar_today, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateExtinguisher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {};

      void addIfNotEmpty(String key, String value) {
        if (value.trim().isNotEmpty) {
          data[key] = value.trim();
        }
      }

      addIfNotEmpty("codeExtintor", codeController.text);
      addIfNotEmpty("serialNumberNFC", serialController.text);
      addIfNotEmpty("location", locationController.text);
      addIfNotEmpty("cylinderNumber", cylinderController.text);
      addIfNotEmpty("type", typeController.text);
      addIfNotEmpty("agent", agentController.text);
      addIfNotEmpty("capacity", capacityController.text);
      addIfNotEmpty("status", statusController.text);
      addIfNotEmpty("pressure", pressureController.text);
      addIfNotEmpty("brand", brandController.text);
      addIfNotEmpty("model", modelController.text);
      addIfNotEmpty("rating", ratingController.text);
      addIfNotEmpty("yearManufacture", yearController.text);

      if (rechargeDateController.text.isNotEmpty) {
        data["rechargeDate"] = DateTime.parse(
          rechargeDateController.text,
        ).toUtc().toIso8601String();
      }

      if (hydrostaticDateController.text.isNotEmpty) {
        data["dateHydrostatic"] = DateTime.parse(
          hydrostaticDateController.text,
        ).toUtc().toIso8601String();
      }

      if (maintenanceDateController.text.isNotEmpty) {
        data["dateMaintenance"] = DateTime.parse(
          maintenanceDateController.text,
        ).toUtc().toIso8601String();
      }

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debe modificar al menos un campo")),
        );
        return;
      }

      final response = await _dio.put(
        "/nfc/edit-extintor/${widget.extinguisher.id}",
        data: data,
      );

      final updatedJson = response.data['data'];

      final updatedExtinguisher = Extinguisher(
        id: updatedJson['id'],
        codeExtintor: updatedJson['codeExtintor'],
        serialNumberNFC: updatedJson['serialNumberNFC'],
        type: updatedJson['type'],
        capacity: updatedJson['capacity'],
        agent: updatedJson['agent'],
        cylinderNumber: updatedJson['cylinderNumber'],
        location: updatedJson['location'],
        status: updatedJson['status'],
        photo: updatedJson['photo'],
        pressure: updatedJson['pressure'],
        brand: updatedJson['brand'],
        model: updatedJson['model'],
        rating: updatedJson['rating'],
        yearManufacture: updatedJson['yearManufacture'],
        dateHydrostatic: updatedJson['dateHydrostatic'] != null
            ? DateTime.parse(updatedJson['dateHydrostatic'])
            : null,
        dateMaintenance: updatedJson['dateMaintenance'] != null
            ? DateTime.parse(updatedJson['dateMaintenance'])
            : null,
        rechargeDate: updatedJson['rechargeDate'] != null
            ? DateTime.parse(updatedJson['rechargeDate'])
            : null,
        createdAt: updatedJson['createdAt'] != null
            ? DateTime.parse(updatedJson['createdAt'])
            : null,
        updatedAt: updatedJson['updatedAt'] != null
            ? DateTime.parse(updatedJson['updatedAt'])
            : null,
        sedeId: updatedJson['sedeId'],
        usuarioCreadorId: updatedJson['usuarioCreadorId'],
        sedeName: updatedJson['sedeName'],
      );

      if (!mounted) return;

      Navigator.pop(context, updatedExtinguisher);

    } on DioException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.response?.data}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      appBar: AppBar(
        title: const Text(
          "Editar Extintor",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600
              ? 600.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField("Código", codeController),
                      _buildField("Nro Serie NFC", serialController),
                      _buildField("Ubicación", locationController),
                      _buildField("Nro Cilindro", cylinderController),
                      _buildField("Tipo", typeController),
                      _buildField("Agente", agentController),
                      _buildField("Capacidad", capacityController),
                      _buildField("Estado", statusController),
                      _buildField("Presión", pressureController),
                      _buildField("Marca", brandController),
                      _buildField("Modelo", modelController),
                      _buildField("Clasificación", ratingController),
                      _buildField("Año Fabricación", yearController),
                      _buildField(
                        "Fecha Recarga",
                        rechargeDateController,
                        isDate: true,
                      ),
                      _buildField(
                        "Fecha Prueba Hidrostática",
                        hydrostaticDateController,
                        isDate: true,
                      ),
                      _buildField(
                        "Fecha Mantenimiento",
                        maintenanceDateController,
                        isDate: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateExtinguisher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Editar Extintor",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
