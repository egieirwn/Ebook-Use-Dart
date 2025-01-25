import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history.dart';
import 'favorite.dart';
import 'profile.dart';
import 'baca_buku.dart';

class BookDetailUserPage extends StatefulWidget {
  final String title;
  final String author;
  final dynamic image;
  final int pages;

  const BookDetailUserPage({
    required this.title,
    required this.author,
    required this.image,
    required this.pages,
    Key? key,
  }) : super(key: key);

  @override
  State<BookDetailUserPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailUserPage> {
  static const String defaultDescription =
      "Selena mengisahkan perjalanan seorang gadis muda yang penuh dengan impian dan harapan...";
  static const String defaultFormat =
      "E-book Selena tersedia dalam beberapa format, termasuk:\n"
      "- PDF: Format yang umum dan mudah diakses di berbagai perangkat.\n"
      "- ePub: Format yang ideal untuk e-reader.\n"
      "- MOBI: Cocok untuk penggunaan Kindle.";

  String _description = defaultDescription;
  String _format = defaultFormat;
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        title: const Text('Detail Buku'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            label: 'Profil',
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 18, 134, 188),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(widget.image),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Format Buku',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_format),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await _addToHistory();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TableOfContentsScreen(),
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
              onPressed: () async {
                await _addToFavorites();
              },
              child: const Text('Tambah ke Favorit'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Disarankan Untuk Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 18, 134, 188),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recommendedBooks(context),
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

  List<Widget> _recommendedBooks(BuildContext context) {
    final books = [
      {"title": "Selena", "author": "Hamna", "image": "assets/images/selena.png"},
      {"title": "Hello", "author": "Nasywa", "image": "assets/images/hello.png"},
      {"title": "Pulang Pergi", "author": "Angga", "image": "assets/images/pulangpergi.png"},
      {"title": "Laskar Pelangi", "author": "Giee", "image": "assets/images/laskarpelangi.png"},
    ];

    return books
        .map(
          (book) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailUserPage(
                    title: book['title']!,
                    author: book['author']!,
                    image: book['image']!,
                    pages: 200,
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Image.asset(book['image']!, height: 100, width: 70),
                Text(book['title']!, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        )
        .toList();
  }

  Future<void> _addToHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'title': widget.title,
          'author': widget.author,
          'image': widget.image is String ? widget.image : 'default',
          'dateViewed': FieldValue.serverTimestamp(),
        });
        print('Berhasil menambahkan ke riwayat');
      } catch (e) {
        print('Gagal menambahkan ke riwayat: $e');
      }
    } else {
      print('Pengguna tidak login');
    }
  }

  Future<void> _addToFavorites() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .add({
          'title': widget.title,
          'author': widget.author,
          'image': widget.image is String ? widget.image : 'default',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil ditambahkan ke Favorit!')),
        );
      } catch (e) {
        print('Gagal menambahkan ke Favorit: $e');
      }
    } else {
      print('Pengguna tidak login');
    }
  }
}
