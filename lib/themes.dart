import 'package:flutter/material.dart';
import 'package:hoppy_club/config.dart';
import 'package:hoppy_club/sizes.dart';

final ThemeData lightTheme = ThemeData(
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: defaultTextSize),
    headlineMedium: TextStyle(fontSize: bigTextSize),
    headlineLarge: TextStyle(
      fontSize: headlineTextSize,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(fontSize: smallTextSize),
  ),
  scaffoldBackgroundColor: lightpurble,
);
