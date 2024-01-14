import 'package:flutter/material.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';

class MySolvedFillButton extends StatelessWidget {
  const MySolvedFillButton({
    required this.onPressed,
    required this.text,
    super.key,
  });

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: MySolvedColor.primaryButtonForeground,
          backgroundColor: MySolvedColor.main,
          disabledForegroundColor: MySolvedColor.disabledButtonForeground,
          disabledBackgroundColor: MySolvedColor.disabledButtonBackground,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        child: Text(
          text,
          style: MySolvedTextStyle.body1,
        ),
      ),
    );
  }
}
