import 'package:ebook/screen/book_detail_user.dart'; // Pastikan path benar
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHomePage extends StatefulWidget {
  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> recommendedBooks = [];
  List<Map<String, dynamic>> newBooks = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _searchController.addListener(() {
      _searchBooks(_searchController.text);
    });
  }

  Future<void> _fetchBooks() async {
    try {
      setState(() => _isLoading = true);

      // Fetch recommended books
      var recommendedSnapshot = await _firestore
          .collection('books')
          .where('category', isEqualTo: 'Recommended')
          .get();

      // Fetch new books
      var newBooksSnapshot = await _firestore
          .collection('books')
          .where('category', isEqualTo: 'NewBook')
          .get();

      setState(() {
        recommendedBooks = recommendedSnapshot.docs.map((doc) {
          var data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'author': data['author'],
            'image': data['image'] ?? 'assets/images/default.png',
            'pages': data['pages'] ?? 0,
          };
        }).toList();

        newBooks = newBooksSnapshot.docs.map((doc) {
          var data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'author': data['author'],
            'image': data['image'] ?? 'assets/images/default.png',
            'pages': data['pages'] ?? 0,
          };
        }).toList();

        searchResults = [...recommendedBooks, ...newBooks];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching books: $e');
      setState(() => _isLoading = false);
    }
  }

  void _searchBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        searchResults = [];
      } else {
        searchResults = [
          ...recommendedBooks.where((book) =>
              book['title'].toLowerCase().contains(query.toLowerCase())),
          ...newBooks.where((book) =>
              book['title'].toLowerCase().contains(query.toLowerCase())),
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ebook',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 600,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/Banner.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Recommended Books
                  if (_searchController.text.isEmpty)
                    const Text(
                      'Rekomendasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  _buildBookGrid(_searchController.text.isEmpty
                      ? recommendedBooks // Display only recommended books if no search
                      : searchResults // Otherwise, display search results
                      ),
                  const SizedBox(height: 20),
                  // New Books
                  const Text(
                    'Buku Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  _buildBookGrid(newBooks), // Always show new books
                ],
              ),
            ),
    );
  }

  Widget _buildBookGrid(List<Map<String, dynamic>> books) {
    if (books.isEmpty) {
      return const Text('Tidak ada buku');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailUserPage(
                  title: books[index]['title'],
                  author: books[index]['author'],
                  image: books[index]['image'],
                  pages: books[index]['pages'],
                ),
              ),
            );
          },
          child: Column(
            children: [
              Image.network(
                books[index]['image'],
                height: 150,
                width: 100,
                fit: BoxFit.cover,
              ),
              Text(
                books[index]['title'],
                textAlign: TextAlign.center,
              ),
              Text(
                books[index]['author'],
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              Text(
                'Pages: ${books[index]['pages']}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
