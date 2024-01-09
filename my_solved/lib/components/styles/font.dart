import 'package:flutter/material.dart';

class MySolvedFont {
  static const String pretendard = "Pretendard";
  static const String sourceCodePro = "SourceCodePro";
}

class MySolvedTextStyle {
  static const TextStyle title1 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    fontFamily: MySolvedFont.pretendard,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    fontFamily: MySolvedFont.pretendard,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    fontFamily: MySolvedFont.pretendard,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    fontFamily: MySolvedFont.pretendard,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    fontFamily: MySolvedFont.pretendard,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w300,
    fontFamily: MySolvedFont.pretendard,
  );
}
