import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebook/screen/baca_buku.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'history.dart';
import 'favorite.dart';
import 'profile.dart';

class BookDetailPage extends StatefulWidget {
  final String title;
  final String author;
  final dynamic image;
  final int pages;

  const BookDetailPage({
    required this.title,
    required this.author,
    required this.image,
    required this.pages,
    Key? key, required Map<String, dynamic> book, required String bookId,
  }) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  String _description =
      "Selena mengisahkan perjalanan seorang gadis muda yang penuh dengan impian dan harapan...";
  String _format = "E-book Selena tersedia dalam beberapa format, termasuk:\n"
      "- PDF: Format yang umum dan mudah diakses di berbagai perangkat.\n"
      "- ePub: Format yang ideal untuk e-reader.\n"
      "- MOBI: Cocok untuk penggunaan Kindle.";

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  // Load book details from Firestore
  Future<void> _loadBookDetails() async {
    var doc = await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.title)
        .get();

    if (doc.exists) {
      setState(() {
        _description = doc['description'] ?? _description;
        _format = doc['format'] ?? _format;
      });
    }
  }

  // Add to the user's history collection in Firestore
  Future<void> _addToHistory() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var book = {
        'title': widget.title,
        'author': widget.author,
        'image': widget.image is Uint8List
            ? base64Encode(widget.image)
            : widget.image,
        'dateViewed': DateTime.now().toString(),
      };

      // Add to user's specific history collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add(book);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku berhasil ditambahkan ke riwayat!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login!')),
      );
    }
  }

  // Add to favorites collection in Firestore
  Future<void> _addToFavorites() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var book = {
        'title': widget.title,
        'author': widget.author,
        'image': widget.image is Uint8List
            ? base64Encode(widget.image)
            : widget.image,
        'dateAdded': DateTime.now().toString(),
      };

      // Add to user's specific favorites collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add(book);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku berhasil ditambahkan ke favorit!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildBookDetailContent(context),
      HistoryPages(),
      FavoriteBookPage(),
      ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Book'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetailContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 18, 134, 188),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(widget.image),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _description,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Format Buku',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_format),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _addToHistory(); // Add book to history before reading
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBukuPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 18, 134, 188),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Baca Buku'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () => _showUpdateDialog(context),
              child: const Text('Update'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: _addToFavorites,
              child: const Text('Tambah ke Favorit'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Disarankan Untuk Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 18, 134, 188),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildRecommendedBook(
                "Selena",
                "Hamna",
                "assets/images/selena.png",
                context,
              ),
              _buildRecommendedBook(
                "Hello",
                "Nasywa",
                "assets/images/hello.png",
                context,
              ),
              _buildRecommendedBook(
                "Pulang Pergi",
                "Angga",
                "assets/images/pulangpergi.png",
                context,
              ),
              _buildRecommendedBook(
                "Laskar Pelangi",
                "Giee",
                "assets/images/laskarpelangi.png",
                context,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic image) {
    if (image is Uint8List) {
      return Image.memory(image, height: 150, width: 100, fit: BoxFit.cover);
    } else if (image is String) {
      return Image.asset(image, height: 150, width: 100, fit: BoxFit.cover);
    } else {
      return Image.asset('assets/images/default.png',
          height: 150, width: 100, fit: BoxFit.cover);
    }
  }

  void _showUpdateDialog(BuildContext context) {
    final TextEditingController descriptionController =
        TextEditingController(text: _description);
    final TextEditingController formatController =
        TextEditingController(text: _format);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Buku'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(hintText: 'Masukkan deskripsi baru'),
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: formatController,
                decoration:
                    const InputDecoration(hintText: 'Masukkan format baru'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _description = descriptionController.text.trim();
                  _format = formatController.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedBook(
      String title, String author, String image, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
              title: title,
              author: author,
              image: image,
              pages: 100, book: {}, bookId: '',
            ),
          ),
        );
      },
      child: Column(
        children: [
          Image.asset(
            image,
            width: 100,
            height: 150,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(author),
        ],
      ),
    );
  }
}
