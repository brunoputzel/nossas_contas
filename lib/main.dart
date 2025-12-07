import 'package:flutter/material.dart';
import 'navegador_principal.dart'; 

void main() {
  runApp(const GranaFacilApp());
}

class GranaFacilApp extends StatelessWidget {
  const GranaFacilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GranaFácil',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainNavigator(), 
      debugShowCheckedModeBanner: false,
    );
  }
}