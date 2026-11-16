import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ebook/model/book_model.dart';
import 'package:ebook/service/book_service.dart';

class BookApiGateway {
  final BookService _bookService = BookService();

  // ─── Katalog Gutenberg (fallback jika Gutendex gagal) ───────────────────────
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

  // ─── API GATEWAY UTAMA ───────────────────────────────────────────────────────
  /// Urutan: Gutendex (live search) → Gutenberg Catalog → Wikisource → Open Library → Google Books
  Future<List<BookModel>> searchGateway(String query, {int limit = 10}) async {
    final cleanQuery = query.trim().toLowerCase();

    // TIER 1a: Gutendex — live search Project Gutenberg (CORS-friendly)
    debugPrint('API Gateway → Mencoba Tier 1a: Gutendex (live Gutenberg)');
    final gutendexResults = await _searchGutendex(cleanQuery, limit: limit);
    if (gutendexResults.isNotEmpty) {
      debugPrint('API Gateway → Berhasil Tier 1a: ${gutendexResults.length} buku');
      return gutendexResults;
    }

    // TIER 1b: Gutenberg hardcoded catalog (fallback)
    debugPrint('API Gateway → Tier 1b: Katalog Gutenberg lokal');
    final gutenbergResults = _searchGutenberg(cleanQuery);
    if (gutenbergResults.isNotEmpty) {
      debugPrint('API Gateway → Berhasil Tier 1b: ${gutenbergResults.length} buku');
      return gutenbergResults;
    }

    // TIER 2: Wikisource API (Indonesia & Dunia) — hanya jika wordcount cukup
    debugPrint('API Gateway → Tier 2: Wikisource');
    final wikisourceResults = await _searchWikisource(cleanQuery, limit: limit);
    if (wikisourceResults.isNotEmpty) {
      debugPrint('API Gateway → Berhasil Tier 2: ${wikisourceResults.length} karya');
      return wikisourceResults;
    }

    // TIER 3: Open Library
    debugPrint('API Gateway → Tier 3: Open Library');
    final openLibraryResults =
        await _bookService.fetchOpenLibraryBooks(cleanQuery, maxResults: limit);
    if (openLibraryResults.isNotEmpty) {
      debugPrint('API Gateway → Berhasil Tier 3: ${openLibraryResults.length} buku');
      return openLibraryResults;
    }

    // TIER 4: Google Books
    debugPrint('API Gateway → Tier 4: Google Books API');
    return _bookService.fetchGoogleBooks(cleanQuery, maxResults: limit);
  }

  // ─── TIER 1a: Gutendex (Project Gutenberg live search) ───────────────────────
  Future<List<BookModel>> _searchGutendex(String query, {int limit = 10}) async {
    try {
      final uri = Uri.parse(
        'https://gutendex.com/books/?search=${Uri.encodeComponent(query)}&languages=en&mime_type=text%2Fplain',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final results = data['results'] as List? ?? [];
        final books = <BookModel>[];
        for (final item in results.take(limit)) {
          final formats = item['formats'] as Map<String, dynamic>? ?? {};
          // Pilih URL teks: utf-8 → us-ascii → text/plain
          String? textUrl = formats['text/plain; charset=utf-8'] as String? ??
              formats['text/plain; charset=us-ascii'] as String? ??
              formats['text/plain'] as String?;
          if (textUrl == null) continue;

          // Hindari file .zip
          if (textUrl.endsWith('.zip')) continue;

          final id = item['id']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Tanpa Judul';
          final authors = item['authors'] as List? ?? [];
          final author = authors.isNotEmpty
              ? (authors.first['name']?.toString() ?? 'Unknown')
              : 'Unknown';

          // Gunakan cover cache Gutenberg jika ada
          final coverUrl = formats['image/jpeg'] as String? ??
              'https://www.gutenberg.org/cache/epub/$id/pg$id.cover.medium.jpg';

          books.add(BookModel(
            id: 'gx_$id',
            title: title,
            author: author,
            category: 'Klasik & Sastra Dunia',
            image: coverUrl,
            pages: 200,
            description: 'Karya klasik $author — tersedia penuh di Project Gutenberg (domain publik).',
            format: 'Teks Lengkap (Project Gutenberg)',
            rating: 4.8,
            textUrl: textUrl,
            source: 'Project Gutenberg',
          ));
        }
        return books;
      }
    } catch (e) {
      debugPrint('Gutendex error: $e');
    }
    return [];
  }

