import 'package:flutter/material.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';

enum MySolvedButtonStyle {
  primary,
  secondary;

  Color get foregroundColor => this == MySolvedButtonStyle.primary
      ? MySolvedColor.primaryButtonForeground
      : MySolvedColor.secondaryFont;

  Color get backgroundColor => this == MySolvedButtonStyle.primary
      ? MySolvedColor.main
      : MySolvedColor.secondaryButtonBackground;
}

class MySolvedFitButton extends StatelessWidget {
  const MySolvedFitButton({
    super.key,
    required this.onPressed,
    this.buttonStyle = MySolvedButtonStyle.primary,
    required this.text,
  });

  final VoidCallback? onPressed;
  final MySolvedButtonStyle buttonStyle;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: Size.zero,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        foregroundColor: buttonStyle.foregroundColor,
        backgroundColor: buttonStyle.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: MySolvedTextStyle.caption1,
      ),
    );
  }
}