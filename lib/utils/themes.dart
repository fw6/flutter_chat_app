import 'package:flutter/material.dart';

class Themes {
  static ThemeData kIOSTheme = ThemeData(
    primaryColor: Colors.grey[100],
    primarySwatch: Colors.blue,
    primaryColorBrightness: Brightness.light,
  );

  static ThemeData kDefaultTheme = ThemeData(
    primarySwatch: Colors.blue,
    accentColor: Colors.blue[400],
  );
}
