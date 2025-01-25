import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebook/screen/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart'; // Import HomePage
import 'searching.dart';
import 'profile.dart';

class HistoryPages extends StatefulWidget {
  @override
  _HistoryPagesState createState() => _HistoryPagesState();
}

class _HistoryPagesState extends State<HistoryPages> {
  int _selectedIndex = 2;
  List<Map<String, dynamic>> bookHistory = [];

  @override
  void initState() {
    super.initState();
    _loadBookHistory();
  }

  // Load book history from Firestore for the logged-in user
  Future<void> _loadBookHistory() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('dateViewed', descending: true)
          .get();

      setState(() {
        bookHistory = snapshot.docs.map((doc) {
          return {
            'id': doc.id, // Store document ID for deletion
            'title': doc['title'],
            'author': doc['author'],
            'image': doc['image'],
            'dateViewed': doc['dateViewed'],
          };
        }).toList();
      });
    }
  }

  // Delete a specific book from history
  Future<void> _deleteBook(String bookId, int index) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .doc(bookId)
          .delete();

      setState(() {
        bookHistory.removeAt(index);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent transparent navigation bar issue
      appBar: AppBar(
        title: Text('Riwayat Membaca'),
        backgroundColor: const Color.fromARGB(255, 60, 169, 241),
      ),
      body: bookHistory.isEmpty
          ? Center(child: Text('Belum ada riwayat buku.'))
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: bookHistory.length,
              itemBuilder: (context, index) {
                final book = bookHistory[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  elevation: 4,
                  child: ListTile(
                    leading: Image.network(
                      book['image']!,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      book['title']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book['author']!),
                        SizedBox(height: 4),
                        Text(
                          'Dibaca pada: ${book['dateViewed']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBook(book['id'], index),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
