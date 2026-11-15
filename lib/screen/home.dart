import 'package:flutter/material.dart';

import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_service.dart';
import 'package:ebook/screen/book_detail.dart';
import 'package:ebook/screen/book_update.dart';
import 'package:ebook/widgets/book_card.dart';
import 'package:ebook/widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  final bool isAdmin;
  final VoidCallback? onOpenSearch;

  const HomePage({
    super.key,
    this.isAdmin = false,
    this.onOpenSearch,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BookService _service = BookService();

  List<BookModel> _books = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat buku: $e';
        _isLoading = false;
      });
    }
  }

  List<String> get _categories {
    final categories = <String>{'Semua'};
    for (final book in _books) {
      if (book.category.trim().isNotEmpty) categories.add(book.category);
    }
    return categories.toList();
  }

  List<BookModel> get _filteredBooks {
    if (_selectedCategory == 'Semua') return _books;
    return _books.where((b) => b.category == _selectedCategory).toList();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'Semua':
        return 'Semua';
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

  Future<void> _openEditor({BookModel? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookPage(
          book: book,
          bookId: book?.id ?? '',
          title: book?.title ?? '',
          author: book?.author ?? '',
          image: book?.image ?? '',
          pages: book?.pages ?? 0,
        ),
      ),
    );

    if (result == true) {
      _loadBooks();
    }
  }

  Future<void> _confirmDelete(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${book.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" berhasil dihapus.')),
      );
      _loadBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus buku: $e')),
      );
    }
  }

  void _openBook(BookModel book) {
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
    ).then((_) => _loadBooks());
  }

  Widget _bookGrid(List<BookModel> books) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 18,
        crossAxisSpacing: 16,
        childAspectRatio: 0.56,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          onTap: () => _openBook(book),
          onEdit: widget.isAdmin ? () => _openEditor(book: book) : null,
          onDelete: widget.isAdmin ? () => _confirmDelete(book) : null,
        );
      },
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Lihat semua'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: scheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ebook',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isAdmin ? 'Mode Admin' : 'Temukan bacaan favoritmu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: widget.isAdmin
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Buku'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBooks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _SearchBarButton(
                    onTap: widget.onOpenSearch,
                  ),
                  const SizedBox(height: 20),
                  const _PromoBanner(),
                  const SizedBox(height: 24),
                  if (_error != null)
                    _ErrorBanner(
                      message: _error!,
                      onRetry: _loadBooks,
                    ),
                  _sectionHeader('Kategori'),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return ChoiceChip(
                          label: Text(_categoryLabel(category)),
                          selected: _selectedCategory == category,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_books.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(
                        title: 'Belum ada buku',
                        message:
                            'Koleksi buku masih kosong. Tambahkan buku pertama untuk mulai membaca.',
                      ),
                    )
                  else if (_selectedCategory == 'Semua')
                    ..._buildDefaultSections()
                  else
                    ..._buildCategorySection(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildDefaultSections() {
    final recommended = _books
        .where((b) => b.category == 'Recommended')
        .toList();
    final newBooks = _books.where((b) => b.category == 'NewBook').toList();
    final others = _books
        .where((b) => b.category != 'Recommended' && b.category != 'NewBook')
        .toList();

    final widgets = <Widget>[];

    if (recommended.isNotEmpty) {
      widgets.add(_sectionHeader('Rekomendasi'));
      widgets.add(const SizedBox(height: 12));
      widgets.add(_bookGrid(recommended));
      widgets.add(const SizedBox(height: 24));
    }

    if (newBooks.isNotEmpty) {
      widgets.add(_sectionHeader('Buku Baru'));
      widgets.add(const SizedBox(height: 12));
      widgets.add(_bookGrid(newBooks));
      widgets.add(const SizedBox(height: 24));
    }

    if (others.isNotEmpty) {
      widgets.add(_sectionHeader('Koleksi Lainnya'));
      widgets.add(const SizedBox(height: 12));
      widgets.add(_bookGrid(others));
    }

    if (recommended.isEmpty && newBooks.isEmpty && others.isEmpty) {
      widgets.add(const EmptyState(
        title: 'Belum ada buku',
        message: 'Tambahkan buku untuk mulai mengisi koleksi.',
      ));
    }

    return widgets;
  }

  List<Widget> _buildCategorySection() {
    final books = _filteredBooks;
    if (books.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: EmptyState(
            title: 'Kategori kosong',
            message:
                'Belum ada buku pada kategori ${_categoryLabel(_selectedCategory)}.',
          ),
        ),
      ];
    }

    return [
      _sectionHeader(_categoryLabel(_selectedCategory)),
      const SizedBox(height: 12),
      _bookGrid(books),
    ];
  }
}

class _SearchBarButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SearchBarButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Cari judul atau penulis...',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatefulWidget {
  const _PromoBanner();

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  int _current = 0;

  final List<_PromoItem> _items = const [
    _PromoItem(
      title: 'Baca di mana saja',
      subtitle: 'Bawa perpustakaanmu dalam genggaman.',
      icon: Icons.auto_stories_rounded,
    ),
    _PromoItem(
      title: 'Koleksi pilihan',
      subtitle: 'Temukan buku rekomendasi terbaik setiap hari.',
      icon: Icons.local_library_rounded,
    ),
    _PromoItem(
      title: 'Jelajahi dunia baru',
      subtitle: 'Ribuan cerita menanti untuk kamu baca.',
      icon: Icons.public_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) {
              final item = _items[index];
              final gradients = [
                [scheme.primary, scheme.tertiary],
                [scheme.tertiary, scheme.secondary],
                [scheme.secondary, scheme.primary],
              ];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradients[index % gradients.length],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: scheme.onPrimary.withOpacity(0.85),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        item.icon,
                        size: 64,
                        color: scheme.onPrimary.withOpacity(0.85),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (index) {
            final active = index == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : scheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
