import 'package:flutter/material.dart';
// import 'pages/login_register_page.dart'; 
import 'dart:async';
import 'widget_tree.dart'; // Make sure this import points to your WidgetTree file

class ChessSplashScreen extends StatefulWidget {
  @override
  _ChessSplashScreenState createState() => _ChessSplashScreenState();
}

class _ChessSplashScreenState extends State<ChessSplashScreen> {
  double _iconOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Start the icon fade-in animation after a delay
    Timer(Duration(seconds: 1), () {
      setState(() {
        _iconOpacity = 1.0; // Fade in the icon
      });
    });

    // Navigate to the main content after some delay
    Future.delayed(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WidgetTree()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/king.jpg', width: 100, height: 100),
            AnimatedOpacity(
              opacity: _iconOpacity,
              duration: Duration(seconds: 2),
              child: Image.asset('assets/location.jpg', width: 40, height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
