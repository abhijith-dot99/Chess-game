// import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // // import 'package:firebase_auth/pages/home_page.dart'; 
// // // import 'package:firebase_auth/pages/login_register_page.dart'; 
 
// // class WidgetTree extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return StreamBuilder<User?>(
// //       // stream: FirebaseAuth.instance.authStateChanges(),
// //       stream: Auth().authStateChanges,
// //       builder: (context, snapshot) {
// //         // Checking the authentication state
// //         if (snapshot.connectionState == ConnectionState.active) {
// //           // If the snapshot has data and the user is logged in
// //           if (snapshot.hasData && snapshot.data != null) {
// //             return HomePage(); // The user is logged in, show HomePage
// //           } else {
// //             return const LoginPage(); // No user is logged in, show LoginPage
// //           }
// //         }

// //         // If the connection to the stream is still loading
// //         return Scaffold(
// //           body: Center(child: CircularProgressIndicator()),
// //         );
// //       },
// //     );
// //   }
// // }
