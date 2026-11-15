import 'package:flutter/material.dart';
import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_api_gateway.dart';

enum ReaderTheme {
  light,
  sepia,
  dark,
}

class DetailBukuPage extends StatefulWidget {
  final BookModel? book;
  final String? title;
  final String? author;

  const DetailBukuPage({
    super.key,
    this.book,
    this.title,
    this.author,
  });

  @override
  State<DetailBukuPage> createState() => _DetailBukuPageState();
}

class _DetailBukuPageState extends State<DetailBukuPage> {
  final BookApiGateway _gateway = BookApiGateway();
  final PageController _pageController = PageController();

  List<String> _pages = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPageIndex = 0;

  // Pengaturan Reader
  double _fontSize = 16.0;
  ReaderTheme _readerTheme = ReaderTheme.sepia;

  String get _bookTitle =>
      widget.book?.title ?? widget.title ?? 'Membaca Buku';
  String get _bookAuthor =>
      widget.book?.author ?? widget.author ?? 'Penulis';
  String get _bookSource =>
      widget.book?.source ?? 'Arsip Terbuka';

  @override
  void initState() {
    super.initState();
    _loadBookContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBookContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final book = widget.book ??
          BookModel(
            id: 'temp',
            title: _bookTitle,
            author: _bookAuthor,
          );

      final fullText = await _gateway.fetchBookFullText(book);
      final paginated = BookApiGateway.paginate(fullText, wordsPerPage: 190);

      if (!mounted) return;
      setState(() {
        _pages = paginated;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat isi buku: $e';
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Color _getBackgroundColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFFFAFAFA);
      case ReaderTheme.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderTheme.dark:
        return const Color(0xFF1E1E1E);
    }
  }

  Color _getTextColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return const Color(0xFF202020);
      case ReaderTheme.sepia:
        return const Color(0xFF4A3B2C);
      case ReaderTheme.dark:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getCardColor() {
    switch (_readerTheme) {
      case ReaderTheme.light:
        return Colors.white;
      case ReaderTheme.sepia:
        return const Color(0xFFF6E7C8);
      case ReaderTheme.dark:
        return const Color(0xFF282828);
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pengaturan Membaca',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ukuran Huruf',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.text_decrease_rounded),
                          onPressed: _fontSize > 13
                              ? () {
                                  setState(() => _fontSize -= 1.5);
                                  setModalState(() {});
                                }
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 13,
                            max: 24,
                            divisions: 8,
                            label: '${_fontSize.toInt()} px',
                            onChanged: (val) {
                              setState(() => _fontSize = val);
                              setModalState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_increase_rounded),
                          onPressed: _fontSize < 24
                              ? () {
                                  setState(() => _fontSize += 1.5);
                                  setModalState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Tema Kertas Baca',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildThemeOption(
                          label: 'Putih',
                          bg: const Color(0xFFFFFFFF),
                          border: Colors.grey.shade400,
                          isSelected: _readerTheme == ReaderTheme.light,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.light);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          label: 'Sepia (Hangat)',
                          bg: const Color(0xFFFBF0D9),
                          border: const Color(0xFFC4A47C),
                          isSelected: _readerTheme == ReaderTheme.sepia,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.sepia);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildThemeOption(
                          label: 'Malam (Gelap)',
                          bg: const Color(0xFF1E1E1E),
                          border: Colors.grey.shade700,
                          isSelected: _readerTheme == ReaderTheme.dark,
                          textColor: Colors.white,
                          onTap: () {
                            setState(() => _readerTheme = ReaderTheme.dark);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String label,
    required Color bg,
    required Color border,
    required bool isSelected,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : border,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final cardColor = _getCardColor();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _bookTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              '$_bookAuthor • $_bookSource',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Tampilan',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: _buildBody(bgColor, textColor, cardColor),
      bottomNavigationBar: _pages.isNotEmpty && !_isLoading
          ? _buildBottomBar(bgColor, textColor)
          : null,
    );
  }

  Widget _buildBody(Color bgColor, Color textColor, Color cardColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Mengunduh lembaran buku dari $_bookSource...',
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadBookContent,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Reader Content Area
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
            },
            itemBuilder: (context, index) {
              final pageText = _pages[index];

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      pageText,
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        color: textColor,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Color bgColor, Color textColor) {
    final progress = _pages.isEmpty
        ? 0.0
        : (_currentPageIndex + 1) / _pages.length;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: textColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentPageIndex > 0 ? _prevPage : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Sebelumnya'),
                ),
                Text(
                  'Halaman ${_currentPageIndex + 1} dari ${_pages.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _currentPageIndex < _pages.length - 1 ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Selanjutnya'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Backward compatibility class
class TableOfContentsScreen extends StatelessWidget {
  const TableOfContentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DetailBukuPage();
  }
}

class ChapterContentScreen extends StatelessWidget {
  final String chapterTitle;
  final int totalPages;

  const ChapterContentScreen({
    super.key,
    required this.chapterTitle,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return DetailBukuPage(title: chapterTitle);
  }
}
