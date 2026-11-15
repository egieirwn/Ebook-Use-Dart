import 'package:flutter/material.dart';

import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_service.dart';
import 'package:ebook/screen/book_detail.dart';
import 'package:ebook/widgets/book_card.dart';
import 'package:ebook/widgets/empty_state.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final BookService _service = BookService();
  final TextEditingController _searchController =
      TextEditingController(text: 'flutter');

  List<BookModel> _onlineBooks = [];
  List<BookModel> _localBooks = [];
  bool _isLoading = true;
  String? _error;
  String _activeQuery = 'flutter';
  bool _isOnlineSource = true; // true = Google Books API, false = Firestore

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _searchOnlineBooks('flutter'),
      _loadLocalBooks(),
    ]);
  }

  Future<void> _searchOnlineBooks(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _activeQuery = query.trim().isEmpty ? 'flutter' : query.trim();
    });

    try {
      final books = await _service.fetchGoogleBooks(_activeQuery, maxResults: 10);
      if (!mounted) return;
      setState(() {
        _onlineBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat buku dari Google Books API: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalBooks() async {
    try {
      final books = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _localBooks = books;
      });
    } catch (_) {
      // Abaikan error background local fetch
    }
  }

  List<BookModel> get _currentResults {
    if (_isOnlineSource) {
      return _onlineBooks;
    } else {
      final q = _searchController.text.trim();
      return _service.search(_localBooks, q);
    }
  }

  void _onSearchSubmitted(String value) {
    if (_isOnlineSource) {
      _searchOnlineBooks(value);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final results = _currentResults;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajahi Buku'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (_isOnlineSource) {
                _searchOnlineBooks(_searchController.text);
              } else {
                _loadLocalBooks();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: _isOnlineSource
                    ? 'Cari Google Books API (cth: flutter, python, novel)...'
                    : 'Cari di koleksi tersimpan...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          if (!_isOnlineSource) setState(() {});
                        },
                      ),
                    IconButton(
                      tooltip: 'Cari',
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () =>
                          _onSearchSubmitted(_searchController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Source Selector Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Google Books API'),
                    ],
                  ),
                  selected: _isOnlineSource,
                  onSelected: (selected) {
                    if (selected && !_isOnlineSource) {
                      setState(() => _isOnlineSource = true);
                      if (_onlineBooks.isEmpty) {
                        _searchOnlineBooks(_searchController.text);
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storage_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Koleksi Tersimpan'),
                    ],
                  ),
                  selected: !_isOnlineSource,
                  onSelected: (selected) {
                    if (selected && _isOnlineSource) {
                      setState(() => _isOnlineSource = false);
                      _loadLocalBooks();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Content Area
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Menghubungi Google Books API...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Tidak dapat memuat buku',
                message: _error!,
              ),
            )
          else if (results.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Tidak ditemukan',
                message: _isOnlineSource
                    ? 'Tidak ada buku ditemukan untuk kata kunci "${_searchController.text}". Coba kata kunci lain.'
                    : 'Koleksi tersimpan masih kosong atau kata kunci tidak cocok.',
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.56,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final book = results[index];
                  return BookCard(
                    book: book,
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
                  );
                },
              ),
            ),

          // Footer Info
          if (!_isLoading && _error == null && results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _isOnlineSource
                    ? '${results.length} buku dari Google Books API (query: "$_activeQuery")'
                    : '${results.length} buku di koleksi tersimpan',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
