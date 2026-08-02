import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;
  String? _token;

  set token(String? value) => _token = value;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Bypasses the ngrok interstitial page
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(
      _uri(path),
      headers: _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      _uri(path),
      headers: _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  Future<Map<String, dynamic>> uploadImage(
    String path, {
    required String filePath,
    required Map<String, String> fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers['ngrok-skip-browser-warning'] = 'true';
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }
}

