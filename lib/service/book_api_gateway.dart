import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_service.dart';

class BookApiGateway {
  final BookService _bookService = BookService();

  // Koleksi Buku Terkenal Project Gutenberg (100% Legal & Full Text)
  static final List<Map<String, dynamic>> _gutenbergCatalog = [
    {
      'id': '1661',
      'title': 'The Adventures of Sherlock Holmes',
      'author': 'Arthur Conan Doyle',
      'category': 'Misteri & Detektif',
      'image': 'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
      'pages': 307,
      'description':
          'Kumpulan kasus misteri paling terkenal yang dipecahkan oleh detektif legendaris Sherlock Holmes bersama Dr. John Watson.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/1661/pg1661.txt',
      'keywords': ['sherlock', 'holmes', 'conan doyle', 'misteri', 'detektif'],
    },
    {
      'id': '84',
      'title': 'Frankenstein; Or, The Modern Prometheus',
      'author': 'Mary Wollstonecraft Shelley',
      'category': 'Sci-Fi & Klasik',
      'image': 'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
      'pages': 280,
      'description':
          'Kisah ilmuwan muda Victor Frankenstein yang berhasil menciptakan makhluk hidup, namun berujung pada bencana dan pertentangan moral.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/84/pg84.txt',
      'keywords': ['frankenstein', 'shelley', 'monster', 'sci-fi', 'klasik'],
    },
    {
      'id': '11',
      'title': "Alice's Adventures in Wonderland",
      'author': 'Lewis Carroll',
      'category': 'Fantasi & Petualangan',
      'image': 'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
      'pages': 160,
      'description':
          'Petualangan Alice ke dunia bawah tanah ajaib yang penuh dengan makhluk aneh, teka-teki, dan keajaiban.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/11/pg11.txt',
      'keywords': ['alice', 'wonderland', 'carroll', 'fantasi', 'kelinci'],
    },
    {
      'id': '345',
      'title': 'Dracula',
      'author': 'Bram Stoker',
      'category': 'Horor & Gotik',
      'image': 'https://www.gutenberg.org/cache/epub/345/pg345.cover.medium.jpg',
      'pages': 418,
      'description':
          'Novel gotik legendaris tentang Count Dracula yang mencoba pindah dari Transylvania ke Inggris untuk mencari mangsa baru.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/345/pg345.txt',
      'keywords': ['dracula', 'stoker', 'vampir', 'horor', 'gotik'],
    },
    {
      'id': '1342',
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'category': 'Romansa & Sastra',
      'image': 'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
      'pages': 380,
      'description':
          'Kisah cinta, status sosial, dan kesalahpahaman antara Elizabeth Bennet yang cerdas dan Mr. Darcy yang arogan namun tulus.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/1342/pg1342.txt',
      'keywords': ['pride', 'prejudice', 'austen', 'darcy', 'romansa'],
    },
    {
      'id': '2701',
      'title': 'Moby Dick; Or, The Whale',
      'author': 'Herman Melville',
      'category': 'Petualangan Maritim',
      'image': 'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
      'pages': 585,
      'description':
          'Kisah pelaut Ishmael dan obsesi Kapten Ahab dalam membalas dendam kepada paus putih raksasa Moby Dick.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/2701/pg2701.txt',
      'keywords': ['moby dick', 'whale', 'melville', 'ahab', 'petualangan'],
    },
    {
      'id': '174',
      'title': 'The Picture of Dorian Gray',
      'author': 'Oscar Wilde',
      'category': 'Drama Psikologis',
      'image': 'https://www.gutenberg.org/cache/epub/174/pg174.cover.medium.jpg',
      'pages': 264,
      'description':
          'Pemuda rupawan Dorian Gray menjual jiwanya agar potret lukisannya yang menua, sementara dirinya tetap muda selamanya.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/174/pg174.txt',
      'keywords': ['dorian gray', 'wilde', 'lukisan', 'filsafat'],
    },
    {
      'id': '2591',
      'title': "Grimms' Fairy Tales",
      'author': 'Jacob Grimm & Wilhelm Grimm',
      'category': 'Dongeng Klasik',
      'image': 'https://www.gutenberg.org/cache/epub/2591/pg2591.cover.medium.jpg',
      'pages': 320,
      'description':
          'Kumpulan dongeng legendaris dunia termasuk Cinderella, Hansel dan Gretel, Putri Salju, dan Rapunzel.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/2591/pg2591.txt',
      'keywords': ['grimm', 'dongeng', 'fairy tales', 'cinderella', 'cerita'],
    },
    {
      'id': '2852',
      'title': 'The Hound of the Baskervilles',
      'author': 'Arthur Conan Doyle',
      'category': 'Misteri',
      'image': 'https://www.gutenberg.org/cache/epub/2852/pg2852.cover.medium.jpg',
      'pages': 256,
      'description':
          'Investigasi Sherlock Holmes atas kutukan anjing iblis raksasa yang meneror keluarga Baskerville di padang rawa Dartmoor.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/2852/pg2852.txt',
      'keywords': ['baskerville', 'hound', 'sherlock', 'anjing', 'kutukan'],
    },
    {
      'id': '160',
      'title': 'The Awakening, and Selected Short Stories',
      'author': 'Kate Chopin',
      'category': 'Sastra Klasik',
      'image': 'https://www.gutenberg.org/cache/epub/160/pg160.cover.medium.jpg',
      'pages': 195,
      'description':
          'Perjalanan emosional Edna Pontellier dalam menemukan kemandirian dan jati dirinya di abad ke-19.',
      'textUrl': 'https://www.gutenberg.org/cache/epub/160/pg160.txt',
      'keywords': ['awakening', 'chopin', 'cerpen', 'sastra'],
    },
  ];

