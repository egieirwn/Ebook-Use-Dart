import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ebook/model/book_model.dart';
import 'package:ebook/provider/auth_provider.dart';
import 'package:ebook/service/book_service.dart';
import 'package:ebook/screen/baca_buku.dart';
import 'package:ebook/screen/book_update.dart';
import 'package:ebook/widgets/book_cover.dart';

class BookDetailPage extends StatefulWidget {
  final String? title;
  final String? author;
  final dynamic image;
  final int? pages;
  final Map<String, dynamic>? book;
  final String bookId;
  final BookModel? bookModel;

  const BookDetailPage({
    super.key,
    this.title,
    this.author,
    this.image,
    this.pages,
    this.book,
    this.bookId = '',
    this.bookModel,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final BookService _service = BookService();

  BookModel? _book;
  dynamic _rawImage;
  List<BookModel> _suggestions = [];
  bool _isRefreshing = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _rawImage = widget.image;
    _book = _initialBook();
    _refresh();
  }

  BookModel? _initialBook() {
    if (widget.bookModel != null) return widget.bookModel;
    if (widget.book != null) {
      return BookModel.fromMap(widget.book!, widget.bookId);
    }
    final hasInfo = (widget.title ?? '').isNotEmpty ||
        (widget.author ?? '').isNotEmpty ||
        widget.image != null;
    if (!hasInfo) return null;

    return BookModel(
      id: widget.bookId,
      title: widget.title ?? '',
      author: widget.author ?? '',
      image: widget.image is String ? widget.image : 'assets/images/cover.png',
      pages: widget.pages ?? 0,
    );
  }

  Future<void> _refresh() async {
    final id = widget.bookId.isNotEmpty ? widget.bookId : (_book?.id ?? '');

    try {
      if (id.isNotEmpty) {
        final fetched = await _service.fetchById(id);
        if (fetched != null && mounted) {
          setState(() {
            _book = fetched;
            if (_rawImage == null) _rawImage = fetched.image;
          });
        }
      }

      final all = await _service.fetchAll(limit: 16);
      if (!mounted) return;
      setState(() {
        _suggestions =
            all.where((b) => b.id != id).take(8).toList(growable: false);
      });
    } catch (_) {
      // Abaikan kegagalan refresh; data awal tetap ditampilkan.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _readBook() async {
    if (_book != null) {
      try {
        await _service.addToHistory(_book!);
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailBukuPage()),
    );
  }

  Future<void> _addToFavorites() async {
    if (_book == null) return;

    try {
      await _service.addToFavorites(_book!);
      if (!mounted) return;
      setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku ditambahkan ke favorit.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan ke favorit: $e')),
      );
    }
  }

  Future<void> _openEditor() async {
    final book = _book;
    if (book == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookPage(
          book: book,
          bookId: book.id,
          title: book.title,
          author: book.author,
          image: book.image,
          pages: book.pages,
        ),
      ),
    );

    if (result == true) {
      setState(() => _isRefreshing = true);
      await _refresh();
    }
  }

  Future<void> _deleteBook() async {
    final book = _book;
    if (book == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Hapus "${book.title}" dari koleksi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteBook(book.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus buku: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final book = _book;
    final title = book?.title ?? widget.title ?? 'Detail Buku';
    final author = book?.author ?? widget.author ?? '';
    final pages = book?.pages ?? widget.pages ?? 0;
    final description = book?.description ?? '';
    final format = book?.format ?? 'PDF, ePub';
    final rating = book?.rating ?? 4.5;
    final category = book?.category ?? '';
    final imageSource = _rawImage ?? book?.image;
    final categoryLabel = _categoryLabel(category);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              if (isAdmin && book != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _openEditor();
                    if (value == 'delete') _deleteBook();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  BookCover(
                    source: imageSource,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                          scheme.surface,
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isRefreshing)
                    LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (categoryLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            categoryLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      const Spacer(),
                      const Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          author.isEmpty ? 'Penulis tidak diketahui' : author,
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoPill(
                        icon: Icons.menu_book_outlined,
                        label: '$pages halaman',
                      ),
                      const SizedBox(width: 10),
                      _InfoPill(
                        icon: Icons.description_outlined,
                        label: format,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _readBook,
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('Baca Buku'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.outlined(
                        tooltip: 'Tambah ke favorit',
                        onPressed: _isFavorite ? null : _addToFavorites,
                        icon: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin && book != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openEditor,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Buku'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _deleteBook,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Hapus'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  const _SectionTitle('Deskripsi'),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? 'Belum ada deskripsi untuk buku ini.'
                        : description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: description.isEmpty
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Format Buku'),
                  const SizedBox(height: 8),
                  Text(
                    format,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle('Kamu mungkin suka'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 214,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return _SuggestionCard(book: suggestion);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final BookModel book;

  const _SuggestionCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailPage(
                bookModel: book,
                bookId: book.id,
                title: book.title,
                author: book.author,
                image: book.image,
                pages: book.pages,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              source: book.image,
              width: 104,
              height: 152,
              borderRadius: 12,
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
