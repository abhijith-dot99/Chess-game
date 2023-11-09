import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mychessapp/main.dart';
// Ensure this path is correct

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedLocation;
  final List<String> _locations = ['Location 1', 'Location 2', 'Location 3'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
Future<void> createUserProfile() async {
  if (_nameController.text.isNotEmpty && _selectedLocation != null) {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection('users');
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await users.doc(userId).set({
        'name': _nameController.text,
        'location': _selectedLocation,
        'profileCreated': true,
      });

      print("Profile created successfully."); // Debug statement

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ChessBoard()),
      );
    } catch (e) {
      print("Error creating profile: $e"); // Error handling
    }
  } else {
    print("Name or location not provided."); // Debug for empty fields
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create User Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              hint: const Text('Select Location'),
              onChanged: (newValue) {
                setState(() {
                  _selectedLocation = newValue;
                });
              },
              items: _locations.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: createUserProfile,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
