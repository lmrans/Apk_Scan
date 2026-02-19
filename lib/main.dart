import 'package:apk_scan/screens/Tpscan.dart';
import 'package:flutter/material.dart';
// ignore: duplicate_import
import 'screens/Tpscan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Tpscan()
    );
  }
}