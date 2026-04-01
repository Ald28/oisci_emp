import 'package:flutter/material.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/floating_label_text_field.dart';
import '../../domain/entities/extinguisher_entity.dart';

/// Widget: Input con Autocomplete + Botón Buscar
class CodeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final List<Extinguisher> extinguishersList;

  const CodeSearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    this.extinguishersList = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Si no puedes escanear la tarjeta ingresa el código o número de serie del extintor',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Autocomplete<Extinguisher>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                // If it's empty, show at most 100 items to keep performance snappy before filtering
                return extinguishersList.take(50);
              }
              final query = textEditingValue.text.toLowerCase();
              return extinguishersList.where((ext) {
                final matchCode =
                    ext.codeExtintor?.toLowerCase().contains(query) ?? false;
                final matchSerial =
                    ext.serialNumberNFC?.toLowerCase().contains(query) ?? false;
                return matchCode || matchSerial;
              });
            },
            displayStringForOption: (Extinguisher option) {
              // Devolver el código o serie para el input al seleccionar
              if (option.codeExtintor != null && option.codeExtintor!.isNotEmpty) {
                return option.codeExtintor!;
              }
              return option.serialNumberNFC ?? '';
            },
            onSelected: (Extinguisher selection) {
              final text = selection.codeExtintor?.isNotEmpty == true
                  ? selection.codeExtintor!
                  : (selection.serialNumberNFC ?? '');
              controller.text = text;
              // Buscamos directamente después de seleccionar
              onSearch();
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              // Sincronizar controlladores solo la primera vez o si difieren
              if (controller.text != textEditingController.text) {
                textEditingController.text = controller.text;
              }

              textEditingController.addListener(() {
                if (controller.text != textEditingController.text) {
                  controller.text = textEditingController.text;
                }
              });

              return FloatingLabelTextField(
                controller: textEditingController,
                focusNode: focusNode,
                label: 'Código o número de serie',
                hintText: 'Ingrese su búsqueda aquí',
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    // Ajustar ancho teniendo en cuenta el padding general (- 48)
                    width: MediaQuery.of(context).size.width - 48,
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          leading: const Icon(
                            Icons.fire_extinguisher,
                            color: Color(0xFFE84343),
                          ),
                          title: Text(
                            option.codeExtintor?.isNotEmpty == true
                                ? option.codeExtintor!
                                : 'Sin código',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Serie: ${option.serialNumberNFC ?? "N/A"} | Tipo: ${option.type ?? "N/A"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                text: 'Buscar',
                onPressed: onSearch,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
