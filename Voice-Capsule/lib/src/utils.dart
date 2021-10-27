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