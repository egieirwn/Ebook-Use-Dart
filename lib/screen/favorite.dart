import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'baca_buku.dart'; // Pastikan nama file benar

class FavoriteBookPage extends StatelessWidget {
  const FavoriteBookPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Favorite Books',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FavoriteBooksPage(),
    );
  }
}

class FavoriteBooksPage extends StatefulWidget {
  const FavoriteBooksPage({Key? key}) : super(key: key);

  @override
  State<FavoriteBooksPage> createState() => _FavoriteBooksPageState();
}

class _FavoriteBooksPageState extends State<FavoriteBooksPage> {
  List<Map<String, dynamic>> _favoriteBooks = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteBooks();
  }

  Future<void> _loadFavoriteBooks() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get()
        .then((querySnapshot) {
      setState(() {
        _favoriteBooks = querySnapshot.docs
            .map((doc) => {
              ...doc.data(),
              'id': doc.id, // Add the document ID to the data
            })
            .toList();
      });
    });
  }
}


  Future<void> _removeBook(Map<String, dynamic> book) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Use the Firestore document ID (assuming 'id' is the document ID field)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(book['id']) // This should match the document ID in Firestore
          .delete();

      setState(() {
        _favoriteBooks.remove(book); // Remove from the list to reflect UI changes
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buku "${book['title']}" telah dihapus dari favorit.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus buku: $e'),
        ),
      );
    }
  }
}

  void _confirmRemoveBook(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Buku'),
          content: Text(
              'Apakah Anda yakin ingin menghapus buku "${book['title']}" dari favorit?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeBook(book);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _rereadBook(Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ulangi Baca'),
          content:
              Text('Apakah Anda ingin membaca ulang buku "${book['title']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBukuPage(), // Halaman daftar isi
                  ),
                );
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Books'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _favoriteBooks.isEmpty
            ? const Center(
                child: Text(
                  'No favorite books yet!',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _favoriteBooks.length,
                itemBuilder: (context, index) {
                  final book = _favoriteBooks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Image.network(
                        book['image'], // Assuming image URL is stored
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(book['title']),
                      subtitle: Text(
                          'Author: ${book['author']}\nPages: ${book['pages']}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.repeat, color: Colors.green),
                            onPressed: () => _rereadBook(book),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmRemoveBook(book),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
