import 'package:flutter/material.dart';

/*
 * Utility functions for general app UI features
 */

// Shows "snackbar" style popup with the given message and an OK button
// Default duration of 5 seconds
void showToast_OK(BuildContext context, String message, {int duration = 5}) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      duration: const Duration(seconds:5),
      behavior: SnackBarBehavior.floating,
      content: Text(
          message,
          textAlign: TextAlign.center
      ),
      action: SnackBarAction(
          label: 'OK',
          onPressed: scaffold.hideCurrentSnackBar,
          textColor: Colors.purpleAccent
      ),
    ),
  );
}

// Shows "snackbar" style popup with the given message and then quickly hides itself
// Default duration of 2 seconds
void showToast_quick(BuildContext context, String message, {int duration = 2}) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      duration: Duration(seconds: duration),
      behavior: SnackBarBehavior.floating,
      content: Text(
          message,
          textAlign: TextAlign.center
      ),
    ),
  );
}

final double millisInASecond = 1000;
final double secondsInAMinute = 60;

// Converts millisecond integer value to a timestamp in the format minutes:seconds.deciseconds
String millisToTimestamp(int milliseconds) {
  double totalSeconds = double.parse((milliseconds / millisInASecond).toStringAsFixed(1));
  int clockMinutesAsInt;
  if(totalSeconds >= secondsInAMinute) {
    clockMinutesAsInt = ((totalSeconds - (totalSeconds % secondsInAMinute)) / 60).round();
  } else {
    clockMinutesAsInt = 0;
  }
  double clockSecondsAsDouble;
  if (clockMinutesAsInt > 0) {
    clockSecondsAsDouble = double.parse((totalSeconds - (60 * clockMinutesAsInt)).toStringAsFixed(2));
  } else {
    clockSecondsAsDouble = totalSeconds;
  }
  String clockSeconds = clockSecondsAsDouble < 10.0 ? '0$clockSecondsAsDouble' : '$clockSecondsAsDouble';
  String clockMinutes = clockMinutesAsInt < 10 ? '0$clockMinutesAsInt' : '$clockMinutesAsInt';
  return '$clockMinutes:$clockSeconds';
}