import 'package:flutter/material.dart';

import 'package:ebook/model/book_model.dart';
import 'package:ebook/screen/book_detail.dart';

class BookDetailUserPage extends StatelessWidget {
  final String title;
  final String author;
  final dynamic image;
  final int pages;
  final BookModel? bookModel;
  final String bookId;

  const BookDetailUserPage({
    super.key,
    required this.title,
    required this.author,
    required this.image,
    required this.pages,
    this.bookModel,
    this.bookId = '',
  });

  @override
  Widget build(BuildContext context) {
    return BookDetailPage(
      title: title,
      author: author,
      image: image,
      pages: pages,
      bookModel: bookModel,
      bookId: bookId,
    );
  }
}
