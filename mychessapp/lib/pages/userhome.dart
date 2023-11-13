import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/pages/userprofiledetails.dart';

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

void _showChallengeModal(BuildContext context, Map<String, dynamic> opponentData) {
  String betAmount = '5\$'; // Default value
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
                  child: Text('View Profile'),
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
                  },
                ),
              ],
            ),
            ElevatedButton(
    onPressed: () {
      _sendChallenge(opponentData['uid'], betAmount);
      Navigator.pop(context); // Close the modal after sending the challenge
    },
    child: Text('Challenge'),
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
  await challenges.add({
    'challengerId': challengerId,
    'opponentId': opponentId,
    'betAmount': betAmount,
    'status': 'pending', // Initial status of the challenge
    'timestamp': FieldValue.serverTimestamp(), // Optional: For ordering or timing out challenges
  });
  // You can add more code here for confirmation or error handling
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

                    var currentUser = FirebaseAuth.instance.currentUser;
                    var filteredUsers = snapshot.data!
                        .where((doc) => doc.id != currentUser!.uid) // Exclude current user
                        .toList();

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Two profiles per row
                        childAspectRatio: 3 / 2, // Adjust the ratio as needed
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        var userData = filteredUsers[index].data() as Map<String, dynamic>;
                        return InkWell(
                          onTap: () => _showChallengeModal(context, userData),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text(userData['name'][0].toUpperCase())),
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
        onPressed: () {
          // Navigate to chessboard or a waiting screen
        },
        child: const Icon(Icons.play_arrow),
        tooltip: 'Start Game',
      ),
    );
  }
}
