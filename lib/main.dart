import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/bootstrap.dart';
import 'app/app.dart';

void main() async {
  final container = await Bootstrap.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SeeMe(),
    ),
  );
}
