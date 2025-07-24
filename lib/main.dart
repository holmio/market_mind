import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_mind/auth/auth_bloc.dart';
import 'package:market_mind/blocs/auth/auth_bloc.dart';
import 'package:market_mind/screens/auth/login_screen.dart';
import 'package:market_mind/screens/home.dart';
import 'package:market_mind/services/firebase_services.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc(FirebaseServices.instance);

    return BlocProvider(
      create: (_) => authBloc,
      child: MaterialApp(
        title: 'Market Mind',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
