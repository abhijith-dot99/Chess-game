import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileDetailsPage extends StatefulWidget {
  const UserProfileDetailsPage({Key? key}) : super(key: key);

  @override
  _UserProfileDetailsPageState createState() => _UserProfileDetailsPageState();
}

class _UserProfileDetailsPageState extends State<UserProfileDetailsPage> {
  final List<String> locations = ['Location 1', 'Location 2', 'Location 3'];
  String? selectedLocation;
  bool isEditingLocation = false;

  // List of avatar URLs or asset paths
  final List<String> avatarImages = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
  ];

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
  }

  Future<void> updateAvatar(String newAvatar) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'avatar': newAvatar});
    setState(() {});
  }

  Future<void> updateLocation(String newLocation) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'location': newLocation});
    setState(() {
      isEditingLocation = false;
    });
  }

  // Function to display avatar selection modal
  void showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
          ),
          itemCount: avatarImages.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                updateAvatar(avatarImages[index]);
                Navigator.pop(context); // Close the modal after selection
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(avatarImages[index]), // Or NetworkImage for network URLs
              ),
            );
          },
        );
      },
    );
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
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            var userData = snapshot.data!;
            String avatarUrl = userData['avatar']; // Get the avatar URL
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4.0,
                    child: ListTile(
                      title: Text('Name: ${userData['name']}'),
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(avatarUrl),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    child: const Text('Edit Avatar'),
                    onPressed: showAvatarSelection,
                  ),
                  // Conditional widget for location editing
                  isEditingLocation
                      ? Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        items: locations.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLocation = newValue;
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
                        onPressed: () {
                          if (selectedLocation != null) {
                            updateLocation(selectedLocation!);
                          }
                        },
                        child: const Text('Update Location'),
                      ),
                    ],
                  )
                      : ListTile(
                    title: const Text('Location'),
                    subtitle: Text(userData['location'] ?? 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          isEditingLocation = true;
                          selectedLocation = userData['location'];
                        });
                      },
                    ),
                  ),
                  // ... additional profile details if any ...
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

