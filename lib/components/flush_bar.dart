import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showSuccessFlushbar(BuildContext context, String message) {
  Flushbar(
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(12),
    backgroundColor: Colors.green.shade600,
    animationDuration: const Duration(milliseconds: 500),
    flushbarPosition: FlushbarPosition.TOP,
    forwardAnimationCurve: Curves.easeOut,
    reverseAnimationCurve: Curves.easeIn,
  ).show(context);
}

void showErrorFlushbar(BuildContext context, String message) {
  Flushbar(
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    icon: const Icon(Icons.error_outline, color: Colors.white),
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(12),
    backgroundColor: Colors.red.shade600,
    animationDuration: const Duration(milliseconds: 500),
    flushbarPosition: FlushbarPosition.TOP,
    forwardAnimationCurve: Curves.easeOut,
    reverseAnimationCurve: Curves.easeIn,
  ).show(context);
}
