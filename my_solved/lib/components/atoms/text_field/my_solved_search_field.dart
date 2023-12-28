import 'package:flutter/material.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';

class MySolvedSearchField extends StatelessWidget {
  const MySolvedSearchField({
    required this.hintText,
    required this.onChange,
    required this.onSubmitted,
    Key? key,
  }) : super(key: key);

  final String hintText;
  final Function(String value) onChange;
  final Function(String value) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: MySolvedTextStyle.body1,
      cursorColor: MySolvedColor.main,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        prefixIcon: Icon(Icons.search, size: 20),
        hintStyle: MySolvedTextStyle.body1,
        hintText: hintText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: MySolvedColor.textFieldBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: MySolvedColor.main,
          ),
        ),
      ),
      onChanged: (value) => onChange(value),
      onSubmitted: (value) => onSubmitted(value),
    );
  }
}
