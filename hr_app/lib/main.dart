import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/app_bootstrap.dart';

void main() async {
  final dependencies = await AppBootstrap.initialize();
  runApp(HrApp(dependencies: dependencies));
}
