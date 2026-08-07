import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Safe Web File Picker
import 'dart:html' as html;

import '../providers/auth_provider.dart';
import 'book_list_screen.dart';
import 'auto_add_book_screen.dart'; // ✅ Correct file name
import 'student_borrow_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _profileImageBytes;

  // 📸 PICK PROFILE PHOTO (Web & Mobile Compatible)
  void _pickProfilePicture() {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();

          reader.readAsArrayBuffer(file);
          reader.onLoadEnd.listen((e) {
            if (mounted) {
              setState(() {
                _profileImageBytes = reader.result as Uint8List?;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture updated.'),
                  backgroundColor: Color(0xFF3E5C50),
                ),
              );
            }
          });
        }
      });
    } else {
      _pickImageMobile();
    }
  }

  Future<void> _pickImageMobile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _profileImageBytes = bytes;
        });
      }
    }
  }

  // 🚪 FIXED LOGOUT HANDLER
  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Strict Design Palette
    const Color softOffWhite = Color(0xFFFAFAF8);
    const Color cardWhite = Colors.white;
    const Color inkCharcoal = Color(0xFF2B2E33);
    const Color mutedForestGreen = Color(0xFF3E5C50);
    const Color stoneGrayBorder = Color(0xFFD8D4C8);
    const Color mutedTextGray = Color(0xFF70747C);

    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        backgroundColor: softOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Library Dashboard',
          style: TextStyle(
            fontFamily: 'Serif',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: inkCharcoal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: inkCharcoal, size: 20),
            tooltip: 'Log Out',
            onPressed: () => _handleLogout(context, authProvider),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 DYNAMIC ADMIN PROFILE CARD
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: stoneGrayBorder, width: 1),
              ),
              child: Row(
                children: [
                  // Photo Avatar
                  GestureDetector(
                    onTap: _pickProfilePicture,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: softOffWhite,
                      child: ClipOval(
                        child: _profileImageBytes != null
                            ? Image.memory(
                                _profileImageBytes!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : (user?['photoUrl'] != null &&
                                      user!['photoUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      user['photoUrl'],
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_outline,
                                        size: 30,
                                        color: mutedForestGreen,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      size: 30,
                                      color: mutedForestGreen,
                                    )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Profile Details from AuthProvider User
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['name'] ??
                              user?['email']?.split('@').first ??
                              'Admin',
                          style: const TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: inkCharcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${user?['role'] ?? 'ADMIN'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: mutedForestGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Email: ${user?['email'] ?? 'admin@library.com'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: mutedTextGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: inkCharcoal,
                      side: const BorderSide(color: stoneGrayBorder, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _pickProfilePicture,
                    child: const Text(
                      'Edit Photo',
                      style: TextStyle(fontSize: 13, color: inkCharcoal),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SECTION HEADER
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: inkCharcoal,
              ),
            ),
            const SizedBox(height: 16),

            // 🔲 UNIFORM NEUTRAL ACTION TILES GRID
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionTile(
                  context,
                  title: 'Borrow & Return Books',
                  subtitle: 'Manage book availability',
                  icon: Icons.assignment_return_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentBorrowScreen(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  title: 'Add Book Stock',
                  subtitle: 'Scan barcode or enter details',
                  icon: Icons.qr_code_scanner_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AutoAddBookDialog(),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  context,
                  title: 'Browse Books',
                  subtitle: 'View and search inventory',
                  icon: Icons.menu_book_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookListScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔲 UNIFORM MINIMAL TILE BUILDER
  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _HoverTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD8D4C8), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF3E5C50), // Muted Forest Green Accent
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2E33),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF70747C)),
            ),
          ],
        ),
      ),
    );
  }
}

// 🖱️ SUBTLE HOVER STATE ANIMATION WIDGET
class _HoverTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverTile({required this.child, required this.onTap});

  @override
  State<_HoverTile> createState() => _HoverTileState();
}

class _HoverTileState extends State<_HoverTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