  // ─── TIER 1b: Katalog Gutenberg lokal ────────────────────────────────────────
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

  // ─── TIER 2: Wikisource (hanya buku dengan wordcount ≥ 500) ─────────────────
  Future<List<BookModel>> _searchWikisource(String query, {int limit = 10}) async {
    try {
      final uri = Uri.parse(
        'https://id.wikisource.org/w/api.php'
        '?action=query&list=search'
        '&srsearch=${Uri.encodeComponent(query)}'
        '&srprop=size|wordcount|snippet'
        '&srlimit=${limit * 2}' // ambil lebih banyak agar bisa difilter
        '&format=json&origin=*',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchList = data['query']?['search'] as List? ?? [];

        final books = <BookModel>[];
        for (final item in searchList) {
          final wordcount = (item['wordcount'] as num?)?.toInt() ?? 0;
          // Filter: skip buku dengan konten sangat sedikit (kemungkinan scan/TOC)
          if (wordcount < 500) continue;

          final title = item['title']?.toString() ?? 'Tanpa Judul';
          // Skip sub-halaman (kemungkinan sub-bab yang tidak punya teks sendiri)
          if (title.contains('/')) continue;

          final snippetRaw = item['snippet']?.toString() ?? '';
          final cleanSnippet = snippetRaw.replaceAll(RegExp(r'<[^>]*>'), '');
          final estimatedPages = (wordcount / 180).ceil().clamp(1, 999);

          books.add(BookModel(
            id: 'ws_${item['pageid'] ?? title.hashCode}',
            title: title,
            author: 'Koleksi Wikisource Indonesia',
            category: 'Sastra & Dokumen Nusantara',
            image: 'assets/images/cover.png',
            pages: estimatedPages,
            description: cleanSnippet.isNotEmpty
                ? cleanSnippet
                : 'Naskah teks lengkap dari repositori Wikisource Indonesia.',
            format: 'Teks Lengkap (Wikisource)',
            rating: 4.5,
            textUrl:
                'https://id.wikisource.org/w/api.php?action=parse&page=${Uri.encodeComponent(title)}&prop=wikitext&format=json&origin=*',
            source: 'Wikisource (Indonesia & Dunia)',
          ));

          if (books.length >= limit) break;
        }
        return books;
      }
    } catch (e) {
      debugPrint('Error searching Wikisource: $e');
    }
    return [];
  }

