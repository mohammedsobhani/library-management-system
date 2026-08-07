import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;
  Timer? _debounce;

  // 🌿 Muted Forest Green Palette
  static const Color mutedForestGreen = Color(0xFF3E5C50);
  static const Color lightGreenBadgeBg = Color(0xFFE8F0EC);
  static const Color softOffWhite = Color(0xFFFAFAF8);

  @override
  void initState() {
    super.initState();
    _fetchBooks('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Predictive search with 300ms debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchBooks(query);
    });
  }

  Future<void> _fetchBooks(String query) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(
        '/books/search?q=${Uri.encodeComponent(query)}',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _books = data['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching books: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🗑️ Delete Confirmation Dialog
  void _confirmDeleteBook(String bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Book'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$bookTitle" from library inventory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _deleteBook(bookId);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.delete('/books/$bookId');
      final data = jsonDecode(res.body);

      if (mounted) {
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Book removed successfully!'),
              backgroundColor: Colors.redAccent,
            ),
          );
          _fetchBooks(_searchController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${data['error'] ?? data['message'] ?? 'Failed to delete'}',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        title: const Text('Browse Library Books'),
        backgroundColor: mutedForestGreen, // 👈 Replaces default blue header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Center Predictive Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText:
                        'Predictive search (e.g. "data", "phys", author, ISBN)...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: mutedForestGreen,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchBooks('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: mutedForestGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: mutedForestGreen),
                  ),
                )
              : _books.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text(
                      'No books currently in stock.\nUse "Add Book" to add stock!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      final String bookId = book['id'].toString();
                      final String title = book['title'] ?? 'Untitled Book';
                      final int totalQty = book['total_quantity'] ?? 1;
                      final int availQty = book['available_quantity'] ?? 0;
                      final int borrowedQty = totalQty - availQty;
                      final bool isAvailable = availQty > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFEFEFEF)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: isAvailable
                                ? lightGreenBadgeBg
                                : Colors.red.shade50,
                            child: Icon(
                              Icons.book_rounded,
                              color: isAvailable
                                  ? mutedForestGreen
                                  : Colors.red.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Author: ${book['author'] ?? 'Unknown'}'),
                              Text('ISBN: ${book['isbn'] ?? 'N/A'}'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '📦 Total Stock: $totalQty  |  📖 Borrowed: $borrowedQty  |  ✅ Left: $availQty',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  isAvailable
                                      ? 'Available ($availQty)'
                                      : 'Out of Stock',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                backgroundColor: isAvailable
                                    ? mutedForestGreen
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Remove Book',
                                onPressed: () =>
                                    _confirmDeleteBook(bookId, title),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
