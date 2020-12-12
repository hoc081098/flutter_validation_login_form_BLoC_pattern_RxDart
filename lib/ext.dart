import 'package:flutter/material.dart';

extension BuildContextSnackbar on BuildContext {
  void showSnackBar(String msg) {
    final scaffoldMessenger = ScaffoldMessenger.of(this);

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

extension StateSnackbar on State {
  void showSnackBar(String msg) => context.showSnackBar(msg);
}