  // ─── FETCH FULL TEXT ─────────────────────────────────────────────────────────
  Future<String> fetchBookFullText(BookModel book) async {
    if (book.rawContent != null && book.rawContent!.isNotEmpty) {
      return book.rawContent!;
    }

    final url = book.textUrl;
    if (url == null || url.isEmpty) {
      return _noContentMessage(book.title);
    }

    // 1. Project Gutenberg — langsung ambil .txt
    if (book.source.contains('Gutenberg') || url.contains('gutenberg.org')) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 && res.body.length > 500) {
          final cleaned = _cleanGutenbergText(res.body);
          if (cleaned.length > 300) return cleaned;
        }
      } catch (e) {
        debugPrint('Gutenberg fetch error: $e');
      }
      return _noContentMessage(book.title,
          reason: 'Koneksi ke Project Gutenberg gagal atau diblokir browser.\n'
              'Coba buka aplikasi di perangkat mobile (Android/iOS).');
    }

    // 2. Wikisource — ambil wikitext (plain text format), bukan HTML
    if (book.source.contains('Wikisource') || url.contains('wikisource.org')) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          // Gunakan wikitext (teks biasa dengan markup wiki) — lebih bersih dari HTML
          final wikitext = data['parse']?['wikitext']?['*']?.toString() ?? '';
          if (wikitext.isNotEmpty) {
            final cleaned = _cleanWikitext(wikitext);
            if (cleaned.length > 300) return cleaned;
          }
        }
      } catch (e) {
        debugPrint('Wikisource fetch error: $e');
      }
      return _noContentMessage(book.title,
          reason: 'Buku ini kemungkinan berasal dari arsip pemindaian (scan) '
              'yang tidak memiliki teks terbaca di Wikisource.');
    }

    // 3. Fallback — tampilkan sinopsis
    if (book.description.isNotEmpty && book.description.length > 100) {
      return '${book.title}\n\nOleh: ${book.author}\n\n'
          '=== SINOPSIS ===\n\n${book.description}\n\n'
          '— Sumber: ${book.source}';
    }

    return _noContentMessage(book.title);
  }

  // ─── BERSIHKAN TEKS GUTENBERG ─────────────────────────────────────────────────
  String _cleanGutenbergText(String raw) {
    String text = raw;
    // Potong header pembuka
    final startMarker = RegExp(
        r'\*\*\*\s*START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*',
        caseSensitive: false,
        dotAll: true);
    final startMatch = startMarker.firstMatch(text);
    if (startMatch != null) text = text.substring(startMatch.end).trim();

    // Potong footer penutup
    final endMarker = RegExp(
        r'\*\*\*\s*END OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*',
        caseSensitive: false,
        dotAll: true);
    final endMatch = endMarker.firstMatch(text);
    if (endMatch != null) text = text.substring(0, endMatch.start).trim();

    return text.replaceAll('\r\n', '\n');
  }

  // ─── BERSIHKAN WIKITEXT WIKISOURCE ───────────────────────────────────────────
  /// Konversi wikitext ke teks bersih dan mudah dibaca
  String _cleanWikitext(String wikitext) {
    String text = wikitext;

    // Hapus template wikisource ({{...}})
    // Hapus template berulang (nested)
    for (int i = 0; i < 5; i++) {
      text = text.replaceAll(RegExp(r'\{\{[^{}]*\}\}'), '');
    }

    // Hapus tag XML/HTML yang masih ada
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // Hapus wikilink — pertahankan teks tampilan [[link|teks]] → teks, [[link]] → link
    text = text.replaceAllMapped(
        RegExp(r'\[\[(?:[^\[\]|]*\|)?([^\[\]]*)\]\]'), (m) => m.group(1) ?? '');

    // Hapus external link [url teks] → teks, [url] → ''
    text = text.replaceAllMapped(
        RegExp(r'\[https?://\S+\s+([^\]]+)\]'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'\[https?://\S+\]'), '');

    // Hapus heading wiki (== Judul == → Judul)
    text = text.replaceAllMapped(
        RegExp(r'^={2,6}\s*(.+?)\s*={2,6}\s*$', multiLine: true),
        (m) => '\n${m.group(1)}\n');

    // Hapus bold/italic markup
    text = text.replaceAll(RegExp(r"'{2,3}"), '');

    // Hapus baris yang hanya berisi titik-titik (dot leaders dari daftar isi scan)
    text = text.replaceAll(RegExp(r'^[\s·\.\u00B7\u2026]+$', multiLine: true), '');

    // Hapus angka halaman berdiri sendiri (sisa dari PDF scan)
    text = text.replaceAll(RegExp(r'^\s*\d{1,4}\s*$', multiLine: true), '');

    // Hapus baris yang hanya huruf tunggal (sisa index)
    text = text.replaceAll(RegExp(r'^\s*[A-Za-z]\.\s*$', multiLine: true), '');

    // Hapus baris kosong berlebih
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Decode entity HTML umum
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    // Filter: Hapus baris-baris pendek yang tidak bermakna (< 3 kata)
    final lines = text.split('\n');
    final meaningfulLines = lines.where((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return true; // pertahankan baris kosong sebagai jeda
      // Hapus baris yang word count < 2 DAN panjang < 15 (kemungkinan noise)
      final words = trimmed.split(RegExp(r'\s+'));
      return words.length >= 2 || trimmed.length >= 15;
    }).toList();

    return meaningfulLines.join('\n').trim();
  }

  // ─── PESAN JIKA TIDAK ADA KONTEN ─────────────────────────────────────────────
  String _noContentMessage(String title, {String? reason}) {
    return '📚 $title\n\n'
        '───────────────────────────\n\n'
        '⚠️ Konten teks tidak tersedia.\n\n'
        '${reason ?? 'Buku ini tidak memiliki versi teks digital yang dapat dibaca langsung.'}\n\n'
        '💡 Saran:\n'
        '• Coba cari judul buku lain (contoh: "sherlock", "alice", "dracula")\n'
        '• Buku dari Project Gutenberg memiliki teks paling lengkap\n'
        '• Jalankan aplikasi di perangkat mobile untuk hasil terbaik';
  }

  // ─── PAGINASI ─────────────────────────────────────────────────────────────────
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

      if (currentWordCount + wordsInP > wordsPerPage && currentPage.isNotEmpty) {
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
