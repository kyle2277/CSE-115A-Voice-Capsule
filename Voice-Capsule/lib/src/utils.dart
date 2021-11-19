import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
/*
 * Utility functions for general app UI features
 */

final dateTimeFormat = DateFormat("MM-dd-yyyy, hh:mm a");

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
void showToast_quick(BuildContext context, String message, {double duration = 2}) {
  int durationInMillis = (duration * 1000).floor();
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: durationInMillis),
      behavior: SnackBarBehavior.floating,
      content: Text(
          message,
          textAlign: TextAlign.center
      ),
    ),
  );
}

Future<void> showAlertDialog_OK(BuildContext context, String message) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Send Capsule'),
        content: SingleChildScrollView(
          child: Text(
            message,
            textScaleFactor: 0.75,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Replaces ' ', '/', '.', ':' characters in a string so it can be used as a file path
String sanitizeString(String input) {
  String output = input.replaceAll(' ', '_');
  output = output.replaceAll('/', '_');
  output = output.replaceAll('.', '-');
  output = output.replaceAll(':', '-');
  return output;
}

final double MILLIS_IN_A_SECOND = 1000;
final double SECONDS_IN_A_MINUTE = 60;

// Converts millisecond integer value to a timestamp in the format minutes:seconds.deciseconds
String millisToTimestamp(int milliseconds) {
  double totalSeconds = double.parse((milliseconds / MILLIS_IN_A_SECOND).toStringAsFixed(1));
  int clockMinutesAsInt;
  if(totalSeconds >= SECONDS_IN_A_MINUTE) {
    clockMinutesAsInt = ((totalSeconds - (totalSeconds % SECONDS_IN_A_MINUTE)) / 60).round();
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