  /// API Gateway Utama:
  /// Urutan Fallback:
  /// 1. Project Gutenberg API
  /// 2. Wikisource API (Indonesia & Dunia)
  /// 3. Open Library (Internet Archive)
  /// 4. Google Books API
  Future<List<BookModel>> searchGateway(String query, {int limit = 10}) async {
    final cleanQuery = query.trim().toLowerCase();

    // ----------------------------------------------------
    // TIER 1: Project Gutenberg
    // ----------------------------------------------------
    debugPrint('API Gateway -> Mencoba Tier 1: Project Gutenberg');
    final gutenbergResults = _searchGutenberg(cleanQuery);
    if (gutenbergResults.isNotEmpty) {
      debugPrint(
          'API Gateway -> Berhasil di Tier 1: ${gutenbergResults.length} buku');
      return gutenbergResults;
    }

    // ----------------------------------------------------
    // TIER 2: Wikisource API (Bahasa Indonesia & Dunia)
    // ----------------------------------------------------
    debugPrint('API Gateway -> Tidak ada di Gutenberg. Pindah ke Tier 2: Wikisource');
    final wikisourceResults = await _searchWikisource(cleanQuery, limit: limit);
    if (wikisourceResults.isNotEmpty) {
      debugPrint(
          'API Gateway -> Berhasil di Tier 2: ${wikisourceResults.length} karya');
      return wikisourceResults;
    }

    // ----------------------------------------------------
    // TIER 3: Open Library (Internet Archive)
    // ----------------------------------------------------
    debugPrint('API Gateway -> Tidak ada di Wikisource. Pindah ke Tier 3: Open Library');
    final openLibraryResults =
        await _bookService.fetchOpenLibraryBooks(cleanQuery, maxResults: limit);
    if (openLibraryResults.isNotEmpty) {
      debugPrint(
          'API Gateway -> Berhasil di Tier 3: ${openLibraryResults.length} buku');
      return openLibraryResults;
    }

    // ----------------------------------------------------
    // TIER 4: Fallback terakhir ke Google Books API
    // ----------------------------------------------------
    debugPrint('API Gateway -> Pindah ke Tier 4: Google Books API');
    return _bookService.fetchGoogleBooks(cleanQuery, maxResults: limit);
  }

