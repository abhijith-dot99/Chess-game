import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mychessapp/pages/userprofiledetails.dart';

import '../main.dart';
import 'UserDetails.dart';
import 'challenge_request_screen.dart'; 

class UserHomePage extends StatefulWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  UserHomePageState createState() => UserHomePageState();
}

class UserHomePageState extends State<UserHomePage> {
  late Stream<List<DocumentSnapshot>> onlineUsersStream;
  String userLocation = 'Unknown';
  late StreamSubscription<DocumentSnapshot> userSubscription;
   late StreamSubscription<QuerySnapshot> challengeRequestsSubscription;

  // Declare betAmount as a class field
  String betAmount = '5\$'; // Default value

  @override
  void initState() {
    super.initState();
    setupUserListener();
    listenToChallengeRequests();
  }



  //new change
  
  void listenToChallengeRequests() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      challengeRequestsSubscription = FirebaseFirestore.instance
          .collection('challengeRequests')
          .where('opponentId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var challengeData = change.doc.data() as Map<String, dynamic>;
                String challengerId = challengeData['challengerId'];
                String betAmount = challengeData['betAmount'];
                // Fetch the challenger's user data such as name
                FirebaseFirestore.instance.collection('users').doc(challengerId).get().then((userDoc) {
                  if (userDoc.exists) {
                    var challengerData = userDoc.data() as Map<String, dynamic>;
                    String challengerName = challengerData['name'];
                    // Show the challenge request dialog
                    showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return ChallengeRequestScreen(challengerName: challengerName, betAmount: betAmount);
                      },
                    ).then((accepted) {
                      if (accepted != null && accepted) {
                        // Navigate to the chessboard or handle accepted challenge
                      }
                    });
                  }
                });
              }
            }
          });
    }
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

  void navigateToUserDetails(BuildContext context, String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => UserDetailsPage(userId: userId),
    ));
  }

  @override
  void dispose() {
    userSubscription.cancel();
    super.dispose();
    challengeRequestsSubscription.cancel();
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
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

  void _showChallengeModal(
      BuildContext context, Map<String, dynamic> opponentData) {
    // Function to update betAmount when a new value is selected in the dropdown
    void updateBetAmount(String? newBetAmount) {
      if (newBetAmount != null) {
        setState(() {
          betAmount = newBetAmount;
        });
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
                      String? userId = opponentData['uid'];
                      if (userId != null) {
                        navigateToUserDetails(context, userId);
                      } else {
                        // Handle the null case, maybe show an error message
                        print(opponentData);
                      }
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
                    onChanged: updateBetAmount,
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  // Send challenge request and get the challengeId
                  String challengeId =
                  await _sendChallenge(opponentData['uid'], betAmount);

                  // Show opponent response dialog
                  _showOpponentResponseDialog(context, challengeId);

                  // Close the modal after sending the challenge
                  Navigator.pop(context);
                },
                child: const Text('Challenge'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOpponentResponseDialog(
      BuildContext context, String challengeId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Challenge Request'),
          content: Column(
            children: [
              // Now, you can access betAmount directly
              Text('You have been challenged with a bet of $betAmount.'),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      // Accept the challenge
                      await _respondToChallenge(challengeId, true);
                      Navigator.pop(context);
                      MaterialPageRoute(
                          builder: (context) => const ChessBoard());
                    },
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Reject the challenge
                      await _respondToChallenge(challengeId, false);
                      Navigator.pop(context);
                    },
                    child: Text('Reject'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to send a challenge
Future<String> _sendChallenge(String opponentId, String betAmount) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null) {
    // Try to send the challenge and handle any potential errors
    try {
      DocumentReference challengeDocRef = await FirebaseFirestore.instance.collection('challengeRequests').add({
        'challengerId': currentUserId,
        'opponentId': opponentId,
        'betAmount': betAmount,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(), // It's a good practice to store the time of the challenge
      });

      // After sending the challenge, display an alert on the challenger's screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challenge sent to $opponentId with bet $betAmount')),
      );

      // Return the challenge ID
      return challengeDocRef.id;
    } catch (e) {
      // If sending the challenge fails, log the error and return an empty string or handle the error as needed
      print('Error sending challenge: $e');
      return ''; // Or handle the error appropriately
    }
  } else {
    // If the user is not logged in, handle this case as well
    print('User is not logged in.');
    return ''; // Or handle the error appropriately
  }
}


  Future<void> _respondToChallenge(String challengeId, bool isAccepted) async {
    CollectionReference challenges =
    FirebaseFirestore.instance.collection('challenges');
    await challenges.doc(challengeId).update({
      'status': isAccepted ? 'accepted' : 'rejected',
    });
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
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
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
                    MaterialPageRoute(
                        builder: (context) => const UserProfileDetailsPage()),
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
                child: Text('Hi, $userName',
                    style: Theme.of(context).textTheme.headline6),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: onlineUsersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No online players in your location'));
                    }

                    var currentUser = FirebaseAuth.instance.currentUser;
                    var filteredUsers = snapshot.data!
                        .where((doc) =>
                    doc.id != currentUser!.uid) // Exclude current user
                        .toList();

                    return GridView.builder(
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        var userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                        String initial = userData['name'][0].toUpperCase();
                        String? avatarUrl = userData['avatar'];

                        return InkWell(
                          onTap: () => _showChallengeModal(context, userData),
                          child: Card(
                            child: ListTile(
                              leading: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? CircleAvatar(
                                  backgroundImage: AssetImage(avatarUrl))
                                  : CircleAvatar(child: Text(initial)),
                              title: Text(userData['name']),
                              subtitle: Text(
                                  userData['location'] ?? 'Unknown location'),
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

