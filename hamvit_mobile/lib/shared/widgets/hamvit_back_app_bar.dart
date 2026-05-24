import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

AppBar hamvitBackAppBar(
  BuildContext context, {
  required String title,
  String fallbackRoute = '/home',
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(fallbackRoute);
        }
      },
    ),
    title: Text(title),
  );
}