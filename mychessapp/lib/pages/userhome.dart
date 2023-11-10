import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/main.dart';
import 'package:mychessapp/pages/chess_board.dart';
import 'package:mychessapp/pages/userprofiledetails.dart'; // Import UserProfileDetailsPage

class UserHomePage extends StatelessWidget {
  const UserHomePage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
  }

  Stream<List<DocumentSnapshot>> fetchUsersInSameLocation(String location) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .where('location', isEqualTo: location)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Players'),
        actions: [
          FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                String initial = snapshot.data!['name'][0].toUpperCase();
                return IconButton(
                  icon: CircleAvatar(child: Text(initial)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserProfileDetailsPage()),
                  ),
                );
              }
              return const CircleAvatar(child: Text('?'));
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final String currentUserLocation = userSnapshot.data?['location'] ?? 'Unknown';
          final String currentUserName = userSnapshot.data?['name'] ?? 'Player';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Hi, $currentUserName', style: Theme.of(context).textTheme.headline6),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: fetchUsersInSameLocation(currentUserLocation),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No online players in your location'));
                    }

                    List<DocumentSnapshot> users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var userData = users[index].data() as Map<String, dynamic>;
                        if (userData['uid'] == FirebaseAuth.instance.currentUser!.uid) {
                          return const SizedBox.shrink(); // Don't display the current user
                        }
                        String initial = userData['name'][0].toUpperCase();
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(initial),
                          ),
                          title: Text(userData['name']),
                          subtitle: Text(userData['location'] ?? 'Unknown location'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChessBoard()),
        ),
        tooltip: 'Start Game',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
