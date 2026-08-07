import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/isbn_service.dart';

class AutoAddBookDialog extends StatefulWidget {
  const AutoAddBookDialog({super.key});

  @override
  State<AutoAddBookDialog> createState() => _AutoAddBookDialogState();
}

class _AutoAddBookDialogState extends State<AutoAddBookDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _publisherController = TextEditingController();
  final _quantityController = TextEditingController(text: '10');

  bool _isScanning = true;
  bool _isLoading = false;

  // 🌿 Theme Palette
  static const Color mutedForestGreen = Color(0xFF3E5C50);
  static const Color softOffWhite = Color(0xFFFAFAF8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Generates a random 5-digit unique ending (e.g. 97800706 + 54321)
  String _generateManualIsbn() {
    final randomDigits = (10000 + Random().nextInt(90000)).toString();
    return '97800706$randomDigits';
  }

  void _onBarcodeScanned(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && _isScanning) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _isLoading = true;
          _isbnController.text = code;
        });

        final bookData = await IsbnService.fetchBookByIsbn(code);
        if (mounted) {
          setState(() {
            _titleController.text = bookData?['title'] ?? 'Scanned Book';
            _authorController.text = bookData?['author'] ?? 'Unknown Author';
            _publisherController.text =
                bookData?['publisher'] ?? 'Standard Publisher';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _saveBookToDatabase() async {
    if (_isbnController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or scan an ISBN and Book Title!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/books/add', {
        'title': _titleController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'author': _authorController.text.trim().isEmpty
            ? 'Unknown Author'
            : _authorController.text.trim(),
        'publisher': _publisherController.text.trim().isEmpty
            ? 'Standard Publisher'
            : _publisherController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
      });

      if (mounted) {
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Book & Stock Added Successfully!'),
              backgroundColor: mutedForestGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['error'] ?? 'Failed to add book'}'),
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
        title: const Text('Add Book Stock'),
        backgroundColor: mutedForestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'MANUAL ENTRY'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'SCAN BARCODE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: MANUAL ENTRY MODE (FAST)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter ISBN & Book Details Manually',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _isbnController,
                  decoration: InputDecoration(
                    labelText: 'ISBN Number (Last 5 digits unique)',
                    hintText: 'e.g. 9780070612345',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.numbers,
                      color: mutedForestGreen,
                    ),
                    suffixIcon: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: mutedForestGreen,
                      ),
                      icon: const Icon(Icons.autorenew, size: 18),
                      label: const Text('Auto 5-Digit'),
                      onPressed: () {
                        setState(() {
                          _isbnController.text = _generateManualIsbn();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book, color: mutedForestGreen),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: mutedForestGreen),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Initial Copies Available (Stock)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.inventory_2,
                      color: mutedForestGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: mutedForestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveBookToDatabase,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE BOOK TO STOCK',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // TAB 2: CAMERA BARCODE SCANNER MODE
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isScanning) ...[
                  const Text(
                    'Scan ISBN Barcode on Book:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: MobileScanner(
                      controller: MobileScannerController(
                        formats: const [
                          BarcodeFormat.ean13,
                          BarcodeFormat.code128,
                        ],
                      ),
                      onDetect: _onBarcodeScanned,
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mutedForestGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('RESCAN BARCODE'),
                    onPressed: () => setState(() => _isScanning = true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'Scanned ISBN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Initial Quantity / Copies Available',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers, color: mutedForestGreen),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: mutedForestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _saveBookToDatabase,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ADD BOOK TO LIBRARY STOCK',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
