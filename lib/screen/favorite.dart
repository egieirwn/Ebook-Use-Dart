import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ebook/screen/book_detail.dart';
import 'package:ebook/widgets/book_cover.dart';
import 'package:ebook/widgets/empty_state.dart';

class FavoriteBookPage extends StatefulWidget {
  const FavoriteBookPage({super.key});

  @override
  State<FavoriteBookPage> createState() => _FavoriteBookPageState();
}

class FavoriteBooksPage extends StatelessWidget {
  const FavoriteBooksPage({super.key});

  @override
  Widget build(BuildContext context) => const FavoriteBookPage();
}

class _FavoriteBookPageState extends State<FavoriteBookPage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _favorites = [];
        _isLoading = false;
        _error = 'Silakan masuk untuk melihat favoritmu.';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();

      final items = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      items.sort((a, b) {
        final da = a['dateAdded']?.toString() ?? '';
        final db = b['dateAdded']?.toString() ?? '';
        return db.compareTo(da);
      });

      if (!mounted) return;
      setState(() {
        _favorites = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat favorit: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(Map<String, dynamic> item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari Favorit'),
        content: Text(
          'Hapus "${item['title'] ?? 'buku ini'}" dari daftar favorit?',
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(item['id'])
          .delete();

      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((e) => e['id'] == item['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item['title'] ?? 'Buku'}" dihapus dari favorit.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  void _openBook(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          title: item['title']?.toString() ?? '',
          author: item['author']?.toString() ?? '',
          image: item['image'],
          pages: (item['pages'] as int?) ?? 0,
          bookId: item['bookId']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit Saya'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Tidak dapat memuat favorit',
                  message: _error!,
                )
              : _favorites.isEmpty
                  ? const EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Belum ada favorit',
                      message:
                          'Simpan buku yang kamu suka agar mudah ditemukan kembali.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _favorites[index];
                          return _FavoriteTile(
                            item: item,
                            onTap: () => _openBook(item),
                            onRemove: () => _removeFavorite(item),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = item['title']?.toString() ?? 'Tanpa judul';
    final author = item['author']?.toString() ?? 'Penulis tidak diketahui';
    final pages = item['pages']?.toString() ?? '-';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(
                source: item['image'],
                width: 56,
                height: 82,
                borderRadius: 8,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pages halaman',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus dari favorit',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
