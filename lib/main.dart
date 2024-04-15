import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:object_detection/HomeScreen.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DMFT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(background: Colors.transparent),
        appBarTheme: AppBarTheme(backgroundColor: Colors.transparent),
      ),
      home: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg', // Change this to your image path
              fit: BoxFit.cover,
            ),
          ),
          // Your actual content goes here
          LoginPage(),
          // CustomPage(), // You can replace this with HomeScreen() or any other widget
        ],
      ),
    );
  }
}
