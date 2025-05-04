
import 'package:flutter/material.dart';
import 'package:campus_dash/core/themes/app_theme.dart';

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isError = false,
  int durationSeconds = 4,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  
  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(
          isError ? Icons.error : Icons.check_circle,
          color: isError ? Colors.red.shade300 : Colors.green.shade300,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: isError ? Colors.red.shade800 : primaryColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.all(12),
    duration: Duration(seconds: durationSeconds),
    action: SnackBarAction(
      label: 'Dismiss',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );
  
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
