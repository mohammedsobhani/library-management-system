import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'book_list_screen.dart';

class PatronDashboardScreen extends StatefulWidget {
  const PatronDashboardScreen({super.key});

  @override
  State<PatronDashboardScreen> createState() => _PatronDashboardScreenState();
}

class _PatronDashboardScreenState extends State<PatronDashboardScreen> {
  List<dynamic> _myBorrowedBooks = [];
  bool _isLoading = true;

  // Minimal Palette
  static const Color softOffWhite = Color(0xFFFAFAF8);
  static const Color cardWhite = Colors.white;
  static const Color inkCharcoal = Color(0xFF2B2E33);
  static const Color mutedForestGreen = Color(0xFF3E5C50);
  static const Color stoneGrayBorder = Color(0xFFD8D4C8);
  static const Color mutedTextGray = Color(0xFF70747C);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color alertRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _fetchMyBooks();
  }

  Future<void> _fetchMyBooks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final borrowerId = user?['id'] ?? user?['email'] ?? '';

    try {
      final res = await ApiService.get(
        '/borrow/my-books?borrowerId=$borrowerId',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _myBorrowedBooks = data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        backgroundColor: softOffWhite,
        elevation: 0,
        title: const Text(
          'My Library Portal',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 22,
            color: inkCharcoal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: inkCharcoal),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PATRON SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stoneGrayBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: softOffWhite,
                    child: Icon(
                      Icons.person_outline,
                      color: mutedForestGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ?? 'Library Patron',
                          style: const TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                        Text(
                          'Role: ${user?['role'] ?? 'STUDENT'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: mutedTextGray,
                          ),
                        ),
                        Text(
                          'Monthly Borrow Limit: ${_myBorrowedBooks.length}/2 Books Used',
                          style: const TextStyle(
                            fontSize: 13,
                            color: mutedForestGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2. MY CURRENTLY BORROWED BOOKS SECTION
            const Text(
              'My Borrowed Books',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: inkCharcoal,
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: mutedForestGreen),
                  )
                : _myBorrowedBooks.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: stoneGrayBorder),
                    ),
                    child: const Text(
                      'You currently have no active borrowed books.',
                      style: TextStyle(color: mutedTextGray),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myBorrowedBooks.length,
                    itemBuilder: (context, index) {
                      final item = _myBorrowedBooks[index];
                      final int remainingDays = item['remaining_days'] ?? 0;
                      final DateTime dueDate =
                          DateTime.tryParse(item['due_date'] ?? '') ??
                          DateTime.now();

                      Color statusColor = mutedForestGreen;
                      if (remainingDays < 0) {
                        statusColor = alertRed;
                      } else if (remainingDays <= 7) {
                        statusColor = warningAmber;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: cardWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: stoneGrayBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              color: mutedForestGreen,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['book_title'] ?? 'Untitled Book',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: inkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ISBN: ${item['book_isbn']}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: mutedTextGray,
                                    ),
                                  ),
                                  Text(
                                    'Due Date: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: mutedTextGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                remainingDays < 0
                                    ? 'Overdue by ${remainingDays.abs()} days'
                                    : '$remainingDays Days Remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 32),

            // 3. CATALOG AVAILABILITY BROWSER BANNER
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stoneGrayBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Browse Library Inventory',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check real-time stock availability. To issue a book, visit the library counter in person.',
                          style: TextStyle(
                            fontSize: 13,
                            color: mutedTextGray.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mutedForestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Check Stock'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
