import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'navegador_principal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NossasContasApp());
}


class NossasContasApp extends StatelessWidget {
  const NossasContasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NossasContas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}
