import 'package:ebook/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ebook/model/edit_profile.dart'; // Import EditProfilePage
import 'package:ebook/provider/auth_provider.dart';
import 'package:ebook/provider/theme_provider.dart';
import 'package:ebook/screen/history.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'AKUN PENGGUNA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No. Telp: $phoneNumber',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tanggal Lahir: $birthDate',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SwitchListTile(
                          secondary: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: const Text(
                            'Mode Gelap',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                      );
                    },
                  ),
                  ProfileMenuItems(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Membaca',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryPages(),
                        ),
                      );
                    },
                  ),
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
                    onTap: () async {
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
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
  final Color? color;

  ProfileMenuItems({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? scheme.primary,
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
          color: scheme.onSurfaceVariant,
        ),
        onTap: () => onTap(),
      ),
    );
  }
}
