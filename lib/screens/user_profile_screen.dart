import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart'; // Import the new EditProfileScreen

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User _user;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_user.uid).get();
    setState(() {
      _userData = userDoc.data() as Map<String, dynamic>;
    });
  }

  String _getRoleName(int role) {
    switch (role) {
      case 1:
        return 'Admin';
      case 2:
        return 'Landlord';
      case 3:
        return 'Tenant';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Neutral background
      appBar: AppBar(
        title: Text('Your Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, // Make the app bar white
        elevation: 0, // Flat app bar
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userData: _userData),
                ),
              );
              if (updated == true) {
                _loadUserData(); // Reload user data if profile was updated
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                child: Icon(Icons.person, size: 50, color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                '${_userData['first_name']} ${_userData['last_name']}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                _getRoleName(_userData['role'] ?? 0),
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            SizedBox(height: 24),
            _buildInfoCard('Email', _userData['email'] ?? '', Icons.email),
            _buildInfoCard('Phone', _userData['phone'] ?? '', Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        trailing: Icon(icon, color: Colors.blueAccent),
      ),
    );
  }
}