  /// Pencarian di Katalog Project Gutenberg
  List<BookModel> _searchGutenberg(String query) {
    if (query.isEmpty) {
      return _gutenbergCatalog.map(_mapGutenbergItem).toList();
    }

    final matches = _gutenbergCatalog.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final author = (item['author'] as String).toLowerCase();
      final keywords = (item['keywords'] as List<String>);
      return title.contains(query) ||
          author.contains(query) ||
          keywords.any((kw) => kw.contains(query));
    }).toList();

    return matches.map(_mapGutenbergItem).toList();
  }

  BookModel _mapGutenbergItem(Map<String, dynamic> item) {
    return BookModel(
      id: 'pg_${item['id']}',
      title: item['title'],
      author: item['author'],
      category: item['category'],
      image: item['image'],
      pages: item['pages'],
      description: item['description'],
      format: 'Teks Lengkap (Public Domain)',
      rating: 4.8,
      textUrl: item['textUrl'],
      source: 'Project Gutenberg',
    );
  }

  /// Pencarian di Wikisource API (Wikimedia Indonesia)
  Future<List<BookModel>> _searchWikisource(String query,
      {int limit = 10}) async {
    try {
      final uri = Uri.parse(
        'https://id.wikisource.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&origin=*',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchList = data['query']?['search'] as List? ?? [];

        if (searchList.isNotEmpty) {
          return searchList.take(limit).map((item) {
            final title = item['title']?.toString() ?? 'Tanpa Judul';
            final snippetRaw = item['snippet']?.toString() ?? '';
            final cleanSnippet =
                snippetRaw.replaceAll(RegExp(r'<[^>]*>'), '');
            final wordcount = item['wordcount'] ?? 300;
            final estimatedPages = (wordcount / 180).ceil().clamp(1, 999);

            return BookModel(
              id: 'ws_${item['pageid'] ?? title.hashCode}',
              title: title,
              author: 'Koleksi Wikimedia Wikisource',
              category: 'Sastra & Dokumen Nusantara',
              image: 'assets/images/cover.png',
              pages: estimatedPages,
              description: cleanSnippet.isNotEmpty
                  ? cleanSnippet
                  : 'Naskah teks lengkap dari repositori Wikisource Indonesia.',
              format: 'Teks Lengkap (Wikisource)',
              rating: 4.7,
              textUrl:
                  'https://id.wikisource.org/w/api.php?action=parse&page=${Uri.encodeComponent(title)}&prop=text&format=json&origin=*',
              source: 'Wikisource (Indonesia & Dunia)',
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error searching Wikisource: $e');
    }
    return [];
  }

  /// Mengambil isi teks buku penuh secara langsung dari sumber API
  Future<String> fetchBookFullText(BookModel book) async {
    if (book.rawContent != null && book.rawContent!.isNotEmpty) {
      return book.rawContent!;
    }

    final url = book.textUrl;
    if (url != null && url.isNotEmpty) {
      // 1. Download dari Project Gutenberg
      if (book.source.contains('Gutenberg') || url.contains('gutenberg.org')) {
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200 && res.body.isNotEmpty) {
            return _cleanGutenbergText(res.body);
          }
        } catch (e) {
          debugPrint('Gutenberg direct fetch error: $e');
        }
      }

      // 2. Download dari Wikisource API
      if (book.source.contains('Wikisource') || url.contains('wikisource.org')) {
        try {
          final res = await http.get(Uri.parse(url));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            final htmlText = data['parse']?['text']?['*']?.toString() ?? '';
            if (htmlText.isNotEmpty) {
              return _cleanWikisourceHtml(htmlText);
            }
          }
        } catch (e) {
          debugPrint('Wikisource fetch error: $e');
        }
      }
    }

    // 3. Fallback jika buku dari Open Library / Google Books
    if (book.description.isNotEmpty) {
      return '${book.title}\n\nOleh: ${book.author}\n\n'
          'Sumber: ${book.source}\n\n'
          '=== SINOPIS & DESKRIPSI LENGKAP ===\n\n'
          '${book.description}\n\n'
          'Buku ini terdaftar di ${book.source}. Anda dapat membaca pratinjau lengkap melalui katalog resminya.';
    }

    return 'Isi buku untuk "${book.title}" sedang disiapkan dari arsip terbuka.';
  }

  /// Membersihkan lisensi & header Gutenberg agar nyaman dibaca
  String _cleanGutenbergText(String raw) {
    String text = raw;

    // Potong header pembuka Gutenberg
    final startMarker = RegExp(r'\*\*\*\s*START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*',
        caseSensitive: false);
    final startMatch = startMarker.firstMatch(text);
    if (startMatch != null) {
      text = text.substring(startMatch.end).trim();
    }

    // Potong footer penutup Gutenberg
    final endMarker = RegExp(
        r'\*\*\*\s*END OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*',
        caseSensitive: false);
    final endMatch = endMarker.firstMatch(text);
    if (endMatch != null) {
      text = text.substring(0, endMatch.start).trim();
    }

    return text.replaceAll('\r\n', '\n');
  }

  /// Membersihkan tag HTML dari Wikisource
  String _cleanWikisourceHtml(String html) {
    String text = html;
    // Hapus script dan style
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), '');
    // Ganti tag paragraf & break dengan newline
    text = text.replaceAll(RegExp(r'</p>|<br\s*/?>'), '\n\n');
    // Hapus tag HTML lainnya
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode entitas HTML umum
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    // Rapikan spasi berlebih
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Membagi teks buku yang sangat panjang menjadi lembar-lembar halaman
  /// [wordsPerPage] Jumlah kata per halaman (default ~180-220 kata agar nyaman di layar)
  static List<String> paginate(String fullText, {int wordsPerPage = 200}) {
    if (fullText.trim().isEmpty) return ['(Halaman ini tidak berisi teks)'];

    final paragraphs = fullText.split(RegExp(r'\n\s*\n'));
    final List<String> pages = [];
    StringBuffer currentPage = StringBuffer();
    int currentWordCount = 0;

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      final wordsInP = trimmed.split(RegExp(r'\s+')).length;

      if (currentWordCount + wordsInP > wordsPerPage &&
          currentPage.isNotEmpty) {
        pages.add(currentPage.toString().trim());
        currentPage.clear();
        currentWordCount = 0;
      }

      currentPage.writeln(trimmed);
      currentPage.writeln();
      currentWordCount += wordsInP;
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage.toString().trim());
    }

    return pages.isEmpty ? [fullText] : pages;
  }
}
