import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mychessapp/main.dart';
import 'pages/login_register_page.dart';

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Checking the authentication state
        if (snapshot.connectionState == ConnectionState.active) {
          // If the snapshot has data and the user is logged in
          if (snapshot.hasData) {
            // return const HomePage();
            return const ChessBoard();
          } else {
            return LoginRegisterPage(); // No user is logged in, show LoginPage
          }
        }

        // If the connection to the stream is still loading
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
