import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String category;
  final String image;
  final int pages;
  final String description;
  final String format;
  final double rating;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.category = 'General',
    this.image = 'assets/images/cover.png',
    this.pages = 0,
    this.description = '',
    this.format = 'PDF, ePub',
    this.rating = 4.5,
  });

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookModel(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? 'Unknown',
      category: data['category'] ?? 'General',
      image: data['image'] ?? 'assets/images/cover.png',
      pages: (data['pages'] is int)
          ? data['pages']
          : int.tryParse(data['pages']?.toString() ?? '0') ?? 0,
      description: data['description'] ?? '',
      format: data['format'] ?? 'PDF, ePub',
      rating: (data['rating'] is num)
          ? (data['rating'] as num).toDouble()
          : double.tryParse(data['rating']?.toString() ?? '4.5') ?? 4.5,
    );
  }

  factory BookModel.fromMap(Map<String, dynamic> data, String id) {
    return BookModel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? 'Unknown',
      category: data['category'] ?? 'General',
      image: data['image'] ?? 'assets/images/cover.png',
      pages: (data['pages'] is int)
          ? data['pages']
          : int.tryParse(data['pages']?.toString() ?? '') ?? 0,
      description: data['description'] ?? '',
      format: data['format'] ?? 'PDF, ePub',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 4.5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'category': category,
      'image': image,
      'pages': pages,
      'description': description,
      'format': format,
      'rating': rating,
    };
  }
}
