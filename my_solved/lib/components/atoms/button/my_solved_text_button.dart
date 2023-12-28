import 'package:flutter/material.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';

class MySolvedTextButton extends StatelessWidget {
  const MySolvedTextButton({
    required this.onPressed,
    required this.text,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: MySolvedTextStyle.body2.copyWith(
          color: MySolvedColor.font,
        ),
      ),
    );
  }
}
