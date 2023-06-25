import 'package:flutter/material.dart';

class CalculateButton extends StatelessWidget {
  const CalculateButton({
    super.key,
    required this.onPressed,
    this.inVerticalOrientation = false,
  });

  final void Function()? onPressed;
  final bool inVerticalOrientation;

  @override
  Widget build(BuildContext context) {
    final String text;
    if (inVerticalOrientation) {
      text = 'Посчитать Статистику';
    } else {
      text = 'Посчитать\nСтатистику';
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}
