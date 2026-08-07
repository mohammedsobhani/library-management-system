import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Import html safely for web builds
import 'dart:html' as html;

class AdminProfileHeader extends StatefulWidget {
  const AdminProfileHeader({super.key});

  @override
  State<AdminProfileHeader> createState() => _AdminProfileHeaderState();
}

class _AdminProfileHeaderState extends State<AdminProfileHeader> {
  Uint8List? _imageBytes;
  bool _isUploading = false;

  // 📸 UNIVERSAL PHOTO PICKER (Web & Desktop Compatible)
  void _pickAdminProfileImage() {
    if (kIsWeb) {
      // Direct Web File Browser Launcher
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
            setState(() {
              _imageBytes = reader.result as Uint8List?;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Admin Profile Picture Updated!'),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
      });
    } else {
      // Mobile / Desktop Fallback
      _pickImageMobile();
    }
  }

  Future<void> _pickImageMobile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 👤 CLICKABLE PROFILE AVATAR
          InkWell(
            onTap: _pickAdminProfileImage,
            borderRadius: BorderRadius.circular(50),
            child: Tooltip(
              message: 'Click to upload picture',
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.indigo.shade200,
                    child: _imageBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _imageBytes!,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 44,
                            color: Colors.white,
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, System Admin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Click avatar to set custom profile image',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
