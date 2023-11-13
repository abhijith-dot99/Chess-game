import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/pages/userprofiledetails.dart';
import '../main.dart';
import '../userprofiledetails.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  UserHomePageState createState() => UserHomePageState();
}

class UserHomePageState extends State<UserHomePage> {
  late Stream<List<DocumentSnapshot>> onlineUsersStream;
  String userLocation = 'Unknown';
  late StreamSubscription<DocumentSnapshot> userSubscription;

  @override
  void initState() {
    super.initState();
    setupUserListener();
  }

  void setupUserListener() {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          var userData = snapshot.data() as Map<String, dynamic>;
          setState(() {
            userLocation = userData['location'] ?? 'Unknown';
            onlineUsersStream = fetchOnlineUsers(userLocation);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    userSubscription.cancel();
    super.dispose();
  }

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

  void _showChallengeModal(BuildContext context, Map<String, dynamic> opponentData) {
    String betAmount = '5\$'; // Default value

    // Function to update betAmount when a new value is selected in the dropdown
    void updateBetAmount(String? newBetAmount) {
      if (newBetAmount != null) {
        betAmount = newBetAmount;
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(opponentData['name'], style: TextStyle(fontSize: 20)),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to user profile
                    },
                    child: Text('Visit'),
                  ),
                ],
              ),
              // Implement logic to display avatar image if available
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bet Amount:"),
                  DropdownButton<String>(
                    value: betAmount,
                    items: ['5\$', '10\$', '15\$'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      // Update the bet amount
                      //  setModalState(() {
                      //       betAmount = newValue ?? betAmount;
                      //     });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _sendChallenge(opponentData['uid'], betAmount);
                  Navigator.pop(context); // Close the modal after sending the challenge
                },
                child: const Text('Challenge'),
              ),
            ],
          ),
        );
      },
    );
  }
  void _sendChallenge(String opponentId, String betAmount) async {
    String challengerId = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference challenges = FirebaseFirestore.instance.collection('challenges');
    DocumentReference challengeDoc = await challenges.add({
      'challengerId': challengerId,
      'opponentId': opponentId,
      'betAmount': betAmount,
      'status': 'pending', // Initial status of the challenge
      'timestamp': FieldValue.serverTimestamp(), // Optional: For ordering or timing out challenges
    });
    // Send a notification to the opponent about the new challenge
    // This could be a push notification or an in-app update
    // For now, we'll assume a simple Firestore update that the opponent's app listens to
    FirebaseFirestore.instance.collection('users').doc(opponentId).collection('notifications').add({
      'type': 'challenge',
      'message': 'You have been challenged to a game!',
      'challengeId': challengeDoc.id, // Reference to the challenge
      'betAmount': betAmount,
      'challengerId': challengerId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text('Challenge sent successfully')),
    );


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: <Widget>[
          FutureBuilder<Map<String, dynamic>?>(
            future: fetchCurrentUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                String avatarUrl = snapshot.data!['avatar'];
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundImage: AssetImage(avatarUrl),
                    ),
                  ),
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
        future: fetchCurrentUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.data == null) {
            return const Center(child: Text('Error fetching user data'));
          }

          String userName = userSnapshot.data?['name'] ?? 'Player';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Hi, $userName', style: Theme.of(context).textTheme.headline6),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: onlineUsersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No online players in your location'));
                    }

                    var currentUser = FirebaseAuth.instance.currentUser;
                    var filteredUsers = snapshot.data!
                        .where((doc) => doc.id != currentUser!.uid) // Exclude current user
                        .toList();

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        var userData = filteredUsers[index].data() as Map<String, dynamic>;
                        String initial = userData['name'][0].toUpperCase();
                        String? avatarUrl = userData['avatar'];

                        return InkWell(
                          onTap: () => _showChallengeModal(context, userData),
                          child: Card(
                            child: ListTile(
                              leading: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CircleAvatar(backgroundImage: AssetImage(avatarUrl))
                                  : CircleAvatar(child: Text(initial)),
                              title: Text(userData['name']),
                              subtitle: Text(userData['location'] ?? 'Unknown location'),
                            ),
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
