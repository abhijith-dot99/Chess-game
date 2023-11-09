import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileDetailsPage extends StatelessWidget {
  const UserProfileDetailsPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${snapshot.data!['name']}', style: Theme.of(context).textTheme.headline6),
                    Text('Location: ${snapshot.data!['location']}', style: Theme.of(context).textTheme.headline6),
                    // Additional user details can be added here
                  ],
                ),
              );
            } else {
              return const Center(child: Text('No user data found'));
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
