import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  // You might need to change this based on your device
  static const String baseUrl = 'http://10.0.2.2/appdocu1/api'; 
  // static const String baseUrl = 'http://localhost/appdocu1/api';

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload.php'));
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Construct full URL
        // Assuming uploads folder is at http://10.0.2.2/appdocu1/uploads/
        return 'http://10.0.2.2/appdocu1/uploads/${data['fileName']}';
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
