import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/*
 * Global specification of light and dark theme app colors
 */

// Levels of darkness for specific colors in the themes
const int dialogLevel = 850;
const int scaffoldLevel = 900;

// Define colors for each theme in the app
const MaterialColor _mainColorLight = Colors.purple;
const Color _textColorNeutral = Colors.grey;

const MaterialColor _mainColorDark = Colors.deepPurple;
const Color _textColorDark = Colors.white;
Color? _dialogColorDark = Colors.grey[dialogLevel];
Color? _scaffoldLevelDark = Colors.grey[scaffoldLevel];

// Returns a ThemeData object containing light theme parameters
ThemeData voCapLight(BuildContext context) {
  return ThemeData(
    primarySwatch: _mainColorLight,
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme.apply(
      ),
    ),
    buttonTheme: Theme.of(context).buttonTheme.copyWith(
      highlightColor: _mainColorLight,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

// Returns a ThemeData object containing dark theme parameters
ThemeData voCapDark(BuildContext context) {
  return ThemeData(
    primarySwatch: _mainColorDark,
    hintColor: _textColorDark,
    textTheme: GoogleFonts.robotoTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: _textColorDark,
        displayColor: _textColorDark,
        decorationColor: _textColorDark,
      ),
    ),
    buttonTheme: Theme.of(context).buttonTheme.copyWith(
      highlightColor: _mainColorDark,
    ),
    dialogBackgroundColor: _dialogColorDark,
    iconTheme: Theme.of(context).iconTheme.copyWith(
      color: _mainColorDark,
    ),
    scaffoldBackgroundColor: _scaffoldLevelDark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}