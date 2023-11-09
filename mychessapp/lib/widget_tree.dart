import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/main.dart';
import 'package:mychessapp/pages/login_register_page.dart';
import 'package:mychessapp/pages/chess_board.dart'; // Ensure this path is correct
import 'package:mychessapp/pages/user_profile.dart';
import 'package:mychessapp/user_profile.dart'; // Ensure this path is correct

class WidgetTree extends StatelessWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.done) {
                  if (userSnapshot.data != null && userSnapshot.data!.exists && userSnapshot.data!['profileCreated'] == true) {
                    return const ChessBoard();
                  } else {
                    return const UserProfilePage();
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          } else {
            return const LoginRegisterPage();
          }
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
