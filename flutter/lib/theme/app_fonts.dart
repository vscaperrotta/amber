import 'package:flutter/material.dart';

/// Locally bundled fonts (assets/fonts) — no network fetch, unlike the
/// previous google_fonts-based Outfit. Mulish carries body/UI text;
/// Baloo2 is reserved for the handful of large screen-title headings.
abstract final class AppFonts {
  static TextStyle body({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'Mulish',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  static TextStyle display({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Baloo2',
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
