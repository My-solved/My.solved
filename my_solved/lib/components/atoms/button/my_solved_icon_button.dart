import 'package:flutter/material.dart';

class MySolvedIconButton extends StatelessWidget {
  const MySolvedIconButton({
    required this.onPressed,
    required this.icon,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: icon,
    );
  }
}
