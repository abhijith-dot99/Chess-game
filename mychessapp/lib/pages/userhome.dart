
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/pages/userprofiledetails.dart';
import '../main.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    }
    return null;
  }

  Stream<List<DocumentSnapshot>> fetchOnlineUsers(String location) {
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
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileDetailsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchCurrentUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.data == null) {
            return const Center(child: Text('Error fetching user data'));
          }

          String userName = userSnapshot.data?['name'] ?? 'Player';
          String userLocation = userSnapshot.data?['location'] ?? 'Unknown';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Hi, $userName', style: Theme.of(context).textTheme.headline6),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: fetchOnlineUsers(userLocation),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No online players in your location'));
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two profiles per row
                        childAspectRatio: 3 / 2, // Adjust the ratio as needed
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var userData = snapshot.data![index].data() as Map<String, dynamic>;
                        String initial = userData['name'][0].toUpperCase();
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(initial)),
                            title: Text(userData['name']),
                            subtitle: Text(userData['location'] ?? 'Unknown location'),
                          ),
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
        child: const Icon(Icons.play_arrow),
        tooltip: 'Start Game',
      ),
    );
  }
}