import 'package:flutter/material.dart';

import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_service.dart';
import 'package:ebook/widgets/book_cover.dart';

class UpdateBookPage extends StatefulWidget {
  final String title;
  final String author;
  final String image;
  final String bookId;
  final int pages;
  final BookModel? book;

  const UpdateBookPage({
    super.key,
    this.title = '',
    this.author = '',
    this.image = '',
    this.bookId = '',
    this.pages = 0,
    this.book,
  });

  @override
  State<UpdateBookPage> createState() => _UpdateBookPageState();
}

class _UpdateBookPageState extends State<UpdateBookPage> {
  final BookService _service = BookService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _pagesController;
  late final TextEditingController _imageController;
  late final TextEditingController _descriptionController;

  String _selectedCategory = 'Recommended';
  bool _isSaving = false;

  bool get _isEditing => widget.bookId.isNotEmpty || widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;

    _titleController =
        TextEditingController(text: book?.title ?? widget.title);
    _authorController =
        TextEditingController(text: book?.author ?? widget.author);
    final initialPages = book?.pages ?? widget.pages;
    _pagesController = TextEditingController(
      text: initialPages > 0 ? initialPages.toString() : '',
    );
    _imageController = TextEditingController(text: book?.image ?? widget.image);
    _descriptionController =
        TextEditingController(text: book?.description ?? '');

    if (book != null && book.category.isNotEmpty) {
      _selectedCategory = book.category;
    }

    _imageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final pages = int.tryParse(_pagesController.text.trim()) ?? 0;
    final existing = widget.book;

    final book = BookModel(
      id: existing?.id ?? widget.bookId,
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      category: _selectedCategory,
      image: _imageController.text.trim().isEmpty
          ? 'assets/images/cover.png'
          : _imageController.text.trim(),
      pages: pages,
      description: _descriptionController.text.trim(),
      format: existing?.format ?? 'PDF, ePub',
      rating: existing?.rating ?? 4.5,
    );

    try {
      if (_isEditing) {
        await _service.updateBook(book.id, book.toMap());
      } else {
        await _service.addBook(book);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan buku: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categoryOptions = <String>{
      'Recommended',
      'NewBook',
      'General',
      if (_selectedCategory.trim().isNotEmpty) _selectedCategory,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Buku' : 'Tambah Buku'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: BookCover(
                source: _imageController.text.trim(),
                width: 110,
                height: 160,
                borderRadius: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Judul Buku',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Judul wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _authorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Penulis',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Penulis wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pagesController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Jumlah Halaman',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              validator: (value) {
                final pages = int.tryParse(value?.trim() ?? '');
                if (pages == null || pages <= 0) {
                  return 'Masukkan jumlah halaman yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: categoryOptions
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_categoryLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Gambar Cover',
                hintText: 'https://... atau assets/images/...',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveBook,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Buku'),
            ),
            const SizedBox(height: 12),
            Text(
              'Gunakan URL gambar (http/https) atau path asset lokal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'Recommended':
        return 'Rekomendasi';
      case 'NewBook':
        return 'Buku Baru';
      case 'General':
        return 'Umum';
      default:
        return category;
    }
  }
}
