import 'package:epub_reader/base_screen.dart';
import 'package:epub_reader/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: BaseScreen(),
    );
  }
}
