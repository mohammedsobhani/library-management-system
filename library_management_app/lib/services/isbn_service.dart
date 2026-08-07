import 'dart:convert';
import 'package:http/http.dart' as http;

class IsbnService {
  static Future<Map<String, dynamic>?> fetchBookByIsbn(String isbn) async {
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['totalItems'] != null && data['totalItems'] > 0) {
          final bookInfo = data['items'][0]['volumeInfo'];

          String rawDate = bookInfo['publishedDate']?.toString() ?? '2024';
          RegExp yearRegex = RegExp(r'\d{4}');
          Match? match = yearRegex.firstMatch(rawDate);
          int extractedYear = match != null ? int.parse(match.group(0)!) : 2024;

          return {
            'title': bookInfo['title'] ?? '',
            'publisher': bookInfo['publisher'] ?? '',
            'publishedYear': extractedYear,
            'description': bookInfo['description'] ?? '',
          };
        }
      } else if (response.statusCode == 429) {
        print('Google Books API Rate Limited (429). Please wait a moment.');
      }
    } catch (e) {
      print('ISBN Lookup Error: $e');
    }
    return null;
  }
}
