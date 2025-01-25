import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateBookPage extends StatefulWidget {
  final String title;
  final String author;
  final String image;
  final String bookId;
  final int pages;

  UpdateBookPage({
    required this.title,
    required this.author,
    required this.image,
    required this.bookId,
    required this.pages,
  });

  @override
  _UpdateBookPageState createState() => _UpdateBookPageState();
}

class _UpdateBookPageState extends State<UpdateBookPage> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _pagesController;
  String _selectedCategory = 'Recommended';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _authorController = TextEditingController(text: widget.author);
    _pagesController = TextEditingController(text: widget.pages.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  void _saveBook() async {
    if (_titleController.text.isNotEmpty &&
        _authorController.text.isNotEmpty &&
        _pagesController.text.isNotEmpty) {
      try {
        int pages = int.parse(_pagesController.text);
        String imageUrl =
            widget.image.isNotEmpty ? widget.image : 'assets/images/other.png';

        if (widget.bookId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('books')
              .doc(widget.bookId)
              .update({
            'title': _titleController.text,
            'author': _authorController.text,
            'pages': pages,
            'image': imageUrl,
            'category': _selectedCategory,
          });
        } else {
          await FirebaseFirestore.instance.collection('books').add({
            'title': _titleController.text,
            'author': _authorController.text,
            'pages': pages,
            'image': imageUrl,
            'category': _selectedCategory,
          });
        }

        Navigator.pop(context, true);
      } catch (e) {
        print('Error saving book: $e');
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Buku')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 10), // Jarak antara title dan author

            // Author Input
            TextField(
              controller: _authorController,
              decoration: InputDecoration(labelText: 'Author'),
            ),
            SizedBox(height: 10),

            TextField(
              controller: _pagesController,
              decoration: InputDecoration(labelText: 'Pages'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['Recommended', 'NewBook']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveBook,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
