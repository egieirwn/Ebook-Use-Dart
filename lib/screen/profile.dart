import 'package:ebook/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebook/model/edit_profile.dart'; // Import EditProfilePage

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String phoneNumber = '';
  String birthDate = '';
  String address = '';
  String email = '';

  // Fetch user profile data
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          userName = snapshot['fullName'] ?? '';
          phoneNumber = snapshot['phone'] ?? '';
          birthDate = snapshot['dob'] ?? '';
          address = snapshot['address'] ?? '';
          email = snapshot['email'] ?? '';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 85, 177, 238),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AKUN PENGGUNA',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color.fromARGB(255, 180, 201, 231),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color.fromARGB(255, 27, 111, 221),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No. Telp: $phoneNumber',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tanggal Lahir: $birthDate',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ProfileMenuItems(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () async {
                      final updatedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            fullName: userName,
                            dob: birthDate,
                            address: address,
                            phone: phoneNumber,
                            email: email,
                          ),
                        ),
                      );

                      if (updatedData != null &&
                          updatedData is Map<String, String>) {
                        setState(() {
                          userName = updatedData['name']!;
                          birthDate = updatedData['dob']!;
                          address = updatedData['address']!;
                          phoneNumber = updatedData['phone']!;
                          email = updatedData['email']!;
                        });

                        // Optionally, you can save the updated data back to Firestore here
                        await _saveUpdatedProfileData(updatedData);
                      }
                    },
                  ),
                  ProfileMenuItems(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: Colors.red,
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save updated data to Firestore
  Future<void> _saveUpdatedProfileData(Map<String, String> updatedData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': updatedData['name'],
        'dob': updatedData['dob'],
        'address': updatedData['address'],
        'phone': updatedData['phone'],
        'email': updatedData['email'],
      });
    }
  }
}

class ProfileMenuItems extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function onTap;
  final Color color;

  ProfileMenuItems({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: () => onTap(),
      ),
    );
  }
}
