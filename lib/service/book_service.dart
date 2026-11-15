import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ebook/model/book_model.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _booksRef =>
      _firestore.collection('books');

  Future<List<BookModel>> fetchByCategory(String category) async {
    final snapshot =
        await _booksRef.where('category', isEqualTo: category).get();
    return snapshot.docs.map(BookModel.fromFirestore).toList();
  }

  Future<List<BookModel>> fetchRecommended() => fetchByCategory('Recommended');

  Future<List<BookModel>> fetchNewBooks() => fetchByCategory('NewBook');

  Future<List<BookModel>> fetchAll({int? limit}) async {
    Query<Map<String, dynamic>> query = _booksRef;
    if (limit != null) query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs.map(BookModel.fromFirestore).toList();
  }

  Future<BookModel?> fetchById(String id) async {
    final doc = await _booksRef.doc(id).get();
    if (!doc.exists) return null;
    return BookModel.fromFirestore(doc);
  }

  Future<String> addBook(BookModel book) async {
    final doc = await _booksRef.add(book.toMap());
    return doc.id;
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _booksRef.doc(id).update(data);
  }

  Future<void> deleteBook(String id) async {
    await _booksRef.doc(id).delete();
  }

  List<BookModel> search(List<BookModel> books, String query) {
    if (query.trim().isEmpty) return books;
    final lower = query.toLowerCase();
    return books
        .where((b) =>
            b.title.toLowerCase().contains(lower) ||
            b.author.toLowerCase().contains(lower))
        .toList();
  }

  Future<void> addToHistory(BookModel book) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
      'bookId': book.id,
      'title': book.title,
      'author': book.author,
      'image': book.image,
      'pages': book.pages,
      'dateViewed': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addToFavorites(BookModel book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    final data = {
      'bookId': book.id,
      'title': book.title,
      'author': book.author,
      'image': book.image,
      'pages': book.pages,
      'dateAdded': DateTime.now().toIso8601String(),
    };

    if (book.id.isNotEmpty) {
      await collection.doc(book.id).set(data, SetOptions(merge: true));
    } else {
      await collection.add(data);
    }
  }

  /// Mengambil data buku dari Google Books API
  /// [query] Kata kunci pencarian (default 'flutter')
  /// [maxResults] Jumlah buku maksimal yang diambil (default 10)
  /// [apiKey] Opsional API Key dari Google Cloud Console
  Future<List<BookModel>> fetchGoogleBooks(
    String query, {
    int maxResults = 10,
    String? apiKey,
  }) async {
    final cleanQuery = query.trim().isEmpty ? 'flutter' : query.trim();
    try {
      final keyParam =
          (apiKey != null && apiKey.isNotEmpty) ? '&key=$apiKey' : '';
      final uri = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=${Uri.encodeComponent(cleanQuery)}&maxResults=$maxResults$keyParam',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];

        return items.map((item) {
          final id = item['id']?.toString() ?? '';
          final info = item['volumeInfo'] as Map<String, dynamic>? ?? {};

          final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
          String cover = imageLinks?['thumbnail'] ??
              imageLinks?['smallThumbnail'] ??
              'assets/images/cover.png';
          if (cover.startsWith('http://')) {
            cover = cover.replaceFirst('http://', 'https://');
          }

          final authorsList = info['authors'] as List?;
          final author = (authorsList != null && authorsList.isNotEmpty)
              ? authorsList.join(', ')
              : 'Penulis Tidak Diketahui';

          final categories = info['categories'] as List?;
          final category = (categories != null && categories.isNotEmpty)
              ? categories.first.toString()
              : 'General';

          final pages = (info['pageCount'] is int)
              ? info['pageCount'] as int
              : int.tryParse(info['pageCount']?.toString() ?? '0') ?? 0;

          final rating = (info['averageRating'] is num)
              ? (info['averageRating'] as num).toDouble()
              : 4.5;

          return BookModel(
            id: 'gb_$id',
            title: info['title']?.toString() ?? 'Tanpa Judul',
            author: author,
            category: category,
            image: cover,
            pages: pages,
            description: info['description']?.toString() ??
                'Tidak ada sinopsis untuk buku ini.',
            format: 'Google Books / ePub',
            rating: rating,
          );
        }).toList();
      } else {
        debugPrint('Google Books API status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetchGoogleBooks: $e');
    }

    // Fallback otomatis ke Open Library jika limit Google Books habis
    return fetchOpenLibraryBooks(cleanQuery, maxResults: maxResults);
  }

  /// Fallback pencarian buku dari Open Library API (Gratis, tanpa rate limit)
  Future<List<BookModel>> fetchOpenLibraryBooks(
    String query, {
    int maxResults = 10,
  }) async {
    try {
      final uri = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=$maxResults',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List? ?? [];

        return docs.map((doc) {
          final title = doc['title']?.toString() ?? 'Tanpa Judul';
          final authors =
              (doc['author_name'] as List?)?.join(', ') ?? 'Penulis Tidak Diketahui';
          final coverId = doc['cover_i'];
          final cover = (coverId != null)
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : 'assets/images/cover.png';
          final pages = (doc['number_of_pages_median'] is int)
              ? doc['number_of_pages_median'] as int
              : 0;

          return BookModel(
            id: 'ol_${doc['key']?.toString().replaceAll('/works/', '') ?? title.hashCode}',
            title: title,
            author: authors,
            category: 'Open Library',
            image: cover,
            pages: pages,
            description: 'Buku tersedia dari katalog terbuka Open Library.',
            format: 'Online Book',
            rating: 4.5,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetchOpenLibraryBooks: $e');
    }
    return [];
  }
}
