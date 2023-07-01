import 'package:flutter/material.dart';

class JqlField extends StatelessWidget {
  const JqlField({
    super.key,
    required this.jqlController,
    required this.onSubmitted,
    required this.error,
    this.isMultiLine = false,
  });

  final TextEditingController jqlController;
  final void Function() onSubmitted;
  final String? error;
  final bool isMultiLine;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: jqlController,
      onSubmitted: (_) {
        onSubmitted();
      },
      maxLines: isMultiLine ? null : 1,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: error,
      ),
    );
  }
}
