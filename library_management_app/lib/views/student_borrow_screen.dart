import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/isbn_service.dart';

class StudentBorrowScreen extends StatefulWidget {
  const StudentBorrowScreen({super.key});

  @override
  State<StudentBorrowScreen> createState() => _StudentBorrowScreenState();
}

class _StudentBorrowScreenState extends State<StudentBorrowScreen> {
  final _borrowerNameController = TextEditingController();
  final _borrowerIdController = TextEditingController();
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();

  String _selectedRole = 'STUDENT';
  final List<String> _roles = ['STUDENT', 'TEACHER', 'OFFICER', 'ADMIN'];

  bool _isManualIsbn = true;
  int _step = 1;
  bool _isLoading = false;
  List<dynamic> _borrowRecords = [];

  String? _capturedBase64Image;
  final ImagePicker _picker = ImagePicker();

  // Palette
  static const Color softOffWhite = Color(0xFFFAFAF8);
  static const Color cardWhite = Colors.white;
  static const Color inkCharcoal = Color(0xFF2B2E33);
  static const Color mutedForestGreen = Color(0xFF3E5C50);
  static const Color stoneGrayBorder = Color(0xFFD8D4C8);
  static const Color mutedTextGray = Color(0xFF70747C);

  @override
  void initState() {
    super.initState();
    // 👈 Keeps the field blank initially instead of filling a random string
    _borrowerIdController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBorrowRecords();
    });
  }

  @override
  void dispose() {
    _borrowerNameController.dispose();
    _borrowerIdController.dispose();
    _isbnController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Updated filtering logic to remove returned books dynamically from the UI
  Future<void> _fetchBorrowRecords() async {
    try {
      final res = await ApiService.get('/borrow/borrow-records');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _borrowRecords = (data['data'] as List? ?? []).where((item) {
              final status = (item['status'] ?? item['borrow_status'] ?? '')
                  .toString()
                  .toUpperCase();
              final returnedDate =
                  item['returned_date'] ?? item['returnedDate'];

              return status != 'RETURNED' &&
                  status != 'RETURN' &&
                  (returnedDate == null || returnedDate.toString().isEmpty);
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching borrow records: $e');
    }
  }

  void _showBorrowerFaceModal(Map<String, dynamic> record) {
    DateTime borrowedDate =
        DateTime.tryParse(record['borrowed_date'] ?? '') ?? DateTime.now();
    DateTime dueDate =
        DateTime.tryParse(record['due_date'] ?? '') ??
        borrowedDate.add(const Duration(days: 180));
    Duration remaining = dueDate.difference(DateTime.now());
    final photoUrl = record['photo_url'] ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          'Borrower Details: ${record['borrower_name']}',
          style: const TextStyle(
            fontFamily: 'Serif',
            color: inkCharcoal,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: softOffWhite,
              child: ClipOval(
                child: photoUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(photoUrl.split(',').last),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      )
                    : (photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 48,
                                color: mutedForestGreen,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 48,
                              color: mutedForestGreen,
                            )),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: softOffWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: stoneGrayBorder),
              ),
              child: Text(
                record['borrower_role'] ?? 'STUDENT',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedForestGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Borrower ID: ${record['borrower_id']}',
                    style: const TextStyle(color: inkCharcoal, fontSize: 13),
                  ),
                  Text(
                    '• Book Borrowed: ${record['book_title']}',
                    style: const TextStyle(
                      color: inkCharcoal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• ISBN: ${record['book_isbn']}',
                    style: const TextStyle(color: mutedTextGray, fontSize: 13),
                  ),
                  const Divider(height: 20),
                  Text(
                    '• Borrowed Date: ${DateFormat('yyyy-MM-dd').format(borrowedDate)}',
                    style: const TextStyle(color: inkCharcoal, fontSize: 13),
                  ),
                  Text(
                    '• Due Date (6 Months): ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                    style: const TextStyle(
                      color: inkCharcoal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: softOffWhite,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: stoneGrayBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: mutedForestGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '⏳ Remaining Time: ${remaining.inDays > 0 ? "${remaining.inDays} Days" : "Due Today"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: mutedForestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: mutedForestGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showDuplicateBorrowDialog(String isbn, String bookTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: mutedForestGreen, size: 24),
            SizedBox(width: 8),
            Text(
              'Active Borrow Found',
              style: TextStyle(
                fontFamily: 'Serif',
                color: inkCharcoal,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This borrower currently has an active borrowed copy of "$bookTitle" ($isbn). A borrower cannot borrow 2 copies of the same book at once.',
          style: const TextStyle(color: inkCharcoal, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComplaintDialog(isbn, bookTitle);
            },
            child: const Text(
              'Log Issue',
              style: TextStyle(color: mutedTextGray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mutedForestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.post('/borrow/return-book', {
                'isbn': isbn,
              });
              final data = jsonDecode(res.body);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      data['message'] ?? 'Book returned successfully.',
                    ),
                    backgroundColor: mutedForestGreen,
                  ),
                );
                _resetForm();
                _fetchBorrowRecords();
              }
            },
            child: const Text('Return First Copy'),
          ),
        ],
      ),
    );
  }

  void _showComplaintDialog(String isbn, String bookTitle) {
    final complaintController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Report Book Issue',
          style: TextStyle(fontFamily: 'Serif', color: inkCharcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book: $bookTitle ($isbn)',
              style: const TextStyle(color: mutedTextGray, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: complaintController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Describe issue (e.g. missing pages, lost copy, damage)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: mutedTextGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mutedForestGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue logged successfully.'),
                  backgroundColor: mutedForestGreen,
                ),
              );
              _resetForm();
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _step = 1;
      _borrowerNameController.clear();
      _borrowerIdController.clear(); // 👈 Reset clears the text
      _isbnController.clear();
      _titleController.clear();
      _capturedBase64Image = null;
    });
  }

  void _showBookPickerModal() {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> searchBooks(String q) async {
            setModalState(() => isSearching = true);
            try {
              final res = await ApiService.get(
                '/books/search?q=${Uri.encodeComponent(q.trim())}',
              );
              if (res.statusCode == 200) {
                final data = jsonDecode(res.body);
                setModalState(() {
                  searchResults = data['data'] ?? [];
                  isSearching = false;
                });
              }
            } catch (e) {
              setModalState(() => isSearching = false);
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isSearching && searchResults.isEmpty) {
              searchBooks('');
            }
          });

          return AlertDialog(
            backgroundColor: cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: const Text(
              'Select Book from Catalog',
              style: TextStyle(fontFamily: 'Serif', color: inkCharcoal),
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (val) => searchBooks(val),
                    decoration: const InputDecoration(
                      hintText: 'Search title, author, or ISBN...',
                      prefixIcon: Icon(Icons.search, color: inkCharcoal),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isSearching
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: inkCharcoal,
                            ),
                          )
                        : searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No books found in catalog.',
                              style: TextStyle(color: mutedTextGray),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final book = searchResults[index];
                              final int availQty =
                                  book['available_quantity'] ?? 0;
                              final bool isAvailable = availQty > 0;

                              return ListTile(
                                title: Text(
                                  book['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: inkCharcoal,
                                  ),
                                ),
                                subtitle: Text(
                                  'ISBN: ${book['isbn']} | Available: $availQty',
                                  style: const TextStyle(
                                    color: mutedTextGray,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isAvailable
                                        ? inkCharcoal
                                        : mutedTextGray,
                                    side: BorderSide(
                                      color: isAvailable
                                          ? inkCharcoal
                                          : stoneGrayBorder,
                                    ),
                                  ),
                                  onPressed: isAvailable
                                      ? () {
                                          setState(() {
                                            _isbnController.text =
                                                book['isbn'] ?? '';
                                            _titleController.text =
                                                book['title'] ?? '';
                                          });
                                          Navigator.pop(ctx);
                                          _processIsbnCode(
                                            book['isbn'] ?? '',
                                            book['title'],
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    isAvailable ? 'Select' : 'Out of Stock',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: mutedTextGray),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processIsbnCode(String code, [String? explicitTitle]) async {
    if (_borrowerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Borrower Name before proceeding.'),
          backgroundColor: mutedForestGreen,
        ),
      );
      return;
    }

    if (_borrowerIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter Borrower ID before proceeding.'),
          backgroundColor: mutedForestGreen,
        ),
      );
      return;
    }

    setState(() {
      _isbnController.text = code;
      _isLoading = true;
    });

    if (explicitTitle != null && explicitTitle.isNotEmpty) {
      setState(() {
        _titleController.text = explicitTitle;
        _isLoading = false;
        _step = 2;
      });
      return;
    }

    try {
      final bookData = await IsbnService.fetchBookByIsbn(code);
      if (mounted) {
        setState(() {
          _titleController.text = bookData?['title'] ?? 'Selected Book';
          _isLoading = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _titleController.text = 'Selected Book';
          _isLoading = false;
          _step = 2;
        });
      }
    }
  }

  void _onBarcodeScanned(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && _step == 1 && !_isManualIsbn) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        _processIsbnCode(code);
      }
    }
  }

  Future<void> _captureRealFaceImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _capturedBase64Image = base64Str;
          _step = 3;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live photo captured successfully.'),
            backgroundColor: mutedForestGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera Error: $e')));
    }
  }

  void _finalizeBorrow() async {
    if (_capturedBase64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification photo is missing.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final regRes = await ApiService.post('/borrow/register-borrower', {
        'id': _borrowerIdController.text.trim(),
        'name': _borrowerNameController.text.trim(),
        'role': _selectedRole,
        'photoUrl': _capturedBase64Image,
      });

      if (regRes.statusCode != 200 && regRes.statusCode != 201) {
        final err = jsonDecode(regRes.body);
        throw Exception(err['error'] ?? 'Registration failed');
      }

      final payload = {
        'borrowerId': _borrowerIdController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'bookTitle': _titleController.text.trim(),
        'quantity': 1,
      };

      final response = await ApiService.post('/borrow/issue-book', payload);
      final data = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 409 || data['isDuplicate'] == true) {
          _showDuplicateBorrowDialog(
            _isbnController.text.trim(),
            _titleController.text.trim(),
          );
        } else if (response.statusCode == 201 ||
            (response.statusCode == 200 && data['success'] == true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book borrowed successfully for 6 months.'),
              backgroundColor: mutedForestGreen,
            ),
          );
          _resetForm();
          _fetchBorrowRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? data['error'] ?? 'Failed to issue book.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReturnBookDialog([String? prefilledIsbn]) {
    final returnIsbnController = TextEditingController(
      text: prefilledIsbn ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Return Book',
          style: TextStyle(fontFamily: 'Serif', color: inkCharcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter or scan the book ISBN to record return:',
              style: TextStyle(color: mutedTextGray, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: returnIsbnController,
              decoration: const InputDecoration(
                labelText: 'Book ISBN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: mutedTextGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mutedForestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              final isbn = returnIsbnController.text.trim();
              if (isbn.isEmpty) return;

              final res = await ApiService.post('/borrow/return-book', {
                'isbn': isbn,
              });
              final data = jsonDecode(res.body);

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      data['message'] ?? 'Book returned successfully.',
                    ),
                    backgroundColor: mutedForestGreen,
                  ),
                );
                _fetchBorrowRecords();
              }
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        backgroundColor: softOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: inkCharcoal, size: 22),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Borrow & Return Books',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: inkCharcoal,
          ),
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: inkCharcoal,
              side: const BorderSide(color: stoneGrayBorder, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            icon: const Icon(
              Icons.assignment_turned_in_outlined,
              size: 18,
              color: mutedForestGreen,
            ),
            label: const Text('Return Book'),
            onPressed: () => _showReturnBookDialog(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stoneGrayBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_step == 1) ...[
                    const Text(
                      'Step 1: Borrower Information & Book Selection',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: inkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Borrower Role',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _borrowerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Borrower Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 👈 UPDATED BORROWER ID TEXTFIELD
                    TextField(
                      controller: _borrowerIdController,
                      decoration: const InputDecoration(
                        labelText: 'Borrower ID',
                        hintText: 'e.g. C1230**', // 👈 Example placeholder hint
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isManualIsbn
                              ? 'Manual Entry / Catalog Search'
                              : 'Camera Scanner Mode',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: inkCharcoal,
                          ),
                        ),
                        Row(
                          children: [
                            Switch(
                              value: _isManualIsbn,
                              activeColor: mutedForestGreen,
                              onChanged: (val) {
                                setState(() => _isManualIsbn = val);
                              },
                            ),
                            const Text(
                              'Manual Mode',
                              style: TextStyle(
                                color: mutedTextGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isManualIsbn) ...[
                      TextField(
                        controller: _isbnController,
                        decoration: InputDecoration(
                          labelText: 'Enter Book ISBN or Search Catalog',
                          hintText: 'e.g. 9780070601680',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: mutedForestGreen,
                              size: 24,
                            ),
                            tooltip: 'Search Catalog',
                            onPressed: _showBookPickerModal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: mutedForestGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('PROCEED WITH ISBN'),
                        onPressed: () {
                          final code = _isbnController.text.trim();
                          if (code.isNotEmpty) {
                            _processIsbnCode(code);
                          }
                        },
                      ),
                    ] else ...[
                      SizedBox(
                        height: 180,
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
                    ],
                  ] else if (_step == 2) ...[
                    const Text(
                      'Step 2: Verification Photo',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: inkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: mutedForestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('CAPTURE VERIFICATION PHOTO'),
                      onPressed: _captureRealFaceImage,
                    ),
                  ] else if (_step == 3) ...[
                    const Text(
                      'Step 3: Confirm Loan',
                      style: TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: inkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: mutedForestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: _isLoading ? null : _finalizeBorrow,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CONFIRM BORROW TRANSACTION'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Borrowed Log',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: inkCharcoal,
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: inkCharcoal,
                    side: const BorderSide(color: stoneGrayBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () => _showReturnBookDialog(),
                  child: const Text('Return Book'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stoneGrayBorder, width: 1),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 96,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(softOffWhite),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Borrower ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Role',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Name (Click Details)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Book Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'ISBN',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                      ),
                    ],
                    rows: _borrowRecords.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item['borrower_id'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              item['borrower_role'] ?? 'STUDENT',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: () => _showBorrowerFaceModal(item),
                              child: Text(
                                item['borrower_name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: mutedForestGreen,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              item['book_title'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              DateFormat('yyyy-MM-dd').format(
                                DateTime.tryParse(
                                      item['borrowed_date'] ?? '',
                                    ) ??
                                    DateTime.now(),
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              item['book_isbn'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: inkCharcoal,
                                side: const BorderSide(color: stoneGrayBorder),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                              ),
                              onPressed: () =>
                                  _showReturnBookDialog(item['book_isbn']),
                              child: const Text(
                                'Return',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
